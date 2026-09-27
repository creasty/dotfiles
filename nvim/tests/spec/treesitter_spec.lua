-- Tree-sitter powered editing: highlighting, indentation, endwise, tags,
-- operator formatting, structural selection, context, custom queries.
local t = require('t')
local probe = require('probe')
local describe, it = t.describe, t.it

local function buffer(name, lines)
  local nvim = t.nvim()
  nvim:edit(name, lines or { '' })
  return nvim
end

local function captures_at(nvim, row, col)
  return nvim:lua(
    [[
    local row, col = ...
    vim.treesitter.get_parser(0):parse(true)
    local names = {}
    for _, c in ipairs(vim.treesitter.get_captures_at_pos(0, row - 1, col)) do
      names[#names + 1] = c.capture .. '@' .. c.lang
    end
    return names
  ]],
    row,
    col
  )
end

describe('Tree-sitter', function()
  it('highlights code with tree-sitter', function()
    for _, name in ipairs({ 'a.ts', 'a.go', 'a.lua', 'a.rb', 'a.py' }) do
      local nvim = buffer(name, { 'x' })
      t.ok(nvim:lua('return vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil'), name)
      nvim:close()
    end
  end)

  describe('indentation', function()
    it('uses nvim-yati for the web and C-family languages, tree-sitter indent elsewhere', function()
      local expect = {
        ['a.ts'] = 'yati',
        ['a.tsx'] = 'yati',
        ['a.js'] = 'yati',
        ['a.lua'] = 'yati',
        ['a.py'] = 'yati',
        ['a.c'] = 'yati',
        ['a.go'] = 'nvim_treesitter',
        ['a.rb'] = 'nvim_treesitter',
      }
      for name, engine in pairs(expect) do
        local nvim = buffer(name, { 'x' })
        t.match(engine, nvim:eval('&l:indentexpr'), name)
        nvim:close()
      end
    end)

    it('o inside a block indents to the block body', function()
      local nvim = buffer('a.ts', { 'function f() {', '  const x = 1;', '}' })
      nvim:type('jox')
      t.eq('  x', nvim:line(3))
    end)
  end)

  describe('endwise', function()
    for _, case in ipairs({
      { 'a.rb', 'def foo', { 'def foo', '  ', 'end' } },
      { 'a.lua', 'function f()', { 'function f()', '  ', 'end' } },
      { 'a.vim', 'function! F() abort', { 'function! F() abort', '  ', 'endfunction' } },
      { 'a.sh', 'if true; then', { 'if true; then', '  ', 'fi' } },
    }) do
      it(('%s: <CR> after "%s" adds the closing keyword'):format(case[1], case[2]), function()
        local nvim = buffer(case[1])
        nvim:type('i' .. case[2] .. '<CR>')
        t.eq(case[3], nvim:lines())
      end)
    end
  end)

  describe('tags', function()
    it('closes a tag as you type it (html, tsx)', function()
      for _, name in ipairs({ 'a.tsx', 'a.html' }) do
        local nvim = buffer(name)
        nvim:type('i<lt>section')
        nvim:type('>')
        t.match('^<section>|?</section>', table.concat(nvim:buffer(), ''), name)
        nvim:close()
      end
    end)

    it('renaming the opening tag renames the closing one', function()
      local nvim = buffer('a.tsx', { '<div>x</div>' })
      nvim:type('lciwspan<Esc>')
      nvim:wait_for(function()
        return nvim:line(1) == '<span>x</span>'
      end)
    end)
  end)

  describe('operator formatting (opfmt)', function()
    -- opfmt is switched off for now (it breaks on Neovim 0.12): these run
    -- again once it is back on.
    local function skip_unless_on(nvim)
      if not probe.opfmt_enabled(nvim) then
        t.skip('opfmt is switched off in the tree-sitter config')
      end
    end

    -- Typed key by key, pausing like a person until the editor has parsed
    -- the syntax tree again: opfmt formats from it, so within one burst of
    -- keys it would format from a tree that lags behind the text.
    local function type_keys(nvim, keys)
      for key in keys:gmatch('.') do
        nvim:type(key == '<' and '<lt>' or key)
        nvim:wait_for(function()
          return nvim:lua('return vim.treesitter.get_parser():is_valid(true)')
        end, { message = 'the syntax tree to be parsed' })
        -- (opfmt formats in a callback scheduled by the parse)
        nvim:lua('return true')
      end
    end

    it('spaces operators and delimiters as you type', function()
      local nvim = buffer('a.ts')
      skip_unless_on(nvim)
      nvim:type('i')
      type_keys(nvim, "foo+=123*fn('abc',{ bar:[4,5]});")
      t.eq({ "foo += 123 * fn('abc', { bar: [4, 5] });" }, nvim:lines())
    end)

    it('typescript: conditions and arrow functions', function()
      local nvim = buffer('a.ts')
      skip_unless_on(nvim)
      nvim:type('i')
      type_keys(nvim, 'if(a&&b||c){')
      t.eq({ 'if (a && b || c) {}' }, nvim:lines())
      nvim:type('<Esc>')
      nvim:set_buffer('|')
      nvim:type('i')
      type_keys(nvim, 'const f=(a,b)=>a*b')
      t.eq({ 'const f = (a, b) => a * b' }, nvim:lines())
    end)

    it('lua: spaces operators as you type', function()
      local nvim = buffer('a.lua')
      skip_unless_on(nvim)
      nvim:type('i')
      type_keys(nvim, 'local x=a+b')
      t.eq({ 'local x = a + b' }, nvim:lines())
    end)
  end)

  describe('structural selection', function()
    it('gs starts and grows a selection by syntax node', function()
      local nvim = buffer('a.ts', { 'const x = f(a, b);' })
      nvim:set_cursor(1, 12)
      nvim:type('gs')
      t.eq('v', nvim:mode())
      t.eq({ 1, 12 }, { nvim:call('line', 'v'), nvim:call('col', 'v') - 1 })
      nvim:type('gs')
      t.eq(11, nvim:call('col', 'v') - 1, 'grew to the argument list')
    end)

    it('vs selects the node under the cursor; s + l / h moves to siblings', function()
      local nvim = buffer('a.ts', { 'f(alpha, beta, gamma);' })
      nvim:set_cursor(1, 9)
      nvim:type('vs')
      t.eq('v', nvim:mode())
      local function selection()
        return nvim:lua([[return table.concat(vim.fn.getregion(vim.fn.getpos('v'), vim.fn.getpos('.'), { type = 'v' }), '\n')]])
      end
      t.eq('beta', selection())
      nvim:type('sl')
      t.eq('gamma', selection())
      nvim:type('shh')
      t.eq('alpha', selection(), 'the submode repeats h')
    end)

    it('vS selects the whole statement; s + k / j go to the parent / child node', function()
      local nvim = buffer('a.ts', { 'const x = f(alpha, beta);' })
      local function selection()
        return nvim:lua([[return table.concat(vim.fn.getregion(vim.fn.getpos('v'), vim.fn.getpos('.'), { type = 'v' }), '\n')]])
      end
      nvim:set_cursor(1, 12)
      nvim:type('vS')
      t.eq('const x = f(alpha, beta);', selection())
      nvim:type('<Esc>')
      nvim:set_cursor(1, 12)
      nvim:type('vs')
      t.eq('alpha', selection())
      nvim:type('sk')
      t.eq('(alpha, beta)', selection())
      nvim:type('sj')
      t.eq('alpha', selection())
    end)

    it('s + L swaps the selected node with the next sibling', function()
      local nvim = buffer('a.ts', { 'f(alpha, beta);' })
      nvim:set_cursor(1, 3)
      nvim:type('vssL')
      t.eq({ 'f(beta, alpha);' }, nvim:lines())
    end)

    it('visual s is taken by the node-surfing keys (it no longer substitutes)', function()
      local nvim = buffer('a.ts', { 'abc' })
      nvim:type('v')
      nvim:type('s')
      t.eq('v', nvim:mode())
      t.eq({ 'abc' }, nvim:lines())
    end)

    t.quirk(
      'vs in a buffer without a tree-sitter parser raises an error',
      'the normal-mode vs mapping calls STSSelectCurrentNode, which assumes a parser',
      function()
        local nvim = buffer('a.txt', { 'abc' })
        nvim:type('vs')
        t.match('Parser could not be created', nvim:messages())
      end
    )
  end)

  it('shows the enclosing function at the top once its header scrolls away', function()
    local lines = { 'function outer() {' }
    for i = 1, 80 do
      lines[#lines + 1] = ('  const v%d = %d;'):format(i, i)
    end
    lines[#lines + 1] = '}'
    local nvim = buffer('a.ts', lines)
    nvim:type('60Gzt')
    nvim:wait_for(function()
      for _, f in ipairs(nvim:floats()) do
        if table.concat(f.lines, '\n'):find('function outer', 1, true) then
          return true
        end
      end
    end, { message = 'the context window' })
  end)

  describe('custom queries', function()
    it('json: nested keys get depth-specific highlights', function()
      local nvim = buffer('a.json', { '{ "a": { "b": { "c": 1 } } }' })
      t.contains(captures_at(nvim, 1, 10), 'property.json.2@json')
      t.contains(captures_at(nvim, 1, 17), 'property.json.3@json')
    end)

    it('package.json: "scripts" values are highlighted as bash', function()
      local nvim = buffer('package.json', { '{', '  "scripts": {', '    "build": "tsc -p . && echo done"', '  }', '}' })
      local langs = nvim:lua([[
        local parser = vim.treesitter.get_parser(0)
        parser:parse(true)
        local langs = {}
        for lang in pairs(parser:children()) do langs[#langs + 1] = lang end
        return langs
      ]])
      t.contains(langs, 'bash')
    end)

    it('dein toml: hook_add / hook_source are highlighted as vim', function()
      local nvim = buffer('plugins.toml', { '[[plugins]]', "repo = 'x/y'", "hook_add = '''", 'let g:x = 1', "'''" })
      local langs = nvim:lua([[
        local parser = vim.treesitter.get_parser(0)
        parser:parse(true)
        local langs = {}
        for lang in pairs(parser:children()) do langs[#langs + 1] = lang end
        return langs
      ]])
      t.contains(langs, 'vim')
    end)

    it('typescript: decorator objects are attributes, #private fields are private members', function()
      local nvim = buffer('a.ts', { 'class A {', '  @computed.struct', '  #secret = 1;', '}' })
      t.contains(captures_at(nvim, 2, 3), 'attribute@typescript')
      t.contains(captures_at(nvim, 3, 3), 'variable.member.private@typescript')
    end)
  end)
end)

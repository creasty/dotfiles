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
    it("indents with nvim-treesitter's queries", function()
      for _, name in ipairs({ 'a.ts', 'a.tsx', 'a.js', 'a.lua', 'a.py', 'a.c', 'a.go', 'a.rb' }) do
        local nvim = buffer(name, { 'x' })
        t.match('nvim%-treesitter', nvim:eval('&l:indentexpr'), name)
        nvim:close()
      end
    end)

    it('o inside a block indents to the block body', function()
      local nvim = buffer('a.ts', { 'function f() {', '  const x = 1;', '}' })
      nvim:type('jox')
      t.eq('  x', nvim:line(3))
    end)

    -- (nvim/queries/typescript/indents.scm and tsx/indents.scm)
    it('typescript: = keeps what prettier formats', function()
      local lines = {
        'export type Config =',
        '  | UserConfig',
        '  | Promise<UserConfig>',
        '',
        'type Resolved = Omit<',
        '  Options,',
        "  'root'",
        '>',
        '',
        'const hosts = raw',
        "  .split(',')",
        '  .map((host) => host.trim())',
        '',
        'const value =',
        '  compute(() => {',
        '    return 1',
        '  })',
        '',
        'const options = {',
        '  createEnvironment:',
        "    name === 'client'",
        '      ? createClient',
        '      : createServer,',
        '}',
        '',
        'const message = `',
        '  Hello,',
        '    world',
        '`',
      }
      local nvim = buffer('a.ts', lines)
      nvim:type('gg=G')
      t.eq(lines, nvim:lines())
    end)

    it('tsx: = keeps what prettier formats', function()
      local lines = {
        'export function Row({',
        '  row,',
        '}: {',
        '  row: RowData',
        '}) {',
        '  return (',
        '    <ul>',
        '      {[',
        "        'light',",
        "        'dark',",
        '      ].map((name) => (',
        '        <li key={name}>{name}</li>',
        '      ))}',
        '    </ul>',
        '  )',
        '}',
        '',
        'const Label = ({',
        '  text,',
        '}: {',
        '  text: string',
        '}) => (',
        '  <span>{text}</span>',
        ')',
      }
      local nvim = buffer('a.tsx', lines)
      nvim:type('gg=G')
      t.eq(lines, nvim:lines())
    end)

    it('o in a multi-line template string keeps the indentation of the line above', function()
      local nvim = buffer('a.ts', { 'const message = `', '  Hello,', '`' })
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
    -- opfmt is off until it moves to nvim-treesitter's main branch: these
    -- run again once it is back on.
    local function skip_unless_on(nvim)
      if not probe.opfmt_enabled(nvim) then
        t.skip("opfmt is off until it moves to nvim-treesitter's main branch")
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

    it('typescript: decorator objects are attributes, #private fields are private members', function()
      local nvim = buffer('a.ts', { 'class A {', '  @computed.struct', '  #secret = 1;', '}' })
      t.contains(captures_at(nvim, 2, 3), 'attribute@typescript')
      t.contains(captures_at(nvim, 3, 3), 'variable.member.private@typescript')
    end)
  end)
end)

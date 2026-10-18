-- Snippet workflow (LuaSnip today). The library itself is pinned by the
-- snippet_library_* specs; this covers how you drive snippets.
local t = require('t')
local probe = require('probe')
local snippets = require('snippets')
local library = require('snippet_library')
local describe, it = t.describe, t.it

local function buffer_with(filetype, name, lines)
  local nvim = t.nvim()
  nvim:edit(name, lines or { '' })
  nvim:cmd('set filetype=' .. filetype)
  probe.wait_services(nvim)
  return nvim
end

describe('Snippets', function()
  it('<Tab> expands the trigger before the cursor', function()
    local nvim = buffer_with('go', 'main.go')
    nvim:type('A')
    probe.expand(nvim, 'if')
    t.buffer(nvim, { 'if | {', '\t', '}' })
    t.ok(probe.snippet_active(nvim))
  end)

  it('<Tab> without a trigger inserts indentation', function()
    local nvim = buffer_with('text', 'notes.txt')
    nvim:type('A<Tab>x')
    t.buffer(nvim, '  x|')
  end)

  -- Each step is its own burst: the engine selects placeholders
  -- asynchronously, and nobody types within microseconds of <Tab>.
  it('typing replaces the selected placeholder; then <C-s><C-n> / <C-s><C-p> jump', function()
    local nvim = buffer_with('go', 'main.go')
    nvim:type('A')
    probe.expand(nvim, 'func')
    t.eq('s', nvim:mode(), 'first placeholder is selected')
    nvim:type('run')
    nvim:type('<C-s><C-n>')
    t.eq('s', nvim:mode(), 'next placeholder is selected')
    nvim:type('x int')
    nvim:type('<C-s><C-n>')
    nvim:type('error')
    t.eq({ 'func run(x int) error {', '\t', '}' }, nvim:lines())
    nvim:type('<C-s><C-p>')
    t.eq('s', nvim:mode())
    nvim:type('int')
    t.eq({ 'func run(int) error {', '\t', '}' }, nvim:lines())
  end)

  it('the last jump lands on $0', function()
    local nvim = buffer_with('go', 'main.go')
    nvim:type('A')
    probe.expand(nvim, 'func')
    nvim:type('run')
    nvim:type('<C-s><C-n>')
    nvim:type('x')
    nvim:type('<C-s><C-n>')
    nvim:type('int')
    nvim:type('<C-s><C-n>')
    t.buffer(nvim, { 'func run(x) int {', '\t|', '}' })
    t.eq('i', nvim:mode())
  end)

  it('<C-s><C-n> on a still-selected placeholder keeps it and jumps to the next one', function()
    local nvim = buffer_with('go', 'main.go')
    nvim:type('A')
    probe.expand(nvim, 'func')
    t.eq('s', nvim:mode())
    nvim:type('<C-s><C-n>')
    t.eq('s', nvim:mode(), 'the next placeholder is selected')
    nvim:type('x')
    t.eq({ 'func name(x) type {', '\t', '}' }, nvim:lines())
  end)

  it('mirrors update while typing', function()
    local nvim = buffer_with('c', 'main.c')
    nvim:type('A')
    probe.expand(nvim, 'def')
    nvim:type('DEBUG')
    t.eq({ '#ifndef DEBUG', '#define DEBUG value', '#endif' }, nvim:lines())
  end)

  it('<Tab> on a selection cuts it for the next snippet ($TM_SELECTED_TEXT)', function()
    local nvim = buffer_with('go', 'main.go', { 'return 1' })
    nvim:type('V<C-g><Tab>')
    t.eq('i', nvim:mode())
    t.eq({ '' }, nvim:lines())
    probe.expand(nvim, 'func')
    t.eq({ 'func name(params) type {', '\treturn 1', '}' }, nvim:lines())
  end)

  describe('arrows (all filetypes)', function()
    it('typescript: x=<Tab> becomes a fat arrow, x-<Tab> a thin arrow', function()
      local nvim = buffer_with('typescript', 'app.ts')
      nvim:type('A')
      probe.expand(nvim, 'const f = ()=')
      t.buffer(nvim, 'const f = () => |')
      nvim:type('<Esc>')
      nvim:set_buffer('|')
      nvim:type('A')
      probe.expand(nvim, 'a-')
      t.buffer(nvim, 'a -> |')
    end)

    it('<Tab> right after an arrow flips its direction', function()
      local nvim = buffer_with('text', 'notes.txt')
      nvim:type('A')
      probe.expand(nvim, 'a ->')
      t.buffer(nvim, 'a <- |')
    end)
  end)

  describe('in the completion menu', function()
    --- The items the menu offers once `text` is typed on a line of its own.
    local function offered(nvim, text)
      nvim:cmd('stopinsert')
      nvim:set_buffer('|')
      nvim:type('A' .. text)
      pcall(probe.wait_completion, nvim, { timeout = 300 })
      return probe.completion(nvim).items
    end

    it('a line-start snippet only at the start of a line', function()
      local nvim = buffer_with('javascript', 'app.js')
      t.contains(offered(nvim, 'cl'), 'clog')
      t.contains(offered(nvim, '  cl'), 'clog')
      for _, text in ipairs({ 'x = cl', '-', '-cl', 'user.cl' }) do
        t.no(vim.tbl_contains(offered(nvim, text), 'clog'), 'clog offered after ' .. text)
      end
      t.no(vim.tbl_contains(offered(nvim, '-'), 'lorem'), 'lorem offered after -')
    end)

    it('a snippet typed out comes first, ahead of a word that matches as well', function()
      local nvim = buffer_with('ruby', 'app.rb', { 'users.each { |u| u }', '' })
      nvim:type('G')
      nvim:type('A')
      probe.expand(nvim, 'items.each')
      t.eq('items.each { ||  }', nvim:line(2))
    end)

    it('none after a lone -, so an arrow expands among words', function()
      local nvim = buffer_with('text', 'notes.txt', { 'some words here', '' })
      nvim:type('G')
      nvim:type('A')
      probe.expand(nvim, 'x -')
      t.eq('x -> ', nvim:line(2))
    end)

    it('a snippet after whitespace only there', function()
      local nvim = buffer_with('sh', 'script.sh')
      t.contains(offered(nvim, 'cat a | tee'), 'teepipe')
      t.no(vim.tbl_contains(offered(nvim, 'cat a |tee'), 'teepipe'), 'teepipe offered after |')
    end)
  end)

  describe('postfix snippets', function()
    it('typescript: count.times<Tab> makes an array of as many indices', function()
      local nvim = buffer_with('typescript', 'app.ts')
      nvim:type('A')
      probe.expand(nvim, 'const xs = count.times')
      t.buffer(nvim, 'const xs = Array.from({ length: count }, (_, i) => i|)')
    end)

    it('typescript: the menu offers times after 10.tim, and <Tab> expands it in place of 10.', function()
      local nvim = buffer_with('typescript', 'app.ts')
      nvim:type('Aconst xs = 10.tim')
      probe.wait_completion(nvim, { item = 'times' })
      nvim:type('<Tab>')
      nvim:wait_for(function()
        return nvim:line(1) ~= 'const xs = 10.tim'
      end)
      t.buffer(nvim, 'const xs = Array.from({ length: 10 }, (_, i) => i|)')
    end)
  end)

  describe('keyi (a JSX key from an index)', function()
    local function list(callback)
      return { 'const list = (', '  <ul>', '    {items.map(' .. callback .. ' => (', '      <Row />', '    ))}', '  </ul>', ');' }
    end

    it('javascriptreact: takes the index of the .map() callback the element is in', function()
      local nvim = buffer_with('javascriptreact', 'app.jsx', list('(item, idx)'))
      nvim:type('4G0f/i')
      probe.expand(nvim, 'keyi')
      t.eq('      <Row key={idx /* eslint-disable-line react/no-array-index-key */}/>', nvim:line(4))
    end)

    it('typescriptreact: takes it from a typed parameter too', function()
      local nvim = buffer_with('typescriptreact', 'app.tsx', list('(item: Item, n: number)'))
      nvim:type('4G0f/i')
      probe.expand(nvim, 'keyi')
      t.eq('      <Row key={n /* eslint-disable-line react/no-array-index-key */}/>', nvim:line(4))
    end)
  end)

  describe('filetype inheritance', function()
    it('javascript gets the C-like statements', function()
      local nvim = buffer_with('javascript', 'app.js')
      nvim:type('A')
      probe.expand(nvim, 'while')
      t.buffer(nvim, { 'while (|) {', '  ', '}' })
    end)

    it('typescript gets the javascript snippets', function()
      local nvim = buffer_with('typescript', 'app.ts')
      nvim:type('A')
      probe.expand(nvim, 'clog')
      t.buffer(nvim, 'console.log(|);')
    end)

    it('typescriptreact gets typescript and javascriptreact snippets', function()
      local nvim = buffer_with('typescriptreact', 'app.tsx')
      nvim:type('A')
      probe.expand(nvim, 'useRef')
      t.match('useRef', nvim:line(1))
      nvim:type('<Esc>')
      nvim:set_buffer('|')
      nvim:type('A')
      probe.expand(nvim, 'keyi')
      t.match('key=', nvim:line(1))
    end)

    it('bash and zsh get the sh snippets', function()
      for _, ft in ipairs({ 'bash', 'zsh' }) do
        local nvim = buffer_with(ft, 'script.' .. ft)
        nvim:type('A')
        probe.expand(nvim, 'set')
        t.eq({ 'set -euo pipefail' }, nvim:lines(), ft)
        nvim:close()
      end
    end)

    it('sql.bq gets the sql and bq snippets', function()
      local nvim = buffer_with('sql.bq', 'query.bq.sql')
      nvim:type('A')
      probe.expand(nvim, 'day_ago')
      t.neq({ 'day_ago  ' }, nvim:lines())
      t.neq({ 'day_ago' }, nvim:lines())
    end)
  end)

  it('the snippet library specs cover every snippet file', function()
    local covered = {}
    for _, shard in ipairs(library.shards) do
      for _, name in ipairs(shard) do
        covered[name] = true
      end
    end
    for _, name in ipairs(snippets.files()) do
      if #snippets.read(name) > 0 then
        t.ok(covered[name], ('%s.snippets is not in any shard of lib/snippet_library.lua'):format(name))
      end
    end
  end)
end)

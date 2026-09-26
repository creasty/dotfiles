-- Snippet workflow (UltiSnips today). The library itself is pinned by the
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
  probe.disable_completion(nvim)
  probe.wait_services(nvim)
  return nvim
end

describe('Snippets', function()
  it('<Tab> expands the trigger before the cursor', function()
    local nvim = buffer_with('go', 'main.go')
    nvim:type('Aif<Tab>')
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
    nvim:type('Afunc<Tab>')
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
    nvim:type('Afunc<Tab>')
    nvim:type('run')
    nvim:type('<C-s><C-n>')
    nvim:type('x')
    nvim:type('<C-s><C-n>')
    nvim:type('int')
    nvim:type('<C-s><C-n>')
    t.buffer(nvim, { 'func run(x) int {', '\t|', '}' })
    t.eq('i', nvim:mode())
  end)

  t.quirk(
    '<C-s><C-n> on a still-selected placeholder switches to Visual mode instead of jumping',
    'the jump keys are `vmap`s, which switch Select mode to Visual mode (:h Select-mode-mapping), while the engines map their jump <Plug>s for Select mode only; type into the placeholder first, then jump',
    function()
      local nvim = buffer_with('go', 'main.go')
      nvim:type('Afunc<Tab>')
      t.eq('s', nvim:mode())
      nvim:type('<C-s><C-n>')
      t.eq('v', nvim:mode())
      t.eq({ 'func name(params) type {', '\t', '}' }, nvim:lines())
    end
  )

  it('mirrors update while typing', function()
    local nvim = buffer_with('c', 'main.c')
    nvim:type('Adef<Tab>')
    nvim:type('DEBUG')
    t.eq({ '#ifndef DEBUG', '#define DEBUG value', '#endif' }, nvim:lines())
  end)

  t.quirk(
    '<Tab> on a selection does not capture it for ${VISUAL}; it just leaves Select mode',
    "UltiSnips' Select-mode expand key calls ExpandSnippet(); ${VISUAL} is captured only by its Visual-mode key, which is not mapped",
    function()
      local nvim = buffer_with('go', 'main.go', { 'return 1' })
      -- The select-mode <Tab> mapping is installed on the first InsertEnter.
      nvim:type('i<Esc>')
      nvim:type('V<C-g><Tab>')
      t.eq('n', nvim:mode())
      t.eq({ 'return 1' }, nvim:lines())
    end
  )

  describe('arrows and headings (all filetypes)', function()
    it('typescript: x=<Tab> becomes a fat arrow, x-<Tab> a thin arrow', function()
      local nvim = buffer_with('typescript', 'app.ts')
      nvim:type('Aconst f = ()=<Tab>')
      t.buffer(nvim, 'const f = () => |')
      nvim:type('<Esc>')
      nvim:set_buffer('|')
      nvim:type('Aa-<Tab>')
      t.buffer(nvim, 'a -> |')
    end)

    it('<Tab> right after an arrow flips its direction', function()
      local nvim = buffer_with('text', 'notes.txt')
      nvim:type('Aa -><Tab>')
      t.buffer(nvim, 'a <- |')
    end)

    it('/ and // at the start of a line become section headings', function()
      local nvim = buffer_with('typescript', 'app.ts')
      nvim:type('A/<Tab>Title')
      t.eq({ '//=== Title', '//' .. string.rep('=', 94) }, nvim:lines())
    end)
  end)

  describe('postfix snippets', function()
    it('go: err.nn<Tab> wraps the expression in a nil check', function()
      local nvim = buffer_with('go', 'main.go')
      nvim:type('Aerr.nn<Tab>')
      t.buffer(nvim, { 'if err != nil {', '\t|', '}' })
    end)

    it('typescript: user.if<Tab> wraps the expression in an if', function()
      local nvim = buffer_with('typescript', 'app.ts')
      nvim:type('Auser.if<Tab>')
      t.buffer(nvim, { 'if (user) {', '  |', '}' })
    end)
  end)

  describe('filetype inheritance', function()
    it('javascript gets the C-like statements', function()
      local nvim = buffer_with('javascript', 'app.js')
      nvim:type('Awhile<Tab>')
      t.buffer(nvim, { 'while (|) {', '  ', '}' })
    end)

    it('typescript gets the javascript snippets', function()
      local nvim = buffer_with('typescript', 'app.ts')
      nvim:type('Aclog<Tab>')
      t.buffer(nvim, 'console.log(|);')
    end)

    it('typescriptreact gets typescript and javascriptreact snippets', function()
      local nvim = buffer_with('typescriptreact', 'app.tsx')
      nvim:type('AuseRef<Tab>')
      t.match('useRef', nvim:line(1))
      nvim:type('<Esc>')
      nvim:set_buffer('|')
      nvim:type('Akeyi<Tab>')
      t.match('key=', nvim:line(1))
    end)

    it('bash and zsh get the sh snippets', function()
      for _, ft in ipairs({ 'bash', 'zsh' }) do
        local nvim = buffer_with(ft, 'script.' .. ft)
        nvim:type('Aset<Tab>')
        t.eq({ 'set -euo pipefail' }, nvim:lines(), ft)
        nvim:close()
      end
    end)

    it('sql.bq gets the sql and bq snippets', function()
      local nvim = buffer_with('sql.bq', 'query.bq.sql')
      nvim:type('Aday_ago<Tab>')
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

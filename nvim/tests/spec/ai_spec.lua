-- AI inline suggestions (copilot.vim today) against fakes/copilot.lua, which
-- only suggests after specific text (see SUGGESTIONS there).
local t = require('t')
local probe = require('probe')
local describe, it = t.describe, t.it

--- Opens `name`, enters insert mode and waits for the AI client to attach
--- (it starts on the first InsertEnter).
local function insert_in(name, lines, opts)
  opts = opts or {}
  local nvim = t.nvim()
  if opts.project then
    nvim:files({ ['.git/'] = true })
  end
  nvim:edit(name, lines or { '' })
  if opts.filetype then
    nvim:cmd('set filetype=' .. opts.filetype)
  end
  probe.wait_services(nvim)
  if opts.project then
    probe.wait_lsp(nvim)
  end
  nvim:type('A')
  probe.wait_ai(nvim)
  return nvim
end

describe('AI suggestions', function()
  it('show up as ghost text after a short pause', function()
    local nvim = insert_in('app.ts')
    nvim:type('return ')
    probe.wait_ghost(nvim, "'from ai';")
    t.eq({ 'return ' }, nvim:lines(), 'ghost text is not inserted')
  end)

  it('<C-s><C-j> accepts the suggestion and stays in insert mode', function()
    local nvim = insert_in('app.ts')
    nvim:type('return ')
    probe.wait_ghost(nvim, "'from ai';")
    nvim:type('<C-s><C-j>')
    t.buffer(nvim, "return 'from ai';|")
    t.eq('i', nvim:mode())
  end)

  it('<C-s><C-j> accepts a multi-line suggestion', function()
    local nvim = insert_in('app.ts')
    nvim:type('class Greeter ')
    probe.wait_ghost(nvim, "hello = 'world';")
    nvim:type('<C-s><C-j>')
    t.eq({ 'class Greeter {', "  hello = 'world';", '}' }, nvim:lines())
  end)

  it('<C-s><C-j> without a suggestion does nothing', function()
    local nvim = insert_in('app.ts')
    nvim:type('let y')
    nvim:type('<C-s><C-j>')
    t.buffer(nvim, 'let y|')
    t.eq('i', nvim:mode())
  end)

  it('<Tab> does not accept the suggestion (it indents)', function()
    local nvim = insert_in('app.ts')
    nvim:type('return ')
    probe.wait_ghost(nvim, "'from ai';")
    nvim:type('<Tab>')
    t.eq({ 'return  ' }, nvim:lines(), 'indented to the next tab stop')
  end)

  it('<Esc> dismisses the suggestion and stays in insert mode; the next <Esc> leaves', function()
    local nvim = insert_in('app.ts')
    nvim:type('return ')
    probe.wait_ghost(nvim, "'from ai';")
    nvim:type('<Esc>')
    t.eq('i', nvim:mode())
    t.eq('', probe.ghost_text(nvim))
    nvim:type('<Esc>')
    t.eq('n', nvim:mode())
    t.eq({ 'return ' }, nvim:lines(), 'the suggestion was not inserted')
  end)

  it('<C-s><C-c> dismisses the suggestion', function()
    local nvim = insert_in('app.ts')
    nvim:type('return ')
    probe.wait_ghost(nvim, "'from ai';")
    nvim:type('<C-s><C-c>')
    t.eq('i', nvim:mode())
    t.eq('', probe.ghost_text(nvim))
    t.eq({ 'return ' }, nvim:lines())
  end)

  describe('stay out of the way', function()
    it('are hidden while the completion menu is open', function()
      local nvim = insert_in('main.go', { 'package main', '' }, { project = true })
      nvim:type('<Esc>Gox := e2e')
      probe.wait_completion(nvim, { item = 'e2eAlpha' })
      nvim:sleep(800)
      t.no_match('from ai', probe.ghost_text(nvim))
    end)

    it('are suppressed while a snippet trigger can be expanded', function()
      local nvim = insert_in('notes.txt')
      probe.disable_completion(nvim)
      nvim:type('lorem')
      nvim:sleep(800)
      t.no_match('from ai', probe.ghost_text(nvim))
      nvim:type('<Tab>')
      t.match('^Lorem ipsum dolor', nvim:line(1), 'the snippet still expands')
    end)

    it('are dismissed when a signature help popup opens', function()
      local nvim = insert_in('app.js', { '' }, { project = true })
      nvim:type('function greet(')
      nvim:wait_for(function()
        for _, f in ipairs(nvim:floats()) do
          if table.concat(f.lines, '\n'):find('greet(first, second)', 1, true) then
            return true
          end
        end
      end)
      nvim:sleep(800)
      t.no_match("return 'hello'", probe.ghost_text(nvim))
    end)

    t.quirk(
      'are suppressed right after " = " (the fat-arrow snippet could expand there)',
      'the all-filetype snippet /(\\S?)(?<![<=])(={1,2})\\s?/ matches "= ", and AI suggestions are disabled whenever a snippet can expand',
      function()
        local nvim = insert_in('app.ts')
        nvim:type('const answer = ')
        nvim:sleep(1000)
        t.eq('', probe.ghost_text(nvim))
      end
    )
  end)

  describe('filetypes', function()
    it('are offered in Markdown', function()
      local nvim = insert_in('notes.md')
      nvim:type('The quick brown ')
      probe.wait_ghost(nvim, 'fox jumps over the lazy dog.')
    end)

    it('are offered in YAML', function()
      local nvim = insert_in('config.yml')
      nvim:type('greeting: ')
      probe.wait_ghost(nvim, 'hello world')
    end)

    it('are not offered in git commit messages', function()
      local nvim = t.nvim()
      nvim:edit('COMMIT_EDITMSG', { '' })
      t.eq('gitcommit', nvim:filetype())
      nvim:type('AThe quick brown ')
      nvim:sleep(1000)
      t.eq('', probe.ghost_text(nvim))
    end)
  end)
end)

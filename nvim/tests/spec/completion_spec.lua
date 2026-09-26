-- Completion menu workflow (coc.nvim today). Items come from the fake
-- language server (e2eAlpha, e2eBeta, e2eGamma, e2eSnippet), buffer words,
-- file paths and the UltiSnips library.
local t = require('t')
local probe = require('probe')
local describe, it = t.describe, t.it

local function go_buffer(extra_lines)
  local nvim = t.nvim()
  nvim:files({ ['.git/'] = true })
  local lines = { 'package main', '', 'func main() {', '\t|', '}' }
  if extra_lines then
    table.insert(lines, 3, '')
    for i = #extra_lines, 1, -1 do
      table.insert(lines, 3, extra_lines[i])
    end
  end
  local text, cursor = {}, nil
  for i, line in ipairs(lines) do
    local s = line:find('|', 1, true)
    if s then
      cursor = { i, s - 1 }
      line = line:sub(1, s - 1) .. line:sub(s + 1)
    end
    text[i] = line
  end
  nvim:edit('main.go', text)
  nvim:set_cursor(cursor[1], cursor[2])
  probe.wait_lsp(nvim)
  return nvim
end

describe('Completion', function()
  it('opens automatically while typing, listing language server items in their order', function()
    local nvim = go_buffer()
    nvim:type('a')
    nvim:type('e2e')
    local menu = probe.wait_completion(nvim, { item = 'e2eSnippet' })
    t.eq('e2eAlpha', menu.items[1])
    t.eq('e2eBeta', menu.items[2])
    t.eq('e2eGamma', menu.items[3])
    t.ok(vim.startswith(menu.items[4], 'e2eSnippet'))
  end)

  it('preselects the first item; <Tab> accepts it and stays in insert mode', function()
    local nvim = go_buffer()
    nvim:type('ae2eB')
    local menu = probe.wait_completion(nvim, { item = 'e2eBeta' })
    t.eq('e2eBeta', menu.selected)
    nvim:type('<Tab>')
    t.buffer(nvim, { 'package main', '', 'func main() {', '\te2eBeta|', '}' })
    t.eq('i', nvim:mode())
    t.no(probe.completion_visible(nvim))
  end)

  it('<CR> accepts the selected item without inserting a newline', function()
    local nvim = go_buffer()
    nvim:type('ae2eG')
    probe.wait_completion(nvim, { item = 'e2eGamma' })
    nvim:type('<CR>')
    t.buffer(nvim, { 'package main', '', 'func main() {', '\te2eGamma|', '}' })
  end)

  it('<C-n> / <C-p> and <Down> / <Up> move the selection', function()
    local nvim = go_buffer()
    nvim:type('ae2e')
    probe.wait_completion(nvim, { item = 'e2eGamma' })
    nvim:type('<C-n>')
    t.eq('e2eBeta', probe.completion(nvim).selected)
    nvim:type('<Down>')
    t.eq('e2eGamma', probe.completion(nvim).selected)
    nvim:type('<C-p>')
    t.eq('e2eBeta', probe.completion(nvim).selected)
    nvim:type('<Up>')
    t.eq('e2eAlpha', probe.completion(nvim).selected)
    nvim:type('<C-n><C-n><Tab>')
    t.eq('\te2eGamma', nvim:line(4))
  end)

  it('<Esc> closes the menu but stays in insert mode; the next <Esc> leaves', function()
    local nvim = go_buffer()
    nvim:type('ae2e')
    probe.wait_completion(nvim)
    nvim:type('<Esc>')
    t.eq('i', nvim:mode())
    t.no(probe.completion_visible(nvim))
    t.eq('\te2e', nvim:line(4), 'typed text is kept')
    nvim:type('<Esc>')
    t.eq('n', nvim:mode())
  end)

  it('<C-c> closes the menu like <Esc>', function()
    local nvim = go_buffer()
    nvim:type('ae2e')
    probe.wait_completion(nvim)
    nvim:type('<C-c>')
    t.eq('i', nvim:mode())
    t.no(probe.completion_visible(nvim))
  end)

  it('<C-l> refreshes an open menu (and otherwise inserts nothing)', function()
    local nvim = go_buffer()
    nvim:type('ae2e')
    probe.wait_completion(nvim)
    nvim:type('<C-l>')
    probe.wait_completion(nvim, { item = 'e2eAlpha' })
    t.eq('\te2e', nvim:line(4))
    nvim:type('<Esc>')
    nvim:sleep(300)
    nvim:type('<C-l>')
    t.eq('\te2e', nvim:line(4))
  end)

  it('shows the rest of the selected item as inline preview text', function()
    local nvim = go_buffer()
    nvim:type('ae2eA')
    probe.wait_completion(nvim, { item = 'e2eAlpha' })
    t.contains(probe.ghost_text(nvim), 'lpha')
  end)

  it('offers words from the buffer', function()
    local nvim = go_buffer({ '// alphabet soup' })
    nvim:type('aalph')
    local menu = probe.wait_completion(nvim, { item = 'alphabet' })
    t.contains(menu.items, 'alphabet')
  end)

  it('completes file paths after ./', function()
    local nvim = go_buffer()
    nvim:files({ ['assets/logo.png'] = 'x', ['assets/icon.svg'] = 'x' })
    nvim:type('a"./assets/')
    local menu = probe.wait_completion(nvim, { item = 'icon.svg' })
    t.contains(menu.items, 'logo.png')
  end)

  it('offers snippets from the snippet library; accepting one expands it', function()
    local nvim = go_buffer()
    nvim:type('<Esc>ofor')
    probe.wait_completion(nvim, { item = 'for' })
    local menu = probe.completion(nvim)
    t.eq('for', menu.selected)
    nvim:type('<Tab>')
    nvim:wait_for(function()
      return nvim:line(5) ~= '\tfor'
    end)
    t.eq({ '\tfor  {', '\t\t', '\t}' }, { nvim:line(5), nvim:lines()[6], nvim:lines()[7] })
    t.ok(probe.snippet_active(nvim))
  end)

  describe('snippet items from the language server', function()
    it('expand with the first placeholder selected; typing replaces it', function()
      local nvim = go_buffer()
      nvim:type('ae2eSn')
      probe.wait_completion(nvim, { item = 'e2eSnippet' })
      nvim:type('<Tab>')
      nvim:wait_mode('s')
      t.eq('\te2eSnippet(first, second)', nvim:line(4))
      nvim:type('X')
      t.buffer(nvim, { 'package main', '', 'func main() {', '\te2eSnippet(X|, second)', '}' })
    end)

    it('<C-s><C-n> / <C-s><C-p> jump between placeholders', function()
      local nvim = go_buffer()
      nvim:type('ae2eSn')
      probe.wait_completion(nvim, { item = 'e2eSnippet' })
      nvim:type('<Tab>')
      nvim:wait_mode('s')
      -- A person reads the placeholder first: typing into it within coc's
      -- first few hundred milliseconds can end the snippet session.
      nvim:sleep(500)
      nvim:type('X', { wait = 1000 })
      nvim:type('<C-s><C-n>')
      nvim:wait_mode('s')
      nvim:type('Y', { wait = 1000 })
      t.eq('\te2eSnippet(X, Y)', nvim:line(4))
      nvim:type('<C-s><C-p>')
      nvim:wait_mode('s')
      nvim:type('Z')
      t.eq('\te2eSnippet(Z, Y)', nvim:line(4))
    end, { retry = 4 })

    -- coc's snippet sessions trip over each other when two run at the same
    -- moment, even in separate Neovims: keep the tests that jump between
    -- placeholders in this file, so they never run in parallel.
    it('jumping to the next placeholder shows the signature help', function()
      local nvim = go_buffer()
      nvim:type('ae2eSn')
      probe.wait_completion(nvim, { item = 'e2eSnippet' })
      nvim:type('<Tab>')
      nvim:wait_mode('s')
      -- A person reads the placeholder first: typing into it within coc's
      -- first few hundred milliseconds can end the snippet session.
      nvim:sleep(500)
      nvim:type('X', { wait = 1000 })
      nvim:type('<C-s><C-n>')
      nvim:wait_for(function()
        for _, f in ipairs(nvim:floats()) do
          if table.concat(f.lines, '\n'):find('e2eSnippet(first, second)', 1, true) then
            return true
          end
        end
      end)
    end, { retry = 4 })

    it('<C-s><C-c> ends the snippet session', function()
      local nvim = go_buffer()
      nvim:type('ae2eSn')
      probe.wait_completion(nvim, { item = 'e2eSnippet' })
      nvim:type('<Tab>')
      nvim:wait_mode('s')
      t.ok(probe.snippet_active(nvim))
      nvim:type('<C-s><C-c>')
      t.no(probe.snippet_active(nvim))
    end)
  end)
end)

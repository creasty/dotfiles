-- Fuzzy finder workflows (snacks.nvim's picker today): <C-q> file finder, <Space>/ grep.
-- What every source does on reopen, scroll, <C-l> and <C-r>: picker_checklist_spec.lua.
local t = require('t')
local probe = require('probe')
local describe, it = t.describe, t.it

local PROJECT = {
  ['.git/'] = true,
  ['.gitignore'] = { 'dist/' },
  ['.env'] = { 'X=1' },
  ['README.md'] = { '# readme', 'needle in the readme' },
  ['src/app.ts'] = { 'export const app = "needle";' },
  ['src/app.test.ts'] = { 'import { app } from "./app";' },
  ['src/util/strings.ts'] = { 'export const upper = (s: string) => s.toUpperCase();', 'const needle = 1;' },
  ['dist/bundle.js'] = { 'needle' },
}

local function in_project(opts)
  local nvim = t.nvim(opts)
  nvim:files(PROJECT)
  probe.wait_picker_ready(nvim)
  return nvim
end

local function open_finder(nvim)
  nvim:type('<C-q>')
  return probe.wait_picker(nvim)
end

local function sorted(list)
  local copy = vim.deepcopy(list)
  table.sort(copy)
  return copy
end

describe('Picker', function()
  describe('file finder (<C-q>)', function()
    it('opens as a floating window with the prompt focused in insert mode', function()
      local nvim = in_project()
      local picker = open_finder(nvim)
      t.ok(picker.floating, 'floating')
      t.eq('prompt', probe.picker(nvim).focus, 'the prompt has focus')
      nvim:wait_mode('i')
    end)

    it('lists project files, including dotfiles, excluding ignored ones', function()
      local nvim = in_project()
      local picker = open_finder(nvim)
      t.eq(sorted({ '.env', '.gitignore', 'README.md', 'src/app.test.ts', 'src/app.ts', 'src/util/strings.ts' }), sorted(picker.items))
    end)

    it('filters fuzzily as you type, best match first', function()
      local nvim = in_project()
      open_finder(nvim)
      nvim:type('ustr')
      local picker = probe.wait_picker(nvim, function(p)
        return #p.items == 1
      end)
      t.eq({ 'src/util/strings.ts' }, picker.items)
      nvim:type('<C-u>apt')
      picker = probe.wait_picker(nvim, function(p)
        return p.items[1] == 'src/app.ts'
      end)
      t.eq('src/app.ts', picker.items[1])
    end)

    it('<CR> opens the top match in the current window and closes the finder', function()
      local nvim = in_project()
      open_finder(nvim)
      nvim:type('ustr')
      probe.wait_picker(nvim, function(p)
        return #p.items == 1
      end)
      nvim:type('<CR>')
      probe.wait_picker_closed(nvim)
      t.eq(nvim:path('src/util/strings.ts'), nvim:bufname())
      t.eq('n', nvim:mode())
      t.eq(1, #nvim:request('nvim_list_wins'))
    end)

    it('<C-j> opens like <CR>', function()
      local nvim = in_project()
      open_finder(nvim)
      nvim:type('readme')
      probe.wait_picker(nvim, function(p)
        return p.items[1] == 'README.md'
      end)
      nvim:type('<C-j>')
      probe.wait_picker_closed(nvim)
      t.eq('README.md', nvim:call('expand', '%:t'))
    end)

    it('<C-n> / <C-p> in the prompt move through the results', function()
      local nvim = in_project()
      open_finder(nvim)
      nvim:type('src')
      probe.wait_picker(nvim, function(p)
        return #p.items == 3
      end)
      local first = probe.picker(nvim).current
      nvim:type('<C-n>')
      local second = nvim:wait_for(function()
        local cur = probe.picker(nvim).current
        return cur ~= first and cur
      end)
      nvim:type('<C-n><C-p>')
      nvim:wait_for(function()
        return probe.picker(nvim).current == second
      end)
      nvim:type('<CR>')
      probe.wait_picker_closed(nvim)
      t.eq(nvim:path(second), nvim:bufname())
    end)

    it('<Esc> leaves the prompt, a second <Esc> closes; <C-q> closes at once', function()
      local nvim = in_project()
      open_finder(nvim)
      nvim:type('<Esc>')
      t.eq('n', nvim:mode())
      t.ok(probe.picker(nvim).open)
      nvim:type('<Esc>')
      probe.wait_picker_closed(nvim)
      open_finder(nvim)
      nvim:type('<C-q>')
      probe.wait_picker_closed(nvim)
    end)
  end)

  describe('repositories (<C-q> in $HOME)', function()
    it('lists ghq repositories (with monorepo packages) and <CR> changes into one', function()
      local nvim = t.nvim({
        env = function(dir)
          return { GHQ_ROOT = dir .. '/ghq' }
        end,
      })
      nvim:files({
        ['ghq/github.com/acme/app/.git/'] = true,
        ['ghq/github.com/acme/lib/.git/'] = true,
        ['ghq/github.com/acme/mono/.git/'] = true,
        ['ghq/github.com/acme/mono/.ghq-monorepo'] = { 'packages/web', 'packages/api' },
        ['ghq/github.com/acme/mono/packages/web/'] = true,
        ['ghq/github.com/acme/mono/packages/api/'] = true,
      })
      probe.wait_picker_ready(nvim)
      nvim:cmd('cd ~')
      local picker = open_finder(nvim)
      t.eq(
        sorted({ 'github.com/acme/app', 'github.com/acme/lib', 'github.com/acme/mono/packages/api', 'github.com/acme/mono/packages/web' }),
        sorted(picker.items)
      )
      nvim:type('monoweb')
      probe.wait_picker(nvim, function(p)
        return p.items[1] == 'github.com/acme/mono/packages/web'
      end)
      nvim:type('<CR>')
      probe.wait_picker_closed(nvim)
      t.eq(nvim:path('ghq/github.com/acme/mono/packages/web'), nvim:call('getcwd'))
    end)
  end)

  describe('grep (<Space>/)', function()
    it('prompts for a pattern and lists matches as path line:col |text', function()
      local nvim = in_project()
      nvim:type('<Space>/')
      t.eq('Search: ', nvim:call('getcmdprompt'))
      nvim:type('needle<CR>')
      local picker = probe.wait_picker(nvim, function(p)
        return #p.items == 3
      end)
      t.eq({
        'README.md 2:0 |needle in the readme',
        'src/app.ts 1:20 |export const app = "needle";',
        'src/util/strings.ts 2:6 |const needle = 1;',
      }, sorted(picker.items))
    end)

    it('<CR> opens the match at its line and column', function()
      local nvim = in_project()
      nvim:type('<Space>/')
      nvim:type('upper<CR>')
      probe.wait_picker(nvim, function(p)
        return #p.items == 1
      end)
      nvim:type('<CR>')
      probe.wait_picker_closed(nvim)
      t.eq('strings.ts', nvim:call('expand', '%:t'))
      t.eq({ 1, 13 }, nvim:cursor())
    end)

    it(':Search {dir} searches below that directory', function()
      local nvim = in_project()
      nvim:type(':Search src/util<CR>')
      nvim:type('needle<CR>')
      local picker = probe.wait_picker(nvim)
      t.eq({ 'strings.ts 2:6 |const needle = 1;' }, picker.items)
    end)
  end)

  describe('result list keys (grep and location lists open with the list focused)', function()
    local function grep(nvim, pattern)
      nvim:type('<Space>/')
      nvim:type(pattern .. '<CR>')
      return probe.wait_picker(nvim)
    end

    it('the list has the focus, in normal mode', function()
      local nvim = in_project()
      grep(nvim, 'needle')
      t.eq('list', probe.picker(nvim).focus)
      t.eq('n', nvim:mode())
    end)

    it('q closes the list', function()
      local nvim = in_project()
      grep(nvim, 'needle')
      nvim:type('q')
      probe.wait_picker_closed(nvim)
    end)

    it('o opens the item under the cursor', function()
      local nvim = in_project()
      grep(nvim, 'upper')
      nvim:type('o')
      probe.wait_picker_closed(nvim)
      t.eq('strings.ts', nvim:call('expand', '%:t'))
    end)

    it('y yanks the path of the item', function()
      local nvim = in_project()
      grep(nvim, 'upper')
      nvim:type('y')
      nvim:wait_for(function()
        return nvim:getreg('"'):find('strings.ts', 1, true)
      end)
      t.eq(nvim:path('src/util/strings.ts'), nvim:getreg('"'))
    end)

    it('i opens the prompt to narrow the results', function()
      local nvim = in_project()
      grep(nvim, 'needle')
      nvim:type('i')
      nvim:wait_for(function()
        return probe.picker(nvim).focus == 'prompt'
      end)
      nvim:type('strings')
      local picker = probe.wait_picker(nvim, function(p)
        return #p.items == 1
      end)
      t.eq({ 'src/util/strings.ts 2:6 |const needle = 1;' }, picker.items)
    end)

    it('- marks items and moves down; <CR> then opens every marked item', function()
      local nvim = in_project()
      grep(nvim, 'needle')
      nvim:type('--')
      nvim:type('<CR>')
      probe.wait_picker_closed(nvim)
      local listed = nvim:lua([[
        local names = {}
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
          if vim.bo[b].buflisted and vim.api.nvim_buf_get_name(b) ~= '' then
            names[#names + 1] = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(b), ':t')
          end
        end
        table.sort(names)
        return names
      ]])
      t.eq(2, #listed, 'two files opened: ' .. vim.inspect(listed))
    end)

    it('<Tab> offers the actions for the item', function()
      local nvim = in_project()
      grep(nvim, 'upper')
      nvim:type('<Tab>')
      local picker = probe.wait_picker(nvim, function(p)
        return vim.tbl_contains(p.items, 'open')
      end)
      t.contains(picker.items, 'open')
      t.contains(picker.items, 'yank')
    end)

    it('p shows a preview of the item; p again hides it', function()
      local nvim = in_project()
      grep(nvim, 'upper')
      local function previewed()
        for _, float in ipairs(nvim:floats()) do
          -- (the list shows only the first line of the file)
          if table.concat(float.lines, '\n'):find('const needle = 1;', 1, true) then
            return true
          end
        end
        return false
      end
      nvim:type('p')
      nvim:wait_for(previewed, { message = 'a preview of strings.ts' })
      t.eq('list', probe.picker(nvim).focus)
      nvim:type('p')
      nvim:wait_for(function()
        return not previewed()
      end, { message = 'the preview to close' })
    end)
  end)
end)

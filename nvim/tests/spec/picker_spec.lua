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

    it("has its border's background, the editor's, not the darker one of other floats", function()
      local nvim = in_project()
      -- (read outside the picker: its windows map NormalFloat to their own)
      local float = nvim:lua([[return vim.api.nvim_get_hl(0, { name = 'NormalFloat', link = false }).bg]])
      open_finder(nvim)
      local colors = probe.picker_colors(nvim)
      t.ok(colors.border, 'the border has a background')
      t.eq({ input = colors.border, list = colors.border }, { input = colors.input, list = colors.list })
      t.neq(float, colors.list, 'not the background of other floats')
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

    it('<Esc> leaves the prompt, a second <Esc> closes; <C-q> and <C-c> close at once', function()
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
      open_finder(nvim)
      nvim:wait_mode('i')
      nvim:sleep(100) -- (a <C-c> typed while Neovim is busy interrupts instead)
      nvim:type('<C-c>')
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

    it('never lists what is in .git, even when rg searches hidden files', function()
      local nvim = t.nvim({
        env = function(dir)
          return { RIPGREP_CONFIG_PATH = dir .. '/ripgreprc' }
        end,
      })
      nvim:files({
        ['ripgreprc'] = { '--hidden' },
        ['.git/COMMIT_EDITMSG'] = { 'needle' },
        ['.env'] = { 'needle' },
        ['a.txt'] = { 'needle' },
      })
      probe.wait_picker_ready(nvim)
      nvim:type('<Space>/')
      nvim:type('needle<CR>')
      local picker = probe.wait_picker(nvim, function(p)
        return #p.items == 2
      end)
      t.eq({ '.env 1:0 |needle', 'a.txt 1:0 |needle' }, sorted(picker.items))
    end)
  end)

  describe('on a short screen (a split pane)', function()
    --- Waits until a row of the screen shows `text`.
    local function wait_on_screen(nvim, text)
      nvim:wait_for(function()
        for _, line in ipairs(nvim:screen()) do
          if line:find(text, 1, true) then
            return true
          end
        end
      end, { message = text .. ' on the screen' })
    end

    it('shows the first result below the prompt, in grep too', function()
      local nvim = in_project({ lines = 24 })
      local picker = open_finder(nvim)
      wait_on_screen(nvim, picker.items[1])
      nvim:type('<C-q>')
      probe.wait_picker_closed(nvim)
      nvim:type('<Space>/')
      nvim:type('needle<CR>')
      picker = probe.wait_picker(nvim, function(p)
        return #p.items == 3
      end)
      wait_on_screen(nvim, picker.items[1])
    end)

    it('shows the first result when the screen shrinks while the picker is open', function()
      local nvim = in_project()
      local picker = open_finder(nvim)
      nvim:cmd('set lines=24')
      wait_on_screen(nvim, picker.items[1])
    end)
  end)

  -- As in VS Code's search view: the files to search, and a replacement
  -- every line of the list previews before R replaces what it lists.
  local SEARCH_TREE = {
    ['.git/'] = true,
    ['README.md'] = { 'needle in the readme' },
    ['src/app.ts'] = { 'const needle = 1;' },
    ['src/app.test.ts'] = { 'expect(needle);' },
    ['src/util/strings.ts'] = { 'export const needle = 2;' },
    ['lib/src/x.ts'] = { 'needle();' },
  }
  local REPLACE_TREE = {
    ['.git/'] = true,
    ['a.txt'] = { 'one needle', 'no match here' },
    ['b.txt'] = { 'needle, needle' },
    ['c.txt'] = { 'the last needle' },
  }

  local function sandbox(files)
    local nvim = t.nvim()
    nvim:files(files)
    probe.wait_picker_ready(nvim)
    return nvim
  end

  local function search(nvim, pattern, pred)
    nvim:type('<Space>/')
    nvim:type(pattern .. '<CR>')
    return probe.wait_picker(nvim, pred)
  end

  local function files_of(picker)
    local files = {}
    for _, item in ipairs(picker.items) do
      files[#files + 1] = item:match('^%S+')
    end
    return sorted(files)
  end

  describe('grep: the files to search (f)', function()
    --- Answers the Files: prompt, and waits for the list to hold `count` lines.
    local function search_files(nvim, files, count)
      nvim:type('f')
      t.eq('Files: ', nvim:call('getcmdprompt'))
      nvim:type('<C-u>' .. files .. '<CR>')
      return probe.wait_picker(nvim, function(p)
        return #p.items == count
      end)
    end

    it('f asks for the paths to search, from the search directory; the title shows them', function()
      local nvim = sandbox(SEARCH_TREE)
      search(nvim, 'needle')
      local picker = search_files(nvim, 'src/', 3)
      t.eq({ 'src/app.test.ts', 'src/app.ts', 'src/util/strings.ts' }, files_of(picker))
      t.eq('Grep needle · src/', picker.title)
      t.eq('list', picker.focus)
      t.eq('n', nvim:mode())
    end)

    it('takes globs as in .gitignore (without a /, at any depth), and ! before those to leave out', function()
      local nvim = sandbox(SEARCH_TREE)
      search(nvim, 'needle')
      local picker = search_files(nvim, '*.ts !*.test.ts', 3)
      t.eq({ 'lib/src/x.ts', 'src/app.ts', 'src/util/strings.ts' }, files_of(picker))
      picker = search_files(nvim, 'src', 4)
      t.eq({ 'lib/src/x.ts', 'src/app.test.ts', 'src/app.ts', 'src/util/strings.ts' }, files_of(picker))
      picker = search_files(nvim, 'src/ !src/util/', 2)
      t.eq({ 'src/app.test.ts', 'src/app.ts' }, files_of(picker))
      picker = search_files(nvim, 'util,README.md', 2)
      t.eq({ 'README.md', 'src/util/strings.ts' }, files_of(picker))
      picker = search_files(nvim, '', 5)
      t.eq('Grep needle', picker.title)
    end)

    it('<Tab> completes the path under the cursor, after ! too', function()
      local nvim = sandbox(SEARCH_TREE)
      search(nvim, 'needle')
      nvim:type('f')
      nvim:type('sr<Tab>')
      t.eq('src/', nvim:call('getcmdline'))
      nvim:type('u<Tab>')
      t.eq('src/util/', nvim:call('getcmdline'))
      nvim:type(' !src/app.t<Tab>')
      t.eq('src/util/ !src/app.test.ts', nvim:call('getcmdline'))
      nvim:type('<CR>')
      local picker = probe.wait_picker(nvim, function(p)
        return #p.items == 1
      end)
      t.eq({ 'src/util/strings.ts 1:13 |export const needle = 2;' }, picker.items)
    end)

    it('completes the paths below the directory :Search {dir} searches', function()
      local nvim = sandbox(SEARCH_TREE)
      nvim:type(':Search src<CR>')
      nvim:type('needle<CR>')
      probe.wait_picker(nvim, function(p)
        return #p.items == 3
      end)
      nvim:type('f')
      nvim:type('u<Tab>')
      t.eq('util/', nvim:call('getcmdline'))
      nvim:type('<CR>')
      local picker = probe.wait_picker(nvim, function(p)
        return #p.items == 1
      end)
      t.eq({ 'util/strings.ts 1:13 |export const needle = 2;' }, picker.items)
    end)

    it('<Esc> at the prompt keeps the files; a new pattern (<C-r>) and reopening keep them too', function()
      local nvim = sandbox(SEARCH_TREE)
      search(nvim, 'needle')
      search_files(nvim, 'src/', 3)
      nvim:type('f')
      nvim:type('<C-u>lib/<Esc>')
      local picker = probe.wait_picker(nvim, function(p)
        return #p.items == 3
      end)
      t.eq('Grep needle · src/', picker.title)
      nvim:type('<C-r>')
      nvim:type('<C-u>const<CR>')
      picker = probe.wait_picker(nvim, function(p)
        return #p.items == 2
      end)
      t.eq({ 'src/app.ts', 'src/util/strings.ts' }, files_of(picker))
      t.eq('Grep const · src/', picker.title)
      nvim:type('q')
      probe.wait_picker_closed(nvim)
      nvim:sleep(300)
      nvim:type('<Space>/')
      picker = probe.wait_picker(nvim, function(p)
        return #p.items == 2
      end)
      t.eq('Grep const · src/', picker.title)
    end)

    it('a new search (:Search) searches every file again', function()
      local nvim = sandbox(SEARCH_TREE)
      search(nvim, 'needle')
      search_files(nvim, 'src/', 3)
      nvim:type('q')
      probe.wait_picker_closed(nvim)
      nvim:type(':Search<CR>')
      nvim:type('needle<CR>')
      local picker = probe.wait_picker(nvim, function(p)
        return #p.items == 5
      end)
      t.eq('Grep needle', picker.title)
    end)
  end)

  describe('grep: replace (r, x, R)', function()
    local PREVIEW = {
      'a.txt 1:4 |one {-needle-}pin',
      'b.txt 1:0 |{-needle-}pin, {-needle-}pin',
      'c.txt 1:9 |the last {-needle-}pin',
    }

    --- Answers the Replace: prompt, and waits for the list to preview it.
    local function replace_with(nvim, replacement, pred)
      nvim:type('r')
      t.eq('Replace: ', nvim:call('getcmdprompt'))
      nvim:type('<C-u>' .. replacement .. '<CR>')
      return probe.wait_picker(nvim, pred or function(p)
        return p.items[1] ~= nil and p.items[1]:find('{-', 1, true) ~= nil
      end)
    end

    --- R, answering y to `question`; waits for the search to run again.
    local function replace(nvim, question)
      nvim:type('R')
      t.eq(question, nvim:call('getcmdprompt'))
      nvim:type('y<CR>')
      return probe.wait_picker(nvim, function(p)
        return not p.title:find('→', 1, true)
      end)
    end

    it('r asks for the replacement, which every line of the list previews; the files stay as they are', function()
      local nvim = sandbox(REPLACE_TREE)
      search(nvim, 'needle', function(p)
        return #p.items == 3
      end)
      local picker = replace_with(nvim, 'pin')
      t.eq(PREVIEW, picker.items)
      t.eq('Grep needle → pin', picker.title)
      t.eq(PREVIEW[1], picker.current, 'the first line stays selected')
      t.eq('list', picker.focus)
      t.eq({ 'one needle', 'no match here' }, nvim:read_file('a.txt'))
    end)

    it('$1 in the replacement is the first group of the pattern', function()
      local nvim = sandbox(REPLACE_TREE)
      search(nvim, 'n(ee)dle')
      local picker = replace_with(nvim, '[$1]')
      t.eq('a.txt 1:4 |one {-needle-}[ee]', picker.items[1])
    end)

    it('an empty replacement ends the preview; <Esc> at the prompt keeps it', function()
      local nvim = sandbox(REPLACE_TREE)
      search(nvim, 'needle')
      replace_with(nvim, 'pin')
      nvim:type('r')
      nvim:type('<C-u>other<Esc>')
      local picker = probe.wait_picker(nvim)
      t.eq(PREVIEW, picker.items)
      picker = replace_with(nvim, '', function(p)
        return p.items[1] == 'a.txt 1:4 |one needle'
      end)
      t.eq('Grep needle', picker.title)
    end)

    it('R replaces the matches of every line in the list once you say y; the search runs again, without the replacement', function()
      local nvim = sandbox(REPLACE_TREE)
      search(nvim, 'needle')
      replace_with(nvim, 'pin')
      local picker = replace(nvim, 'Replace 4 matches in 3 files with "pin"? [y/N] ')
      t.eq({ 'one pin', 'no match here' }, nvim:read_file('a.txt'))
      t.eq({ 'pin, pin' }, nvim:read_file('b.txt'))
      t.eq({ 'the last pin' }, nvim:read_file('c.txt'))
      t.eq({}, picker.items)
      t.eq('Grep needle', picker.title)
      t.eq('list', picker.focus)
      t.match('Replaced 4 matches in 3 files', nvim:messages())
    end)

    it('R keeps the files as they are unless you say y', function()
      local nvim = sandbox(REPLACE_TREE)
      search(nvim, 'needle')
      replace_with(nvim, 'pin')
      for _, answer in ipairs({ '<CR>', 'n<CR>', '<Esc>' }) do
        nvim:type('R')
        nvim:type(answer)
        t.eq(PREVIEW, probe.wait_picker(nvim).items)
      end
      t.eq({ 'one needle', 'no match here' }, nvim:read_file('a.txt'))
      t.eq({ 'needle, needle' }, nvim:read_file('b.txt'))
    end)

    it('x drops the line under the cursor from the list, and so from what R replaces', function()
      local nvim = sandbox(REPLACE_TREE)
      search(nvim, 'needle')
      replace_with(nvim, 'pin')
      nvim:type('x')
      local picker = probe.wait_picker(nvim, function(p)
        return #p.items == 2
      end)
      t.eq({ PREVIEW[2], PREVIEW[3] }, picker.items)
      t.eq(PREVIEW[2], picker.current, 'the next line takes its place')
      replace(nvim, 'Replace 3 matches in 2 files with "pin"? [y/N] ')
      t.eq({ 'one needle', 'no match here' }, nvim:read_file('a.txt'))
      t.eq({ 'pin, pin' }, nvim:read_file('b.txt'))
      t.eq({ 'the last pin' }, nvim:read_file('c.txt'))
    end)

    it('x and R act on the marked lines when there are some', function()
      local nvim = sandbox(REPLACE_TREE)
      nvim:files({ ['d.txt'] = { 'needle 4' } })
      search(nvim, 'needle', function(p)
        return #p.items == 4
      end)
      replace_with(nvim, 'pin')
      nvim:type('--') -- (marks a.txt and b.txt)
      nvim:type('x')
      probe.wait_picker(nvim, function(p)
        return vim.deep_equal(files_of(p), { 'c.txt', 'd.txt' })
      end)
      nvim:type('gg-')
      replace(nvim, 'Replace 1 match in 1 file with "pin"? [y/N] ')
      t.eq({ 'the last pin' }, nvim:read_file('c.txt'))
      t.eq({ 'needle 4' }, nvim:read_file('d.txt'))
      t.eq({ 'needle, needle' }, nvim:read_file('b.txt'))
    end)

    it('R replaces only the lines the prompt leaves in the list', function()
      local nvim = sandbox(REPLACE_TREE)
      search(nvim, 'needle')
      replace_with(nvim, 'pin')
      nvim:type('i')
      nvim:type('c.txt')
      probe.wait_picker(nvim, function(p)
        return #p.items == 1
      end)
      nvim:sleep(100) -- (a <C-c> typed while Neovim is busy interrupts instead)
      nvim:type('<C-c>')
      nvim:wait_for(function()
        return probe.picker(nvim).focus == 'list'
      end)
      replace(nvim, 'Replace 1 match in 1 file with "pin"? [y/N] ')
      t.eq({ 'the last pin' }, nvim:read_file('c.txt'))
      t.eq({ 'needle, needle' }, nvim:read_file('b.txt'))
    end)

    it('dropped lines stay dropped with another replacement, and come back when the search runs again (<C-l>)', function()
      local nvim = sandbox(REPLACE_TREE)
      search(nvim, 'needle')
      nvim:type('x')
      probe.wait_picker(nvim, function(p)
        return #p.items == 2
      end)
      local picker = replace_with(nvim, 'pin')
      t.eq({ PREVIEW[2], PREVIEW[3] }, picker.items)
      nvim:type('<C-l>')
      picker = probe.wait_picker(nvim, function(p)
        return #p.items == 3
      end)
      t.eq(PREVIEW, picker.items)
    end)

    it('reopens as left: the replacement previewed, the lines dropped', function()
      local nvim = sandbox(REPLACE_TREE)
      search(nvim, 'needle')
      replace_with(nvim, 'pin')
      nvim:type('x')
      probe.wait_picker(nvim, function(p)
        return #p.items == 2
      end)
      nvim:type('q')
      probe.wait_picker_closed(nvim)
      nvim:sleep(300)
      nvim:type('<Space>/')
      local picker = probe.wait_picker(nvim, function(p)
        return #p.items == 2
      end)
      t.eq({ PREVIEW[2], PREVIEW[3] }, picker.items)
      t.eq('Grep needle → pin', picker.title)
    end)

    it('R without a replacement deletes the matches once you say y', function()
      local nvim = sandbox(REPLACE_TREE)
      search(nvim, ' ?needle')
      replace(nvim, 'Delete 4 matches in 3 files? [y/N] ')
      t.eq({ 'one', 'no match here' }, nvim:read_file('a.txt'))
      t.eq({ ',' }, nvim:read_file('b.txt'))
      t.eq({ 'the last' }, nvim:read_file('c.txt'))
      t.match('Deleted 4 matches in 3 files', nvim:messages())
    end)

    it('R replaces in the buffer of an open file, which u undoes', function()
      local nvim = sandbox(REPLACE_TREE)
      nvim:edit('a.txt')
      search(nvim, 'needle')
      replace_with(nvim, 'pin')
      replace(nvim, 'Replace 4 matches in 3 files with "pin"? [y/N] ')
      t.eq({ 'one pin', 'no match here' }, nvim:read_file('a.txt'))
      nvim:type('q')
      probe.wait_picker_closed(nvim)
      t.eq({ 'one pin', 'no match here' }, nvim:lines())
      t.eq(0, nvim:eval('&modified'), 'written')
      nvim:type('u')
      t.eq({ 'one needle', 'no match here' }, nvim:lines())
    end)

    it('R leaves a line that changed since the search as it is, and says so', function()
      local nvim = sandbox(REPLACE_TREE)
      search(nvim, 'needle')
      replace_with(nvim, 'pin')
      nvim:write_file('c.txt', { 'the last needle, edited' })
      replace(nvim, 'Replace 4 matches in 3 files with "pin"? [y/N] ')
      t.eq({ 'the last needle, edited' }, nvim:read_file('c.txt'))
      t.eq({ 'pin, pin' }, nvim:read_file('b.txt'))
      t.match('Replaced 3 matches in 2 files; left 1 line that changed since the search', nvim:messages())
    end)

    it('R keeps the line endings of a file with CRLF ones', function()
      local nvim = sandbox({ ['.git/'] = true })
      local path = nvim:path('crlf.txt')
      vim.fn.writefile({ 'one needle\r', 'two\r', '' }, path, 'b')
      search(nvim, 'needle')
      local picker = replace_with(nvim, 'pin')
      t.eq({ 'crlf.txt 1:4 |one {-needle-}pin' }, picker.items)
      replace(nvim, 'Replace 1 match in 1 file with "pin"? [y/N] ')
      t.eq({ 'one pin\r', 'two\r', '' }, vim.fn.readfile(path, 'b'))
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

    it('<C-c> or <Esc> in the prompt goes back to the list, still narrowed; <C-c> there closes', function()
      for _, key in ipairs({ '<C-c>', '<Esc>' }) do
        local nvim = in_project()
        grep(nvim, 'needle')
        nvim:type('i')
        nvim:wait_for(function()
          return probe.picker(nvim).focus == 'prompt'
        end)
        nvim:wait_mode('i')
        nvim:type('strings')
        probe.wait_picker(nvim, function(p)
          return #p.items == 1
        end)
        nvim:sleep(100) -- (a <C-c> typed while Neovim is busy interrupts instead)
        nvim:type(key)
        local picker = nvim:wait_for(function()
          local p = probe.picker(nvim)
          return p.focus == 'list' and p
        end, { message = 'the list to have the focus after ' .. key })
        t.eq('n', nvim:mode())
        t.eq('strings', picker.query)
        t.eq({ 'src/util/strings.ts 2:6 |const needle = 1;' }, picker.items)
        nvim:sleep(100)
        nvim:type('<C-c>')
        probe.wait_picker_closed(nvim)
      end
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

    it('<Tab> does nothing, in the list or in the prompt', function()
      local nvim = in_project()
      local before = grep(nvim, 'needle')
      local floats = #nvim:floats()
      nvim:type('<Tab>')
      nvim:sleep(300)
      local after = probe.picker(nvim)
      t.eq({ 'list', before.current, {} }, { after.focus, after.current, after.marked })
      t.eq(floats, #nvim:floats(), 'no other window')
      nvim:type('i')
      nvim:wait_for(function()
        return probe.picker(nvim).focus == 'prompt'
      end)
      nvim:wait_mode('i')
      nvim:type('<Tab>')
      nvim:sleep(300)
      after = probe.picker(nvim)
      t.eq({ 'prompt', '', before.current }, { after.focus, after.query, after.current })
      t.eq('i', nvim:mode())
      t.eq(floats, #nvim:floats(), 'no other window')
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

-- What the screen shows: tabline, statusline, title, signs, whitespace, kitty's scrollback.
local t = require('t')
local probe = require('probe')
local describe, it = t.describe, t.it

local function git(nvim, ...)
  local args = { ... }
  local allow_failure = args[#args] == true
  if allow_failure then
    table.remove(args)
  end
  local res = vim.system(vim.list_extend({ 'git' }, args), {
    cwd = nvim.dir,
    text = true,
    env = {
      GIT_CONFIG_NOSYSTEM = '1',
      GIT_CONFIG_GLOBAL = '/dev/null',
      GIT_AUTHOR_NAME = 'e2e',
      GIT_AUTHOR_EMAIL = 'e2e@example.com',
      GIT_COMMITTER_NAME = 'e2e',
      GIT_COMMITTER_EMAIL = 'e2e@example.com',
    },
  }):wait()
  assert(allow_failure or res.code == 0, (res.stderr or ''))
end

--- Text of a statusline/tabline with highlight and click markers removed.
local function plain(s)
  return (s:gsub('%s+$', ''))
end

describe('UI', function()
  describe('tabline', function()
    it('lists every tab by file name, separated by ∙', function()
      local nvim = t.nvim()
      nvim:files({ ['dir/a.txt'] = 'a', ['b.txt'] = 'b' })
      nvim:edit('dir/a.txt')
      nvim:cmd('tabnew b.txt')
      nvim:cmd('tabnew')
      t.eq(' a.txt ∙ b.txt ∙ Untitled', plain(nvim:tabline()))
    end)

    it('flags modified (+), readonly (!) and unsaved new (?) files', function()
      local nvim = t.nvim()
      nvim:cmd('AutoSaveToggle')
      nvim:files({ ['ro.txt'] = 'x', ['mod.txt'] = 'x' })
      nvim:edit('mod.txt')
      nvim:set_buffer('changed')
      nvim:cmd('tabnew ro.txt | setlocal readonly')
      nvim:cmd('tabnew new.txt')
      t.eq(' +mod.txt ∙ !ro.txt ∙ ?new.txt', plain(nvim:tabline()))
    end)
  end)

  describe('statusline', function()
    it('active window: filetype, position and encoding', function()
      local nvim = t.nvim()
      nvim:edit('a.ts', { 'one', 'two', 'three', 'four' })
      nvim:type('2G')
      local stl = nvim:statusline()
      t.match('^ typescript ', stl)
      t.match('utf%-8 unix ∙ 2:1 ∙ 50%%%s*$', stl)
    end)

    it('shows "plain" when there is no filetype', function()
      local nvim = t.nvim()
      t.match('^ plain ', nvim:statusline())
    end)

    it('shows ✓ and the time of the last save for a minute, after the diagnostics', function()
      local nvim = t.nvim()
      nvim:edit('a.txt', { 'x' })
      nvim:lua([[
        local diagnostic = { lnum = 0, col = 0, message = 'e2e', severity = vim.diagnostic.severity.ERROR }
        vim.diagnostic.set(vim.api.nvim_create_namespace('e2e'), 0, { diagnostic })
      ]])
      nvim:cmd('write')
      t.match(' ✕ 1 ✓ %d%d:%d%d:%d%d ', nvim:statusline())
    end)

    it('is a single global statusline for the current window', function()
      local nvim = t.nvim()
      t.eq(3, nvim:eval('&laststatus'))
      nvim:files({ ['a.ts'] = 'a', ['b.go'] = 'b' })
      nvim:edit('a.ts')
      nvim:cmd('vsplit b.go')
      t.match('^ go ', nvim:statusline())
      nvim:cmd('wincmd p')
      t.match('^ typescript ', nvim:statusline())
    end)

    it('shows the snippet indicator while a snippet is being filled in', function()
      local nvim = t.nvim()
      nvim:files({ ['.git/'] = true })
      nvim:edit('main.go', { 'package main', '' })
      probe.wait_lsp(nvim)
      nvim:type('Go')
      nvim:type('e2eSn')
      probe.wait_completion(nvim, { item = 'e2eSnippet' })
      nvim:type('<Tab>')
      nvim:wait_mode('s')
      nvim:wait_for(function()
        return nvim:statusline():find('SNIP', 1, true)
      end)
    end)

    it('shows the git branch, marked when lines are added (+), changed (~) or removed (-)', function()
      local nvim = t.nvim()
      nvim:files({ ['a.txt'] = { '1', '2', '3', '4', '5', '6', '7', '8', '9' } })
      git(nvim, 'init', '-q', '-b', 'main')
      git(nvim, 'add', '-A')
      git(nvim, 'commit', '-q', '-m', 'init')
      nvim:edit('a.txt')
      probe.wait_services(nvim)
      nvim:wait_for(function()
        return nvim:statusline():find('  main ', 1, true)
      end, { timeout = 10000, message = 'the branch in the statusline' })
      nvim:set_buffer({ '1', 'two', '3', '4', '6', '7', '8', '9', '10' })
      nvim:wait_for(function()
        return nvim:statusline():find('  main+~- ', 1, true)
      end, { timeout = 10000, message = 'the changed lines in the statusline' })
    end)

    it('lists the language servers of the buffer, with the work one is doing', function()
      local nvim = t.nvim()
      nvim:files({ ['.e2e-root'] = '' })
      nvim:edit('main.go', { 'package main' })
      probe.wait_lsp(nvim)
      t.contains(nvim:statusline(), ' e2e ')
      -- $/progress, as a server reports it
      local function progress(value)
        nvim:lua(
          [[
          local client = vim.lsp.get_clients({ bufnr = 0, name = 'e2e' })[1]
          vim.lsp.handlers['$/progress'](nil, { token = 'index', value = ... }, { client_id = client.id })
        ]],
          value
        )
      end
      progress({ kind = 'begin', title = 'Indexing' })
      t.contains(nvim:statusline(), ' e2e: Indexing ')
      progress({ kind = 'report', percentage = 45 })
      t.contains(nvim:statusline(), ' e2e: Indexing 45% ')
      progress({ kind = 'end' })
      t.contains(nvim:statusline(), ' e2e ')
      t.no(nvim:statusline():find('Indexing', 1, true), 'no work once it ends')
    end)
  end)

  describe('window title', function()
    it('shows the file path with ~ for home and ~g for ~/go/src/github.com', function()
      local nvim = t.nvim()
      nvim:cmd('let $HOME = ' .. vim.fn.string(nvim:path('home')))
      nvim:edit('home/go/src/github.com/acme/app/main.go')
      t.eq('~g/acme/app/main.go', nvim:call('UserTitleString'))
      nvim:edit('home/notes.txt')
      t.eq('~/notes.txt', nvim:call('UserTitleString'))
    end)

    it('shows the buffer name or type for special buffers', function()
      local nvim = t.nvim()
      nvim:cmd('help help')
      t.match('help%.txt$', nvim:call('UserTitleString'))
    end)
  end)

  describe('signs', function()
    it('marks are shown in the sign column', function()
      local nvim = t.nvim()
      nvim:set_buffer({ 'one', '|two' })
      nvim:type('ma')
      nvim:wait_for(function()
        return vim.tbl_contains(probe.signs(nvim, 2), 'a')
      end)
    end)

    it('git changes are marked in the sign column; [g / ]g jump between hunks', function()
      local nvim = t.nvim()
      nvim:files({ ['a.txt'] = { '1', '2', '3', '4', '5', '6', '7', '8', '9' } })
      git(nvim, 'init', '-q', '-b', 'main')
      git(nvim, 'add', '-A')
      git(nvim, 'commit', '-q', '-m', 'init')
      nvim:edit('a.txt')
      probe.wait_services(nvim)
      nvim:set_buffer({ '1', 'two', '3', '4', '5', '6', '7', '8', '9', '10' })
      nvim:cmd('write')
      nvim:wait_for(function()
        return vim.tbl_contains(probe.signs(nvim, 2), '┃') and vim.tbl_contains(probe.signs(nvim, 10), '┃')
      end, { timeout = 10000, message = 'git signs on the changed and added lines' })
      nvim:set_cursor(1, 0)
      nvim:type(']g')
      nvim:wait_for(function()
        return nvim:cursor()[1] == 2
      end)
      nvim:type(']g')
      nvim:wait_for(function()
        return nvim:cursor()[1] == 10
      end)
      nvim:type('[g')
      nvim:wait_for(function()
        return nvim:cursor()[1] == 2
      end)
    end)

    it('removed lines are marked on the line above', function()
      local nvim = t.nvim()
      nvim:files({ ['a.txt'] = { '1', '2', '3', '4' } })
      git(nvim, 'init', '-q', '-b', 'main')
      git(nvim, 'add', '-A')
      git(nvim, 'commit', '-q', '-m', 'init')
      nvim:edit('a.txt')
      probe.wait_services(nvim)
      nvim:set_buffer({ '1', '2', '4' })
      nvim:cmd('write')
      nvim:wait_for(function()
        return vim.tbl_contains(probe.signs(nvim, 2), '▁')
      end, { timeout = 10000, message = 'a removed-line sign on line 2' })
    end)

    it('[C / ]C jump between merge conflicts', function()
      local nvim = t.nvim()
      local function content(x, y)
        return { 'a', x, 'b', 'c', 'd', 'e', 'f', 'g', y }
      end
      nvim:files({ ['a.txt'] = content('x', 'y') })
      git(nvim, 'init', '-q', '-b', 'main')
      git(nvim, 'add', '-A')
      git(nvim, 'commit', '-q', '-m', 'base')
      git(nvim, 'checkout', '-q', '-b', 'other')
      nvim:write_file('a.txt', content('X-other', 'Y-other'))
      git(nvim, 'commit', '-q', '-am', 'other')
      git(nvim, 'checkout', '-q', 'main')
      nvim:write_file('a.txt', content('X-main', 'Y-main'))
      git(nvim, 'commit', '-q', '-am', 'main')
      git(nvim, 'merge', '-q', 'other', true)
      nvim:edit('a.txt')
      probe.wait_services(nvim)
      local starts = {}
      for i, line in ipairs(nvim:lines()) do
        if line:match('^<<<<<<<') then
          starts[#starts + 1] = i
        end
      end
      t.eq(2, #starts, 'two conflicts')
      -- The conflict list is built asynchronously; retry each jump from a
      -- known position until it lands.
      local function jump(from, keys, to)
        nvim:wait_for(function()
          nvim:set_cursor(from, 0)
          nvim:type(keys)
          return nvim:cursor()[1] == to
        end, { timeout = 10000, message = ('%s from line %d to line %d'):format(keys, from, to) })
      end
      jump(1, ']C', starts[1])
      jump(starts[1], ']C', starts[2])
      jump(starts[2], '[C', starts[1])
    end)

    it('two sign columns are always reserved', function()
      local nvim = t.nvim()
      t.eq('yes:2', nvim:eval('&signcolumn'))
    end)
  end)

  it('renders tabs as ──⏵ and trailing spaces as ·', function()
    local nvim = t.nvim()
    nvim:cmd('setlocal noexpandtab tabstop=4')
    nvim:set_buffer({ '\tx  ' })
    local row = nvim:screen()[2]
    t.contains(row, '───⏵x··')
  end)

  describe("kitty's scrollback (copy mode)", function()
    --- kitty's scrollback_pager: lines with their colors, read from stdin into an unnamed buffer
    local function scrollback(nvim, n)
      nvim:cmd('enew')
      local lines = {}
      for i = 1, n do
        lines[i] = ('\27[3%dmline %d\27[0m'):format(i % 7 + 1, i)
      end
      lines[n + 1] = '$ ls'
      nvim:set_buffer(lines)
    end

    it('has no line numbers, signs, color column, scroll offset or language servers', function()
      local nvim = t.nvim()
      nvim:files({ ['.e2e-root'] = '', ['notes.txt'] = { 'x' } })
      nvim:lua("vim.lsp.config('e2e', { filetypes = { 'text' } })")
      nvim:edit('notes.txt')
      probe.wait_lsp(nvim)
      scrollback(nvim, 3)
      nvim:lua("require('user.scrollback').open(1, 4, 3)")
      t.eq(
        { 0, 'no', '', 0, 'terminal', 0 },
        nvim:eval(
          "[&number, &signcolumn, &colorcolumn, &scrolloff, &buftype, luaeval('#vim.lsp.get_clients({ bufnr = 0 })')]"
        )
      )
    end)

    it("keeps kitty's screen where it was, with no tabline, statusline or command line, and the cursor on kitty's", function()
      local nvim = t.nvim()
      scrollback(nvim, 60)
      -- kitty's screen of 40 lines: line 22 at the top, the prompt at the bottom, the cursor on its third column
      nvim:lua("require('user.scrollback').open(22, 40, 3)")
      local screen = nvim:screen()
      t.eq(nvim:eval('&lines'), nvim:eval('winheight(0)'))
      t.eq('line 22', screen[1])
      t.eq('$ ls', screen[40])
      t.eq({ 61, 2 }, nvim:cursor())
    end)
  end)
end)

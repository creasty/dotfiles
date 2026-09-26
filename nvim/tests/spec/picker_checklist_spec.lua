-- The picker checklist, source by source (ddu.vim today). The keys of each
-- picker are in picker_spec.lua.
local t = require('t')
local probe = require('probe')
local describe, it = t.describe, t.it

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
  -- The checklist, for every source: reopening brings the picker back as you
  -- left it (query, results in the same order, selected line, marks, prompt
  -- or list focus), each source keeps its own state, a long list scrolls
  -- with the up/down keys, and while it is open <C-l> refreshes and <C-r>
  -- reloads. Reopening resumes only when the previous picker call happened
  -- in the same directory (user#plugin#ddu's s:can_resume()).
  describe('every source', function()
    local FILES = {
      ['.git/'] = true,
      ['src/a1.ts'] = 'x',
      ['src/a2.ts'] = 'x',
      ['src/a3.ts'] = 'x',
      ['a.txt'] = { 'needle 1' },
      ['b.txt'] = { 'needle 2' },
      ['c.txt'] = { 'needle 3' },
    }
    local GO = { 'package main', '', 'func load() int { return 1 }', '', 'func main() {', '\tprintln(load())', '\tprintln(load())', '\tprintln(load())', '}' }
    local REFS = { 'main.go 6:10 |\tprintln(load())', 'main.go 7:10 |\tprintln(load())', 'main.go 8:10 |\tprintln(load())' }
    local STALE_PROMPT = "user#plugin#ddu#update_input() redraws every source but grep with an empty input: the filter is cleared, the prompt's text is not, and typing filters by that text again"

    local function sandbox(files)
      local nvim = t.nvim()
      nvim:files(files)
      probe.wait_picker_ready(nvim)
      return nvim
    end

    local function project(extra)
      return sandbox(vim.tbl_extend('force', FILES, extra or {}))
    end

    --- A child whose $HOME is its sandbox, where <C-q> lists ghq repositories.
    local function home(extra)
      local nvim = t.nvim({
        env = function(dir)
          return { HOME = dir, GHQ_ROOT = dir .. '/ghq' }
        end,
      })
      nvim:files(vim.tbl_extend('force', {
        ['ghq/github.com/acme/app/.git/'] = true,
        ['ghq/github.com/acme/lib/.git/'] = true,
        ['ghq/github.com/acme/tool/.git/'] = true,
        ['ghq/github.com/other/x/.git/'] = true,
      }, extra or {}))
      probe.wait_picker_ready(nvim)
      return nvim
    end

    --- Moves the list selection with `key` until `pred(state)` holds,
    --- checking after every key press (the list may redraw while it loads).
    local function select_with(nvim, key, pred, target)
      return nvim:wait_for(function()
        local state = probe.picker(nvim)
        if pred(state) then
          return state
        end
        nvim:type(key)
        return false
      end, { message = ('moving the picker selection with %s%s'):format(key, target and (' to ' .. target) or '') })
    end

    --- Finder narrowed to src/a{1,2,3}.ts with the second one selected.
    local function finder_state(nvim)
      open_finder(nvim)
      nvim:type('src/a')
      probe.wait_picker(nvim, function(p)
        return #p.items == 3
      end)
      return select_with(nvim, '<C-n>', function(p)
        return p.current == p.items[2]
      end)
    end

    --- Repositories narrowed to acme/* with the second one selected.
    local function repos_state(nvim)
      nvim:type('<C-q>')
      probe.wait_picker(nvim, function(p)
        return #p.items == 4
      end)
      nvim:type('acme')
      probe.wait_picker(nvim, function(p)
        return #p.items == 3
      end)
      return select_with(nvim, '<C-n>', function(p)
        return p.current == p.items[2]
      end)
    end

    --- Grep results for "needle" with the second one selected. rg returns
    --- matches in no particular order, so states are compared as seen.
    local function grep_state(nvim)
      nvim:type('<Space>/')
      nvim:type('needle<CR>')
      probe.wait_picker(nvim, function(p)
        return #p.items == 3
      end)
      return select_with(nvim, 'j', function(p)
        return p.current == p.items[2]
      end)
    end

    --- References of load() in main.go (GO) with the third one selected.
    local function refs_state(nvim)
      nvim:set_cursor(3, 6)
      nvim:type('gR')
      probe.wait_picker(nvim, function(p)
        return vim.deep_equal(p.items, REFS)
      end)
      return select_with(nvim, 'j', function(p)
        return p.current == REFS[3]
      end)
    end

    local function go_project()
      local nvim = project({ ['main.go'] = GO })
      nvim:edit('main.go')
      probe.wait_lsp(nvim)
      return nvim
    end

    local function numbered(format, n, value)
      local files = {}
      for i = 1, n do
        files[format:format(i)] = value
      end
      return files
    end

    local NEEDLES = {}
    local GO_LONG = { 'package main', '', 'func load() int { return 1 }', '', 'func main() {' }
    for i = 1, 50 do
      NEEDLES[i] = ('needle %02d'):format(i)
      GO_LONG[#GO_LONG + 1] = '\tprintln(load())'
    end
    GO_LONG[#GO_LONG + 1] = '}'

    local function index_of(list, value)
      for i, v in ipairs(list) do
        if v == value then
          return i
        end
      end
    end

    --- In a list longer than its window, moving the selection past the last
    --- visible line brings the lines below into view (instead of jumping back
    --- to the top), reopening shows the selected line again, down stops at
    --- the end, and moving up brings the lines above back into view.
    local function check_scrolling(nvim, down, up, reopen)
      local picker = probe.wait_picker(nvim)
      local items, height = picker.items, #picker.visible
      t.ok(height < #items, ('the window (%d lines) is shorter than the list (%d items)'):format(height, #items))
      t.eq(items[1], picker.current, 'the first item is selected')

      local below = items[height + 10]
      picker = select_with(nvim, down, function(p)
        return p.current == below
      end, below .. ', below the window')
      t.contains(picker.visible, below, 'the selected item is on screen')
      t.no(vim.tbl_contains(picker.visible, items[1]), 'the top scrolled out of view')

      reopen()
      picker = probe.wait_picker(nvim, function(p)
        return p.current == below and vim.deep_equal(p.items, items)
      end)
      t.contains(picker.visible, below, 'reopened: the selected item is on screen')

      local last = items[#items]
      picker = select_with(nvim, down, function(p)
        return p.current == last
      end, last .. ', the last item')
      t.contains(picker.visible, last, 'the last item is on screen')
      nvim:type(down:rep(3))
      picker = probe.picker(nvim)
      t.contains(picker.visible, last, 'down at the end stays at the end')
      t.no(vim.tbl_contains(picker.visible, items[1]), 'down at the end does not jump back to the top')

      local above = items[#items - height - 10]
      picker = select_with(nvim, up, function(p)
        return p.current == above
      end, above .. ', above the window')
      t.contains(picker.visible, above, 'the selected item is on screen')
      t.no(vim.tbl_contains(picker.visible, last), 'the bottom scrolled out of view')
      picker = select_with(nvim, up, function(p)
        return p.current == items[1]
      end, items[1] .. ', the first item')
      t.eq(items[1], picker.visible[1], 'back at the top')
    end

    --- Closes the picker, then pauses like a person before the next picker:
    --- reopening within a few milliseconds can race ddu's own cleanup of the
    --- window it just closed ("Invalid window id") and show an empty list.
    local function close(nvim, key)
      nvim:type(key)
      probe.wait_picker_closed(nvim)
      nvim:sleep(300)
    end

    local function in_prompt(nvim)
      t.eq('ddu-ff-filter', nvim:filetype(), 'the prompt has the focus')
      t.eq('i', nvim:mode())
    end

    local function in_list(nvim)
      t.eq('ddu-ff', nvim:filetype(), 'the list has the focus')
      t.eq('n', nvim:mode())
    end

    local function listed_files(nvim)
      return nvim:lua([[
        local names = {}
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
          if vim.bo[b].buflisted and vim.api.nvim_buf_get_name(b) ~= '' then
            names[#names + 1] = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(b), ':t')
          end
        end
        table.sort(names)
        return names
      ]])
    end

    describe('files (<C-q>)', function()
      for _, key in ipairs({ '<C-q>', '<Esc><Esc>', '<CR>' }) do
        it(('reopens as left after closing with %s: query, results, selected line, in the prompt'):format(key), function()
          local nvim = project()
          local before = finder_state(nvim)
          close(nvim, key)
          nvim:type('<C-q>')
          local after = probe.wait_picker(nvim, function(p)
            return p.query == before.query and p.current == before.current
          end)
          t.eq(before.items, after.items)
          in_prompt(nvim)
        end)
      end

      it('<C-n> / <C-p> scroll a long list; it reopens at the selected line', function()
        local nvim = sandbox(vim.tbl_extend('force', { ['.git/'] = true }, numbered('f/file%02d.txt', 50, 'x')))
        open_finder(nvim)
        probe.wait_picker(nvim, function(p)
          return #p.items == 50
        end)
        check_scrolling(nvim, '<C-n>', '<C-p>', function()
          close(nvim, '<C-q>')
          nvim:type('<C-q>')
        end)
        in_prompt(nvim)
      end)

      it('<C-l> picks up new files, keeps the query and selects the first line', function()
        local nvim = project()
        finder_state(nvim)
        nvim:write_file('src/a4.ts', 'x')
        nvim:type('<C-l>')
        local picker = probe.wait_picker(nvim, function(p)
          return #p.items == 4 and p.current == p.items[1]
        end)
        t.contains(picker.items, 'src/a4.ts')
        t.eq('src/a', picker.query)
        in_prompt(nvim)
      end)

      it('<C-r> lists every file again, new ones included, in the prompt', function()
        local nvim = project()
        finder_state(nvim)
        nvim:write_file('d.txt', 'x')
        nvim:type('<C-r>')
        local picker = probe.wait_picker(nvim, function(p)
          return #p.items == 7
        end)
        t.eq({ 'a.txt', 'b.txt', 'c.txt', 'd.txt', 'src/a1.ts', 'src/a2.ts', 'src/a3.ts' }, sorted(picker.items))
        in_prompt(nvim)
      end)

      t.quirk('<C-r> leaves the old query in the prompt, though it no longer filters', STALE_PROMPT, function()
        local nvim = project()
        finder_state(nvim)
        nvim:type('<C-r>')
        local picker = probe.wait_picker(nvim, function(p)
          return #p.items == 6
        end)
        t.eq('src/a', picker.query)
      end)
    end)

    describe('repositories (<C-q> in $HOME)', function()
      it('reopens as left: query, results, selected line, in the prompt', function()
        local nvim = home()
        local before = repos_state(nvim)
        close(nvim, '<C-q>')
        nvim:type('<C-q>')
        local after = probe.wait_picker(nvim, function(p)
          return p.query == before.query and p.current == before.current
        end)
        t.eq(before.items, after.items)
        in_prompt(nvim)
      end)

      it('<C-n> / <C-p> scroll a long list; it reopens at the selected line', function()
        local nvim = home(numbered('ghq/github.com/acme/repo%02d/.git/', 46, true))
        nvim:type('<C-q>')
        probe.wait_picker(nvim, function(p)
          return #p.items == 50
        end)
        check_scrolling(nvim, '<C-n>', '<C-p>', function()
          close(nvim, '<C-q>')
          nvim:type('<C-q>')
        end)
        in_prompt(nvim)
      end)

      t.quirk(
        'the list ends with an empty entry, which down can select',
        "the ghq source splits ghq-list-monorepo's output on newlines and keeps the empty string after the last one",
        function()
          local nvim = home()
          nvim:type('<C-q>')
          probe.wait_picker(nvim, function(p)
            return #p.items == 4
          end)
          local picker = select_with(nvim, '<C-n>', function(p)
            return p.current == nil
          end)
          t.eq('github.com/other/x', picker.visible[#picker.visible])
        end
      )

      it('<C-l> picks up new repositories, keeps the query and selects the first line', function()
        local nvim = home()
        repos_state(nvim)
        nvim:files({ ['ghq/github.com/acme/zeta/.git/'] = true })
        nvim:type('<C-l>')
        local picker = probe.wait_picker(nvim, function(p)
          return #p.items == 4 and p.current == p.items[1]
        end)
        t.contains(picker.items, 'github.com/acme/zeta')
        t.eq('acme', picker.query)
        in_prompt(nvim)
      end)

      it('<C-r> lists every repository again, in the prompt', function()
        local nvim = home()
        repos_state(nvim)
        nvim:type('<C-r>')
        local picker = probe.wait_picker(nvim, function(p)
          return #p.items == 4
        end)
        t.contains(picker.items, 'github.com/other/x')
        in_prompt(nvim)
      end)

      t.quirk('<C-r> leaves the old query in the prompt, though it no longer filters', STALE_PROMPT, function()
        local nvim = home()
        repos_state(nvim)
        nvim:type('<C-r>')
        local picker = probe.wait_picker(nvim, function(p)
          return #p.items == 4
        end)
        t.eq('acme', picker.query)
      end)
    end)

    describe('grep (<Space>/)', function()
      for _, key in ipairs({ 'q', '<Esc>', '<C-q>', '<CR>' }) do
        it(('reopens as left after closing with %s: results in the same order, selected line, in the list'):format(key), function()
          local nvim = project()
          local before = grep_state(nvim)
          close(nvim, key)
          nvim:type('<Space>/')
          local after = probe.wait_picker(nvim, function(p)
            return #p.items == 3 and p.current == before.current
          end)
          t.eq(before.items, after.items)
          in_list(nvim)
        end)
      end

      it('reopens with marked items still marked; <CR> then opens them', function()
        local nvim = project()
        nvim:type('<Space>/')
        nvim:type('needle<CR>')
        local marked = probe.wait_picker(nvim, function(p)
          return #p.items == 3 and p.current
        end).current
        nvim:type('-')
        nvim:wait_for(function()
          return vim.deep_equal(probe.picker(nvim).marked, { marked })
        end, { message = 'the item to be marked' })
        close(nvim, 'q')
        nvim:type('<Space>/')
        probe.wait_picker(nvim, function(p)
          return #p.items == 3 and vim.deep_equal(p.marked, { marked })
        end)
        close(nvim, '<CR>')
        t.eq({ marked:match('^(%S+)') }, listed_files(nvim))
      end)

      it('j / k and <Down> / <Up> scroll a long list; it reopens at the selected line', function()
        local nvim = sandbox({ ['.git/'] = true, ['notes.txt'] = NEEDLES })
        nvim:type('<Space>/')
        nvim:type('needle<CR>')
        probe.wait_picker(nvim, function(p)
          return #p.items == 50
        end)
        check_scrolling(nvim, 'j', 'k', function()
          close(nvim, 'q')
          nvim:type('<Space>/')
        end)
        check_scrolling(nvim, '<Down>', '<Up>', function()
          close(nvim, '<Esc>')
          nvim:type('<Space>/')
        end)
        in_list(nvim)
      end, { timeout = 60000 })

      t.quirk(
        'a scrolled list reopens with the selected line in the middle of the window, not where it was',
        'ddu-ui-ff restores the cursor line; the window is then scrolled to center it',
        function()
          local nvim = sandbox({ ['.git/'] = true, ['notes.txt'] = NEEDLES })
          nvim:type('<Space>/')
          nvim:type('needle<CR>')
          local items = probe.wait_picker(nvim, function(p)
            return #p.items == 50
          end).items
          local picker = select_with(nvim, 'j', function(p)
            return p.current == items[30]
          end)
          local height = #picker.visible
          t.neq(height / 2, index_of(picker.visible, items[30]), 'while moving down: not in the middle')
          close(nvim, 'q')
          nvim:type('<Space>/')
          probe.wait_picker(nvim, function(p)
            return p.current == items[30]
          end)
          nvim:sleep(300)
          t.eq(height / 2, index_of(probe.picker(nvim).visible, items[30]), 'reopened: in the middle')
        end
      )

      it('<C-l> searches again: new matches show up, in the list', function()
        local nvim = project()
        grep_state(nvim)
        nvim:write_file('d.txt', { 'needle 4' })
        nvim:type('<C-l>')
        local picker = probe.wait_picker(nvim, function(p)
          return #p.items == 4
        end)
        t.contains(picker.items, 'd.txt 1:0 |needle 4')
        in_list(nvim)
      end)

      t.quirk(
        '<C-l> keeps the selection on the same match',
        'the mapping moves the cursor to the first line before refreshing, but from the list ddu-ui-ff puts it back on the item it saved when the cursor last moved (from the prompt, the reset sticks)',
        function()
          local nvim = project()
          local before = grep_state(nvim)
          nvim:write_file('d.txt', { 'needle 4' })
          nvim:type('<C-l>')
          probe.wait_picker(nvim, function(p)
            return #p.items == 4 and p.current == before.current
          end)
        end
      )

      it('<C-r> asks for a new pattern and searches again; reopening shows the new search', function()
        local nvim = project()
        grep_state(nvim)
        nvim:type('<C-r>')
        t.eq('Search: ', nvim:call('getcmdprompt'))
        nvim:type('<C-u>needle 2<CR>')
        probe.wait_picker(nvim, function(p)
          return vim.deep_equal(p.items, { 'b.txt 1:0 |needle 2' })
        end)
        in_list(nvim)
        close(nvim, 'q')
        nvim:type('<Space>/')
        probe.wait_picker(nvim, function(p)
          return vim.deep_equal(p.items, { 'b.txt 1:0 |needle 2' })
        end)
        in_list(nvim)
      end)

      t.quirk(
        'after <Esc> at the <C-r> prompt, the next <Space>/ asks for a pattern again',
        'the cancelled prompt stores an empty pattern, and user#plugin#ddu#search() asks whenever the stored one is empty',
        function()
          local nvim = project()
          grep_state(nvim)
          nvim:type('<C-r>')
          t.eq('Search: ', nvim:call('getcmdprompt'))
          nvim:type('<Esc>')
          probe.wait_picker(nvim, function(p)
            return #p.items == 3
          end)
          close(nvim, 'q')
          nvim:type('<Space>/')
          t.eq('Search: ', nvim:call('getcmdprompt'))
        end
      )
    end)

    describe('locations (gR / gD / gT, then gll)', function()
      it('gll reopens as left: results and selected line, in the list', function()
        local nvim = go_project()
        refs_state(nvim)
        close(nvim, 'q')
        -- The first gll after startup starts at the top (a quirk pinned in
        -- the LSP spec); from then on gll resumes.
        nvim:type('gll')
        probe.wait_picker(nvim, function(p)
          return vim.deep_equal(p.items, REFS)
        end)
        select_with(nvim, 'j', function(p)
          return p.current == REFS[3]
        end)
        close(nvim, 'q')
        nvim:type('gll')
        probe.wait_picker(nvim, function(p)
          return vim.deep_equal(p.items, REFS) and p.current == REFS[3]
        end)
        in_list(nvim)
      end, { timeout = 40000, retry = 2 })

      it('j / k scroll a long list; gll reopens it at the selected line', function()
        local nvim = project({ ['main.go'] = GO_LONG })
        nvim:edit('main.go')
        probe.wait_lsp(nvim)
        nvim:set_cursor(3, 6)
        nvim:type('gR')
        probe.wait_picker(nvim, function(p)
          return #p.items == 50
        end)
        -- (the first gll after startup starts at the top; see the LSP spec)
        close(nvim, 'q')
        nvim:type('gll')
        probe.wait_picker(nvim, function(p)
          return #p.items == 50
        end)
        check_scrolling(nvim, 'j', 'k', function()
          close(nvim, 'q')
          nvim:type('gll')
        end)
        in_list(nvim)
      end, { timeout = 40000 })

      t.quirk(
        '<C-l> shows the same locations and selection: the language server is not asked again',
        'the coc-locations source re-reads g:coc_jump_locations, the result of the last request',
        function()
          local nvim = go_project()
          refs_state(nvim)
          nvim:lua([[vim.api.nvim_buf_set_lines(vim.fn.bufnr('main.go'), 8, 8, false, { '\tprintln(load())' })]])
          nvim:type('<C-l>')
          nvim:sleep(1000)
          local picker = probe.picker(nvim)
          t.eq(REFS, picker.items)
          t.eq(REFS[3], picker.current)
          in_list(nvim)
        end,
        { timeout = 40000 }
      )

      it('<C-r> clears the narrowing: every location is listed again, in the prompt', function()
        local nvim = go_project()
        refs_state(nvim)
        nvim:type('i')
        nvim:wait_for(function()
          return nvim:filetype() == 'ddu-ff-filter'
        end)
        nvim:type('7')
        probe.wait_picker(nvim, function(p)
          return #p.items == 1
        end)
        nvim:type('<C-r>')
        probe.wait_picker(nvim, function(p)
          return vim.deep_equal(p.items, REFS)
        end)
        in_prompt(nvim)
      end, { timeout = 40000 })

      t.quirk('<C-r> leaves the old query in the prompt, though it no longer filters', STALE_PROMPT, function()
        local nvim = go_project()
        refs_state(nvim)
        nvim:type('i')
        nvim:wait_for(function()
          return nvim:filetype() == 'ddu-ff-filter'
        end)
        nvim:type('7')
        probe.wait_picker(nvim, function(p)
          return #p.items == 1
        end)
        nvim:type('<C-r>')
        local picker = probe.wait_picker(nvim, function(p)
          return vim.deep_equal(p.items, REFS)
        end)
        t.eq('7', picker.query)
      end, { timeout = 40000 })
    end)

    it('each source keeps its own state: files, grep and locations', function()
      local nvim = go_project()
      local finder = finder_state(nvim)
      close(nvim, '<C-q>')
      local grep = grep_state(nvim)
      close(nvim, 'q')
      local refs = refs_state(nvim)
      close(nvim, 'q')

      nvim:type('<C-q>')
      probe.wait_picker(nvim, function(p)
        return p.query == finder.query and p.current == finder.current and vim.deep_equal(p.items, finder.items)
      end)
      close(nvim, '<C-q>')
      nvim:type('<Space>/')
      probe.wait_picker(nvim, function(p)
        return p.current == grep.current and vim.deep_equal(p.items, grep.items)
      end)
      close(nvim, 'q')
      nvim:type('gll')
      probe.wait_picker(nvim, function(p)
        return p.current == refs.current and vim.deep_equal(p.items, refs.items)
      end)
      close(nvim, 'q')
      nvim:type('<C-q>')
      probe.wait_picker(nvim, function(p)
        return p.query == finder.query and p.current == finder.current
      end)
    end, { timeout = 60000 })

    it('each source keeps its own state in $HOME: repositories, grep and locations', function()
      local nvim = home({
        ['notes/a.txt'] = { 'needle 1' },
        ['notes/b.txt'] = { 'needle 2' },
        ['notes/c.txt'] = { 'needle 3' },
        ['main.go'] = GO,
      })
      local repos = repos_state(nvim)
      close(nvim, '<C-q>')
      local grep = grep_state(nvim)
      close(nvim, 'q')
      nvim:edit('main.go')
      probe.wait_lsp(nvim)
      local refs = refs_state(nvim)
      close(nvim, 'q')

      nvim:type('<C-q>')
      probe.wait_picker(nvim, function(p)
        return p.query == repos.query and p.current == repos.current and vim.deep_equal(p.items, repos.items)
      end)
      close(nvim, '<C-q>')
      nvim:type('<Space>/')
      probe.wait_picker(nvim, function(p)
        return p.current == grep.current and vim.deep_equal(p.items, grep.items)
      end)
      close(nvim, 'q')
      nvim:type('gll')
      probe.wait_picker(nvim, function(p)
        return p.current == refs.current and vim.deep_equal(p.items, refs.items)
      end)
    end, { timeout = 60000 })

    t.quirk(
      'after <Tab> and q, the list comes back with the first line selected',
      "ddu-ui-ff's chooseAction returns to the list without its saved cursor",
      function()
        local nvim = go_project()
        refs_state(nvim)
        nvim:type('<Tab>')
        probe.wait_picker(nvim, function(p)
          return vim.tbl_contains(p.items, 'open')
        end)
        nvim:type('q')
        local picker = probe.wait_picker(nvim, function(p)
          return vim.deep_equal(p.items, REFS)
        end)
        nvim:sleep(500)
        t.eq(REFS[1], probe.picker(nvim).current)
        in_list(nvim)
      end,
      { timeout = 40000 }
    )

    it('a picker opened after changing directory starts fresh', function()
      local nvim = project()
      finder_state(nvim)
      close(nvim, '<C-q>')
      nvim:cmd('cd src')
      local picker = open_finder(nvim)
      t.eq('', picker.query)
      t.eq({ 'a1.ts', 'a2.ts', 'a3.ts' }, sorted(picker.items))
    end)

    t.quirk(
      'back in the first directory, the finder shows the old query over an unfiltered list',
      'the fresh session keeps the prompt text from the last time the finder ran there but lists every file; typing re-filters',
      function()
        local nvim = project()
        finder_state(nvim)
        close(nvim, '<C-q>')
        nvim:cmd('cd src')
        open_finder(nvim)
        close(nvim, '<C-q>')
        nvim:cmd('cd ..')
        open_finder(nvim)
        nvim:sleep(1000)
        local picker = probe.picker(nvim)
        t.eq('src/a', picker.query)
        t.eq(6, #picker.items)
      end
    )
  end)
end)

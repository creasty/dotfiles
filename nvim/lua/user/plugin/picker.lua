-- Fuzzy finder built on snacks.nvim's picker.
--
--   <C-q>      files, or ghq repositories in $HOME (:Open)
--   <Space>/   grep for a pattern (:Search [dir])
--   gR gD gT   LSP locations (user.plugin.lsp); gll reopens them
--
-- Each source reopens as you left it (query, results, selected line, marks)
-- as long as you stay in the directory of the previous picker; the results
-- are gathered again only with <C-l> (refresh) or <C-r> (reload).

local M = {}

local ACTIONS = { 'open', 'split', 'vsplit', 'tab', 'yank', 'quickfix' }

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------

local last_cwd

--- True when the previous picker was opened in the current directory.
local function can_resume()
  local cwd = vim.fn.getcwd()
  local same = cwd == last_cwd
  last_cwd = cwd
  return same
end

--- Items gathered by the last session of each source.
local cache = {}

--- Wraps a finder so a resumed session shows the items it had.
local function cached(source, finder)
  return function(opts, ctx)
    if cache[source] then
      return cache[source]
    end
    local result = finder(opts, ctx)
    if type(result) == 'table' then
      cache[source] = result
      return result
    end
    return function(cb)
      local items = {}
      result(function(item)
        items[#items + 1] = item
        cb(item)
      end)
      if not ctx.picker.closed then
        cache[source] = items
      end
    end
  end
end

local function open(opts, resume)
  if resume and require('snacks.picker.resume').state[opts.source] then
    return Snacks.picker.resume({ source = opts.source })
  end
  cache[opts.source] = nil
  return Snacks.picker(opts)
end

---------------------------------------------------------------------------
-- Formatting: `path`, or `path lnum:col |text` for positions
---------------------------------------------------------------------------

local function format_path(path)
  local dir, base = path:match('^(.*/)([^/]*)$')
  if not dir then
    return { { path, 'SnacksPickerFile' } }
  end
  return { { dir, 'SnacksPickerDir' }, { base, 'SnacksPickerFile' } }
end

local function format_file(item)
  return format_path(item.label or item.file)
end

local function format_location(item)
  local ret = {
    { item.label, 'Identifier' },
    { ' ' },
    { ('%d:%d |'):format(item.pos[1], item.col_label), 'Comment' },
  }
  local line = item.line or ''
  local s, e = item.match and item.match[1], item.match and item.match[2]
  if s and e and e > s then
    ret[#ret + 1] = { line:sub(1, s) }
    ret[#ret + 1] = { line:sub(s + 1, e), 'Constant' }
    ret[#ret + 1] = { line:sub(e + 1) }
  else
    ret[#ret + 1] = { line }
  end
  return ret
end

--- The text an item shows (what the matcher filters on).
local function location_text(item)
  return ('%s %d:%d |%s'):format(item.label, item.pos[1], item.col_label, item.line or '')
end

---------------------------------------------------------------------------
-- Actions
---------------------------------------------------------------------------

local function path_of(item)
  return Snacks.picker.util.path(item)
end

local function run_action(name, items)
  if #items == 0 then
    return
  end
  if name == 'yank' then
    local text = table.concat(vim.tbl_map(path_of, items), '\n')
    vim.fn.setreg('"', text, 'v')
    vim.fn.setreg(vim.v.register, text, 'v')
  elseif name == 'quickfix' then
    vim.fn.setqflist(vim.tbl_map(function(item)
      return { filename = path_of(item), lnum = item.pos and item.pos[1] or 1, col = item.pos and item.pos[2] + 1 or 1, text = item.line or item.text }
    end, items))
    vim.cmd('botright copen')
  elseif name == 'cd' then
    vim.fn.chdir(path_of(items[1]))
  else
    local cmd = ({ open = 'edit', split = 'split', vsplit = 'vsplit', tab = 'tabedit' })[name]
    for i = #items, 2, -1 do
      vim.bo[vim.fn.bufadd(path_of(items[i]))].buflisted = true
    end
    vim.cmd[cmd](vim.fn.fnameescape(path_of(items[1])))
    local pos = items[1].pos
    if pos and pos[1] > 0 then
      vim.api.nvim_win_set_cursor(0, { pos[1], pos[2] })
      vim.cmd('normal! zzzv')
    end
  end
end

local actions = {}

--- Lists the actions for the item(s); cancelling returns to the picker.
function actions.choose_action(picker)
  local source = picker.opts.source
  local items = picker:selected({ fallback = true })
  local names = picker.opts.item_actions or ACTIONS
  picker:close()
  local chosen = false
  vim.schedule(function()
    Snacks.picker({
      source = 'item_actions',
      title = 'Actions',
      layout = { preset = 'select' },
      focus = 'list',
      items = vim.tbl_map(function(name)
        return { text = name }
      end, names),
      format = 'text',
      confirm = function(p, item)
        chosen = true
        p:close()
        vim.schedule(function()
          run_action(item.text, items)
        end)
      end,
      on_close = function()
        if not chosen then
          vim.schedule(function()
            M.resume(source)
          end)
        end
      end,
    })
  end)
end

for _, name in ipairs({ 'open', 'yank', 'cd' }) do
  actions['item_' .. name] = function(picker)
    local items = picker:selected({ fallback = true })
    picker:close()
    vim.schedule(function()
      run_action(name, items)
    end)
  end
end

--- <Esc>: leaves insert mode in the prompt, closes the picker otherwise.
function actions.escape(picker)
  if vim.fn.mode():sub(1, 1) == 'i' then
    vim.cmd.stopinsert()
  else
    picker:close()
  end
end

--- <C-l>: gathers the items again, keeping the query; selects the first line.
function actions.refresh(picker)
  cache[picker.opts.source] = nil
  picker.list:set_selected()
  picker.list:set_target(1, 1, { force = true })
  picker:find({ refresh = true })
end

--- <C-r>: grep asks for a new pattern; the others clear the query and list
--- every item again, in the prompt.
function actions.reload(picker)
  if picker.opts.reload then
    return picker.opts.reload(picker)
  end
  cache[picker.opts.source] = nil
  picker.list:set_selected()
  picker.list:set_target(1, 1, { force = true })
  picker.input:set('', '')
  picker:find({ refresh = true })
  picker:focus('input')
end

---------------------------------------------------------------------------
-- Keys
---------------------------------------------------------------------------

local function keys(extra)
  local common = {
    ['<CR>'] = { 'confirm', mode = { 'n', 'i' } },
    ['<c-j>'] = { 'confirm', mode = { 'n', 'i' } },
    ['<c-q>'] = { 'close', mode = { 'n', 'i' } },
    ['<Tab>'] = { 'choose_action', mode = { 'n', 'i' } },
    ['<S-Tab>'] = false,
    ['<c-l>'] = { 'refresh', mode = { 'n', 'i' } },
    ['<c-r>'] = { 'reload', mode = { 'n', 'i' } },
  }
  return vim.tbl_extend('force', common, extra)
end

local input_keys = keys({
  ['<Esc>'] = { 'escape', mode = { 'n', 'i' } },
  ['q'] = 'close',
  ['<c-n>'] = { 'list_down', mode = { 'n', 'i' } },
  ['<c-p>'] = { 'list_up', mode = { 'n', 'i' } },
  -- insert mode keeps the Emacs keys (plugin/emacs_cursor.vim) and <C-v> paste
  ['<c-a>'] = { 'select_all', mode = { 'n' } },
  ['<c-b>'] = { 'preview_scroll_up', mode = { 'n' } },
  ['<c-d>'] = { 'list_scroll_down', mode = { 'n' } },
  ['<c-f>'] = { 'preview_scroll_down', mode = { 'n' } },
  ['<c-k>'] = { 'list_up', mode = { 'n' } },
  ['<c-s>'] = { 'edit_split', mode = { 'n' } },
  ['<c-t>'] = { 'tab', mode = { 'n' } },
  ['<c-u>'] = { 'list_scroll_up', mode = { 'n' } },
  ['<c-v>'] = { 'edit_vsplit', mode = { 'n' } },
  -- <C-r> reloads; its register-like defaults would make it wait
  ['<c-r>#'] = false,
  ['<c-r>%'] = false,
  ['<c-r><c-a>'] = false,
  ['<c-r><c-f>'] = false,
  ['<c-r><c-l>'] = false,
  ['<c-r><c-p>'] = false,
  ['<c-r><c-w>'] = false,
})

local list_keys = keys({
  ['<Esc>'] = 'close',
  ['q'] = 'close',
  ['-'] = 'select_and_next',
  ['o'] = 'item_open',
  ['y'] = 'item_yank',
  ['p'] = 'toggle_preview',
})

---------------------------------------------------------------------------
-- Sources
---------------------------------------------------------------------------

local function files_finder(opts, ctx)
  return require('snacks.picker.source.files').files(opts, ctx)
end

--- Repositories under `ghq root`, with the packages of monorepos.
local function repos_finder(opts, ctx)
  local root = vim.trim(vim.fn.system({ 'ghq', 'root' }))
  return require('snacks.picker.source.proc').proc(
    ctx:opts({
      cmd = 'ghq-list-monorepo',
      args = {},
      notify = false,
      transform = function(item)
        if item.text == '' then
          return false
        end
        item.label = item.text
        item.file = root .. '/' .. item.text
        item.dir = true
      end,
    }),
    ctx
  )
end

--- Lines matching `pattern` below `dir` (relative paths), sorted by position.
local function grep_finder(pattern, dir)
  return function(opts, ctx)
    local matches = {}
    local run = require('snacks.picker.source.proc').proc(
      ctx:opts({
        cmd = 'rg',
        args = { '--json', '--', pattern },
        cwd = dir,
        notify = false,
        transform = function(item)
          local ok, json = pcall(vim.json.decode, item.text)
          if ok and json.type == 'match' then
            local data = json.data
            local sub = data.submatches[1] or { start = 0, ['end'] = 0 }
            local line = (data.lines.text or ''):gsub('\r?\n$', '')
            local match = {
              label = data.path.text,
              file = vim.fs.joinpath(dir, data.path.text),
              pos = { data.line_number, sub.start },
              col_label = sub.start,
              line = line,
              match = { sub.start, sub['end'] },
            }
            match.text = location_text(match)
            matches[#matches + 1] = match
          end
          return false
        end,
      }),
      ctx
    )
    return function(cb)
      run(function() end)
      table.sort(matches, function(a, b)
        if a.label ~= b.label then
          return a.label < b.label
        end
        if a.pos[1] ~= b.pos[1] then
          return a.pos[1] < b.pos[1]
        end
        return a.pos[2] < b.pos[2]
      end)
      for _, match in ipairs(matches) do
        cb(match)
      end
    end
  end
end

local grep_pattern

--- The grep pattern: asks for one when there is none yet or when `ask`.
--- Returns nil when the prompt is cancelled.
local function pattern_for(ask)
  if ask or not grep_pattern then
    local ok, input = pcall(vim.fn.input, 'Search: ')
    if not ok or input == '' then
      return nil
    end
    grep_pattern = input
  end
  return grep_pattern
end

---------------------------------------------------------------------------
-- API
---------------------------------------------------------------------------

--- <C-q>: files, or repositories when started in $HOME.
function M.open()
  local resume = can_resume()
  if vim.fn.getcwd() == vim.fs.normalize(vim.env.HOME) then
    return open({
      source = 'repositories',
      title = 'Repositories',
      finder = cached('repositories', repos_finder),
      format = format_file,
      confirm = 'item_cd',
      item_actions = { 'cd', 'yank' },
    }, resume)
  end
  return open({
    source = 'files',
    title = 'Files',
    finder = cached('files', files_finder),
    format = format_file,
    hidden = true,
    follow = true,
  }, resume)
end

--- <Space>/ (resume) and :Search {dir}: grep, with the results focused.
function M.search(dir, resume)
  resume = resume and can_resume()
  if not resume then
    last_cwd = vim.fn.getcwd()
  end
  if resume and require('snacks.picker.resume').state.rg and grep_pattern then
    return Snacks.picker.resume({ source = 'rg' })
  end
  local pattern = pattern_for(not resume)
  if not pattern then
    return
  end
  dir = vim.fs.normalize(vim.fn.fnamemodify(dir ~= '' and dir or '.', ':p'))
  local finder = grep_finder(pattern, dir)
  cache.rg = nil
  return Snacks.picker({
    source = 'rg',
    title = 'Grep',
    finder = cached('rg', function(opts, ctx)
      return finder(opts, ctx)
    end),
    format = format_location,
    focus = 'list',
    reload = function(picker)
      local new = pattern_for(true)
      if not new then
        return
      end
      finder = grep_finder(new, dir)
      actions.refresh(picker)
    end,
  })
end

local function location_item(it)
  local item = {
    label = vim.fn.fnamemodify(it.filename, ':.'),
    file = it.filename,
    pos = { it.lnum, math.max(it.col - 1, 0) },
    col_label = it.col,
    line = it.text,
  }
  if it.end_lnum == it.lnum and it.end_col and it.end_col > it.col then
    item.match = { it.col - 1, it.end_col - 1 }
  end
  item.text = location_text(item)
  return item
end

local locations_request

--- The locations shown last; <C-l> asks the language server again.
local function locations_finder()
  if cache.locations then
    return vim.deepcopy(cache.locations)
  end
  return function(cb)
    local async = require('snacks.picker.util.async').running()
    local items
    vim.schedule(function()
      if not locations_request then
        items = {}
        return async:resume()
      end
      locations_request(function(result)
        items = result
        async:resume()
      end)
    end)
    async:suspend()
    cache.locations = vim.tbl_map(location_item, items or {})
    for _, item in ipairs(vim.deepcopy(cache.locations)) do
      cb(item)
    end
  end
end

--- Shows LSP locations (quickfix items) in the picker; `request(callback)`
--- gathers them again.
function M.locations(items, request)
  last_cwd = vim.fn.getcwd()
  locations_request = request
  cache.locations = vim.tbl_map(location_item, items)
  return Snacks.picker({
    source = 'locations',
    title = 'Locations',
    finder = locations_finder,
    format = format_location,
    focus = 'list',
  })
end

--- gll: the last locations, as you left them.
function M.last_locations()
  if not cache.locations then
    return vim.notify('No locations', vim.log.levels.INFO)
  end
  if can_resume() and require('snacks.picker.resume').state.locations then
    return Snacks.picker.resume({ source = 'locations' })
  end
  -- paths relative to the new directory
  for _, item in ipairs(cache.locations) do
    item.label = vim.fn.fnamemodify(item.file, ':.')
    item.text = location_text(item)
  end
  return Snacks.picker({
    source = 'locations',
    title = 'Locations',
    finder = locations_finder,
    format = format_location,
    focus = 'list',
  })
end

function M.diagnostics()
  last_cwd = vim.fn.getcwd()
  return Snacks.picker.diagnostics({ focus = 'list' })
end

--- Reopens a source as it was left, whatever the directory.
function M.resume(source)
  if require('snacks.picker.resume').state[source] then
    Snacks.picker.resume({ source = source })
  end
end

--- Where a list of `count` code actions opens: next to the cursor, as
--- coc.nvim's did, just below the line, or just above it when there is no
--- room below. (Placed on the screen, not at the cursor, which is the
--- prompt's by the time the picker lays itself out again.)
local function next_to_cursor(count)
  -- as tall as the select layout makes it: the list (as many rows as items,
  -- at least 2), the prompt and its rule, the border
  local height = math.max(math.min(count, math.floor(vim.o.lines * 0.8) - 10), 2) + 4
  local cursor = vim.fn.screenpos(0, vim.fn.line('.'), vim.fn.col('.'))
  local above = cursor.row - 1
  local below = vim.o.lines - vim.o.cmdheight - 1 - cursor.row -- (above the statusline)
  local row = cursor.row -- (0-based: the row below the cursor)
  if below < height and above > below then
    row = math.max(above - height, 0)
  end
  return { relative = 'editor', row = row, col = cursor.col - 1, width = 0.4, min_width = 50, max_width = 80 }
end

function M.setup()
  require('snacks').setup({
    picker = {
      ui_select = true,
      layout = {
        preset = 'vertical',
        hidden = { 'preview' },
        cycle = false,
      },
      actions = actions,
      win = {
        input = { keys = input_keys },
        list = { keys = list_keys },
      },
      icons = { files = { enabled = false } },
    },
  })
  -- (snacks sets it on UIEnter, which a headless Neovim never gets)
  vim.ui.select = function(items, opts, on_choice)
    if opts and opts.kind == 'codeaction' then
      opts = vim.tbl_extend('force', opts, { snacks = { layout = { layout = next_to_cursor(#items) } } })
    end
    return Snacks.picker.select(items, opts, on_choice)
  end

  vim.api.nvim_create_user_command('Open', M.open, { nargs = 0 })
  vim.api.nvim_create_user_command('Search', function(opts)
    M.search(opts.args, opts.bang)
  end, { nargs = '?', bang = true, complete = 'dir' })

  vim.keymap.set('n', '<C-q>', M.open, { desc = 'Files (repositories in $HOME)' })
  vim.keymap.set('n', '<Space>/', '<Cmd>Search!<CR>', { desc = 'Grep' })
  vim.keymap.set('n', 'gll', M.last_locations, { desc = 'Last locations' })
end

return M

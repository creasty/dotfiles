-- Fuzzy finder built on snacks.nvim's picker.
--
--   <C-q>      files, or ghq repositories in $HOME (:Open)
--   <Space>/   grep for a pattern (:Search [dir]), and replace it
--   gR gD gT   LSP locations (user.plugin.lsp); gll reopens them
--
-- Each source reopens as you left it (query, results, selected line, marks)
-- as long as you stay in the directory of the previous picker; the results
-- are gathered again only with <C-l> (refresh) or <C-r> (reload).
--
-- In grep's list, as in VS Code's search view:
--
--   f   the files to search: paths and globs, ! before those to leave out
--       (src/ !*.test.ts); <Tab> completes the paths
--   r   the replacement ($1 for the first group), which every line previews
--   x   drops the line, or the marked lines, from the results
--   R   replaces the matches of the lines in the list (the marked ones if
--       any) in their files; deletes them without a replacement

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

--- The matches (`item.matches`: start, end, replacement) highlighted; with a
--- replacement (`item.replaced`: the line after it), what each turns into,
--- after the match struck through (as VS Code previews it).
local function format_location(item)
  local ret = {
    { item.label, 'Identifier' },
    { ' ' },
    { ('%d:%d |'):format(item.pos[1], item.col_label), 'Comment' },
  }
  local line, at = item.line or '', 0
  for _, match in ipairs(item.matches or {}) do
    ret[#ret + 1] = { line:sub(at + 1, match[1]) }
    local old = line:sub(match[1] + 1, match[2])
    if item.replaced then
      ret[#ret + 1] = { old, 'PickerReplaceOld', inline = true }
      ret[#ret + 1] = { match[3] or '', 'PickerReplaceNew' }
    else
      ret[#ret + 1] = { old, 'Constant' }
    end
    at = match[2]
  end
  ret[#ret + 1] = { line:sub(at + 1) }
  return ret
end

--- The text an item shows (what the matcher filters on).
local function location_text(item)
  return ('%s %d:%d |%s'):format(item.label, item.pos[1], item.col_label, item.replaced or item.line or '')
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
  if picker.opts.refresh then
    picker.opts.refresh(picker)
  end
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

--- The search <Space>/ reopens: its pattern, the directory it runs in, the
--- files it searches there (see filter_globs()), the replacement its list
--- previews (nil: none), and the lines dropped from its results (by
--- line_key()) until it runs again.
local grep = { filter = '', dropped = {} }

--- The paths and globs of a filter, between spaces or commas (not those of
--- a {a,b} glob).
local function filter_entries(filter)
  local entries, entry, depth = {}, '', 0
  for char in filter:gmatch('.') do
    depth = math.max(depth + (char == '{' and 1 or char == '}' and -1 or 0), 0)
    if char:match('%s') or (char == ',' and depth == 0) then
      entries[#entries + 1] = entry ~= '' and entry or nil
      entry = ''
    else
      entry = entry .. char
    end
  end
  entries[#entries + 1] = entry ~= '' and entry or nil
  return entries
end

--- rg's globs for the files to search: `src/ lib/util *.ts !*.test.ts`.
--- Each is a pattern as in .gitignore, but one with a / anywhere is a path
--- from the search directory, as <Tab> completes it (./src too), and a
--- directory stands for everything below it. Those after ! are left out.
local function filter_globs(filter)
  local globs = {}
  for _, entry in ipairs(filter_entries(filter)) do
    local bang, glob = entry:match('^(!?)(.*)$')
    glob = glob:gsub('^%./', '/')
    if glob:find('/') and not glob:find('^/') and not glob:find('^%*%*/') then
      glob = '/' .. glob
    end
    local everything = glob:find('^/?$')
    if bang == '!' and not everything then
      globs[#globs + 1] = '!' .. glob -- (rg leaves out a directory as a whole)
    elseif not everything then
      -- rg searches the files an include matches, not those below a
      -- directory it matches
      local dir = glob:match('^(.*)/$')
      if not dir then
        globs[#globs + 1] = glob
        dir = glob
      end
      if not dir:find('%*%*$') then
        globs[#globs + 1] = (dir:find('/') and dir or '**/' .. dir) .. '/**'
      end
    end
  end
  return globs
end

--- Where a result is: its file and line.
local function line_key(item)
  return item.file .. ':' .. item.pos[1]
end

--- `line` with its matches (start, end, replacement) replaced; by nothing
--- when they have no replacement.
local function replace_matches(line, matches)
  local parts, at = {}, 0
  for _, match in ipairs(matches) do
    parts[#parts + 1] = line:sub(at + 1, match[1])
    parts[#parts + 1] = match[3] or ''
    at = match[2]
  end
  parts[#parts + 1] = line:sub(at + 1)
  return table.concat(parts)
end

--- A result, from rg's JSON message about a line with matches.
local function grep_item(data, dir)
  -- (rg gives the bytes, not the text, of a line that is not UTF-8: the
  -- list shows it empty, and R leaves it as it is)
  local raw = data.lines.text and data.lines.text:gsub('\n$', '')
  local item = {
    label = data.path.text,
    file = vim.fs.joinpath(dir, data.path.text),
    raw = raw, -- (with the \r of a CRLF line)
    line = raw and raw:gsub('\r$', '') or '',
    matches = {},
  }
  for _, sub in ipairs(data.submatches) do
    item.matches[#item.matches + 1] = { sub.start, sub['end'], sub.replacement and sub.replacement.text }
  end
  local col = item.matches[1] and item.matches[1][1] or 0
  item.pos = { data.line_number, col }
  item.col_label = col
  if grep.replacement then
    item.replaced = replace_matches(item.line, item.matches)
  end
  item.text = location_text(item)
  return item
end

--- Lines matching the pattern below the directory (relative paths), sorted
--- by position, but for those dropped from the results.
local function grep_finder(opts, ctx)
  local dir, matches = grep.dir, {}
  -- (nothing in .git, which rg searches with --hidden)
  local args = { '--json', '--glob=!.git' }
  if grep.replacement then
    args[#args + 1] = '--replace=' .. grep.replacement
  end
  for _, glob in ipairs(filter_globs(grep.filter)) do
    args[#args + 1] = '--glob=' .. glob
  end
  vim.list_extend(args, { '--', grep.pattern })
  local run = require('snacks.picker.source.proc').proc(
    ctx:opts({
      cmd = 'rg',
      args = args,
      cwd = dir,
      notify = false,
      transform = function(item)
        local ok, json = pcall(vim.json.decode, item.text)
        if ok and json.type == 'match' and json.data.path.text then
          local match = grep_item(json.data, dir)
          if not grep.dropped[line_key(match)] then
            matches[#matches + 1] = match
          end
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

--- The grep pattern: asks for one when there is none yet or when `ask`.
--- Returns nil when the prompt is cancelled.
local function pattern_for(ask)
  if ask or not grep.pattern then
    local ok, input = pcall(vim.fn.input, 'Search: ')
    if not ok or input == '' then
      return nil
    end
    grep.pattern = input
  end
  return grep.pattern
end

--- The pattern, the replacement and the files to search.
local function grep_title()
  local title = 'Grep ' .. grep.pattern
  if grep.replacement then
    title = title .. ' → ' .. grep.replacement
  end
  if grep.filter ~= '' then
    title = title .. ' · ' .. grep.filter
  end
  return title
end

--- Shows the search as it is now in the title, and when it reopens.
local function update_title(picker)
  picker.title = grep_title()
  picker.init_opts.title = picker.title
  picker:update_titles()
end

--- Completes the last path of the files to search (f), below the search
--- directory. (input() completes the whole line: the others stay.)
function M.complete_files(lead)
  local before, word = lead:match('^(.*[%s,])(.-)$')
  if not before then
    before, word = '', lead
  end
  local bang, path = word:match('^(!?)(.*)$')
  local dir, name = path:match('^(.*/)(.-)$')
  if not dir then
    dir, name = '', path
  end
  local base = vim.fs.joinpath(grep.dir or vim.fn.getcwd(), dir)
  if path:find('[*?[{]') or (vim.uv.fs_stat(base) or {}).type ~= 'directory' then
    return {}
  end
  local case = vim.o.wildignorecase and string.lower or function(s)
    return s
  end
  local paths = {}
  for entry, kind in vim.fs.dir(base) do
    -- (hidden ones once the name starts with a dot, as in the shell)
    local hidden = entry:sub(1, 1) == '.' and name:sub(1, 1) ~= '.'
    if not hidden and entry ~= '.git' and vim.startswith(case(entry), case(name)) then
      if kind == 'link' then
        kind = (vim.uv.fs_stat(vim.fs.joinpath(base, entry)) or {}).type
      end
      paths[#paths + 1] = before .. bang .. dir .. entry .. (kind == 'directory' and '/' or '')
    end
  end
  table.sort(paths)
  return paths
end

local function plural(n, one, many)
  return ('%d %s'):format(n, n == 1 and one or many)
end

--- Replaces the matches of `items` (results of grep) in their files: in its
--- buffer when a file is loaded (and writes it, unless it has changes of
--- its own), in the file itself otherwise. A line that changed since the
--- search stays as it is. Returns the numbers of matches replaced, of files
--- changed and of lines left.
local function replace_in_files(items)
  local by_file, files = {}, {}
  for _, item in ipairs(items) do
    if not by_file[item.file] then
      by_file[item.file] = {}
      files[#files + 1] = item.file
    end
    table.insert(by_file[item.file], item)
  end
  local bufs = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local path = vim.api.nvim_buf_is_loaded(buf) and vim.uv.fs_realpath(vim.api.nvim_buf_get_name(buf))
    if path then
      bufs[path] = buf
    end
  end

  local replaced, changed, left = 0, 0, 0
  for _, file in ipairs(files) do
    local buf = bufs[vim.uv.fs_realpath(file) or file]
    local ok, lines = true, nil
    if buf then
      lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    else
      ok, lines = pcall(vim.fn.readfile, file, 'b')
    end
    local lnums, count = {}, 0
    for _, item in ipairs(by_file[file]) do
      local old = item.raw
      local new = old and replace_matches(old, item.matches)
      if old and buf and vim.bo[buf].fileformat == 'dos' then
        old, new = (old:gsub('\r$', '')), (new:gsub('\r$', ''))
      end
      local lnum = item.pos[1]
      if ok and old and lines[lnum] == old then
        lines[lnum] = new
        lnums[#lnums + 1] = lnum
        count = count + #item.matches
      else
        left = left + 1
      end
    end
    if #lnums > 0 then
      local written
      if buf then
        local modified = vim.bo[buf].modified
        for _, lnum in ipairs(lnums) do
          vim.api.nvim_buf_set_lines(buf, lnum - 1, lnum, true, { lines[lnum] })
        end
        written = modified or pcall(vim.api.nvim_buf_call, buf, function()
          vim.cmd('silent update')
        end)
      else
        local wrote, result = pcall(vim.fn.writefile, lines, file, 'b')
        written = wrote and result == 0
      end
      if written then
        replaced, changed = replaced + count, changed + 1
      else
        vim.notify('Cannot write ' .. vim.fn.fnamemodify(file, ':~:.'), vim.log.levels.ERROR)
      end
    end
  end
  return replaced, changed, left
end

--- f: asks for the files to search (filter_globs()).
function actions.grep_files(picker)
  local ok, filter = pcall(vim.fn.input, {
    prompt = 'Files: ',
    default = grep.filter,
    completion = "customlist,v:lua.require'user.plugin.picker'.complete_files",
    cancelreturn = vim.NIL,
  })
  if not ok or filter == vim.NIL then
    return
  end
  grep.filter = vim.trim(filter)
  update_title(picker)
  actions.refresh(picker)
end

--- r: asks for the replacement (rg's: $1 for the first group, $$ for a $)
--- that every line previews, staying on the line; none ends the preview.
function actions.grep_replace(picker)
  local ok, replacement = pcall(vim.fn.input, {
    prompt = 'Replace: ',
    default = grep.replacement or '',
    cancelreturn = vim.NIL,
  })
  if not ok or replacement == vim.NIL then
    return
  end
  grep.replacement = replacement ~= '' and replacement or nil
  update_title(picker)
  cache.rg = nil
  picker:refresh()
end

--- x: drops the marked lines, or the line under the cursor, from the results
--- (and from what R replaces), until the search runs again.
function actions.grep_drop(picker)
  local dropped = {}
  for _, item in ipairs(picker:selected({ fallback = true })) do
    dropped[line_key(item)] = true
    grep.dropped[line_key(item)] = true
  end
  local function kept(item)
    return not dropped[line_key(item)]
  end
  if cache.rg then
    cache.rg = vim.tbl_filter(kept, cache.rg)
  end
  -- on the line that took the place of the one under the cursor
  local count = #vim.tbl_filter(kept, picker:items())
  picker.list:set_selected()
  picker.list:set_target(math.max(math.min(picker.list.cursor, count), 1), nil, { force = true })
  picker:find({ refresh = true })
end

--- R: replaces the matches of the lines in the list (the marked ones, if
--- any) in their files, once you confirm; deletes them without a
--- replacement. The search then runs again, without it.
function actions.grep_apply(picker)
  local items = picker:selected()
  if #items == 0 then
    items = picker:items()
  end
  local matches, files = 0, {}
  for _, item in ipairs(items) do
    matches = matches + #item.matches
    files[item.file] = true
  end
  if matches == 0 then
    return
  end
  local what = ('%s in %s'):format(plural(matches, 'match', 'matches'), plural(vim.tbl_count(files), 'file', 'files'))
  local question = grep.replacement and ('Replace %s with "%s"? [y/N] '):format(what, grep.replacement)
    or ('Delete %s? [y/N] '):format(what)
  local ok, answer = pcall(vim.fn.input, question)
  if not ok or not answer:match('^%s*[yY]') then
    return
  end
  local replaced, changed, left = replace_in_files(items)
  local message = ('%s %s in %s'):format(
    grep.replacement and 'Replaced' or 'Deleted',
    plural(replaced, 'match', 'matches'),
    plural(changed, 'file', 'files')
  )
  if left > 0 then
    message = ('%s; left %s that changed since the search'):format(message, plural(left, 'line', 'lines'))
  end
  vim.notify(message, left > 0 and vim.log.levels.WARN or vim.log.levels.INFO)
  grep.replacement = nil
  update_title(picker)
  actions.refresh(picker)
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

--- <Space>/ (resume) and :Search {dir}: grep, with the results focused. A
--- new search starts with every file, and no replacement.
function M.search(dir, resume)
  resume = resume and can_resume()
  if not resume then
    last_cwd = vim.fn.getcwd()
  end
  if resume and require('snacks.picker.resume').state.rg and grep.pattern then
    return Snacks.picker.resume({ source = 'rg' })
  end
  if not pattern_for(not resume) then
    return
  end
  grep.dir = vim.fs.normalize(vim.fn.fnamemodify(dir ~= '' and dir or '.', ':p'))
  grep.filter, grep.replacement, grep.dropped = '', nil, {}
  cache.rg = nil
  return Snacks.picker({
    source = 'rg',
    title = grep_title(),
    finder = cached('rg', grep_finder),
    format = format_location,
    focus = 'list',
    -- (searching again brings back the lines dropped from the results)
    refresh = function()
      grep.dropped = {}
    end,
    reload = function(picker)
      if pattern_for(true) then
        update_title(picker)
        actions.refresh(picker)
      end
    end,
    win = {
      list = {
        keys = { f = 'grep_files', r = 'grep_replace', x = 'grep_drop', R = 'grep_apply' },
      },
    },
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
    item.matches = { { it.col - 1, it.end_col - 1 } }
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

--- Where a list of `count` code actions opens: next to the cursor, just below
--- the line, or just above it when there is no room below. (Placed on the
--- screen, not at the cursor, which is the prompt's by the time the picker
--- lays itself out again.)
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
      ui_select = false, -- (set below, placing code actions)
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

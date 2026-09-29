-- Loaded inside every child as `_G.__e2e` (see prelude.lua).
--
-- Observes plugin-provided UI in terms of what you see, not how a plugin
-- implements it. Each probe knows the current plugin *and* the usual
-- replacements, so specs keep working across a swap. When you adopt a plugin
-- that is not recognized here, teach the relevant probe about it.

local M = {}

local function try_require(name)
  if not package.loaded[name] and not vim.api.nvim_get_runtime_file('lua/' .. name:gsub('%.', '/') .. '*', false)[1] then
    return nil
  end
  local ok, mod = pcall(require, name)
  return ok and mod or nil
end

---------------------------------------------------------------------------
-- Completion menu
---------------------------------------------------------------------------

--- { visible, items = { word... }, selected = word|nil, engine }
function M.completion()
  -- blink.cmp
  local blink = try_require('blink.cmp')
  if blink and blink.is_menu_visible and blink.is_menu_visible() then
    local list = require('blink.cmp.completion.list')
    local items = vim.tbl_map(function(item)
      return item.label
    end, list.items or {})
    local selected = list.get_selected_item and list.get_selected_item()
    return { visible = true, items = items, selected = selected and selected.label or nil, engine = 'blink' }
  end
  -- nvim-cmp
  local cmp = try_require('cmp')
  if cmp and cmp.visible and cmp.visible() then
    local items = vim.tbl_map(function(entry)
      return entry:get_completion_item().label
    end, cmp.get_entries())
    local selected = cmp.get_selected_entry()
    return { visible = true, items = items, selected = selected and selected:get_completion_item().label or nil, engine = 'cmp' }
  end
  -- built-in popup menu (vim.lsp.completion, <C-n>, ...)
  if vim.fn.pumvisible() == 1 then
    local info = vim.fn.complete_info({ 'items', 'selected' })
    local items = vim.tbl_map(function(item)
      return item.abbr ~= '' and item.abbr or item.word
    end, info.items)
    return { visible = true, items = items, selected = info.selected >= 0 and items[info.selected + 1] or nil, engine = 'native' }
  end
  return { visible = false, items = {} }
end

--- Turns the completion menu off for the current buffer, for tests about
--- something else (e.g. pinning snippet expansions) that must not race it.
function M.disable_completion()
  vim.b.completion = false -- blink.cmp
  local cmp = try_require('cmp')
  if cmp and cmp.setup and cmp.setup.buffer then
    cmp.setup.buffer({ enabled = false })
  end
end

---------------------------------------------------------------------------
-- Snippet session
---------------------------------------------------------------------------

function M.snippet_active()
  local luasnip = try_require('luasnip')
  if luasnip and luasnip.get_active_snip and luasnip.get_active_snip() then
    return true
  end
  if vim.snippet and vim.snippet.active() then
    return true
  end
  return false
end

---------------------------------------------------------------------------
-- Ghost text (AI inline suggestions)
---------------------------------------------------------------------------

--- Whether the AI plugin would ask for a suggestion now. copilot.lua marks
--- its client initialized a moment after the server has the buffer open, and
--- drops what you type before that until the cursor moves again.
function M.ai_ready()
  local copilot = package.loaded['copilot.client']
  if copilot then
    return copilot.initialized == true and copilot.buf_is_attached(0) == true
  end
  return true
end

--- All virtual text anchored on the cursor line (virt_text + virt_lines),
--- except right-aligned status text (such as a picker's result counter).
function M.ghost_text()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local texts = {}
  local marks = vim.api.nvim_buf_get_extmarks(0, -1, { row, 0 }, { row, -1 }, { details = true })
  for _, mark in ipairs(marks) do
    local d = mark[4]
    if d.virt_text_pos == 'right_align' then
      d = { virt_lines = d.virt_lines }
    end
    local parts = {}
    for _, chunk in ipairs(d.virt_text or {}) do
      parts[#parts + 1] = chunk[1]
    end
    for _, line in ipairs(d.virt_lines or {}) do
      local l = {}
      for _, chunk in ipairs(line) do
        l[#l + 1] = chunk[1]
      end
      parts[#parts + 1] = '\n' .. table.concat(l)
    end
    if #parts > 0 then
      texts[#texts + 1] = table.concat(parts)
    end
  end
  return table.concat(texts, '\n')
end

---------------------------------------------------------------------------
-- Fuzzy finder / picker
---------------------------------------------------------------------------

-- Pickers whose list is a plain buffer of result lines.
local LIST_FILETYPES = {
  TelescopeResults = true,
  minipick = true,
}
local PROMPT_FILETYPES = {
  TelescopePrompt = true,
}

-- Highlight groups pickers use for marked (multi-selected) items.
local MARKED_HIGHLIGHTS = {
  TelescopeMultiSelection = true,
}

local function marked_lines(buf)
  local lines = {}
  for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })) do
    if MARKED_HIGHLIGHTS[mark[4].hl_group] then
      lines[#lines + 1] = vim.api.nvim_buf_get_lines(buf, mark[2], mark[2] + 1, false)[1]
    end
  end
  return lines
end

local function struck_through(group)
  return type(group) == 'string' and vim.api.nvim_get_hl(0, { name = group, link = false }).strikethrough == true
end

--- The text a snacks.nvim picker shows for an item (without the column
--- marking selected items). Text shown struck through between the
--- characters, as a replacement's preview shows what it replaces, reads
--- {-text-}.
local function snacks_text(picker, item)
  local hl = Snacks.picker.highlight
  local ok, text = pcall(function()
    local line = hl.resolve(picker.format(item, picker), 1000)
    for _, chunk in ipairs(line) do
      if chunk.inline and type(chunk[1]) == 'string' and struck_through(chunk[2]) then
        chunk[1], chunk.inline = '{-' .. chunk[1] .. '-}', nil
      end
    end
    return (hl.to_text(line))
  end)
  return ok and text:gsub('%s+$', '') or item.text
end

--- snacks.nvim renders only the visible part of its list: read its state.
local function snacks_picker(result)
  local ok, pickers = pcall(function()
    return Snacks.picker.get()
  end)
  local picker = ok and pickers[#pickers]
  if not picker then
    return false
  end
  local cur = vim.api.nvim_get_current_win()
  local list, input = picker.list, picker.input
  result.open = true
  result.source = picker.opts.source
  result.title = picker.title
  for _, win in ipairs({ list.win.win, input.win.win }) do
    if win and vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_config(win).relative ~= '' then
      result.floating = true
    end
  end
  if list.win.win == cur then
    result.focus = 'list'
  elseif input.win.win == cur then
    result.focus = 'prompt'
  end
  result.focused = result.focus ~= nil
  result.loading = picker:is_active() or list.target ~= nil
  for i = 1, list:count() do
    result.items[#result.items + 1] = snacks_text(picker, list:get(i))
  end
  local height = list:height()
  for i = list.top, math.min(list.top + height - 1, list:count()) do
    result.visible[#result.visible + 1] = result.items[i]
  end
  result.current = result.items[list.cursor]
  for _, item in ipairs(picker:selected({ fallback = false })) do
    result.marked[#result.marked + 1] = snacks_text(picker, item)
  end
  result.query = input.win:valid() and input:get() or nil
  return true
end

--- { open, floating, focused, focus, loading, items, visible, current,
---   marked, query, source, title }
--- focus: 'prompt' or 'list', the picker window with the cursor; loading:
--- the picker is still filling the list; items: the results, as shown
--- (struck-through text in {- -}); visible: those on screen in the list
--- window; current: the selected one (the item <CR> acts on); marked: those
--- marked for a multi-item action; query: the prompt text; source: the
--- picker's name for what it lists; title: the title on its border.
function M.picker()
  local result = { open = false, floating = false, focused = false, loading = false, items = {}, visible = {}, marked = {}, query = nil, current = nil }
  if snacks_picker(result) then
    return result
  end
  local cur = vim.api.nvim_get_current_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.bo[buf].filetype
    local floating = vim.api.nvim_win_get_config(win).relative ~= ''
    if LIST_FILETYPES[ft] then
      result.open = true
      result.floating = result.floating or floating
      if win == cur then
        result.focus = 'list'
      end
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      for _, line in ipairs(lines) do
        if line ~= '' then
          result.items[#result.items + 1] = line
        end
      end
      local row = vim.api.nvim_win_get_cursor(win)[1]
      result.current = lines[row] ~= '' and lines[row] or nil
      result.marked = marked_lines(buf)
      local info = vim.fn.getwininfo(win)[1]
      for i = info.topline, info.botline do
        if lines[i] and lines[i] ~= '' then
          result.visible[#result.visible + 1] = lines[i]
        end
      end
    elseif PROMPT_FILETYPES[ft] then
      result.open = true
      result.floating = result.floating or floating
      if win == cur then
        result.focus = 'prompt'
      end
      result.query = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ''
    end
  end
  result.focused = result.focus ~= nil
  return result
end

--- True once the background services started at VimEnter are up (you
--- never type within the first second after launching).
function M.services_ready()
  return true
end

--- True once the picker backend can serve requests.
function M.picker_ready()
  return true
end

--- True once a choice menu (code actions etc.) accepts keys: a picker
--- listing the choices, or the built-in vim.ui.select on the command line.
function M.choice_menu_ready()
  local picker = M.picker()
  if picker.open and not picker.loading and #picker.items > 0 then
    return true
  end
  local mode = vim.api.nvim_get_mode().mode
  return mode == 'c' or mode:sub(1, 1) == 'r'
end

--- The open picker (snacks.nvim's), or nil.
local function open_picker()
  local ok, pickers = pcall(function()
    return Snacks.picker.get()
  end)
  return ok and pickers[#pickers] or nil
end

--- Where the open picker is on the screen: the first row and column of its
--- outer window, border included, and its last row (1-based).
function M.picker_box()
  local picker = open_picker()
  local win = picker and picker.layout.root.win
  if not (win and vim.api.nvim_win_is_valid(win)) then
    return nil
  end
  local pos = vim.api.nvim_win_get_position(win)
  local border = vim.api.nvim_win_get_config(win).border or {}
  local function edge(i)
    local char = border[i] or ''
    return (type(char) == 'table' and char[1] or char) ~= '' and 1 or 0
  end
  -- (a side takes a row when its middle character is set)
  local height = edge(2) + vim.api.nvim_win_get_height(win) + edge(6)
  return { row = pos[1] + 1, col = pos[2] + 1, last_row = pos[1] + height }
end

--- The background colors of the open picker's input, list and border.
function M.picker_colors()
  local picker = open_picker()
  if not picker then
    return nil
  end
  --- The color `group` has in `win`, through its 'winhighlight'.
  local function background(win, group)
    for from, to in vim.wo[win].winhighlight:gmatch('([^:,]+):([^,]+)') do
      if from == group then
        group = to
      end
    end
    return vim.api.nvim_get_hl(0, { name = group, link = false }).bg
  end
  return {
    input = background(picker.input.win.win, 'NormalFloat'),
    list = background(picker.list.win.win, 'NormalFloat'),
    border = background(picker.layout.root.win, 'FloatBorder'),
  }
end

---------------------------------------------------------------------------
-- Signs & highlights
---------------------------------------------------------------------------

--- Sign texts shown on a line (legacy signs and extmark signs).
function M.signs(lnum, buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local texts = {}
  local placed = vim.fn.sign_getplaced(buf, { group = '*', lnum = lnum })[1]
  for _, sign in ipairs(placed and placed.signs or {}) do
    local def = vim.fn.sign_getdefined(sign.name)[1]
    if def and def.text then
      texts[#texts + 1] = vim.trim(def.text)
    end
  end
  local marks = vim.api.nvim_buf_get_extmarks(buf, -1, { lnum - 1, 0 }, { lnum - 1, -1 }, { details = true })
  for _, mark in ipairs(marks) do
    if mark[4].sign_text then
      texts[#texts + 1] = vim.trim(mark[4].sign_text)
    end
  end
  return texts
end

--- Positions ({lnum, col}, 1-based) highlighted as "same symbol as under the
--- cursor" (LSP document highlight).
function M.reference_highlights()
  local positions = {}
  local marks = vim.api.nvim_buf_get_extmarks(0, -1, 0, -1, { details = true })
  for _, mark in ipairs(marks) do
    local hl = mark[4].hl_group
    if type(hl) == 'string' and hl:match('^LspReference') then
      positions[#positions + 1] = { mark[2] + 1, mark[3] + 1 }
    end
  end
  table.sort(positions, function(a, b)
    return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2])
  end)
  return positions
end

--- Diagnostic counts for the current buffer, from whichever client owns them.
function M.diagnostics()
  local counts = { error = 0, warning = 0, info = 0, hint = 0 }
  local s = vim.diagnostic.severity
  for _, d in ipairs(vim.diagnostic.get(0)) do
    local key = ({ [s.ERROR] = 'error', [s.WARN] = 'warning', [s.INFO] = 'info', [s.HINT] = 'hint' })[d.severity]
    counts[key] = counts[key] + 1
  end
  return counts
end

---------------------------------------------------------------------------
-- Git views
---------------------------------------------------------------------------

--- True once the current buffer's git state is known (its signs, its blame).
--- (gitsigns sets its status before it attaches, and the counts of changes
--- once it has compared the buffer.)
function M.git_ready()
  local status = vim.b.gitsigns_status_dict
  return status ~= nil and status.added ~= nil
end

--- The windows of the current tab page, left to right, then top to bottom.
local function tab_wins()
  local wins = vim.api.nvim_tabpage_list_wins(0)
  table.sort(wins, function(a, b)
    local pa, pb = vim.api.nvim_win_get_position(a), vim.api.nvim_win_get_position(b)
    return pa[2] < pb[2] or (pa[2] == pb[2] and pa[1] < pb[1])
  end)
  return wins
end

local function win_lines(win)
  return vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false)
end

--- The lines of the blame shown beside the file, or nil.
function M.blame_view()
  for _, win in ipairs(tab_wins()) do
    local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
    if ft == 'gitsigns-blame' or ft == 'fugitiveblame' then
      return win_lines(win)
    end
  end
end

--- The diff of many files: { files = the text of its file list, sides = the
--- lines of each window in diff mode, left to right }, or nil.
function M.diff_view()
  local view = { sides = {} }
  for _, win in ipairs(tab_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'DiffviewFiles' then
      view.files = table.concat(win_lines(win), '\n')
    elseif vim.wo[win].diff then
      view.sides[#view.sides + 1] = win_lines(win)
    end
  end
  return view.files and view or nil
end

---------------------------------------------------------------------------
-- Operator formatting
---------------------------------------------------------------------------

--- Whether operator formatting (creasty/opfmt) is switched on: it is not
--- loaded until it moves to nvim-treesitter's main branch.
function M.opfmt_enabled()
  return package.loaded['opfmt'] ~= nil
end

return M

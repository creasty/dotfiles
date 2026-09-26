-- Loaded inside every child as `_G.__e2e` (see prelude.lua).
--
-- Observes plugin-provided UI in terms of what you see, not how a plugin
-- implements it. Each probe knows the current plugin *and* the usual
-- replacements, so specs keep working across a swap. When you adopt a plugin
-- that is not recognized here, teach the relevant probe about it.

local M = {}

local function has_fn(name)
  return vim.fn.exists('*' .. name) == 1
end

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
  -- coc.nvim (custom floating pum)
  if has_fn('coc#pum#visible') and vim.fn['coc#pum#visible']() == 1 then
    local win = vim.fn['coc#pum#winid']()
    local info = vim.fn['coc#pum#info']()
    local words = vim.fn.getwinvar(win, 'words', {})
    local selected = info.index and info.index >= 0 and words[info.index + 1] or nil
    return { visible = true, items = words, selected = selected, engine = 'coc' }
  end
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
  vim.b.coc_suggest_disable = 1 -- coc.nvim
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
  local coc = vim.b.coc_snippet_active
  if coc == 1 or coc == true then
    return true
  end
  if vim.g.did_plugin_ultisnips == 1 and has_fn('UltiSnips#CanJumpForwards') then
    if vim.fn['UltiSnips#CanJumpForwards']() == 1 or vim.fn['UltiSnips#CanJumpBackwards']() == 1 then
      return true
    end
  end
  local luasnip = try_require('luasnip')
  if luasnip and luasnip.in_snippet and luasnip.in_snippet() then
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

--- All virtual text anchored on the cursor line (virt_text + virt_lines).
function M.ghost_text()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local texts = {}
  local marks = vim.api.nvim_buf_get_extmarks(0, -1, { row, 0 }, { row, -1 }, { details = true })
  for _, mark in ipairs(marks) do
    local d = mark[4]
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

local LIST_FILETYPES = {
  ['ddu-ff'] = true,
  TelescopeResults = true,
  snacks_picker_list = true,
  minipick = true,
}
local PROMPT_FILETYPES = {
  ['ddu-ff-filter'] = true,
  TelescopePrompt = true,
  snacks_picker_input = true,
}

--- { open, floating, focused, items, current, query }
--- items: non-empty lines of the result list; current: the line under the
--- list cursor (the item <CR> acts on); query: the prompt text.
function M.picker()
  local result = { open = false, floating = false, focused = false, items = {}, query = nil, current = nil }
  local cur = vim.api.nvim_get_current_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.bo[buf].filetype
    local floating = vim.api.nvim_win_get_config(win).relative ~= ''
    if LIST_FILETYPES[ft] then
      result.open = true
      result.floating = result.floating or floating
      result.focused = result.focused or win == cur
      result.list_filetype = ft
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      for _, line in ipairs(lines) do
        if line ~= '' then
          result.items[#result.items + 1] = line
        end
      end
      local row = vim.api.nvim_win_get_cursor(win)[1]
      result.current = lines[row] ~= '' and lines[row] or nil
    elseif PROMPT_FILETYPES[ft] then
      result.open = true
      result.floating = result.floating or floating
      result.focused = result.focused or win == cur
      result.prompt_filetype = ft
      result.query = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ''
    end
  end
  return result
end

--- True once the background services started at VimEnter are up (you
--- never type within the first second after launching).
function M.services_ready()
  if vim.g.did_coc_loaded and vim.g.coc_service_initialized ~= 1 then
    return false
  end
  return true
end

--- True once the picker backend can serve requests (ddu runs in denops,
--- which starts after startup).
function M.picker_ready()
  if has_fn('denops#plugin#is_loaded') then
    return vim.fn['denops#server#status']() == 'running' and vim.fn['denops#plugin#is_loaded']('ddu') == 1
  end
  return true
end

--- True once a choice menu (code actions etc.) accepts keys: coc runs its
--- own key loop, the built-in vim.ui.select prompts on the command line.
function M.choice_menu_ready()
  if has_fn('coc#prompt#activated') and vim.fn['coc#prompt#activated']() == 1 then
    return true
  end
  local mode = vim.api.nvim_get_mode().mode
  return mode == 'c' or mode:sub(1, 1) == 'r'
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
  for _, m in ipairs(vim.fn.getmatches()) do
    if m.group:match('^CocHighlight') then
      for i = 1, 8 do
        local pos = m['pos' .. i]
        if pos then
          positions[#positions + 1] = { pos[1], pos[2] }
        end
      end
    end
  end
  local marks = vim.api.nvim_buf_get_extmarks(0, -1, 0, -1, { details = true })
  for _, mark in ipairs(marks) do
    local hl = mark[4].hl_group
    if type(hl) == 'string' and (hl:match('^LspReference') or hl:match('^CocHighlight')) then
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
  local coc = vim.b.coc_diagnostic_info
  if type(coc) == 'table' then
    counts.error = counts.error + (coc.error or 0)
    counts.warning = counts.warning + (coc.warning or 0)
    counts.info = counts.info + (coc.information or 0)
    counts.hint = counts.hint + (coc.hint or 0)
  end
  local s = vim.diagnostic.severity
  for _, d in ipairs(vim.diagnostic.get(0)) do
    local key = ({ [s.ERROR] = 'error', [s.WARN] = 'warning', [s.INFO] = 'info', [s.HINT] = 'hint' })[d.severity]
    counts[key] = counts[key] + 1
  end
  return counts
end

return M

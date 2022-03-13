local filereadable_key = 'filereadable'

local function file_exists(name)
  local f = io.open(name, 'r')
  return f ~= nil and io.close(f)
end

local function buf_get_var(bufnr, name, default)
  local ok, value = pcall(vim.api.nvim_buf_get_var, bufnr, name)
  if ok then return value end
  return default
end

local function update_filereadable()
  local path = vim.api.nvim_buf_get_name(0)
  if path ~= '' then
    vim.api.nvim_buf_set_var(0, filereadable_key, file_exists(path))
  end
end

local function tabpage_get_win_normal(tabnr)
  for _, winnr in ipairs(vim.api.nvim_tabpage_list_wins(tabnr)) do
    local config = vim.api.nvim_win_get_config(winnr)
    -- `relative` is empty for normal windows
    if config.relative == '' then
      return winnr
    end
  end
  -- Fallback
  return vim.api.nvim_tabpage_get_win(tabnr)
end

local function tabline()
  local line = {}

	local tab_list = vim.api.nvim_list_tabpages()
	local current = vim.api.nvim_get_current_tabpage()
  for _, tabnr in ipairs(tab_list) do
    local winnr = tabpage_get_win_normal(tabnr)
    local bufnr = vim.api.nvim_win_get_buf(winnr)
    local path = vim.api.nvim_buf_get_name(bufnr)

    local name = vim.fn.fnamemodify(path, ':t')
    name = name ~= '' and name or '[No Name]'

    local flags = {}
    if vim.bo[bufnr].mod then
      table.insert(flags, '+')
    end
    if not buf_get_var(bufnr, filereadable_key, true) then
      table.insert(flags, '?')
    end

    local tab = {
      '%', tabnr, 'T',
      (tabnr == current and '%#TabLineSel#' or '%#TabLine#'),
      ' ', name,
      (#flags > 0 and ' ' .. table.concat(flags, '') or ''),
      ' ',
    }
    table.insert(line, table.concat(tab, ''))
  end

  table.insert(line, '%#TabLineFill#')

  return table.concat(line, '')
end

local function render_statusline(winnr, active)
  local bufnr = vim.api.nvim_win_get_buf(winnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  local buftype = vim.bo[bufnr].buftype
  local is_file = (buftype == '')

  local l0 = {}
  local l1 = {}
  local r1 = {}
  local r0 = {}

  if active then
    table.insert(l0, '%#StatusLineMode#▌%#StatusLineL0#')
  else
    table.insert(l0, '%#StatusLine#')
  end

  if active then
    local filetype = vim.bo[bufnr].filetype
    table.insert(l0, filetype == '' and 'plain' or filetype)
  else
    if is_file and path ~= '' then
      local rel_path = vim.fn.fnamemodify(path, ':p:~:.')
      table.insert(l0, rel_path)
    elseif is_file then
      table.insert(l0, '[No Name]')
    else
      table.insert(l0, buftype)
    end
  end

  local flags = {}
  if vim.bo[bufnr].readonly then
    table.insert(flags, '!')
  end
  if vim.bo[bufnr].modified then
    table.insert(flags, '+')
  end
  if not buf_get_var(bufnr, filereadable_key, true) then
    table.insert(flags, '?')
  end
  if #flags > 0 then
    table.insert(l0, table.concat(flags, ''))
  end

  if active and is_file then
    local last_saved_time = buf_get_var(bufnr, 'auto_save_last_saved_time', 0)
    if 0 < last_saved_time and last_saved_time >= os.time() - 60 then
      table.insert(l1, os.date('✓ %X', last_saved_time))
    end
  end

  if active then
    local diagnostics = { E = 0, W = 0, I = 0, H = 0 }

    local status = buf_get_var(bufnr, 'coc_diagnostic_info', nil)
    if status then
      diagnostics.E = diagnostics.E + (status.error or 0)
      diagnostics.W = diagnostics.W + (status.warning or 0)
      diagnostics.I = diagnostics.I + (status.information or 0)
      diagnostics.H = diagnostics.H + (status.hint or 0)
    end

    if diagnostics.E > 0 then
      local text = string.format('%%#StatusLineDiagnosticsError#%s %d%%*', '✗', diagnostics.E)
      table.insert(l1, text)
    end
    if diagnostics.W > 0 then
      local text = string.format('%%#StatusLineDiagnosticsWarning#%s %d%%*', '∆', diagnostics.W)
      table.insert(l1, text)
    end
    if diagnostics.I > 0 then
      local text = string.format('%%#StatusLineDiagnosticsInfo#%s %d%%*', '▸', diagnostics.I)
      table.insert(l1, text)
    end
    if diagnostics.H > 0 then
      local text = string.format('%%#StatusLineDiagnosticsHint#%s %d%%*', '▪︎', diagnostics.H)
      table.insert(l1, text)
    end
  end

  local coc_status = vim.g.coc_status or ''
  if active and coc_status ~= '' then
    table.insert(r1, string.sub(coc_status, 0, 60))
  end

  if active then
    local encoding = vim.bo[bufnr].fileencoding
    local format = vim.bo[bufnr].fileformat
    table.insert(r0, encoding ~= '' and encoding or vim.o.encoding)
    table.insert(r0, format)
    table.insert(r0, '∙')
    table.insert(r0, '%l:%c')
    table.insert(r0, '∙')
    table.insert(r0, '%p%%')
  end

  return table.concat({
    table.concat(l0, ' '),
    '%*',
    table.concat(l1, ' '),
    '%=',
    table.concat(r1, ' '),
    '%*',
    table.concat(r0, ' '),
    '%*',
  }, ' ')
end

local function statusline()
  local winnr = vim.g.statusline_winid
  local active = winnr == vim.fn.win_getid()

  if active then
    require('candle').update_mode_highlight()
  end

  return render_statusline(winnr, active)
end

local function setup()
  vim.o.tabline = [[%!v:lua.require'user.ui'.tabline()]]

  vim.o.statusline = [[%!v:lua.require'user.ui'.statusline()]]
  vim.api.nvim_exec([[
    augroup user_ui_statusline
      autocmd!
      autocmd FocusGained,BufEnter,BufReadPost,BufWritePost * lua require'user.ui'.update_filereadable()
      autocmd WinLeave,BufLeave * lua vim.wo.statusline=require'user.ui'.statusline()
      autocmd BufWinEnter,WinEnter,BufEnter * set statusline<
      autocmd VimResized * redrawstatus
    augroup END
  ]], false)
end

return {
  setup = setup,
  statusline = statusline,
  tabline = tabline,
  update_filereadable = update_filereadable,
}

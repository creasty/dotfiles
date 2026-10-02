local file_readable_key = 'user_ui_file_readable'
local current_normal_winnr_key = 'user_ui_current_normal_winnr'

local separator = '∙'
local no_name_file = 'Untitled'

-- Unfinished work of each language server ($/progress), by client id and token
local lsp_work = {}

--- Text to show as is in a statusline or tabline.
local function escape(text)
  return (text:gsub('%%', '%%%%'))
end

local function file_exists(name)
  local f = io.open(name, 'r')
  return f ~= nil and io.close(f)
end

local function update_filereadable()
  local path = vim.api.nvim_buf_get_name(0)
  -- (files only: a terminal's name is term://...)
  if path ~= '' and vim.bo.buftype == '' then
    vim.api.nvim_buf_set_var(0, file_readable_key, file_exists(path))
  end
end

local function update_lsp_work(ev)
  local token, value = ev.data.params.token, ev.data.params.value
  -- (anything but "work done progress" has no title to show)
  if type(value) ~= 'table' or not value.kind then
    return
  end
  local work = lsp_work[ev.data.client_id] or {}
  lsp_work[ev.data.client_id] = work
  -- (Neovim carries the title of `begin` over to `report` and `end`)
  work[token] = value.kind ~= 'end' and value.title and value or nil
end

local function safe_buf_get_var(bufnr, name, default)
  local ok, value = pcall(vim.api.nvim_buf_get_var, bufnr, name)
  if ok then return value end
  return default
end

local function safe_tabpage_get_var(tabnr, name, default)
  local ok, value = pcall(vim.api.nvim_tabpage_get_var, tabnr, name)
  if ok then return value end
  return default
end

local function tabpage_get_win(tabnr)
  local winnr = vim.api.nvim_tabpage_get_win(tabnr)
  local config = vim.api.nvim_win_get_config(winnr)
  local is_normal = config.relative == ''
  if is_normal then
    vim.api.nvim_tabpage_set_var(tabnr, current_normal_winnr_key, winnr)
    return winnr
  end
  return safe_tabpage_get_var(tabnr, current_normal_winnr_key, winnr)
end

--- A terminal's name: `$` and the title its program sets, or the name of the command it runs (Neovim titles it with the
--- buffer's name, term://{cwd}//{pid}:{cmd}, until the program does).
local function terminal_name(bufnr)
  local title = vim.b[bufnr].term_title or ''
  local path = vim.api.nvim_buf_get_name(bufnr)
  if title == '' or title == path then
    title = vim.fn.fnamemodify(path:match('^term://.-//%d+:(%S*)') or '', ':t')
  end
  return '$' .. title
end

local function get_buffer_flags(bufnr)
  local flags = {}
  if vim.bo[bufnr].readonly then
    table.insert(flags, '!')
  end
  if vim.bo[bufnr].modified then
    table.insert(flags, '+')
  end
  if not safe_buf_get_var(bufnr, file_readable_key, true) then
    table.insert(flags, '?')
  end
  return flags
end

local function retry_call(fn, args, times)
  times = times or 3
  for _ = 0, times - 1 do
    local result = {pcall(fn, unpack(args))}
    if result[1] == true then
      return unpack(result, 2)
    end
  end
  return fn(unpack(args))
end

-- @note Workaround for "Error executing lua Keyboard interrupt"
local function retry_call_wrap(fn, times)
  return function(...)
    return retry_call(fn, {...}, times)
  end
end

local tabline = retry_call_wrap(function ()
  local line = {}

  local tab_list = vim.api.nvim_list_tabpages()
  local current = vim.api.nvim_get_current_tabpage()
  for i, tabnr in ipairs(tab_list) do
    local winnr = tabpage_get_win(tabnr)
    local bufnr = vim.api.nvim_win_get_buf(winnr)
    local path = vim.api.nvim_buf_get_name(bufnr)

    local name = vim.bo[bufnr].buftype == 'terminal' and terminal_name(bufnr) or vim.fn.fnamemodify(path, ':t')
    name = name ~= '' and name or no_name_file

    local flags = get_buffer_flags(bufnr)

    -- (a terminal of the tab printed while another tab was the current one: user/terminal.lua)
    local active = false
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabnr)) do
      active = active or vim.b[vim.api.nvim_win_get_buf(win)].user_terminal_activity == true
    end

    local tab = {
      (i > 1 and separator or ''),
      '%', tabnr, 'T',
      (tabnr == current and '%#TabLineSel#' or (active and '%#TabLineActivity#' or '%#TabLine#')),
      ' ',
      (#flags > 0 and '' .. table.concat(flags, '') or ''),
      escape(name),
      ' %#TabLine#',
    }
    table.insert(line, table.concat(tab, ''))
  end

  table.insert(line, '%#TabLineFill#')

  return table.concat(line, '')
end)

local statusline = retry_call_wrap(function ()
  local winnr = vim.g.statusline_winid
  if not winnr then
    return
  end

  local active = winnr == vim.fn.win_getid()
  local bufnr = vim.api.nvim_win_get_buf(winnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  local buftype = vim.bo[bufnr].buftype
  local is_file = (buftype == '')

  local l0 = {'%#StatusLinePrimary#'}
  local l1 = {}
  local r1 = {}
  local r0 = {}

  if active then
    local filetype = vim.bo[bufnr].filetype
    table.insert(l0, filetype == '' and 'plain' or filetype)
  else
    if is_file and path ~= '' then
      local rel_path = vim.fn.fnamemodify(path, ':p:~:.')
      table.insert(l0, rel_path)
    elseif is_file then
      table.insert(l0, no_name_file)
    else
      table.insert(l0, buftype)
    end
  end

  local flags = get_buffer_flags(bufnr)
  if #flags > 0 then
    table.insert(l0, table.concat(flags, ''))
  end

  if active then
    local git = vim.b[bufnr].gitsigns_status_dict
    if git and git.head and git.head ~= '' then
      local text = {escape(git.head)}
      if (git.added or 0) > 0 then
        table.insert(text, '%#StatusLineGitAdd#+%*')
      end
      if (git.changed or 0) > 0 then
        table.insert(text, '%#StatusLineGitChange#~%*')
      end
      if (git.removed or 0) > 0 then
        table.insert(text, '%#StatusLineGitDelete#-%*')
      end
      table.insert(l1, table.concat(text, ''))
    end
  end

  if active then
    local count = vim.diagnostic.count(bufnr)
    local severity = vim.diagnostic.severity
    local diagnostics = {
      E = count[severity.ERROR] or 0,
      W = count[severity.WARN] or 0,
      I = count[severity.INFO] or 0,
      H = count[severity.HINT] or 0,
    }

    if diagnostics.E > 0 then
      local text = string.format('%%#StatusLineDiagnosticsError#%s %d%%*', '✕', diagnostics.E)
      table.insert(l1, text)
    end
    if diagnostics.W > 0 then
      local text = string.format('%%#StatusLineDiagnosticsWarning#%s %d%%*', '∆', diagnostics.W)
      table.insert(l1, text)
    end
    if diagnostics.I > 0 then
      local text = string.format('%%#StatusLineDiagnosticsInfo#%s %d%%*', '□', diagnostics.I)
      table.insert(l1, text)
    end
    if diagnostics.H > 0 then
      local text = string.format('%%#StatusLineDiagnosticsHint#%s %d%%*', '*', diagnostics.H)
      table.insert(l1, text)
    end
  end

  if active and is_file then
    local last_saved_time = safe_buf_get_var(bufnr, 'auto_save_last_saved_time', 0)
    if 0 < last_saved_time and last_saved_time >= os.time() - 60 then
      table.insert(l1, os.date('✓ %X', last_saved_time))
    end
  end

  if active then
    local luasnip = package.loaded.luasnip
    if luasnip and luasnip.get_active_snip() then
      table.insert(r1, 'SNIP')
    end
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
      local _, work = next(lsp_work[client.id] or {})
      if work then
        local percentage = work.percentage and string.format(' %d%%%%', work.percentage) or ''
        table.insert(r1, string.format('%s: %s%s', client.name, escape(work.title), percentage))
      else
        table.insert(r1, client.name)
      end
    end
  end

  if active then
    local encoding = vim.bo[bufnr].fileencoding
    local format = vim.bo[bufnr].fileformat
    table.insert(r0, encoding ~= '' and encoding or vim.o.encoding)
    table.insert(r0, format)
    table.insert(r0, separator)
    table.insert(r0, '%l:%c')
    table.insert(r0, separator)
    table.insert(r0, '%p%%')
  end

  return table.concat({
    table.concat(l0, ' '),
    -- (too long, it's cut here: the branch, not the filetype)
    '%*%<',
    table.concat(l1, ' '),
    '%=',
    table.concat(r1, ' '),
    '%*',
    table.concat(r0, ' '),
    '%*',
  }, ' ')
end)

local function setup()
  vim.o.tabline = [[%!v:lua.require'user.ui'.tabline()]]

  vim.o.statusline = [[%!v:lua.require'user.ui'.statusline()]]
  vim.api.nvim_exec([[
    augroup user_ui_statusline
      autocmd!
      autocmd FocusGained,BufEnter,BufReadPost,BufWritePost * lua require'user.ui'.update_filereadable()
      " (this statusline in place of a window's own: quickfix's, NERDTree's)
      autocmd BufWinEnter,WinEnter,BufEnter * set statusline<
      autocmd VimResized,DiagnosticChanged * redrawstatus
      autocmd User GitSignsUpdate redrawstatus
    augroup END
  ]], false)
  vim.api.nvim_create_autocmd('LspProgress', {
    group = 'user_ui_statusline',
    callback = function(ev)
      update_lsp_work(ev)
      vim.cmd.redrawstatus()
    end,
  })
  -- (once the client is attached, or detached: LspDetach comes before)
  vim.api.nvim_create_autocmd({ 'LspAttach', 'LspDetach' }, {
    group = 'user_ui_statusline',
    callback = function()
      vim.schedule(vim.cmd.redrawstatus)
    end,
  })
end

return {
  setup = setup,
  statusline = statusline,
  tabline = tabline,
  update_filereadable = update_filereadable,
}

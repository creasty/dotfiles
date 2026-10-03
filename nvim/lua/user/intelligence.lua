-- How completion (blink.cmp), snippets (LuaSnip), auto-pairs and AI
-- suggestions (Copilot, through Neovim's inline completion) share the
-- insert-mode keys, and where they stay out of the way.
--
--   <Tab>        accept the completion item / expand a snippet / indent
--   <CR>         accept the completion item / newline (with auto-pairs)
--   <Esc>        close the menu, signature help or suggestion first
--   <C-l>        refresh the menu / auto-pairs' <C-l> rules
--   <C-s><C-j>   accept the AI suggestion
--   <C-s><C-n>   next / previous snippet placeholder (also in Select mode)
--   <C-s><C-p>
--   <C-s><C-c>   dismiss the AI suggestion / end the snippet session

local M = {}

local k = vim.keycode

local function blink()
  return package.loaded['blink.cmp']
end

local function menu_visible()
  local cmp = blink()
  return cmp ~= nil and cmp.is_menu_visible()
end

local function luasnip()
  return package.loaded.luasnip
end

local function expandable()
  local ls = luasnip()
  return ls ~= nil and ls.expandable()
end

--- Dismisses the AI suggestion; false when there is none.
local function dismiss_ai(buf)
  return vim.lsp.inline_completion.get({ bufnr = buf, on_accept = function() end })
end

--- The AI suggestion, unless it was made for another line (the one before a
--- <CR> or a move).
local function on_cursor_line(item)
  if item.range and item.range:to_extmark() ~= vim.api.nvim_win_get_cursor(0)[1] - 1 then
    return nil
  end
  return item
end

local function autopairs()
  return require('user.plugin.autopairs')
end

local function cmd(lua)
  return k('<Cmd>lua ' .. lua .. '<CR>')
end

---------------------------------------------------------------------------
-- AI suggestions stay hidden while something else is offered
---------------------------------------------------------------------------

-- (Neovim shows each suggestion as it arrives: one that arrives while hidden
-- is dismissed, in the LspRequest autocmd below, and the next keystroke brings
-- a new one)
local function set_ai_hidden(hidden)
  vim.b.user_ai_hidden = hidden
  if hidden then
    dismiss_ai(0)
  end
end

local function update_ai()
  set_ai_hidden(vim.b.user_intelligence_stopped or menu_visible() or expandable())
end

---------------------------------------------------------------------------
-- Stopped while inserting in several lines at once
---------------------------------------------------------------------------

function M.stop()
  vim.b.user_intelligence_stopped = true
  vim.b.completion = false -- blink.cmp
  set_ai_hidden(true)
  autopairs().set_stopped(true)
end

function M.resume()
  vim.b.user_intelligence_stopped = nil
  vim.b.completion = nil
  set_ai_hidden(false)
  autopairs().set_stopped(false)
end

---------------------------------------------------------------------------
-- Keys
---------------------------------------------------------------------------

local keys = {}

function keys.tab()
  if menu_visible() then
    blink().select_and_accept()
    return ''
  elseif vim.fn.pumvisible() == 1 then
    return k('<C-y>')
  elseif expandable() then
    return cmd("require('luasnip').expand()")
  end
  return k('<Tab>')
end

function keys.cr()
  if menu_visible() then
    blink().accept()
    return ''
  elseif vim.fn.pumvisible() == 1 then
    return k('<C-y>')
  end
  -- (the suggestion was for this line)
  dismiss_ai(0)
  return autopairs().cr()
end

function keys.esc()
  local cmp = blink()
  if menu_visible() then
    cmp.cancel()
    return ''
  elseif vim.fn.pumvisible() == 1 then
    return k('<C-e>')
  elseif cmp and cmp.is_signature_visible() then
    cmp.hide_signature()
    return ''
  elseif dismiss_ai(0) then
    return ''
  end
  return k('<Esc>')
end

function keys.c_l()
  local rule = autopairs().c_l()
  if rule ~= '' then
    if menu_visible() then
      blink().hide()
    end
    return rule
  elseif menu_visible() then
    local providers = require('blink.cmp.config').sources.default
    blink().show({ providers = type(providers) == 'function' and providers() or providers })
  end
  return ''
end

function keys.accept_ai()
  vim.lsp.inline_completion.get({ on_accept = on_cursor_line })
  return ''
end

local function jump(direction)
  return function()
    local ls = luasnip()
    if ls and ls.jumpable(direction) then
      return cmd(('require("luasnip").jump(%d)'):format(direction))
    end
    return ''
  end
end

function keys.cancel()
  local ls = luasnip()
  if dismiss_ai(0) then
    return ''
  elseif ls and ls.get_active_snip() then
    return cmd("require('luasnip').unlink_current()")
  end
  return ''
end

local function move(key, command)
  return function()
    if menu_visible() then
      blink()[command]()
      return ''
    end
    return k(key)
  end
end

local function leave_menu(key)
  return function()
    if menu_visible() then
      blink().hide()
    end
    return k(key)
  end
end

function M.setup()
  local function map(modes, lhs, fn)
    vim.keymap.set(modes, lhs, fn, { expr = true, replace_keycodes = false, silent = true })
  end

  map('i', '<Tab>', keys.tab)
  map('i', '<CR>', keys.cr)
  map('i', '<Esc>', keys.esc)
  map('i', '<C-l>', keys.c_l)
  map('i', '<C-s><C-j>', keys.accept_ai)
  map({ 'i', 's' }, '<C-s><C-n>', jump(1))
  map({ 'i', 's' }, '<C-s><C-p>', jump(-1))
  map({ 'i', 's' }, '<C-s><C-c>', keys.cancel)
  map('i', '<Down>', move('<Down>', 'select_next'))
  map('i', '<Up>', move('<Up>', 'select_prev'))
  map('i', '<Left>', leave_menu('<Left>'))
  map('i', '<Right>', leave_menu('<Right>'))
  map('i', '<BS>', function()
    return autopairs().bs()
  end)
  map('i', '<Space>', function()
    return autopairs().space()
  end)
  for _, char in ipairs({ '<', '>', '|', '/' }) do
    local lhs = ({ ['<'] = '<lt>', ['|'] = '<Bar>' })[char] or char
    map('i', lhs, function()
      return autopairs().char(char)
    end)
  end
  -- <Tab> on a selection keeps it for the next snippet (see user.plugin.luasnip)
  vim.keymap.set('s', '<Tab>', '<C-g><Tab>', { remap = true })

  -- plugin/emacs_cursor.vim: <C-n> / <C-p> move in the menu
  vim.g.EmacsCursorPumvisible = menu_visible

  local group = vim.api.nvim_create_augroup('user_intelligence', {})
  -- plugin/blockwise_visual_insert.vim
  vim.api.nvim_create_autocmd('User', { group = group, pattern = 'BlockwiseVisualInsertPre', callback = M.stop })
  vim.api.nvim_create_autocmd('User', { group = group, pattern = 'BlockwiseVisualInsertPost', callback = M.resume })

  vim.api.nvim_create_autocmd({ 'TextChangedI', 'CursorMovedI' }, { group = group, callback = update_ai })
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'BlinkCmpShow',
    callback = function()
      set_ai_hidden(true)
    end,
  })
  -- (the menu may close after the last key's check)
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'BlinkCmpHide',
    callback = vim.schedule_wrap(update_ai),
  })
  vim.api.nvim_create_autocmd('InsertEnter', {
    group = group,
    callback = function()
      set_ai_hidden(vim.b.user_intelligence_stopped == true)
    end,
  })
  -- a suggestion that arrives while hidden (once Neovim has shown it)
  vim.api.nvim_create_autocmd('LspRequest', {
    group = group,
    callback = function(ev)
      local request = ev.data.request
      if request.method == 'textDocument/inlineCompletion' and request.type == 'complete' then
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(ev.buf) and vim.b[ev.buf].user_ai_hidden then
            dismiss_ai(ev.buf)
          end
        end)
      end
    end,
  })
  -- signature help popups
  local ok, trigger = pcall(require, 'blink.cmp.signature.trigger')
  if ok and trigger.show_emitter then
    trigger.show_emitter:on(function()
      set_ai_hidden(true)
    end)
  end
end

return M

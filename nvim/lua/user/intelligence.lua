-- How completion (blink.cmp), snippets (LuaSnip), auto-pairs and AI
-- suggestions (copilot.lua) share the insert-mode keys, and where they stay
-- out of the way.
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

local function suggestion()
  return package.loaded['copilot.suggestion']
end

local function ai_visible()
  local s = suggestion()
  return s ~= nil and s.is_visible()
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

local function set_ai_hidden(hidden)
  local was_hidden = vim.b.copilot_suggestion_hidden
  vim.b.copilot_suggestion_hidden = hidden
  local s = suggestion()
  if not s then
    return
  end
  if hidden and s.is_visible() then
    s.dismiss()
  elseif not hidden and was_hidden then
    -- a suggestion that arrived while hidden shows up now
    pcall(s.update_preview)
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
  elseif ai_visible() then
    suggestion().dismiss()
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
  if ai_visible() then
    return cmd("require('copilot.suggestion').accept()")
  end
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
  if ai_visible() then
    suggestion().dismiss()
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
  -- signature help popups
  local ok, trigger = pcall(require, 'blink.cmp.signature.trigger')
  if ok and trigger.show_emitter then
    trigger.show_emitter:on(function()
      set_ai_hidden(true)
    end)
  end
end

return M

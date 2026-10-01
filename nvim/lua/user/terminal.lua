-- Neovim as the terminal: kitty runs Neovim alone (config/kitty/kitty.conf), and Neovim runs the shells and commands
-- in its terminals, shown in windows and tabs like files, and still running while hidden.
--
--   <C-/>       the shell of the current directory, in a bottom split, shown or hidden (snacks.nvim); with a count,
--               another one (2<C-/>)
--   :terminal   a shell, or a command, in the current window (<C-s> v, s or t first for a new one)
--   <Space>t    a terminal, hidden ones included, in the current window
--
-- In a terminal, the keys go to the program (Esc too), but:
--
--   <C-s>       the window keys of Normal mode (<C-s> v, <C-s><C-n>...); <C-s><C-s> sends C-s to the program
--   <C-y>       copy mode: Normal mode, scrolled a line up, to search and yank; i types again
--
-- Entering a terminal's window types into it, unless it was left in copy mode.
--
-- A terminal's tab shows the command it runs, or its shell's directory at the prompt (the title term.zsh sets), and
-- stands out once the terminal prints while another tab is the current one, as tmux's windows did, until the tab is
-- current again. The window title shows the shell's directory (OSC 7, from term.zsh).

local M = {}

-- Set while a terminal is in copy mode, until it types again
local copy_mode_key = 'user_terminal_copy_mode'
-- Set once a terminal prints while not in the current tab, until it is (nvim/lua/user/ui.lua's tabline shows it)
local activity_key = 'user_terminal_activity'
-- The shell's directory, from OSC 7 (UserTitleString in nvim/init.vim shows it)
local cwd_key = 'user_terminal_cwd'

local function is_running(buf)
  local channel = vim.bo[buf].channel
  return channel > 0 and vim.fn.jobwait({ channel }, 0)[1] == -1
end

local function in_current_tab(buf)
  local tab = vim.api.nvim_get_current_tabpage()
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if vim.api.nvim_win_get_tabpage(win) == tab then
      return true
    end
  end
  return false
end

local function watch_activity(buf)
  vim.api.nvim_buf_attach(buf, false, {
    on_lines = function(_, b)
      if vim.b[b][activity_key] or in_current_tab(b) then
        return
      end
      vim.b[b][activity_key] = true
      vim.schedule(vim.cmd.redrawtabline)
    end,
  })
end

local function pick()
  Snacks.picker.buffers({
    hidden = true, -- (snacks.nvim's terminals are unlisted)
    filter = {
      filter = function(item)
        return item.buftype == 'terminal'
      end,
    },
  })
end

function M.setup()
  -- history, as long as the terminal had
  vim.o.scrollback = 15000

  -- kitty runs Neovim with no shell to resume it: suspending would freeze the window (C-z reaches the programs in
  -- terminals)
  vim.keymap.set({ 'n', 'x' }, '<C-z>', '<Nop>')

  vim.keymap.set('t', '<C-s>', [[<C-\><C-n><C-s>]], { remap = true, desc = 'Window keys' })
  vim.keymap.set('t', '<C-s><C-s>', '<C-s>', { desc = 'C-s to the program' })
  vim.keymap.set('t', '<C-y>', function()
    vim.b[copy_mode_key] = true
    return [[<C-\><C-n><C-y>]]
  end, { expr = true, desc = 'Copy mode' })

  vim.keymap.set({ 'n', 't' }, '<C-/>', function()
    -- Esc goes to the program, as in the other terminals (not twice to Normal mode)
    Snacks.terminal.toggle(nil, { win = { keys = { term_normal = false } } })
  end, { desc = 'Terminal (bottom)' })
  vim.keymap.set('n', '<Space>t', pick, { desc = 'Terminals' })

  local group = vim.api.nvim_create_augroup('user_terminal', {})
  vim.api.nvim_create_autocmd('TermOpen', {
    group = group,
    callback = function(ev)
      -- (Neovim takes the numbers and signs off)
      vim.wo[0][0].colorcolumn = ''
      watch_activity(ev.buf)
      if ev.buf == vim.api.nvim_get_current_buf() then
        vim.cmd.startinsert()
      end
    end,
  })
  vim.api.nvim_create_autocmd({ 'TabEnter', 'BufWinEnter', 'WinEnter' }, {
    group = group,
    callback = function()
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        vim.b[vim.api.nvim_win_get_buf(win)][activity_key] = nil
      end
    end,
  })
  vim.api.nvim_create_autocmd('TermRequest', {
    group = group,
    callback = function(ev)
      local dir = ev.data.sequence:match('^\027%]7;file://[^/]*(/.*)$')
      if dir and vim.fn.isdirectory(dir) == 1 then
        vim.b[ev.buf][cwd_key] = dir
      end
    end,
  })
  vim.api.nvim_create_autocmd('TermEnter', {
    group = group,
    callback = function()
      vim.b[copy_mode_key] = nil
    end,
  })
  vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
    group = group,
    -- (once the command is done: :vnew enters a split of the current window before its new buffer)
    callback = vim.schedule_wrap(function()
      local buf = vim.api.nvim_get_current_buf()
      if vim.bo[buf].buftype == 'terminal' and not vim.b[buf][copy_mode_key] and is_running(buf)
        and vim.api.nvim_get_mode().mode == 'nt' then
        vim.cmd.startinsert()
      end
    end),
  })
end

return M

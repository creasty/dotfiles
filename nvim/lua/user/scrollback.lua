-- kitty's copy mode (config/kitty/kitty.conf): kitty pipes a window's screen and its history, in their colors, into
-- this Neovim, which shows them as a terminal over the window, to scroll, search and yank with vi's keys.
--
-- The terminal has no line numbers, signs or color column, so its lines are as wide as the window's, and no file to
-- work on: language servers, linters, Git signs, AI suggestions and auto-pairs leave it alone. The tabline, statusline
-- and command line go as well, and the scroll offset, so its lines stay where the window had them. The first three are
-- global options, and this Neovim views nothing else.

local M = {}

--- Shows the current buffer, kitty's text read from stdin, as a terminal, with the window's screen where it was.
--- `top` is the line of the text at the top of kitty's screen; the cursor goes to kitty's (`cursor_line` and
--- `cursor_column`, from 1), or to the top when kitty's is off the screen (0).
function M.open(top, cursor_line, cursor_column)
  vim.wo.number = false
  vim.wo.signcolumn = 'no'
  vim.wo.colorcolumn = ''
  vim.wo.scrolloff = 0
  vim.o.laststatus = 1
  vim.o.showtabline = 1
  vim.o.cmdheight = 0

  vim.api.nvim_open_term(0, {})
  vim.bo.modified = false

  -- The terminal takes the text in on a later refresh, following its end until then
  local line = top + math.max(cursor_line, 1) - 1
  vim.wait(1000, function() return vim.api.nvim_buf_line_count(0) >= line end)
  vim.fn.winrestview({ topline = top, lnum = line, col = math.max(cursor_column - 1, 0) })
end

return M

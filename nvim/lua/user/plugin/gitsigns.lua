-- Git changes in the sign column, hunk / conflict navigation, and :GBlame.

local M = {}

--- Moves to the next (1) or previous (-1) merge conflict marker.
local function conflict(direction)
  return function()
    vim.fn.search([[^<<<<<<< \|^<<<<<<<$]], direction > 0 and 'W' or 'bW')
  end
end

local function hunk(direction)
  return function()
    require('gitsigns').nav_hunk(direction, { wrap = false })
  end
end

function M.setup()
  require('gitsigns').setup({
    signs = {
      add = { text = '┃' },
      change = { text = '┃' },
      changedelete = { text = '┣' },
      delete = { text = '▁' },
      topdelete = { text = '▔' },
      untracked = { text = '┆' },
    },
    signs_staged_enable = false,
    attach_to_untracked = false,
    sign_priority = 100,
    update_debounce = 100,
  })

  vim.keymap.set('n', '[g', hunk('prev'), { desc = 'Previous git hunk' })
  vim.keymap.set('n', ']g', hunk('next'), { desc = 'Next git hunk' })
  vim.keymap.set('n', '[C', conflict(-1), { desc = 'Previous merge conflict' })
  vim.keymap.set('n', ']C', conflict(1), { desc = 'Next merge conflict' })

  vim.api.nvim_create_user_command('GBlame', 'Gitsigns blame', { desc = 'Blame the file' })
  local group = vim.api.nvim_create_augroup('user_gitsigns', {})
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = 'gitsigns-blame',
    callback = function(ev)
      -- o shows the line's commit, as s does, and q closes the blame
      vim.keymap.set('n', 'o', 's', { buffer = ev.buf, remap = true, desc = 'Show commit in a vertical split' })
      vim.keymap.set('n', 'q', '<Cmd>close<CR>', { buffer = ev.buf, nowait = true, desc = 'Close the blame' })

      -- The lines of the commit under the cursor (CursorLine) as faint as a
      -- changed line in a diff, in the blame and in the file's window (the
      -- one it split from) while the blame is open
      local blame_win = vim.api.nvim_get_current_win()
      local file_win = vim.fn.win_getid(vim.fn.winnr('#'))
      vim.wo[blame_win].winhighlight = 'CursorLine:DiffChange'
      if file_win == 0 or file_win == blame_win then
        return
      end
      local file_winhighlight = vim.wo[file_win].winhighlight
      vim.wo[file_win].winhighlight = (file_winhighlight == '' and '' or file_winhighlight .. ',')
        .. 'CursorLine:DiffChange'
      vim.api.nvim_create_autocmd('WinClosed', {
        pattern = tostring(blame_win),
        once = true,
        callback = function()
          if vim.api.nvim_win_is_valid(file_win) then
            vim.wo[file_win].winhighlight = file_winhighlight
          end
        end,
      })
    end,
  })
  -- q closes a commit gitsigns shows (the blame's o, s and S)
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = 'git',
    callback = function(ev)
      if vim.api.nvim_buf_get_name(ev.buf):find('^gitsigns://') then
        vim.keymap.set('n', 'q', '<Cmd>close<CR>', { buffer = ev.buf, nowait = true, desc = 'Close the commit' })
      end
    end,
  })
end

return M

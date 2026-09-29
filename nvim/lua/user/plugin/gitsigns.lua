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
end

return M

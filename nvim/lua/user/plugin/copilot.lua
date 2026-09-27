-- GitHub Copilot's inline suggestions (copilot.lua). Accepted with <C-s><C-j>
-- and dismissed with <Esc> / <C-s><C-c> (user.intelligence); hidden while the
-- completion menu, a signature help or an expandable snippet is shown.

local M = {}

function M.setup()
  require('copilot').setup({
    panel = { enabled = false },
    suggestion = {
      enabled = true,
      auto_trigger = true,
      debounce = 200,
      keymap = {
        accept = false,
        accept_word = false,
        accept_line = false,
        next = false,
        prev = false,
        dismiss = false,
      },
    },
    filetypes = {
      markdown = true,
      yaml = true,
    },
    -- copilot-language-server from nixpkgs; copilot.lua downloads one without it
    server = {
      type = 'binary',
      custom_server_filepath = vim.fn.executable('copilot-language-server') == 1 and 'copilot-language-server' or nil,
    },
  })
end

return M

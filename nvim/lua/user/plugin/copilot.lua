-- GitHub Copilot's inline suggestions: Neovim's inline completion, from
-- copilot-language-server (config/mise/config.toml) with
-- nvim-lspconfig's `copilot` config, which adds :LspCopilotSignIn and
-- :LspCopilotSignOut. Accepted with <C-s><C-j> and dismissed with <Esc> /
-- <C-s><C-c> (user.intelligence); hidden while the completion menu, a
-- signature help or an expandable snippet is shown.

local M = {}

-- No suggestions in help and commit messages
local EXCLUDED = { help = true, gitcommit = true, gitrebase = true, hgcommit = true, svn = true, cvs = true }

function M.setup()
  vim.lsp.config('copilot', {
    root_dir = function(bufnr, on_dir)
      if not EXCLUDED[vim.bo[bufnr].filetype:match('^[^.]*')] then
        on_dir(vim.fs.root(bufnr, '.git'))
      end
    end,
    -- one server for all the projects
    reuse_client = function(client, config)
      return client.name == config.name
    end,
  })
  vim.lsp.inline_completion.enable()
  -- started on the first insert, rather than with the first file
  vim.api.nvim_create_autocmd('InsertEnter', {
    group = vim.api.nvim_create_augroup('user_plugin_copilot', {}),
    once = true,
    callback = function()
      vim.lsp.enable('copilot')
    end,
  })
end

return M

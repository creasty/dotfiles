-- Snippets with LuaSnip. The library is nvim/snippets/<filetype>.lua (see
-- user.snippets for the helpers it is written with); <Tab> expands and
-- <C-s><C-n> / <C-s><C-p> jump (user.intelligence).

local M = {}

-- Filetypes that also load other snippet files, like UltiSnips' `extends`
-- and <ft>_*.snippets.
M.extends = {
  bash = { 'sh' },
  c = { 'clike_stmt', 'clike_postfix' },
  go = { 'go_postfix' },
  javascript = { 'clike_stmt', 'clike_postfix' },
  javascriptreact = { 'javascript', 'clike_stmt', 'clike_postfix' },
  ruby = { 'ruby_postfix' },
  typescript = { 'typescript_henry', 'javascript', 'clike_stmt', 'clike_postfix' },
  typescriptreact = {
    'typescript',
    'typescript_henry',
    'javascriptreact',
    'javascript',
    'clike_stmt',
    'clike_postfix',
  },
  zsh = { 'sh' },
}

function M.setup()
  local ls = require('luasnip')
  local types = require('luasnip.util.types')

  ls.setup({
    update_events = { 'TextChanged', 'TextChangedI' },
    delete_check_events = { 'TextChanged', 'InsertLeave' },
    region_check_events = { 'CursorMoved', 'CursorMovedI' },
    enable_autosnippets = true,
    -- <Tab> on a selection keeps it for the next snippet's $TM_SELECTED_TEXT
    cut_selection_keys = '<Tab>',
    ext_opts = {
      [types.insertNode] = { active = { hl_group = 'SnipPlaceholder' } },
    },
  })

  for ft, extends in pairs(M.extends) do
    ls.filetype_extend(ft, extends)
  end

  require('luasnip.loaders.from_lua').lazy_load({ paths = { vim.fn.stdpath('config') .. '/snippets' } })

  -- The signature help follows the placeholders of a snippet.
  vim.api.nvim_create_autocmd('User', {
    group = vim.api.nvim_create_augroup('user_plugin_luasnip', {}),
    pattern = 'LuasnipInsertNodeEnter',
    callback = function()
      vim.schedule(function()
        if vim.fn.mode():match('^[is]') and #vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/signatureHelp' }) > 0 then
          require('blink.cmp').show_signature()
        end
      end)
    end,
  })
end

return M

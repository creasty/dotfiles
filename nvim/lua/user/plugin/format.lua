-- Formatting with conform.nvim: prettier and friends where they apply, the
-- language server otherwise.

local M = {}

local prettier = { 'prettier' }

M.formatters_by_ft = {
  css = prettier,
  glsl = { 'clang-format' },
  graphql = prettier,
  html = prettier,
  javascript = prettier,
  javascriptreact = prettier,
  json = prettier,
  jsonc = prettier,
  less = prettier,
  markdown = prettier,
  nix = { 'nixfmt' },
  proto = { 'clang-format' },
  scss = prettier,
  sql = { 'sqlfluff' },
  terraform = { 'terraform_fmt' },
  typescript = prettier,
  typescriptreact = prettier,
  yaml = prettier,
}

--- Formats with the filetype's formatter, or the language server without one.
function M.format(opts)
  require('conform').format(vim.tbl_extend('keep', opts or {}, { lsp_format = 'fallback' }))
end

function M.setup()
  require('conform').setup({
    formatters_by_ft = M.formatters_by_ft,
    default_format_opts = { lsp_format = 'fallback' },
    notify_no_formatters = false,
  })
end

return M

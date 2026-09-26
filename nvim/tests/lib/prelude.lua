-- Sourced by every child with `--cmd`, i.e. *before* init.vim.
--
-- It only redirects side effects and external services to test doubles; it
-- never changes editing behavior. Plugin-specific wiring lives here, so when a
-- plugin is replaced, point its replacement at the same fakes:
--   * Copilot  -> fakes/copilot.lua (a copilot-language-server stand-in)
--   * LSP      -> fakes/lsp.lua (registered for LSP_FILETYPES)

local ctx = vim.json.decode(table.concat(vim.fn.readfile(vim.env.E2E_CONTEXT), '\n'))

-- Filetypes the fake language server attaches to.
local LSP_FILETYPES = { 'go', 'typescript', 'typescriptreact', 'javascript', 'lua', 'ruby', 'python', 'e2e' }

-- clipboard=unnamed would otherwise write every yank to the system clipboard.
local registers = { ['+'] = { { '' }, 'v' }, ['*'] = { { '' }, 'v' } }
local function copy(reg)
  return function(lines, regtype)
    registers[reg] = { lines, regtype }
  end
end
local function paste(reg)
  return function()
    return registers[reg]
  end
end
vim.g.clipboard = {
  name = 'e2e',
  copy = { ['+'] = copy('+'), ['*'] = copy('*') },
  paste = { ['+'] = paste('+'), ['*'] = paste('*') },
  cache_enabled = 0,
}

-- Same Python host Neovim would detect, resolved once per run (speed only).
if ctx.python3_host_prog and ctx.python3_host_prog ~= '' then
  vim.g.python3_host_prog = ctx.python3_host_prog
end

-- copilot.vim: runs `g:copilot_command + ['--stdio']`.
vim.g.copilot_command = { ctx.nvim, '--clean', '-l', ctx.fakes.copilot }

-- coc.nvim: register the fake server and disable the real ones configured in
-- coc-settings.json; keep extensions to the linked set so coc never tries to
-- install the ones listed in g:coc_global_extensions.
local languageservers = {
  e2e = {
    command = ctx.nvim,
    args = { '--clean', '-l', ctx.fakes.lsp },
    filetypes = LSP_FILETYPES,
    rootPatterns = { '.git', '.e2e-root' },
    requireRootPattern = false,
  },
}
local settings_path = ctx.config_dir .. '/coc-settings.json'
if vim.fn.filereadable(settings_path) == 1 then
  -- JSONC: drop full-line comments (the file has no trailing ones).
  local lines = vim.tbl_filter(function(line)
    return not line:match('^%s*//')
  end, vim.fn.readfile(settings_path))
  local ok, settings = pcall(vim.json.decode, table.concat(lines, '\n'))
  if ok and type(settings.languageserver) == 'table' then
    for name in pairs(settings.languageserver) do
      languageservers[name] = languageservers[name] or { enable = false }
    end
  end
end
vim.g.coc_user_config = { languageserver = languageservers }
vim.g.coc_data_home = ctx.coc_data_home
vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    vim.g.coc_global_extensions = ctx.coc_extensions
  end,
})

-- Probes the specs use to observe plugin UI (see probe_child.lua).
_G.__e2e = dofile(ctx.tests_dir .. '/lib/probe_child.lua')

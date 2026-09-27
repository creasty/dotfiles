-- Sourced by every child with `--cmd`, i.e. *before* init.vim.
--
-- It only redirects side effects and external services to test doubles, and
-- stands in for the terminal UI (UIEnter); it never changes editing behavior.
-- Plugin-specific wiring lives here, so when a plugin is replaced, point its
-- replacement at the same fakes:
--   * LSP      -> fakes/lsp.lua (registered for LSP_FILETYPES); the config's
--                 own servers are never enabled
--   * Copilot  -> fakes/copilot.lua, as `copilot-language-server` on PATH
--                 (env.lua writes it)
--   * formatters and linters (conform.nvim, nvim-lint) -> none, so the
--     language server formats, like the fake one does

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

-- Native LSP: the fake server instead of the configured ones.
vim.lsp.config('e2e', {
  cmd = { ctx.nvim, '--clean', '-l', ctx.fakes.lsp },
  filetypes = LSP_FILETYPES,
  root_markers = { '.git', '.e2e-root' },
})
local enable = vim.lsp.enable
enable('e2e')
vim.lsp.enable = function() end

--- Patches a Lua module when it is first required.
local function patch(name, fn)
  package.preload[name] = function()
    package.preload[name] = nil
    local path = vim.api.nvim_get_runtime_file('lua/' .. name:gsub('%.', '/') .. '.lua', false)[1]
      or vim.api.nvim_get_runtime_file('lua/' .. name:gsub('%.', '/') .. '/init.lua', false)[1]
    local mod = dofile(path)
    fn(mod)
    return mod
  end
end

-- conform.nvim / nvim-lint: no external formatters or linters.
patch('conform', function(conform)
  local setup = conform.setup
  conform.setup = function(opts)
    setup(vim.tbl_extend('force', opts or {}, { formatters_by_ft = {} }))
  end
end)
patch('lint', function(lint)
  lint.try_lint = function() end
end)

-- A terminal UI is attached by the end of startup, and Neovim fires UIEnter
-- after VimEnter; plugins finish setting up then (snacks.nvim installs its
-- vim.ui.select). A headless child has no UI, so fire it the same way.
vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    -- (after the config's own VimEnter autocommands)
    vim.schedule(function()
      vim.api.nvim_exec_autocmds('UIEnter', { modeline = false })
    end)
  end,
})

-- Probes the specs use to observe plugin UI (see probe_child.lua).
_G.__e2e = dofile(ctx.tests_dir .. '/lib/probe_child.lua')

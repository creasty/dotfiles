-- Language servers through Neovim's LSP client, with nvim-lspconfig's server
-- configs (lsp/*.lua on the runtimepath). A server starts only when its
-- command is installed: see nix/modules/neovim.nix and config/mise.

local M = {}

M.servers = {
  'bashls', -- bash-language-server (runs shellcheck)
  'clangd',
  'codebook', -- spell checking; your words are in config/codebook/codebook.toml
  'cssls', -- vscode-langservers-extracted
  'dartls',
  'denols', -- in Deno projects (ts_ls in the others)
  'eslint', -- vscode-langservers-extracted
  'gopls',
  'graphql', -- graphql-language-service-cli
  'jsonls', -- vscode-langservers-extracted
  'kotlin_lsp', -- JetBrains' kotlin-lsp (nix/modules/java.nix)
  'lua_ls',
  'pyright',
  'rust_analyzer',
  'solargraph',
  'tailwindcss',
  'terraformls',
  'ts_ls', -- typescript-language-server, for TypeScript 6 and older
  'tsc', -- TypeScript 7's own server
  'vimls',
  'yamlls',
}

local settings = {
  codebook = {
    init_options = { diagnosticSeverity = 'hint' },
  },
  gopls = {
    settings = {
      gopls = {
        completeUnimported = true,
        usePlaceholders = true,
      },
    },
  },
  graphql = {
    -- only in projects with a GraphQL config
    workspace_required = true,
    filetypes = { 'graphql', 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  },
  kotlin_lsp = {
    -- the name JetBrains' formula links it by (nvim-lspconfig runs intellij-server)
    cmd = { 'kotlin-lsp', '--stdio' },
    -- only in a project it imports (Gradle, Maven or workspace.json)
    workspace_required = true,
  },
  lua_ls = {
    settings = {
      Lua = {
        workspace = { library = { vim.env.VIMRUNTIME .. '/lua' } },
      },
    },
  },
  ts_ls = {
    init_options = {
      preferences = { includeCompletionsWithSnippetText = false },
    },
  },
}

--- Whether the project's TypeScript still ships the tsserver.js that
--- typescript-language-server runs (TypeScript 6 and older).
local function has_tsserver(root)
  return vim.uv.fs_stat(vim.fs.joinpath(root, 'node_modules/typescript/lib/tsserver.js')) ~= nil
end

--- TypeScript 7 (the native compiler) is its own language server, `tsc
--- --lsp`: ts_ls takes the projects on an older TypeScript, tsc the others,
--- including those without one (mise installs TypeScript 7).
local function route_typescript()
  -- (nvim-lspconfig's: the project root, unless the file is Deno's)
  local project_root = vim.lsp.config.ts_ls.root_dir
  -- nvim-lspconfig's tsc picks a binary that has --lsp in its root_dir and
  -- starts it in its cmd; keep both from this load of the config, as each
  -- load has its own choice of binary.
  local tsc = vim.lsp.config.tsc
  settings.ts_ls.root_dir = function(bufnr, on_dir)
    project_root(bufnr, function(root)
      if has_tsserver(root) then
        on_dir(root)
      end
    end)
  end
  settings.tsc = {
    cmd = tsc.cmd,
    root_dir = function(bufnr, on_dir)
      project_root(bufnr, function(root)
        if not has_tsserver(root) then
          tsc.root_dir(bufnr, on_dir)
        end
      end)
    end,
  }
end

local severity = vim.diagnostic.severity

--- A column of padding left and right of a float, in its own background.
M.padding = { '', '', '', { ' ', 'NormalFloat' }, '', '', '', { ' ', 'NormalFloat' } }

M.signs = {
  [severity.ERROR] = '✕',
  [severity.WARN] = '∆',
  [severity.INFO] = '□',
  [severity.HINT] = '*',
}

---------------------------------------------------------------------------
-- Locations: one result jumps, several open the picker
---------------------------------------------------------------------------

local METHODS = {
  definition = 'textDocument/definition',
  type_definition = 'textDocument/typeDefinition',
  implementation = 'textDocument/implementation',
  references = 'textDocument/references',
}

--- A function asking the language servers for `method` at the cursor (as it
--- is now) and calling back with quickfix items (nil without a server); the
--- picker calls it again to refresh.
local function requester(method)
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()
  local params = {}
  local function params_for(client)
    if not params[client.id] then
      local p = vim.lsp.util.make_position_params(win, client.offset_encoding)
      if method == 'references' then
        p.context = { includeDeclaration = false }
      end
      params[client.id] = p
    end
    return params[client.id]
  end
  return function(callback)
    if not vim.api.nvim_buf_is_valid(buf) or #vim.lsp.get_clients({ bufnr = buf, method = METHODS[method] }) == 0 then
      vim.notify(('No language server provides %s here'):format(METHODS[method]), vim.log.levels.WARN)
      return callback(nil)
    end
    vim.lsp.buf_request_all(buf, METHODS[method], params_for, function(results)
      local items = {}
      for client_id, response in pairs(results) do
        local client = vim.lsp.get_client_by_id(client_id)
        local result = response.result
        if client and result and not response.err then
          if result.uri or result.targetUri then
            result = { result }
          end
          vim.list_extend(items, vim.lsp.util.locations_to_items(result, client.offset_encoding))
        end
      end
      callback(items)
    end)
  end
end

local function jump_to(item)
  vim.cmd("normal! m'")
  if vim.fs.normalize(item.filename) ~= vim.fs.normalize(vim.api.nvim_buf_get_name(0)) then
    vim.cmd.edit(vim.fn.fnameescape(item.filename))
  end
  vim.api.nvim_win_set_cursor(0, { item.lnum, math.max(item.col - 1, 0) })
  vim.cmd('normal! zv')
end

local function locations(method, opts)
  opts = opts or {}
  return function()
    local request = requester(method)
    request(function(items)
      if not items then
        return
      elseif #items == 0 then
        vim.notify(('No locations found (%s)'):format(METHODS[method]), vim.log.levels.INFO)
      elseif #items == 1 and not opts.list then
        jump_to(items[1])
      else
        require('user.plugin.picker').locations(items, request)
      end
    end)
  end
end

---------------------------------------------------------------------------
-- Floats
---------------------------------------------------------------------------

--- The hover / diagnostic float shown for the current buffer, if any.
local function preview_float()
  local win = vim.b.lsp_floating_preview
  if win and vim.api.nvim_win_is_valid(win) then
    return win
  end
end

--- Scrolls the preview float by a page, or pages the buffer without one.
local function scroll(key)
  return function()
    local win = preview_float()
    local keys = vim.keycode(key)
    if win then
      vim.api.nvim_win_call(win, function()
        vim.cmd.normal({ args = { keys }, bang = true })
      end)
    else
      vim.cmd.normal({ args = { vim.v.count1 .. keys }, bang = true })
    end
  end
end

--- Shows the diagnostic under the cursor in a float, like hovering it.
local function show_diagnostic()
  if vim.fn.mode() ~= 'n' or preview_float() then
    return
  end
  local lnum, col = unpack(vim.api.nvim_win_get_cursor(0))
  local here = vim.diagnostic.get(0, { lnum = lnum - 1 })
  for _, d in ipairs(here) do
    if col >= d.col and (col < d.end_col or d.end_lnum > d.lnum or d.col == d.end_col) then
      vim.diagnostic.open_float({ scope = 'cursor', focus = false })
      return
    end
  end
end

---------------------------------------------------------------------------
-- Formatting
---------------------------------------------------------------------------

--- Formats a Go buffer when you leave it (not while you type in it).
local function auto_format(args)
  local buf = args.buf
  if vim.bo[buf].readonly or not vim.bo[buf].modifiable or vim.fn.mode() ~= 'n' then
    return
  end
  require('user.plugin.format').format({ bufnr = buf, async = true })
end

local function organize_imports()
  vim.lsp.buf.code_action({
    context = { only = { 'source.organizeImports' }, diagnostics = {} },
    apply = true,
  })
end

---------------------------------------------------------------------------
-- Setup
---------------------------------------------------------------------------

function M.setup()
  route_typescript()
  -- (blink.cmp adds its completion capabilities to every server itself)
  for name, config in pairs(settings) do
    vim.lsp.config(name, config)
  end
  vim.lsp.enable(M.servers)

  vim.diagnostic.config({
    signs = { text = M.signs },
    virtual_text = false,
    severity_sort = true,
    float = { source = 'if_many', border = M.padding },
    jump = { float = false },
  })

  -- the gr* defaults would make gr wait
  for _, lhs in ipairs({ 'grn', 'gra', 'grr', 'gri', 'grt' }) do
    for _, mode in ipairs({ 'n', 'x' }) do
      pcall(vim.keymap.del, mode, lhs)
    end
  end

  local map = vim.keymap.set

  -- Cross references
  map('n', 'gd', locations('definition'), { desc = 'Go to definition' })
  map('n', 'gt', locations('type_definition'), { desc = 'Go to type definition' })
  map('n', 'gi', locations('implementation'), { desc = 'Go to implementation' })
  map('n', 'gD', locations('definition', { list = true }), { desc = 'List definitions' })
  map('n', 'gT', locations('type_definition', { list = true }), { desc = 'List type definitions' })
  map('n', 'gR', locations('references', { list = true }), { desc = 'List references' })

  -- Refactoring
  map('n', 'gr', vim.lsp.buf.rename, { nowait = true, desc = 'Rename symbol' })
  map({ 'n', 'x' }, 'gq', vim.lsp.buf.code_action, { desc = 'Code action' })

  -- Hover
  map('n', 'gh', function()
    vim.lsp.buf.hover({ border = M.padding })
  end, { desc = 'Hover' })
  map('i', '<C-s><C-s>', function()
    require('blink.cmp').show_signature()
  end, { desc = 'Signature help' })

  -- Diagnostics
  local function jump(count, sev)
    return function()
      vim.diagnostic.jump({ count = count, severity = sev })
    end
  end
  map('n', '[d', jump(-1), { desc = 'Previous diagnostic' })
  map('n', ']d', jump(1), { desc = 'Next diagnostic' })
  map('n', '[e', jump(-1, severity.ERROR), { desc = 'Previous error' })
  map('n', ']e', jump(1, severity.ERROR), { desc = 'Next error' })

  -- Scroll float
  map('n', '<C-f>', scroll('<C-f>'), { desc = 'Scroll the float, or page down' })
  map('n', '<C-b>', scroll('<C-b>'), { desc = 'Scroll the float, or page up' })

  vim.api.nvim_create_user_command('Import', organize_imports, { desc = 'Organize imports' })
  vim.api.nvim_create_user_command('Format', function(opts)
    local range
    if opts.range > 0 then
      range = {
        start = { opts.line1, 0 },
        ['end'] = { opts.line2, #vim.fn.getline(opts.line2) },
      }
    end
    require('user.plugin.format').format({ async = true, range = range })
  end, { range = '%', desc = 'Format the buffer or the range' })
  vim.api.nvim_create_user_command('Diagnostics', function()
    require('user.plugin.picker').diagnostics()
  end, { desc = 'List diagnostics' })

  local group = vim.api.nvim_create_augroup('user_plugin_lsp', {})

  vim.api.nvim_create_autocmd('LspAttach', {
    group = group,
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client or not client:supports_method('textDocument/documentHighlight', args.buf) then
        return
      end
      if vim.b[args.buf].user_lsp_highlight then
        return
      end
      vim.b[args.buf].user_lsp_highlight = true
      -- Highlight the symbol and its references when holding the cursor.
      vim.api.nvim_create_autocmd('CursorHold', {
        group = group,
        buffer = args.buf,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'InsertEnter', 'BufLeave' }, {
        group = group,
        buffer = args.buf,
        callback = vim.lsp.buf.clear_references,
      })
    end,
  })

  vim.api.nvim_create_autocmd('CursorHold', {
    group = group,
    callback = show_diagnostic,
  })

  vim.api.nvim_create_autocmd({ 'FocusLost', 'BufLeave' }, {
    group = group,
    pattern = '*.go',
    callback = auto_format,
  })

  vim.api.nvim_create_autocmd({ 'DiagnosticChanged', 'LspProgress' }, {
    group = group,
    command = 'redrawstatus',
  })
end

return M

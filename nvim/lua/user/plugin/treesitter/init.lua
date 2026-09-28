local ts = require('nvim-treesitter')
local master = require('user.plugin.treesitter.master')

-- Parsers and their queries go into nvim-treesitter's own directory, as they
-- did with its master branch: with the plugins lazy.nvim keeps, where the e2e
-- tests find them (nvim/tests/plugins.lua).
local install_dir = vim.fs.joinpath(require('lazy.core.config').plugins['nvim-treesitter'].dir, 'site')
ts.setup { install_dir = install_dir }

-- nvim-treesitter's build installs the parsers of parsers.lua (build.lua).
-- When one is missing (added since, or the build failed), lazy.nvim runs the
-- build again, as it installs missing plugins: at startup, in its window. Not
-- without a UI (scripts, the e2e suite), nor without the tree-sitter CLI it
-- builds them with (nix/modules/neovim.nix): it would fail at every startup.
-- (What is missing is checked here: nvim-treesitter takes milliseconds to find
-- nothing is.)
local missing = vim.tbl_filter(function(lang)
  return not vim.uv.fs_stat(vim.fs.joinpath(install_dir, 'parser', lang .. '.so'))
end, require('user.plugin.treesitter.parsers'))
if #missing > 0 and #vim.api.nvim_list_uis() > 0 and vim.fn.executable('tree-sitter') == 1 then
  require('lazy').build({ plugins = { 'nvim-treesitter' }, wait = true })
end

-- These indent with nvim-yati, which still does better than nvim-treesitter's
-- queries in TypeScript, TSX and Rust
-- @see https://github.com/yioneko/nvim-yati/tree/main/lua/nvim-yati/configs
master.load_yati()
local yati = {
  c = true,
  cpp = true,
  css = true,
  graphql = true,
  html = true,
  javascript = true,
  jsdoc = true,
  json = true,
  json5 = true,
  jsx = true,
  lua = true,
  python = true,
  rust = true,
  toml = true,
  tsx = true,
  typescript = true,
}

--- Selects the syntax node under the cursor.
local function select_node()
  vim.treesitter.get_parser():parse({ vim.fn.line('w0') - 1, vim.fn.line('w$') })
  local node = vim.treesitter.get_node({ ignore_injections = false })
  if not node then
    return
  end
  local srow, scol, erow, ecol = node:range()
  if ecol == 0 then
    -- (it ends with a line break: up to the end of the line before)
    erow = erow - 1
    ecol = #vim.api.nvim_buf_get_lines(0, erow, erow + 1, true)[1]
  end
  vim.api.nvim_win_set_cursor(0, { srow + 1, scol })
  vim.cmd('normal! v')
  vim.api.nvim_win_set_cursor(0, { erow + 1, math.max(ecol - 1, 0) })
end

-- Highlighting and indentation, where there are a parser and queries for them
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('user_treesitter', {}),
  callback = function(ev)
    local lang = vim.treesitter.language.get_lang(ev.match)
    if not lang or not vim.treesitter.language.add(lang) then
      -- (the buffer's filetype had one before)
      if vim.b[ev.buf].user_treesitter then
        vim.b[ev.buf].user_treesitter = nil
        vim.treesitter.stop(ev.buf)
        vim.keymap.del({ 'n', 'x' }, 'gs', { buffer = ev.buf })
      end
      return
    end
    vim.b[ev.buf].user_treesitter = true
    local function has(query)
      return #vim.treesitter.query.get_files(lang, query) > 0
    end
    if has('highlights') then
      vim.treesitter.start(ev.buf, lang)
    end
    if yati[lang] then
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-yati.indent'.indentexpr()"
    elseif has('indents') then
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
    -- gs selects the node under the cursor, then the one around the selection
    vim.keymap.set('n', 'gs', select_node, { buffer = ev.buf })
    vim.keymap.set('x', 'gs', 'an', { buffer = ev.buf, remap = true })
  end,
})

master.load_syntax_tree_surfer()

require('treesitter-context').setup {
  enable = true,           -- Enable this plugin (Can be enabled/disabled later via commands)
  multiwindow = false,     -- Enable multiwindow support.
  max_lines = 0,           -- How many lines the window should span. Values <= 0 mean no limit.
  min_window_height = 0,   -- Minimum editor window height to enable context. Values <= 0 mean no limit.
  line_numbers = true,
  multiline_threshold = 1, -- Maximum number of lines to show for a single context
  trim_scope = 'outer',    -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
  mode = 'cursor',         -- Line used to calculate context. Choices: 'cursor', 'topline'
  -- Separator between context and content. Should be a single character string, like '-'.
  -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
  separator = nil,
  zindex = 20,     -- The Z-index of the context window
  on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
}

require('nvim-ts-autotag').setup {
  opts = {
    enable_close = true,
    enable_rename = true,
    enable_close_on_slash = true,
  },
}

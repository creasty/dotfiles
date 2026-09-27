local install = require('nvim-treesitter.install')
-- Some hosts answer curl's tarball download with a bot check, which tar
-- cannot extract (GitLab, for jsonc); git gets through.
install.prefer_git = true
-- nvim-treesitter's master branch passes `--no-bindings` to `tree-sitter
-- generate`, which the tree-sitter CLI dropped in 0.26.
install.ts_generate_args = { 'generate', '--abi', vim.treesitter.language_version }

--- Parsers generated from their grammar (latex, swift) need the tree-sitter CLI
--- (nix/modules/neovim.nix). Without it, installing one fails with an error at
--- every startup, so they wait until the CLI is there.
local function installable(langs)
  if vim.fn.executable('tree-sitter') == 1 then
    return langs
  end
  local parsers = require('nvim-treesitter.parsers').get_parser_configs()
  return vim.tbl_filter(function(lang)
    return not parsers[lang].install_info.requires_generate_from_grammar
  end, langs)
end

require('nvim-treesitter.configs').setup {
  ensure_installed = installable(require('user.plugin.treesitter.parsers')),
  highlight = {
    enable = true,
  },
  indent = {
    enable = true,

    -- Use nvim-yati
    -- @see https://github.com/yioneko/nvim-yati/tree/main/lua/nvim-yati/configs
    disable = {
      'c',
      'cpp',
      'css',
      'graphql',
      'html',
      'javascript',
      'jsdoc',
      'json',
      'json5',
      'jsx',
      'lua',
      'python',
      'rust',
      'toml',
      'tsx',
      'typescript',
    },
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = 'gs',
      node_incremental = 'gs',
    },
  },
  -- yioneko/nvim-yati
  yati = {
    enable = true,
    suppress_conflict_warning = true,
  },
  -- RRethy/nvim-treesitter-endwise
  endwise = {
    enable = true,
  },
  -- creasty/opfmt (off for now: it breaks on Neovim 0.12)
  opfmt = {
    enable = false,
  },
}

require('syntax-tree-surfer')

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

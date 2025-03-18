require('nvim-treesitter.configs').setup {
  ensure_installed = {
    'bash',
    'c',
    'cmake',
    'comment',
    'commonlisp',
    'cpp',
    'css',
    'dart',
    'dockerfile',
    'glsl',
    'go',
    'gomod',
    'graphql',
    'hcl',
    'html',
    'java',
    'javascript',
    'jsdoc',
    'json',
    'jsonc',
    'kotlin',
    'latex',
    'lua',
    'make',
    'markdown',
    'markdown_inline',
    'proto',
    'python',
    'query',
    'regex',
    'rst',
    'ruby',
    'rust',
    'sql',
    'styled',
    'swift',
    'terraform',
    'tlaplus',
    'toml',
    'tsx',
    'typescript',
    'vim',
    'yaml',
  },
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
  -- windwp/nvim-ts-autotag
  autotag = {
    enable = true,
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
  -- creasty/opfmt
  opfmt = {
    enable = true,
  },
}

require('syntax-tree-surfer')

require('treesitter-context').setup {
  enable = true,            -- Enable this plugin (Can be enabled/disabled later via commands)
  multiwindow = false,      -- Enable multiwindow support.
  max_lines = 0,            -- How many lines the window should span. Values <= 0 mean no limit.
  min_window_height = 0,    -- Minimum editor window height to enable context. Values <= 0 mean no limit.
  line_numbers = true,
  multiline_threshold = 1, -- Maximum number of lines to show for a single context
  trim_scope = 'outer',     -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
  mode = 'cursor',          -- Line used to calculate context. Choices: 'cursor', 'topline'
  -- Separator between context and content. Should be a single character string, like '-'.
  -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
  separator = nil,
  zindex = 20,     -- The Z-index of the context window
  on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
}

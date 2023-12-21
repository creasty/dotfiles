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

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
    'proto',
    'python',
    'query',
    'regex',
    'rst',
    'ruby',
    'rust',
    'sql',
    'swift',
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
  -- nvim-treesitter/playground
  playground = {
    enable = true,
    disable = {},
    updatetime = 25,
    persist_queries = false,
  },
  -- nvim-treesitter/nvim-treesitter-textobjects
  textobjects = {
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ["af"] = '@function.outer',
        ["if"] = '@function.inner',
        ["ac"] = '@class.outer',
        ["ic"] = '@class.inner',
      },
    },
    swap = {
      enable = true,
      swap_next = {
        ['>p'] = '@parameter.inner',
        ['>f'] = '@function.outer',
      },
      swap_previous = {
        ['<p'] = '@parameter.inner',
        ['<f'] = '@function.outer',
      },
    },
    move = {
      enable = true,
      set_jumps = true,
      goto_next_start = {
        [']f'] = '@function.outer',
        [']c'] = '@class.outer',
      },
      goto_previous_start = {
        ['[f'] = '@function.outer',
        ['[c'] = '@class.outer',
      },
    },
  },
  -- yioneko/nvim-yati
  yati = {
    enable = true,
  },
  -- RRethy/nvim-treesitter-endwise
  endwise = {
    enable = true,
  },
  opfmt = {
    enable = true,
  },
}

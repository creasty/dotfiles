require('nvim-treesitter.configs').setup {
  ensure_installed = 'maintained',
  highlight = {
    enable = true,
  },
  indent = {
    enable = true,
  },
  autotag = {
    enable = true,
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = 'gs',
      node_incremental = 'gs',
    },
  },
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
}

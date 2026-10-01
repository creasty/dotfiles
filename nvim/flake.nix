# The Neovim plugins of nvim/lua/user/plugins.lua, pinned: flake.lock locks each input at a commit,
# which lazy.nvim installs, and Dependabot bumps them (.github/dependabot.yml). Nothing builds this
# flake; it only locks. An input is named after its plugin, with dashes for dots, and follows the
# plugin's default branch unless the spec sets another.
#
# To bump a plugin by hand: nix flake update --flake ./nvim <input>; the next start checks it out
{
  inputs = {
    lazy-nvim = {
      url = "git+https://github.com/folke/lazy.nvim?shallow=1";
      flake = false;
    };

    # Editing
    vim-textobj-user = {
      url = "git+https://github.com/kana/vim-textobj-user?shallow=1";
      flake = false;
    };
    vim-textobj-indent = {
      url = "git+https://github.com/kana/vim-textobj-indent?shallow=1";
      flake = false;
    };
    vim-surround = {
      url = "git+https://github.com/tpope/vim-surround?shallow=1";
      flake = false;
    };
    vim-repeat = {
      url = "git+https://github.com/tpope/vim-repeat?shallow=1";
      flake = false;
    };
    vim-pasta = {
      url = "git+https://github.com/ku1ik/vim-pasta?shallow=1";
      flake = false;
    };
    mold-vim = {
      url = "git+https://github.com/creasty/mold.vim?shallow=1";
      flake = false;
    };
    switch-vim = {
      url = "git+https://github.com/AndrewRadev/switch.vim?shallow=1";
      flake = false;
    };
    vim-rengbang = {
      url = "git+https://github.com/deris/vim-rengbang?shallow=1";
      flake = false;
    };
    vim-operator-user = {
      url = "git+https://github.com/kana/vim-operator-user?shallow=1";
      flake = false;
    };
    vim-operator-replace = {
      url = "git+https://github.com/kana/vim-operator-replace?shallow=1";
      flake = false;
    };
    vim-easy-align = {
      url = "git+https://github.com/junegunn/vim-easy-align?shallow=1";
      flake = false;
    };
    nvim-autopairs = {
      url = "git+https://github.com/windwp/nvim-autopairs?shallow=1";
      flake = false;
    };
    vim-textmanip = {
      url = "git+https://github.com/t9md/vim-textmanip?shallow=1";
      flake = false;
    };
    hop-nvim = {
      url = "git+https://github.com/smoka7/hop.nvim?shallow=1";
      flake = false;
    };
    copilot-lua = {
      url = "git+https://github.com/zbirenbaum/copilot.lua?shallow=1";
      flake = false;
    };
    live-command-nvim = {
      url = "git+https://github.com/smjonas/live-command.nvim?shallow=1";
      flake = false;
    };
    text-case-nvim = {
      url = "git+https://github.com/johmsalas/text-case.nvim?shallow=1";
      flake = false;
    };

    # Treesitter
    nvim-treesitter = {
      url = "git+https://github.com/nvim-treesitter/nvim-treesitter?ref=main&shallow=1";
      flake = false;
    };
    nvim-treesitter-context = {
      url = "git+https://github.com/nvim-treesitter/nvim-treesitter-context?shallow=1";
      flake = false;
    };
    nvim-ts-autotag = {
      url = "git+https://github.com/windwp/nvim-ts-autotag?shallow=1";
      flake = false;
    };
    nvim-treesitter-endwise = {
      url = "git+https://github.com/RRethy/nvim-treesitter-endwise?shallow=1";
      flake = false;
    };
    opfmt = {
      url = "git+https://github.com/creasty/opfmt?shallow=1";
      flake = false;
    };

    # UI
    vim-signature = {
      url = "git+https://github.com/kshenoy/vim-signature?shallow=1";
      flake = false;
    };
    nerdtree = {
      url = "git+https://github.com/preservim/nerdtree?shallow=1";
      flake = false;
    };

    # LSP, completion and snippets
    nvim-lspconfig = {
      url = "git+https://github.com/neovim/nvim-lspconfig?shallow=1";
      flake = false;
    };
    blink-cmp = {
      url = "git+https://github.com/saghen/blink.cmp?ref=v1&shallow=1";
      flake = false;
    };
    LuaSnip = {
      url = "git+https://github.com/L3MON4D3/LuaSnip?shallow=1";
      flake = false;
    };
    conform-nvim = {
      url = "git+https://github.com/stevearc/conform.nvim?shallow=1";
      flake = false;
    };
    nvim-lint = {
      url = "git+https://github.com/mfussenegger/nvim-lint?shallow=1";
      flake = false;
    };
    gitsigns-nvim = {
      url = "git+https://github.com/lewis6991/gitsigns.nvim?shallow=1";
      flake = false;
    };

    # Picker
    snacks-nvim = {
      url = "git+https://github.com/folke/snacks.nvim?shallow=1";
      flake = false;
    };

    # Navigation
    vim-altr = {
      url = "git+https://github.com/kana/vim-altr?shallow=1";
      flake = false;
    };
    diffview-plus-nvim = {
      url = "git+https://github.com/dlyongemallo/diffview-plus.nvim?shallow=1";
      flake = false;
    };

    # Runner
    vim-quickrun = {
      url = "git+https://github.com/thinca/vim-quickrun?shallow=1";
      flake = false;
    };

    # Terminal
    flatten-nvim = {
      url = "git+https://github.com/willothy/flatten.nvim?shallow=1";
      flake = false;
    };
  };

  outputs = _: { };
}

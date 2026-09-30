# Neovim, with the language servers, linters and formatters its config relies on
# (nvim/lua/user/plugin/{lsp,lint,format}.lua). lazy.nvim installs the plugins at the commits
# nvim/flake.lock pins, and itself on the first start (nvim/lua/user/plugins.lua); copilot.lua
# downloads GitHub's copilot-language-server (unfree in nixpkgs).
{ pkgs, username, ... }:
{
  home-manager.users.${username} = {
    home.packages = with pkgs; [
      neovim
      ansible-lint
      clang-tools # clangd, clang-format
      codebook # spell checking (codebook-lsp)
      glsl_analyzer
      lua-language-server
      nil # Nix's language server
      nixfmt
      prettier
      pyright
      shellcheck # through bash-language-server
      sqlfluff
      tailwindcss-language-server
      terraform-ls
      tree-sitter # CLI nvim-treesitter builds the parsers with
      vim-language-server
      vim-vint
      vscode-langservers-extracted # CSS, ESLint, HTML and JSON language servers
      watchman # file watching (nvim/plugin/file.vim renames the way it needs)
      yaml-language-server
    ];

    # As a whole, so that new files apply without a switch
    dotfiles.link.".config/nvim" = "nvim";
  };
}

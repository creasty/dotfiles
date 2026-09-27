# Neovim, with the language servers, linters and formatters its config relies on
# (nvim/lua/user/plugin/{lsp,lint,format}.lua). dein.vim installs the plugins; copilot.lua
# downloads GitHub's copilot-language-server (unfree in nixpkgs).
{
  pkgs,
  username,
  dotfiles,
  ...
}:
{
  home-manager.users.${username} =
    { lib, ... }:
    {
      home.packages = with pkgs; [
        neovim
        ansible-lint
        clang-tools # clangd, clang-format
        codebook # spell checking (codebook-lsp)
        lua-language-server
        prettier
        pyright
        shellcheck # through bash-language-server
        sqlfluff
        tailwindcss-language-server
        terraform-ls
        vim-language-server
        vim-vint
        vscode-langservers-extracted # CSS, ESLint, HTML and JSON language servers
        watchman # file watching (nvim/plugin/file.vim renames the way it needs)
        yaml-language-server
      ];

      # dein.vim writes the plugins into nvim/dein/repos, so the directory is linked as a whole
      dotfiles.link.".config/nvim" = "nvim";

      home.activation.installDein = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        dein=${lib.escapeShellArg dotfiles}/nvim/dein/repos/github.com/Shougo/dein.vim
        if [ ! -d "$dein" ]; then
          run ${pkgs.git}/bin/git clone --quiet https://github.com/Shougo/dein.vim "$dein"
        fi
      '';
    };
}

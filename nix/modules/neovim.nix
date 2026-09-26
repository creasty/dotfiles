# Neovim, with the language servers and linters its config relies on. dein.vim installs the plugins.
{
  pkgs,
  username,
  dotfiles,
  ...
}:
{
  # nvim/coc-settings.json finds Neovim's runtime through the user's profile
  environment.pathsToLink = [ "/share/nvim" ];

  home-manager.users.${username} =
    { lib, ... }:
    {
      home.packages = with pkgs; [
        # With the Python 3 provider (pynvim), which UltiSnips needs
        (neovim.override { withPython3 = true; })
        ansible-lint
        clang-tools # clangd, clang-format
        shellcheck
        terraform-ls
        watchman
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

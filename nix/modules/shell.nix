# zsh (macOS's, or whichever zsh is already the login shell) with the dotfiles' shell config
{ pkgs, username, ... }:
{
  # nix-darwin's /etc/zshenv sets up the environment for every zsh: PATH and the completions of Nix packages.
  # Completion, the prompt and plugins are left to the dotfiles' zshrc, which is tuned for startup time.
  programs.zsh = {
    enableCompletion = false;
    enableBashCompletion = false;
    promptInit = "";
  };

  # New terminals start the login shell: make it zsh where it isn't (e.g. on CI runners)
  system.activationScripts.postActivation.text = ''
    login_shell="$(dscl . -read /Users/${username} UserShell | awk '{ print $2 }')"
    case "$login_shell" in
      */zsh) ;;
      *) dscl . -create /Users/${username} UserShell /bin/zsh ;;
    esac
  '';

  home-manager.users.${username} = {
    dotfiles.link = {
      ".profile" = "shell/profile";
      ".bash_profile" = "shell/bash/bash_profile";
      ".bashrc" = "shell/bash/bashrc";
      ".zshenv" = "shell/zsh/zshenv";
      ".zprofile" = "shell/zsh/zprofile";
      ".zshrc" = "shell/zsh/zshrc";
      ".zsh" = "shell/zsh";
    };

    # Plugins, which the zshrc sources from here
    xdg.dataFile = {
      "zsh/plugins/zsh-autosuggestions".source = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
      "zsh/plugins/fast-syntax-highlighting".source =
        "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting";
    };
  };
}

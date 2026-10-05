# zsh (macOS's, or whichever zsh is already the login shell) with the dotfiles' shell config
{ username, ... }:
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

    # Plugins, which the zshrc sources from here, each at a release's commit, which Renovate moves
    xdg.dataFile = {
      "zsh/plugins/zsh-autosuggestions".source = builtins.fetchGit {
        url = "https://github.com/zsh-users/zsh-autosuggestions";
        ref = "refs/tags/v0.7.1";
        rev = "e52ee8ca55bcc56a17c828767a3f98f22a68d4eb";
      };
      "zsh/plugins/fast-syntax-highlighting".source = builtins.fetchGit {
        url = "https://github.com/zdharma-continuum/fast-syntax-highlighting";
        ref = "refs/tags/v1.56";
        rev = "5ecd353c81214f82bdeca5483fab6ccc5a2d5494";
      };
    };
  };
}

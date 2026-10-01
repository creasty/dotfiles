# kitty (https://sw.kovidgoyal.net/kitty/), with config/kitty/kitty.conf: the terminal
{ username, ... }:
{
  homebrew.casks = [ "kitty" ];

  # kitty starts the shell, and Ghostty Neovim (ghostty.nix), with login(1), which prints the last login unless there's
  # a ~/.hushlogin
  home-manager.users.${username}.home.file.".hushlogin".text = "";
}

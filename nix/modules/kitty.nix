# kitty (https://sw.kovidgoyal.net/kitty/), with config/kitty/kitty.conf: Neovim's window, where Neovim runs the shells
{ username, ... }:
{
  homebrew.casks = [ "kitty" ];

  # kitty starts Neovim through zsh with login(1), which prints the last login unless there's a ~/.hushlogin
  home-manager.users.${username}.home.file.".hushlogin".text = "";
}

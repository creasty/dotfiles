# Hammerspoon (https://www.hammerspoon.org), with hammerspoon/ as its config: creasty/Keyboard's key bindings
# (hammerspoon/README.md)
{ username, ... }:
{
  homebrew.casks = [ "hammerspoon" ];

  # As a whole, so that new files apply without a switch
  home-manager.users.${username}.dotfiles.link.".hammerspoon" = "hammerspoon";
}

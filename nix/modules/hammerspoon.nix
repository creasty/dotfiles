# Hammerspoon (https://www.hammerspoon.org), with hammerspoon/ as its config: creasty/Keyboard's key bindings
# (hammerspoon/README.md)
{ username, ... }:
{
  homebrew.casks = [ "hammerspoon" ];

  # As a whole, so that new files apply without a switch
  home-manager.users.${username}.dotfiles.link.".hammerspoon" = "hammerspoon";

  # The shortcuts the key bindings stroke (keyboard.lua): no character (65535), the key code, and the modifier flags,
  # with the Fn flag (8388608) that arrow and function keys carry besides Ctrl's (262144) or Cmd's (1048576)
  dotfiles.hotKeys = {
    # Mission Control > Move left a space: Ctrl-LeftArrow
    "79" = [
      65535
      123
      8650752
    ];
    # Mission Control > Move right a space: Ctrl-RightArrow
    "81" = [
      65535
      124
      8650752
    ];
    # Keyboard > Move focus to next window: Cmd-F1
    "27" = [
      65535
      122
      9437184
    ];
  };
}

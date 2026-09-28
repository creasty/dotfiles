# Ghostty (https://ghostty.org), with config/ghostty/config.ghostty, and ghostty-pane (ghostty-pane/): the shell of its
# panes, with Neovim over the pane on C-y in place of tmux's copy mode
{ pkgs, username, ... }:
let
  ghostty-pane = pkgs.runCommandCC "ghostty-pane" { meta.mainProgram = "ghostty-pane"; } ''
    mkdir -p $out/bin
    $CC -O2 -Wall -Wextra -o $out/bin/ghostty-pane ${../../ghostty-pane/ghostty-pane.c}
  '';
in
{
  homebrew.casks = [ "ghostty" ];

  home-manager.users.${username}.home.packages = [ ghostty-pane ];
}

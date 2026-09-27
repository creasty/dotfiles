#!/usr/bin/env bats
#
# tmux's panes have a terminal type that macOS's own programs know (nix/modules/tmux.nix)

load helper

@test "macOS's own programs know the terminal type of tmux's panes" {
  local term
  run -0 login_zsh 'tmux -L verify -f /dev/null start-server \; source-file ~/.config/tmux/tmux.conf \; show-options -gv default-terminal'
  term="$output"
  # With macOS's ncurses, which less, clear and /bin/zsh read terminfo with
  run -0 pristine /usr/bin/tput -T "$term" colors
  assert_equal "$output" 256
  # ...and not the 0 color pairs that more than ncurses 5.7 holds would overflow to
  run -0 pristine /usr/bin/tput -T "$term" pairs
  [ "$output" -gt 0 ]
}

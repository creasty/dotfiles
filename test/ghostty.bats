#!/usr/bin/env bats
#
# Ghostty's panes start the login shell through ghostty-pane (nix/modules/ghostty.nix). Its own end-to-end tests
# (ghostty-pane/tests) run in the tests workflow.

load helper

@test "Ghostty's panes start zsh as a login shell, through ghostty-pane" {
  local command
  run -0 pristine /Applications/Ghostty.app/Contents/MacOS/ghostty +show-config
  command="$(sed -n 's/^command = //p' <<< "$output")"
  # As Ghostty starts it, with bash's exec -l, in a terminal: script's. Stopped if it doesn't end in a minute.
  run -0 pristine /usr/bin/perl -e 'alarm shift; exec @ARGV' 60 \
    /usr/bin/script -q /dev/null /bin/bash --noprofile --norc -c "exec -l $command" \
    <<< 'print -r -- "login shell: $options[login], in ${${$(ps -o comm= -p $PPID)#-}:t}"; exit'
  assert_like "$output" '*login shell: on, in ghostty-pane*'
}

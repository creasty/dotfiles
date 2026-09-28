#!/usr/bin/env bats
#
# Ghostty's panes start the login shell through ghostty-pane (nix/modules/ghostty.nix). Its own end-to-end tests
# (ghostty-pane/tests) run in the tests workflow.

load helper

@test "Ghostty's panes start zsh as a login shell, through ghostty-pane" {
  local command check
  run -0 pristine /Applications/Ghostty.app/Contents/MacOS/ghostty +show-config
  command="$(sed -n 's/^command = //p' <<< "$output")"
  # As Ghostty starts it, with bash's exec -l, in a terminal (script's), but with a command for zsh: typed ahead, it
  # would come before the prompt, where the startup files may read it. Stopped if it doesn't end in a minute.
  # shellcheck disable=SC2016 # zsh's
  check='print -r -- "login shell: $options[login], in ${${$(ps -o comm= -p $PPID)#-}:t}"'
  run -0 pristine /usr/bin/perl -e 'alarm shift; exec @ARGV' 60 \
    /usr/bin/script -q /dev/null /bin/bash --noprofile --norc -c "exec -l $command -c $(q "$check")" < /dev/null
  assert_like "$output" '*login shell: on, in ghostty-pane*'
}

# Ghostty starts the command of a pane with `login -flp <user> <command>`, as the user
@test "Ghostty's panes start without the last login" {
  local login=(/usr/bin/perl -e 'alarm shift; exec @ARGV' 60 /usr/bin/script -q /dev/null
    /usr/bin/login -flp "$(id -un)")
  # A login first, for the second to report
  run -0 pristine "${login[@]}" /usr/bin/true < /dev/null
  run -0 pristine "${login[@]}" /bin/echo started < /dev/null
  assert_like "$output" '*started*'
  [[ $output != *'Last login'* ]]
}

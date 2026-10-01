#!/usr/bin/env bats
#
# kitty starts the shell, and Ghostty Neovim, with login(1) (nix/modules/kitty.nix)

load helper

# As `login -f -l -p <user> <command>`, as the user
@test "kitty's windows start without the last login" {
  local login=(/usr/bin/perl -e 'alarm shift; exec @ARGV' 60 /usr/bin/script -q /dev/null
    /usr/bin/login -flp "$(id -un)")
  # A login first, for the second to report
  run -0 pristine "${login[@]}" /usr/bin/true < /dev/null
  run -0 pristine "${login[@]}" /bin/echo started < /dev/null
  assert_like "$output" '*started*'
  [[ $output != *'Last login'* ]]
}

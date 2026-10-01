#!/usr/bin/env bats
#
# ssh signs in with the keys in 1Password (nix/modules/ssh.nix), and keeps its files private

load helper

file_mode() {
  stat -c %a "$1" 2> /dev/null || stat -f %Lp "$1"
}

@test "ssh directories are private" {
  local modes
  modes="$(file_mode ~/.ssh) $(file_mode ~/.ssh/config.d) $(file_mode ~/.ssh/keys)"
  assert_equal "$modes" '700 700 700'
}

@test "the ssh config comes from the Nix store" {
  run -0 readlink ~/.ssh/config
  assert_like "$output" '/nix/store/*'
}

@test "ssh uses 1Password's agent and the common config" {
  run -0 ssh -G example.com
  assert_like "$(grep '^identityagent ' <<< "$output")" '*/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock*'
  assert_line 'identitiesonly yes'
  assert_line 'serveraliveinterval 30'
}

@test "ssh trusts a host's key on the first connection, and refuses the host once it changes" {
  run -0 ssh -G example.com
  assert_line 'stricthostkeychecking accept-new'
  # With the home directory as `~` or expanded
  assert_like "$(grep '^userknownhostsfile ' <<< "$output")" 'userknownhostsfile */.ssh/known_hosts *'
}

# The ssh function (shell/zsh/src/functions.zsh), with a fake ssh that prints the terminal type it's given
@test "ssh gives remote hosts xterm-256color in place of kitty's terminal type" {
  mkdir "$BATS_TEST_TMPDIR/bin"
  printf '#!/bin/sh\necho "TERM=$TERM"\n' > "$BATS_TEST_TMPDIR/bin/ssh"
  chmod +x "$BATS_TEST_TMPDIR/bin/ssh"
  run -0 pristine env TERM=xterm-kitty "$VERIFY_ZSH" -il +m -c "path=($(q "$BATS_TEST_TMPDIR/bin") \$path); ssh example.com"
  assert_line 'TERM=xterm-256color'
}

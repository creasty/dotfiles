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
  assert_line 'userknownhostsfile /dev/null'
}

@test "Vagrant machines use Vagrant's key" {
  run -0 ssh -G va_example
  assert_line 'user vagrant'
  # With the home directory as `~` or expanded
  assert_like "$(grep '^identityfile ' <<< "$output")" '*/.vagrant.d/insecure_private_key'
}

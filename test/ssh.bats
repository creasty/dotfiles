#!/usr/bin/env bats
#
# base.ssh: the ssh config is assembled from the common files and kept private

load helper

# bats file_tags=base:ssh

file_mode() {
  stat -c %a "$1" 2> /dev/null || stat -f %Lp "$1"
}

@test "ssh files are private" {
  local modes
  modes="$(file_mode ~/.ssh) $(file_mode ~/.ssh/config.d) $(file_mode ~/.ssh/keys) $(file_mode ~/.ssh/config)"
  assert_equal "$modes" '700 700 700 600'
}

@test "ssh applies the common config" {
  run -0 ssh -G example.com
  assert_line 'identitiesonly yes'
  assert_line 'serveraliveinterval 30'
  assert_line 'userknownhostsfile /dev/null'
}

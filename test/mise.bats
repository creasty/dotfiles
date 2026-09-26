#!/usr/bin/env bats
#
# mise manages the language runtimes with the dotfiles' config (nix/modules/mise.nix)

load helper

@test "mise reads its global config from the dotfiles" {
  # not_found_auto_install defaults to true
  run -0 login_bash 'mise settings get not_found_auto_install'
  assert_equal "$output" false
}

#!/usr/bin/env bats
#
# 1Password's CLI (nix/modules/1password.nix)

load helper

@test "1Password's CLI is where the app integrates with it" {
  run -0 /usr/local/bin/op --version
}

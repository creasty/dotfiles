#!/usr/bin/env bats
#
# The Flutter SDK (nix/modules/flutter.nix)

load helper

@test "flutter is installed" {
  run -0 brew list --cask flutter
  [ -x "$HOMEBREW_PREFIX/bin/flutter" ]
}

#!/usr/bin/env bats
#
# Tools for Cocoa development (nix/modules/swift.nix)

load helper

@test "carthage is installed and runs" {
  assert_formulae carthage
  run -0 "$HOMEBREW_PREFIX/bin/carthage" version
}

#!/usr/bin/env bats
#
# Keyboard, from its GitHub release (nix/modules/keyboard.nix)

load helper

# Where home-manager copies the apps of its packages
KEYBOARD_APP="$HOME/Applications/Home Manager Apps/Keyboard.app"

@test "Keyboard is installed, its signature intact" {
  run -0 codesign --verify --strict "$KEYBOARD_APP"
}

# Gatekeeper wouldn't open it, since it isn't notarized
@test "Keyboard isn't quarantined" {
  run -0 xattr "$KEYBOARD_APP"
  [[ $output != *com.apple.quarantine* ]]
}

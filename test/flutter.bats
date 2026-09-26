#!/usr/bin/env bats
#
# app.flutter: the Flutter SDK

load helper

# bats file_tags=app:flutter

@test "flutter is installed" {
  run -0 brew list --cask flutter
  [ -x "$HOMEBREW_PREFIX/bin/flutter" ]
}

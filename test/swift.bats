#!/usr/bin/env bats
#
# lang.swift: tools for Cocoa development

load helper

# bats file_tags=lang:swift

@test "carthage is installed and runs" {
  # shellcheck disable=SC2046
  assert_formulae $(role_formulae swift)
  run -0 "$HOMEBREW_PREFIX/bin/carthage" version
}

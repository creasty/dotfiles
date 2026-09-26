#!/usr/bin/env bats
#
# lang.mise.mise: mise manages the language runtimes with the dotfiles' config

load helper

# bats file_tags=lang:mise:mise

@test "mise is installed" {
  # shellcheck disable=SC2046
  assert_formulae $(role_formulae mise)
}

@test "mise reads its global config from the dotfiles" {
  require_linked .profile .config/mise
  # not_found_auto_install defaults to true
  run -0 login_bash 'mise settings get not_found_auto_install'
  assert_equal "$output" false
}

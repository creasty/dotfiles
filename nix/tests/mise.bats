#!/usr/bin/env bats
#
# mise manages the language runtimes and tools with the dotfiles' config (nix/modules/mise.nix)

load helper

@test "mise reads its global config from the dotfiles" {
  # not_found_auto_install defaults to true
  run -0 login_bash 'mise settings get not_found_auto_install'
  assert_equal "$output" false
}

@test "the npm and gem tools are installed at their configured versions" {
  local tool problems=''
  for tool in $(mise_config '.tools | keys | .[] | select(test("^(npm|gem):"))'); do
    login_bash "mise where $(q "$tool@$(mise_config ".tools[\"$tool\"]")")" > /dev/null 2>&1 || problems+="$tool"$'\n'
  done
  assert_none "$problems" 'not installed'
}

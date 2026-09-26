#!/usr/bin/env bats
#
# VS Code with the dotfiles' settings and the configured extensions (nix/modules/vscode.nix)

load helper

@test "the code command runs" {
  run -0 "$HOMEBREW_PREFIX/bin/code" --version
}

@test "configured extensions are installed" {
  local installed extension problems=''
  run -0 "$HOMEBREW_PREFIX/bin/code" --list-extensions
  installed="$(tr '[:upper:]' '[:lower:]' <<< "$output")"
  for extension in $(manifest '.vscode.extensions[]'); do
    grep -qxF -- "$(tr '[:upper:]' '[:lower:]' <<< "$extension")" <<< "$installed" || problems+="$extension"$'\n'
  done
  assert_none "$problems" 'not installed'
}

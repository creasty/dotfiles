#!/usr/bin/env bats
#
# app.vscode: VS Code with the dotfiles' settings and the configured extensions

load helper

# bats file_tags=app:vscode

user_dir="$HOME/Library/Application Support/Code/User"

@test "the code command runs" {
  run -0 "$HOMEBREW_PREFIX/bin/code" --version
}

@test "settings and keybindings point into the dotfiles" {
  local src dest problems=''
  while read -r src dest; do
    [[ -L $user_dir/$dest && $user_dir/$dest -ef $DOTFILES_PATH/$src ]] || problems+="$dest -> $src"$'\n'
  done < <(config '.vscode.link | to_entries | .[] | .key + " " + .value')
  assert_none "$problems" 'not linked'
}

@test "configured extensions are installed" {
  local installed extension problems=''
  run -0 "$HOMEBREW_PREFIX/bin/code" --list-extensions
  installed="$(tr '[:upper:]' '[:lower:]' <<< "$output")"
  for extension in $(role_tasks vscode '.[] | select(.name == "install extensions") | .loop[]'); do
    grep -qxF -- "$(tr '[:upper:]' '[:lower:]' <<< "$extension")" <<< "$installed" || problems+="$extension"$'\n'
  done
  assert_none "$problems" 'not installed'
}

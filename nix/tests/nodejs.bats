#!/usr/bin/env bats
#
# Node.js at the version of config/mise/config.toml, for terminals and scripts alike

load helper

setup() {
  node_version="$(mise_config '.tools.node.version')"
}

@test "terminals run node from mise at the configured version" {
  run -0 login_zsh 'print -r -- $commands[node]; node --version'
  assert_equal "${lines[0]}" "$HOME/.local/share/mise/installs/node/$node_version/bin/node"
  assert_equal "${lines[1]}" "v$node_version"
}

@test "scripts and login bash run node through mise's shims" {
  run -0 login_bash 'command -v node; node --version'
  assert_equal "${lines[0]}" "$HOME/.local/share/mise/shims/node"
  assert_equal "${lines[1]}" "v$node_version"

  run -0 script_zsh 'whence -p node'
  assert_equal "$output" "$HOME/.local/share/mise/shims/node"
}

@test "default npm packages are installed" {
  local pkg problems=''
  run -0 login_bash 'npm ls --global --parseable --depth=0'
  # shellcheck disable=SC2013
  for pkg in $(sed 's/#.*//' "$DOTFILES_PATH/config/mise/default-npm-packages"); do
    grep -qx ".*/node_modules/$pkg" <<< "$output" || problems+="$pkg"$'\n'
  done
  assert_none "$problems" 'not installed'
}

@test "yarn runs" {
  run -0 login_zsh 'yarn --version'
}

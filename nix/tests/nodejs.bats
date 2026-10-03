#!/usr/bin/env bats
#
# Node.js at the version of config/mise/config.toml, for terminals and scripts alike

load helper

setup() {
  node_version="$(mise_config '.tools.node')"
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

# Apart from Node, as a project's .node-version swaps the Node that runs
@test "terminals run the npm tools from their own installs" {
  local version
  version="$(mise_config '.tools["npm:typescript"]')"
  run -0 login_zsh 'print -r -- $commands[tsc]; tsc --version'
  assert_equal "${lines[0]}" "$HOME/.local/share/mise/installs/npm-typescript/$version/bin/tsc"
  assert_equal "${lines[1]}" "Version $version"
}

@test "yarn runs" {
  run -0 login_zsh 'yarn --version'
}

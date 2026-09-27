#!/usr/bin/env bats
#
# Python at the version of config/mise/config.toml, for terminals and scripts alike

load helper

setup() {
  python_version="$(mise_config '.tools.python')"
}

@test "terminals run python3 from mise at the configured version" {
  run -0 login_zsh 'print -r -- $commands[python3]; python3 --version'
  assert_equal "${lines[0]}" "$HOME/.local/share/mise/installs/python/$python_version/bin/python3"
  assert_equal "${lines[1]}" "Python $python_version"
}

@test "scripts and login bash run python3 through mise's shims" {
  run -0 login_bash 'command -v python3; python3 --version'
  assert_equal "${lines[0]}" "$HOME/.local/share/mise/shims/python3"
  assert_equal "${lines[1]}" "Python $python_version"

  run -0 script_zsh 'whence -p python3'
  assert_equal "$output" "$HOME/.local/share/mise/shims/python3"
}

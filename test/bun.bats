#!/usr/bin/env bats
#
# Bun at the version of config/mise/config.toml, for terminals and scripts alike

load helper

setup() {
  bun_version="$(mise_config '.tools.bun')"
}

@test "terminals run bun from mise at the configured version" {
  run -0 login_zsh 'print -r -- $commands[bun]; bun --version'
  assert_equal "${lines[0]}" "$HOME/.local/share/mise/installs/bun/$bun_version/bin/bun"
  assert_equal "${lines[1]}" "$bun_version"
}

@test "scripts and login bash run bun through mise's shims" {
  run -0 login_bash 'command -v bun; bun --version'
  assert_equal "${lines[0]}" "$HOME/.local/share/mise/shims/bun"
  assert_equal "${lines[1]}" "$bun_version"

  run -0 script_zsh 'whence -p bun'
  assert_equal "$output" "$HOME/.local/share/mise/shims/bun"
}

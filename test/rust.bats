#!/usr/bin/env bats
#
# lang.rust: Homebrew's rustup with a default toolchain and the configured components

load helper

# bats file_tags=lang:rust

setup() {
  require_linked .profile .zshenv .zshrc
}

@test "terminals get rustup and its proxies from Homebrew's rustup" {
  run -0 login_zsh 'print -rl -- $commands[rustup] $commands[cargo] $commands[rustc]'
  assert_same_file "${lines[0]}" "$HOMEBREW_PREFIX/opt/rustup/bin/rustup"
  assert_equal "${lines[1]}" "$HOMEBREW_PREFIX/opt/rustup/bin/cargo"
  assert_equal "${lines[2]}" "$HOMEBREW_PREFIX/opt/rustup/bin/rustc"
}

@test "the default toolchain has the configured components" {
  local component problems=''
  run -0 login_bash 'rustup component list --installed'
  for component in $(role_tasks rust '.[] | select(.name == "install components") | .loop[]'); do
    grep -q "^$component" <<< "$output" || problems+="$component"$'\n'
  done
  assert_none "$problems" 'not installed'
}

@test "cargo builds and runs a crate" {
  cd "$BATS_TEST_TMPDIR"
  run -0 login_zsh 'cargo new --quiet hello && cargo run --quiet --manifest-path hello/Cargo.toml'
  assert_equal "$output" 'Hello, world!'
}

@test "clippy and rust-analyzer run" {
  run -0 login_zsh 'cargo clippy --version && rust-analyzer --version'
}

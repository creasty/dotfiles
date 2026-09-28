#!/usr/bin/env bats
#
# rustup with a default toolchain and the configured components (nix/modules/rust.nix)

load helper

@test "terminals get rustup and its proxies from Nix" {
  run -0 login_zsh 'print -rl -- $commands[rustup] $commands[cargo] $commands[rustc]'
  assert_equal "${lines[0]}" "$PROFILE_BIN/rustup"
  assert_equal "${lines[1]}" "$PROFILE_BIN/cargo"
  assert_equal "${lines[2]}" "$PROFILE_BIN/rustc"
}

@test "the default toolchain has the configured components" {
  local component problems=''
  run -0 login_bash 'rustup component list --installed'
  for component in $(manifest '.rust.components[]'); do
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

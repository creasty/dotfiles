#!/usr/bin/env bats
#
# base.link: shells get the dotfiles' environment, however they're started

# `run` sets $output and $stderr for the helpers below
# shellcheck disable=SC2030,SC2031,SC2154

load helper

# bats file_tags=base:link

setup() {
  require_linked .profile .zshenv .zshrc .zsh .bash_profile .bashrc
}

starts_cleanly() {
  run --separate-stderr -0 "$1" exit
  assert_none "$output$stderr" "$1 printed"
}

@test "new terminals start without errors" {
  starts_cleanly login_zsh
}

@test "Neovim's terminal starts without errors" {
  starts_cleanly interactive_zsh
}

@test "zsh scripts start without errors" {
  starts_cleanly script_zsh
}

@test "login bash starts without errors" {
  starts_cleanly login_bash
}

@test "terminals load the plugins and completions" {
  run -0 login_zsh 'print ${+functions[_zsh_autosuggest_start]} ${+functions[_zsh_highlight]} ${+functions[compdef]}'
  assert_equal "$output" '1 1 1'
}

prefers_homebrew() {
  run -0 "$1" 'echo "$PATH"'
  assert_before "$output" "$HOMEBREW_PREFIX/bin" /usr/bin
}

@test "new terminals prefer Homebrew's commands to macOS's" {
  prefers_homebrew login_zsh
}

@test "Neovim's terminal prefers Homebrew's commands to macOS's" {
  prefers_homebrew interactive_zsh
}

@test "zsh scripts prefer Homebrew's commands to macOS's" {
  prefers_homebrew script_zsh
}

@test "login bash prefers Homebrew's commands to macOS's" {
  prefers_homebrew login_bash
}

@test "terminals find the dotfiles' commands" {
  run -0 login_zsh 'whence -p git-info'
  assert_same_file "$output" "$DOTFILES_PATH/bin/git-info"
}

@test "interactive shells start within the startup budget" {
  local budget="${DOTFILES_VERIFY_STARTUP_MS:-150}"
  # The median of 10 runs after 3 warm-up runs, like `hyperfine --warmup 3 'zsh -i -c exit'`
  run -0 pristine "$VERIFY_ZSH" -c '
    zmodload zsh/datetime zsh/mathfunc
    local -a ms
    local start
    repeat 13; do
      start=$EPOCHREALTIME
      $1 -i -c exit > /dev/null 2>&1
      ms+=( $(( int((EPOCHREALTIME - start) * 1000) )) )
    done
    ms=( ${(n)ms[4,-1]} )
    print $(( (ms[5] + ms[6]) / 2 ))
  ' zsh "$VERIFY_ZSH"
  echo "# zsh -i -c exit: ${output}ms (budget: ${budget}ms)" >&3
  [ "$output" -le "$budget" ]
}

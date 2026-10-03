#!/usr/bin/env bats
#
# Shells get the dotfiles' environment, however they're started (nix/modules/shell.nix)

# `run` sets $output and $stderr for the helpers below
# shellcheck disable=SC2030,SC2031,SC2154

load helper

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

# Nix's packages come first, then Homebrew's, then macOS's commands
prefers_nix() {
  run -0 "$1" 'echo "$PATH"'
  assert_before "$output" "$PROFILE_BIN" "$HOMEBREW_PREFIX/bin"
  assert_before "$output" "$HOMEBREW_PREFIX/bin" /usr/bin
}

@test "new terminals prefer Nix's commands to Homebrew's and macOS's" {
  prefers_nix login_zsh
}

@test "Neovim's terminal prefers Nix's commands to Homebrew's and macOS's" {
  prefers_nix interactive_zsh
}

@test "zsh scripts prefer Nix's commands to Homebrew's and macOS's" {
  prefers_nix script_zsh
}

@test "login bash prefers Nix's commands to Homebrew's and macOS's" {
  prefers_nix login_bash
}

# Claude Code runs its Bash tool in the shell CLAUDE_CODE_SHELL names (home/claude/settings.json), and silently in the
# login zsh when that isn't a bash or zsh that runs. Claude writes bash: zsh leaves an unquoted $var unsplit and fails
# on a glob that matches nothing. macOS's bash 3.2 lacks mapfile, ${var,,} and associative arrays.
@test "Claude Code runs commands in bash 4 or later" {
  local shell
  shell="$(yq -p json -o yaml '.env.CLAUDE_CODE_SHELL' "$HOME/.claude/settings.json")"
  assert_like "$shell" '*/bash'
  run -0 "$shell" -c 'echo "${BASH_VERSINFO[0]}"'
  [ "$output" -ge 4 ]
}

@test "terminals find the dotfiles' commands" {
  run -0 login_zsh 'whence -p git-info'
  assert_same_file "$output" "$DOTFILES_PATH/bin/git-info"
}

@test "interactive shells start within the startup budget" {
  local budget="${DOTFILES_VERIFY_STARTUP_MS:-150}"
  # The median of 10 runs after 3 warm-up runs, like `hyperfine --warmup 3 'zsh -i -c exit'` (without job control, as
  # login_zsh)
  run -0 pristine "$VERIFY_ZSH" -c '
    zmodload zsh/datetime zsh/mathfunc
    local -a ms
    local start
    repeat 13; do
      start=$EPOCHREALTIME
      $1 -i +m -c exit > /dev/null 2>&1
      ms+=( $(( int((EPOCHREALTIME - start) * 1000) )) )
    done
    ms=( ${(n)ms[4,-1]} )
    print $(( (ms[5] + ms[6]) / 2 ))
  ' zsh "$VERIFY_ZSH"
  echo "# zsh -i -c exit: ${output}ms (budget: ${budget}ms)" >&3
  [ "$output" -le "$budget" ]
}

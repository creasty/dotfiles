# shellcheck shell=bash
#
# Helpers for the tests of the commands in bin/ and the zsh config, which run them from this checkout, with fakes
# for what they'd reach outside the test's directory:
#
#   nix shell .#bats --command bats shell/tests

bats_require_minimum_version 1.8.0

# The checkout under test
DOTFILES_PATH="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

# The zsh plugins nix/modules/shell.nix pins: where the switch installs them, or where ./plugins did
: "${SHELL_TESTS_PLUGINS:=$HOME/.local/share/zsh/plugins}"

# macOS's zsh, the login shell (nix/modules/shell.nix)
LOGIN_ZSH=/bin/zsh

# Quotes a value to use it in a command line
q() {
  printf '%q' "$1"
}

#  Shells
#-----------------------------------------------
# Runs a command from the minimal environment launchd gives a new terminal, so that nothing leaks in from the
# environment running the tests
pristine() {
  env -i HOME="$HOME" USER="$(id -un)" LOGNAME="$(id -un)" SHELL="$LOGIN_ZSH" TERM=xterm-256color \
    TMPDIR="${TMPDIR:-/tmp}" PATH=/usr/bin:/bin:/usr/sbin:/sbin "$@"
}

# The home directory of the shells below, which they write their history and completion dump to. The shell files are
# linked as nix/modules/shell.nix links them, and the fakes come first on PATH.
zsh_home() {
  # Without links, as the shells' $PWD: zsh shows ~ for $HOME only where $PWD starts with it
  ZSH_HOME="$(cd "$BATS_TEST_TMPDIR" && pwd -P)/home"
  [ -d "$ZSH_HOME" ] && return
  mkdir -p "$ZSH_HOME/.local/share/zsh" "$BATS_TEST_TMPDIR/fakes"
  ln -s "$SHELL_TESTS_PLUGINS" "$ZSH_HOME/.local/share/zsh/plugins"
  ln -s "$DOTFILES_PATH" "$ZSH_HOME/dotfiles"
  local target source
  # ".zshrc" = "shell/zsh/zshrc";
  while IFS=$'\t' read -r target source; do
    ln -s "$DOTFILES_PATH/$source" "$ZSH_HOME/$target"
  done < <(sed -n -E 's/^ *"(\.[^"]+)" = "(shell\/[^"]+)";$/\1\t\2/p' "$DOTFILES_PATH/nix/modules/shell.nix")
}

# Runs a command in an interactive zsh in zsh_home, from that directory: zsh_run <command>
zsh_run() {
  zsh_home
  # From the home directory: mise asks whether to trust the config files of the directories above, the real home's
  (cd "$ZSH_HOME" && HOME="$ZSH_HOME" pristine "$LOGIN_ZSH" -i +m -c "path=($(q "$BATS_TEST_TMPDIR/fakes") \$path); $1")
}

# Starts a new terminal's zsh in zsh_home, from that directory, on a pty, types each argument into it a moment apart,
# and prints the command line it ends with, with a | at the cursor. The shell's directory then goes to
# $BATS_TEST_TMPDIR/pwd, the suggestion it shows after the line to $BATS_TEST_TMPDIR/suggestion, and what it printed to
# $BATS_TEST_TMPDIR/screen. $ZLE_ENV has assignments for the shell's environment.
zle_type() {
  local out="$BATS_TEST_TMPDIR"
  zsh_home
  rm -f "$out/line"
  # ~/.zlogin, which the switch doesn't link, is read last, and leaves nothing in the history
  cat > "$ZSH_HOME/.zlogin" <<EOF
path=($(q "$out/fakes") \$path)
_zle_dump() {
  print -rn -- "\$LBUFFER|\$RBUFFER" > $(q "$out/line")
  print -rn -- "\$POSTDISPLAY" > $(q "$out/suggestion")
  print -rn -- "\$PWD" > $(q "$out/pwd")
}
zle -N _zle_dump
bindkey '\e[24~' _zle_dump
EOF
  # shellcheck disable=SC2086 # assignments, split on spaces
  (cd "$ZSH_HOME" && HOME="$ZSH_HOME" pristine env ${ZLE_ENV:-} "$LOGIN_ZSH" -f "$BATS_TEST_DIRNAME/zle.zsh" "$out" "$@") ||
    return
  cat "$out/line"
}

#  Fakes
#-----------------------------------------------
# Puts a command first on the PATH of the commands a test runs, which logs each call as a line of
# $BATS_TEST_TMPDIR/calls, its name and arguments (in single quotes where they have spaces or quotes), then runs the
# given bash script with them: fake <name> [<script>]
fake() {
  local dir="$BATS_TEST_TMPDIR/fakes"
  mkdir -p "$dir"
  {
    echo '#!/usr/bin/env bash'
    printf 'calls=%q name=%q\n' "$BATS_TEST_TMPDIR/calls" "$1"
    cat <<'EOF'
line="$name"
for arg; do
  [[ $arg =~ ^[^[:space:]\'\"]+$ ]] || arg="'${arg//\'/\'\\\'\'}'"
  line+=" $arg"
done
echo "$line" >> "$calls"
EOF
    echo "${2:-}"
  } > "$dir/$1"
  chmod +x "$dir/$1"
}

# The calls the fakes logged, a line each
calls() {
  cat "$BATS_TEST_TMPDIR/calls" 2> /dev/null || true
}

#  Assertions
#-----------------------------------------------
assert_equal() {
  [[ $1 == "$2" ]] && return
  printf 'expected: %s\nactual:   %s\n' "$2" "$1" >&2
  return 1
}

assert_like() {
  # shellcheck disable=SC2053
  [[ $1 == $2 ]] && return
  printf 'expected like: %s\nactual:        %s\n' "$2" "$1" >&2
  return 1
}

# Asserts that $output (set by `run`) has the given line
# shellcheck disable=SC2154
assert_line() {
  grep -qxF -- "$1" <<< "$output" && return
  printf 'expected a line: %s\nin:\n%s\n' "$1" "$output" >&2
  return 1
}

# Asserts that a newline separated list of problems is empty: assert_none <problems> [heading]
assert_none() {
  [ -z "$1" ] && return
  printf '%s:\n%s\n' "${2:-problems}" "$1" >&2
  return 1
}

# shellcheck shell=bash
#
# Helpers for the behavioral tests that ../../verify runs.
# Tests run on macOS's bash 3.2: no associative arrays, mapfile, ${var,,} or negative indices.

bats_require_minimum_version 1.8.0

: "${DOTFILES_PATH:="$HOME/dotfiles"}"
: "${HOMEBREW_PREFIX:=/opt/homebrew}"

# What the activated configuration set up (nix/modules/verify.nix)
MANIFEST=/etc/dotfiles/manifest.json

# Where the commands of the packages installed with Nix are
# shellcheck disable=SC2034 # used by the tests
PROFILE_BIN="/etc/profiles/per-user/$(id -un)/bin"

#  Benchmarks
#-----------------------------------------------
# A test tagged bench measures against a budget, which a busy machine misses: `./verify --bench` runs the benchmarks
# alone, and other runs skip them. A file's own setup() replaces this one.
setup() {
  if [[ " ${BATS_TEST_TAGS[*]-} " == *' bench '* && -z ${VERIFY_BENCH:-} ]]; then
    skip 'a benchmark, which ./verify --bench runs alone'
  fi
}

#  Shells
#-----------------------------------------------
# The zsh new terminals start: the login shell
if [ -z "${VERIFY_ZSH:-}" ]; then
  VERIFY_ZSH="$(dscl . -read "/Users/$(id -un)" UserShell 2> /dev/null | awk '{ print $2 }' || true)"
  [[ $VERIFY_ZSH == */zsh ]] || VERIFY_ZSH="$(command -v zsh)"
fi

# Runs a command from the minimal environment launchd gives a new terminal, so that nothing leaks in
# from the environment running the tests (e.g. the CI runner's own PATH and JAVA_HOME)
pristine() {
  env -i HOME="$HOME" USER="$(id -un)" LOGNAME="$(id -un)" SHELL="$VERIFY_ZSH" TERM=xterm-256color \
    TMPDIR="${TMPDIR:-/tmp}" PATH=/usr/bin:/bin:/usr/sbin:/sbin "$@"
}

# A new terminal tab or pane: an interactive login shell. Without job control (+m), as on CI, where there's no
# terminal: an interactive zsh with job control takes over the terminal, and C-c would interrupt its command instead
# of ./verify.
login_zsh() {
  pristine "$VERIFY_ZSH" -il +m -c "$1"
}

# Neovim's :terminal: an interactive shell that isn't a login shell (without job control, as above)
interactive_zsh() {
  pristine "$VERIFY_ZSH" -i +m -c "$1"
}

# Scripts, and programs that run commands (e.g. kitty starting nvim): a non-interactive shell
script_zsh() {
  pristine "$VERIFY_ZSH" -c "$1"
}

# Programs that take the environment of a login shell, like the switch's own tasks
login_bash() {
  pristine /bin/bash -lc "$1"
}

# Quotes a value to use it in a command line
q() {
  printf '%q' "$1"
}

#  Shells in a home of their own
#-----------------------------------------------
# The home directory of the shells below, which they write their history and completion dump to. The shell files are
# linked as the switch links them, the zsh plugins are the switch's, and the fakes come first on PATH.
zsh_home() {
  # Without links, as the shells' $PWD: zsh shows ~ for $HOME only where $PWD starts with it
  ZSH_HOME="$(cd "$BATS_TEST_TMPDIR" && pwd -P)/home"
  [ -d "$ZSH_HOME" ] && return
  mkdir -p "$ZSH_HOME/.local/share/zsh" "$BATS_TEST_TMPDIR/fakes"
  ln -s "$HOME/.local/share/zsh/plugins" "$ZSH_HOME/.local/share/zsh/plugins"
  ln -s "$DOTFILES_PATH" "$ZSH_HOME/dotfiles"
  local target source
  while IFS=$'\t' read -r target source; do
    ln -s "$DOTFILES_PATH/$source" "$ZSH_HOME/$target"
  done < <(manifest '.links | to_entries | .[] | select(.value == "shell/*") | [.key, .value] | @tsv')
}

# Runs a command in an interactive zsh in zsh_home, from that directory: zsh_run <command>
zsh_run() {
  zsh_home
  # From the home directory: mise asks whether to trust the config files of the directories above, the real home's
  (cd "$ZSH_HOME" && HOME="$ZSH_HOME" pristine "$VERIFY_ZSH" -i +m -c "path=($(q "$BATS_TEST_TMPDIR/fakes") \$path); $1")
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
  (cd "$ZSH_HOME" && HOME="$ZSH_HOME" pristine env ${ZLE_ENV:-} "$VERIFY_ZSH" -f "$BATS_TEST_DIRNAME/zle.zsh" "$out" "$@") ||
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

#  Configuration
#-----------------------------------------------
# Queries the manifest with yq
manifest() {
  yq -p json "$1" "$MANIFEST"
}

# Queries config/mise/config.toml with yq
mise_config() {
  yq -p toml -o yaml "$1" "$DOTFILES_PATH/config/mise/config.toml"
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

assert_same_file() {
  [[ -n $1 && $1 -ef $2 ]] && return
  printf 'expected: %s\nactual:   %s\n' "$2" "$1" >&2
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

# Asserts that a directory comes before another one in a PATH: assert_before <path> <dir> <other dir>
assert_before() {
  local IFS=: dir i=0 first=0 second=0
  for dir in $1; do
    i=$((i + 1))
    if [ "$dir" = "$2" ] && [ "$first" -eq 0 ]; then first=$i; fi
    if [ "$dir" = "$3" ] && [ "$second" -eq 0 ]; then second=$i; fi
  done
  if [ "$first" -gt 0 ] && { [ "$second" -eq 0 ] || [ "$first" -lt "$second" ]; }; then
    return
  fi
  printf 'expected %s before %s in:\n' "$2" "$3" >&2
  tr : '\n' <<< "$1" >&2
  return 1
}

# Asserts that the given Homebrew formulae are installed, by name or alias
assert_formulae() {
  local name missing=''
  for name in "$@"; do
    brew list --formula --versions "$name" > /dev/null 2>&1 || missing+="$name"$'\n'
  done
  assert_none "$missing" 'not installed'
}

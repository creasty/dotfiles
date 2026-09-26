# shellcheck shell=bash
#
# Helpers for the behavioral tests that ../verify runs.
# Tests run on macOS's bash 3.2: no associative arrays, mapfile, ${var,,} or negative indices.

bats_require_minimum_version 1.8.0

: "${DOTFILES_PATH:="$HOME/dotfiles"}"
: "${HOMEBREW_PREFIX:=/opt/homebrew}"

#  Shells
#-----------------------------------------------
# The zsh new terminals start: the login shell (Homebrew's once system.zsh has run)
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

# A new terminal tab or tmux pane: an interactive login shell
login_zsh() {
  pristine "$VERIFY_ZSH" -il -c "$1"
}

# Neovim's :terminal: an interactive shell that isn't a login shell
interactive_zsh() {
  pristine "$VERIFY_ZSH" -i -c "$1"
}

# Scripts, and programs that run commands (e.g. kitty starting nvim): a non-interactive shell
script_zsh() {
  pristine "$VERIFY_ZSH" -c "$1"
}

# Programs that take the environment of a login shell, like the provisioning's own tasks
login_bash() {
  pristine /bin/bash -lc "$1"
}

# Quotes a value to use it in a command line
q() {
  printf '%q' "$1"
}

#  Configuration
#-----------------------------------------------
# Queries provisioning/config.yml with yq
config() {
  yq "$1" "$DOTFILES_PATH/provisioning/config.yml"
}

# Queries config/mise/config.toml with yq
mise_config() {
  yq -p toml -o yaml "$1" "$DOTFILES_PATH/config/mise/config.toml"
}

# Queries a task file of a role with yq: role_tasks <role> <query> [file]
role_tasks() {
  yq "$2" "$DOTFILES_PATH/provisioning/roles/$1/tasks/${3:-main}.yml"
}

# Prints the Homebrew formulae a role installs by name
role_formulae() {
  role_tasks "$1" '.[] | .["community.general.homebrew"].name | .. | select(tag == "!!str") | select(contains("{{") | not)'
}

#  Prerequisites
#-----------------------------------------------
# Skips the test unless the files it relies on are linked (base.link)
require_linked() {
  local dest
  for dest in "$@"; do
    [ -L "$HOME/$dest" ] || skip "$dest is not linked into the home directory (base.link)"
  done
}

# Skips the test unless the commands it relies on are installed with Homebrew
require_commands() {
  local cmd
  for cmd in "$@"; do
    [ -x "$HOMEBREW_PREFIX/bin/$cmd" ] || skip "$cmd is not installed"
  done
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

# Asserts that the given Homebrew formulae are installed
assert_formulae() {
  local installed name missing=''
  installed="$(brew list --formula --full-name)"
  for name in "$@"; do
    grep -qxF -- "$name" <<< "$installed" || missing+="$name"$'\n'
  done
  assert_none "$missing" 'not installed'
}

# Reload config
reload() {
  exec zsh -l
  [ -n "$TMUX" ] && tmux source-file ~/.tmux.conf
}

# Move to project root
cdrt() {
  if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    cd `git rev-parse --show-toplevel`
  fi
}

# Make a directory and cd there
mkd() {
  mkdir -p "$@" && cd "$@"
}

# Tmux: kill all non-attached sessions
tmk() {
  tmux ls \
    | grep -v attached \
    | cut -d: -f 1 \
    | xargs -n 1 tmux kill-session -t
}

# Load .env
load-env() {
  local envchain_ns="${1:-}"

  set -o allexport
  [ -r .env ] && source .env
  [ -n "$envchain_ns" ] && envchain -l -v "$envchain_ns"
  set +o allexport
}

# which + edit
whiche() {
  local file="$(which $1)"
  if [ -f "$file" ]; then
    vim "$file"
  else
    echo "$file"
  fi
}

# which + stat
whichs() {
  ls -la "$(which $1)"
}

# Open Xcode project file
openx() {
  if [ -n "$(find . -maxdepth 1 -name '*.xcworkspace' -print -quit)" ]; then
    echo 'Opening workspace...'
    open *.xcworkspace
  elif [ -n "$(find . -maxdepth 1 -name '*.xcodeproj' -print -quit)" ]; then
    echo 'Opening project...'
    open *.xcodeproj
  else
    echo 'Nothing found'
    exit 1
  fi
}

# Concat ssh configs
ssh() {
  cat ~/.ssh/config.d/* > ~/.ssh/config
  [ $# -gt 0 ] && command ssh "$@"
}

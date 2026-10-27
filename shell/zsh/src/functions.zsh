# Reload config
reload() {
  exec zsh -l
}

# Move to project root
cdrt() {
  if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    cd "$(git rev-parse --show-toplevel)"
  fi
}

# Make a directory and cd there
mkd() {
  mkdir -p "$@" && cd "$@"
}

# Load .env, then the variables of an envchain namespace if given
load-env() {
  local envchain_ns="${1:-}"

  set -o allexport
  [ -r .env ] && source .env
  set +o allexport

  if [ -n "$envchain_ns" ]; then
    local var
    envchain -l -v "$envchain_ns" | while IFS= read -r var; do
      export "$var"
    done
  fi
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
    return 1
  fi
}

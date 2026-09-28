#!/usr/bin/env bats
#
# The taps, formulae and casks of nix/modules/*.nix are installed with Homebrew

load helper

@test "configured taps are tapped and trusted" {
  local tapped trusted tap problems=''
  tapped="$(brew tap)"
  trusted="$(brew trust --json v1 | yq -p json '.taps[]')"
  while read -r tap; do
    grep -qxiF -- "$tap" <<< "$tapped" || problems+="$tap is not tapped"$'\n'
    grep -qxiF -- "$tap" <<< "$trusted" || problems+="$tap is not trusted"$'\n'
  done < <(manifest '.homebrew.taps[]')
  assert_none "$problems"
}

@test "configured formulae are installed" {
  # shellcheck disable=SC2046
  assert_formulae $(manifest '.homebrew.brews[]')
}

# Succeeds when the apps of a cask are in /Applications, even though Homebrew didn't install them
has_external_apps() {
  local apps app
  apps="$(brew info --cask --json=v2 "$1" | yq -p json '.casks[].artifacts[] | select(has("app")) | .app[] | select(tag == "!!str")')" || return
  [ -n "$apps" ] || return
  while IFS= read -r app; do
    [ -d "/Applications/$app" ] || return
  done <<< "$apps"
}

@test "configured casks are installed" {
  local installed cask problems=''
  installed="$(brew list --cask --full-name)"
  while read -r cask; do
    grep -qxF -- "$cask" <<< "$installed" && continue
    # brew bundle skips apps that were installed without Homebrew
    has_external_apps "$cask" 2> /dev/null && continue
    problems+="$cask"$'\n'
  done < <(manifest '.homebrew.casks[]')
  assert_none "$problems" 'not installed'
}

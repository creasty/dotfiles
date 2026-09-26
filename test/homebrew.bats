#!/usr/bin/env bats
#
# install.homebrew: the configured taps, formulae and casks are installed

load helper

# bats test_tags=install:homebrew:tap
@test "configured taps are tapped and trusted" {
  local tapped trusted tap problems=''
  tapped="$(brew tap)"
  trusted="$(brew trust --json v1 | yq -p json '.taps[]')"
  while read -r tap; do
    grep -qxiF -- "$tap" <<< "$tapped" || problems+="$tap is not tapped"$'\n'
    grep -qxiF -- "$tap" <<< "$trusted" || problems+="$tap is not trusted"$'\n'
  done < <(config '.homebrew.taps[]')
  assert_none "$problems"
}

# bats test_tags=install:homebrew:formula
@test "configured formulae are installed" {
  # shellcheck disable=SC2046
  assert_formulae $(config '.homebrew.formulas[]')
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

# bats test_tags=install:homebrew:cask
@test "configured casks are installed" {
  local installed cask problems=''
  installed="$(brew list --cask --full-name)"
  while read -r cask; do
    case " ${DOTFILES_VERIFY_SKIP_CASKS:-} " in *" $cask "*) continue ;; esac
    grep -qxF -- "$cask" <<< "$installed" && continue
    # The provisioning accepts apps installed without Homebrew (accept_external_apps)
    has_external_apps "$cask" 2> /dev/null && continue
    problems+="$cask"$'\n'
  done < <(config '.homebrew.casks[]')
  assert_none "$problems" 'not installed'
}

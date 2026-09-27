#!/usr/bin/env bats
#
# The App Store apps of nix/modules/appstore.nix, which brew bundle installs with mas

load helper

@test "the App Store has the configured apps" {
  local id name out problems=''
  while read -r id name; do
    out="$(mas lookup "$id" 2>&1)" || problems+="$id $name: $(tail -n 1 <<< "$out")"$'\n'
  done < <(manifest '.appStore.apps[]')
  assert_none "$problems" 'not found in the App Store'
}

@test "the configured App Store apps are installed" {
  [ "$(manifest '.appStore.install')" = true ] || skip 'this configuration has no Apple Account to install them with'
  local installed id name problems=''
  installed="$(mas list | awk '{ print $1 }')"
  while read -r id name; do
    grep -qxF -- "$id" <<< "$installed" || problems+="$id $name"$'\n'
  done < <(manifest '.appStore.apps[]')
  assert_none "$problems" 'not installed'
}

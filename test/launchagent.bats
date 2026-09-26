#!/usr/bin/env bats
#
# system.launchagent: the launch agents of config/launchagent are installed and loaded

load helper

# bats file_tags=system:launchagent

@test "launch agents are installed and loaded" {
  local plist label problems=''
  for plist in "$DOTFILES_PATH"/config/launchagent/*.plist; do
    [ -e "$plist" ] || skip 'no launch agents configured'
    label="$(plutil -extract Label raw "$plist")"
    cmp -s "$plist" "$HOME/Library/LaunchAgents/${plist##*/}" || problems+="$label is not installed"$'\n'
    launchctl list "$label" > /dev/null 2>&1 || problems+="$label is not loaded"$'\n'
  done
  assert_none "$problems"
}

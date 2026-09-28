#!/usr/bin/env bats
#
# Docker Desktop, with its command-line tools in /usr/local/bin (nix/modules/docker.nix)

load helper

SETTINGS="$HOME/Library/Group Containers/group.com.docker/settings-store.json"

@test "Docker Desktop has the configured settings" {
  local key problems=''
  for key in $(manifest '.docker.settings | keys | .[]'); do
    [ "$(yq -p json ".$key" "$SETTINGS")" = "$(manifest ".docker.settings.$key")" ] || problems+="$key"$'\n'
  done
  # Provisioning only sets them before Docker Desktop's first start
  assert_none "$problems" "not as configured: change them in Docker Desktop's settings"
}

# In "User" mode, Docker Desktop adds ~/.docker/bin to PATH at the top of the shell files, on every start
@test "the shell files have no section Docker Desktop added" {
  run -1 grep -rl 'added by Docker Desktop' "$DOTFILES_PATH/shell"
}

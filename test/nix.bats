#!/usr/bin/env bats
#
# The packages of nix/modules/*.nix are installed with Nix, and shells find them first

load helper

@test "the packages' commands come from Nix" {
  local commands name path problems=''
  commands="$(manifest '.commands[]' | tr '\n' ' ')"
  run -0 login_zsh "for name in $commands; do print -r -- \"\$name \${commands[\$name]:-}\"; done"
  while read -r name path; do
    [ "$path" = "$PROFILE_BIN/$name" ] || problems+="$name: ${path:-not found}"$'\n'
  done <<< "$output"
  assert_none "$problems" 'not from Nix'
}

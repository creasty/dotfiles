#!/usr/bin/env bats
#
# macOS preferences (nix/modules/macos.nix)

load helper

# Prints the configured defaults as `domain<TAB>key<TAB>type<TAB>value`
configured_defaults() {
  manifest '.defaults | to_entries | .[] | .key as $domain | .value | to_entries | .[] | [$domain, .key, (.value | tag), .value] | @tsv'
}

@test "macOS defaults are applied" {
  local domain key type value actual problems=''
  while IFS=$'\t' read -r domain key type value; do
    if ! actual="$(defaults read "$domain" "$key" 2>&1)"; then
      problems+="$domain $key: not set"$'\n'
      continue
    fi
    # `defaults read` prints booleans as 1/0 and floats in their shortest form (3.0 as 3)
    if [ "$type" = '!!bool' ]; then
      if [ "$value" = true ]; then value=1; else value=0; fi
    elif [ "$type" = '!!float' ] && awk -v a="$actual" -v e="$value" 'BEGIN { exit !(a - e < 1e-9 && e - a < 1e-9) }'; then
      actual="$value"
    fi
    [ "$actual" = "$value" ] || problems+="$domain $key: $actual (expected $value)"$'\n'
  done < <(configured_defaults)
  assert_none "$problems" 'unexpected defaults'
}

# The shortcuts of System Settings > Keyboard > Keyboard Shortcuts, which the switch adds to the user's
@test "keyboard shortcuts are set" {
  local shortcuts id expected actual problems=''
  shortcuts="$(defaults export com.apple.symbolichotkeys - | plutil -convert json -o - -)"
  while read -r id; do
    expected="$(manifest ".hotKeys[\"$id\"] | sort_keys(..) | @json")"
    actual="$(yq -p json ".AppleSymbolicHotKeys[\"$id\"] | sort_keys(..) | @json" <<< "$shortcuts")"
    [ "$actual" = "$expected" ] || problems+="$id: $actual (expected $expected)"$'\n'
  done < <(manifest '.hotKeys | keys | .[]')
  assert_none "$problems" 'unexpected shortcuts'
}

# The shortcuts the session uses, which the switch has it take up: the window server's, through its private calls
@test "keyboard shortcuts are live" {
  local reader="$BATS_TEST_TMPDIR/hotkeys" id expected actual problems=''
  cc -framework CoreGraphics -x c -o "$reader" - << 'EOF'
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
int32_t CGSGetSymbolicHotKeyValue(int, uint16_t *, uint16_t *, uint32_t *);
bool CGSIsSymbolicHotKeyEnabled(int);
// Prints the shortcut of the ID as an entry of AppleSymbolicHotKeys
int main(int argc, char **argv) {
  int id = atoi(argv[1]);
  uint16_t character, code;
  uint32_t flags;
  if (!CGSIsSymbolicHotKeyEnabled(id)) return puts("{\"enabled\":false}") < 0;
  if (CGSGetSymbolicHotKeyValue(id, &character, &code, &flags) != 0) return 1;
  printf("{\"enabled\":true,\"value\":{\"parameters\":[%u,%u,%u],\"type\":\"standard\"}}\n", character, code, flags);
}
EOF
  while read -r id; do
    expected="$(manifest ".hotKeys[\"$id\"] | sort_keys(..) | @json")"
    actual="$("$reader" "$id" | yq -p json 'sort_keys(..) | @json')"
    [ "$actual" = "$expected" ] || problems+="$id: $actual (expected $expected)"$'\n'
  done < <(manifest '.hotKeys | keys | .[]')
  assert_none "$problems" 'shortcuts not live'
}

# The apps the switch assigns to All Desktops, among the user's assignments to Spaces
@test "apps show on every Space" {
  local bindings id problems=''
  bindings="$(defaults export com.apple.spaces - | plutil -convert json -o - -)"
  while read -r id; do
    [ "$(yq -p json ".[\"app-bindings\"][\"$id\"]" <<< "$bindings")" = AllSpaces ] || problems+="$id"$'\n'
  done < <(manifest '.allDesktops[]')
  assert_none "$problems" 'not on every Space'
}

# On every keyboard: nix-darwin maps it with hidutil
@test "Caps Lock is Control" {
  run -0 hidutil property --get UserKeyMapping
  # Caps Lock (0x700000039) to left Control (0x7000000E0)
  assert_like "$(tr -d '[:space:]' <<< "$output")" \
    '*{HIDKeyboardModifierMappingDst=30064771296;HIDKeyboardModifierMappingSrc=30064771129;}*'
}

@test "the Library folder is visible in Finder" {
  run -0 ls -ldO "$HOME/Library"
  [[ $output != *hidden* ]]
}

@test "the startup chime is muted" {
  run -0 nvram StartupMute
  assert_like "$output" 'StartupMute*%01'
}

# nix/modules/default.nix
@test "sudo accepts Touch ID" {
  grep -qE '^auth[[:space:]]+include[[:space:]]+sudo_local' /etc/pam.d/sudo
  run -0 awk '$1 == "auth" { print $3 }' /etc/pam.d/sudo_local
  assert_equal "$output" pam_tid.so
}

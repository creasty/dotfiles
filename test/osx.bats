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

@test "the Library folder is visible in Finder" {
  run -0 ls -ldO "$HOME/Library"
  [[ $output != *hidden* ]]
}

@test "the startup chime is muted" {
  run -0 nvram StartupMute
  assert_like "$output" 'StartupMute*%01'
}

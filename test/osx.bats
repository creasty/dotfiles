#!/usr/bin/env bats
#
# system.osx: macOS preferences

load helper

# bats file_tags=system:osx

# Prints the defaults the role writes as `domain<TAB>key<TAB>type<TAB>value`, the last write of a key winning
configured_defaults() {
  role_tasks osx '
    [.[] | select(has("community.general.osx_defaults") and (has("when") | not)) | .["community.general.osx_defaults"]]
    | group_by(.domain + " " + .key) | .[] | .[-1]
    | [.domain, .key, .type, .value] | @tsv
  ' defaults
}

@test "macOS defaults are applied" {
  local domain key type value actual problems=''
  while IFS=$'\t' read -r domain key type value; do
    value="${value//\{\{ home_path \}\}/$HOME}"
    if ! actual="$(defaults read "$domain" "$key" 2>&1)"; then
      problems+="$domain $key: not set"$'\n'
      continue
    fi
    # `defaults read` prints booleans as 1/0 and floats in their shortest form (3.0 as 3)
    if [ "$type" = bool ]; then
      if [ "$value" = true ]; then value=1; else value=0; fi
    elif [ "$type" = float ] && awk -v a="$actual" -v e="$value" 'BEGIN { exit !(a - e < 1e-9 && e - a < 1e-9) }'; then
      actual="$value"
    fi
    [ "$actual" = "$value" ] || problems+="$domain $key: $actual (expected $value)"$'\n'
  done < <(configured_defaults)
  assert_none "$problems" 'unexpected defaults'
}

@test "~/Library is visible in Finder" {
  run -0 ls -ldO "$HOME/Library"
  [[ $output != *hidden* ]]
}

@test "the startup chime is muted" {
  run -0 nvram StartupMute
  assert_like "$output" 'StartupMute*%01'
}

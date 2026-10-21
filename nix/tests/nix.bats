#!/usr/bin/env bats
#
# The packages of nix/modules/*.nix are installed with Nix, and shells find them first, in front of macOS's commands of
# the same names only where meant

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

# The commands of macOS's that Nix's hide on purpose: newer releases of the same tools, universal-ctags for BSD's ctags,
# and nix-darwin's shells (its sh is bash in POSIX mode, as macOS's is). A package can bring commands besides the one
# it's for (e.g. gawk's awk), which would change what scripts written for macOS do.
HIDDEN_MACOS_COMMANDS=(bash bashbug clangd ctags curl expect git git-receive-pack git-shell git-upload-archive
  git-upload-pack jq sh zsh)

@test "Nix's commands hide macOS's only where meant" {
  local command dir name problems=''
  for command in "$PROFILE_BIN"/* /run/current-system/sw/bin/*; do
    name="${command##*/}"
    [[ " ${HIDDEN_MACOS_COMMANDS[*]} " == *" $name "* ]] && continue
    for dir in /usr/bin /bin /usr/sbin /sbin; do
      [ ! -e "$dir/$name" ] || problems+="$dir/$name: by $(readlink -f "$command")"$'\n'
    done
  done
  assert_none "$problems" 'hidden by Nix'
}

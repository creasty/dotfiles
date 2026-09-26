#!/usr/bin/env bats
#
# zsh is the login shell, set up by nix-darwin and the dotfiles (nix/modules/shell.nix)

load helper

@test "the login shell is zsh" {
  run -0 dscl . -read "/Users/$(id -un)" UserShell
  assert_like "$output" 'UserShell: */zsh'
}

@test "zsh gets nix-darwin's environment" {
  run -0 login_zsh 'print -r -- ${__NIX_DARWIN_SET_ENVIRONMENT_DONE:-}'
  assert_equal "$output" 1
}

@test "zsh plugins come from Nix" {
  local plugin problems=''
  for plugin in zsh-autosuggestions fast-syntax-highlighting; do
    [[ "$(cd "$HOME/.local/share/zsh/plugins/$plugin" && pwd -P)" == /nix/store/* ]] || problems+="$plugin"$'\n'
  done
  assert_none "$problems" 'not from the Nix store'
}

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

@test "Neovim's terminal's zsh asks for bracketed paste at its prompt, which keeps a pasted line from running" {
  # (on a pty, as zle runs only there: zsh -c starts none)
  run -0 pristine "$VERIFY_ZSH" -fc '
    zmodload zsh/zpty
    zpty shell ${(q)1} -i +m
    local out chunk
    repeat 100; do
      zpty -rt shell chunk && out+=$chunk || sleep 0.1
      if [[ $out == *"$2"* ]]; then
        zpty -d shell
        exit
      fi
    done
    print -r -- "the prompt never asked for it: ${(V)out}"
    exit 1
  ' zsh "$VERIFY_ZSH" "$(printf '\033[?2004h')"
}

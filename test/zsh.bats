#!/usr/bin/env bats
#
# system.zsh: Homebrew's zsh is the login shell, with the plugins checked out

load helper

# bats file_tags=system:zsh

@test "Homebrew's zsh is the login shell" {
  # shellcheck disable=SC2046
  assert_formulae $(role_formulae zsh)
  run -0 dscl . -read "/Users/$(id -un)" UserShell
  assert_equal "$output" "UserShell: $HOMEBREW_PREFIX/bin/zsh"
  grep -qxF -- "$HOMEBREW_PREFIX/bin/zsh" /etc/shells
}

@test "/etc/zshenv doesn't get in the way of the dotfiles" {
  [ ! -e /etc/zshenv ]
}

@test "zsh plugins are checked out at the pinned commits" {
  run -0 git -C "$DOTFILES_PATH" submodule status
  # a prefix of `-`, `+` or `U` means not checked out, at another commit, or conflicted
  assert_none "$(grep -v '^ ' <<< "$output" || true)" 'not at the pinned commit'
}

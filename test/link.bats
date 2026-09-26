#!/usr/bin/env bats
#
# The dotfiles are linked into the home directory (nix/modules/links.nix), and the tools pick them up

load helper

@test "the home directory links into the dotfiles" {
  local target source problems=''
  while IFS=$'\t' read -r target source; do
    [[ -L $HOME/$target && $HOME/$target -ef $DOTFILES_PATH/$source ]] || problems+="$target -> $source"$'\n'
  done < <(manifest '.links | to_entries | .[] | [.key, .value] | @tsv')
  assert_none "$problems" 'not linked'
}

@test "git reads its config from the dotfiles" {
  local tab=$'\t'
  # Not `--global`, which reads ~/.config/git/config only when there's no ~/.gitconfig
  cd "$BATS_TEST_TMPDIR"
  run -0 login_zsh 'git config --show-origin --get core.editor'
  # file:/Users/me/.config/git/config	nvim
  local origin="${output%%"$tab"*}"
  assert_same_file "${origin#file:}" "$DOTFILES_PATH/config/git/config"
  assert_equal "${output#*"$tab"}" nvim
}

@test "git ignores the files the dotfiles ignore globally" {
  cd "$BATS_TEST_TMPDIR"
  git init --quiet
  touch .DS_Store
  run -0 login_zsh 'git check-ignore --verbose .DS_Store'
  # /Users/me/.config/git/ignore:1:.DS_Store	.DS_Store
  assert_same_file "${output%%:*}" "$DOTFILES_PATH/config/git/ignore"
}

@test "ripgrep reads its config from the dotfiles" {
  cd "$BATS_TEST_TMPDIR"
  echo needle > .hidden
  # `command`: skip the interactive wrapper function; hidden files are searched due to `--hidden`
  run -0 login_zsh 'command rg --files-with-matches needle .'
  assert_equal "$output" ./.hidden
}

@test "tmux accepts the config" {
  run -0 login_zsh 'tmux -L verify -f /dev/null start-server \; source-file -n ~/.config/tmux/tmux.conf'
  assert_equal "$output" ''
}

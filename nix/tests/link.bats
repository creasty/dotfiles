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

@test "ctags reads its config from the dotfiles" {
  local tab=$'\t'
  cd "$BATS_TEST_TMPDIR"
  mkdir node_modules
  echo 'type Query { me: User }' > schema.graphql
  echo 'type Hidden { me: User }' > node_modules/schema.graphql
  echo '{ "name": "app" }' > package.json
  # Recursing into the directory, GraphQL, and skipping node_modules and JSON are the config's, which Universal Ctags
  # reads from ~/.config/ctags. Warnings about it would be extra lines.
  run -0 login_zsh 'ctags -f -'
  assert_equal "${#lines[@]}" 1
  assert_like "${lines[0]}" "Query${tab}schema.graphql${tab}*${tab}language:graphql"
}

@test "Codebook reads its config from the dotfiles" {
  cd "$BATS_TEST_TMPDIR"
  # One of your words, a word under 4 letters and a possessive pass by the config; the misspelling doesn't
  printf '%s\n' creasty qwx "zzyzx's" qwxz > words.txt
  run -1 login_zsh 'codebook-lsp lint words.txt'
  # using global config /Users/me/.config/codebook/codebook.toml
  assert_same_file "${lines[0]#using global config }" "$DOTFILES_PATH/config/codebook/codebook.toml"
  assert_like "$output" '*words.txt:4:1*qwxz*'
  assert_line 'Found 1 spelling error(s) in 1 file(s).'
}

# kitty has no command to check a config: its loader reports the options it doesn't know, but not values or actions
@test "kitty accepts the config, and reads it from the dotfiles" {
  assert_same_file ~/.config/kitty/kitty.conf "$DOTFILES_PATH/config/kitty/kitty.conf"
  run -0 pristine /Applications/kitty.app/Contents/MacOS/kitty +runpy \
    'import sys; from kitty.config import load_config; print(load_config(sys.argv[-1]).shell)' \
    ~/.config/kitty/kitty.conf
  assert_equal "$output" "/bin/zsh -c 'exec nvim'"
}

# Provisioning installs these commands with Nix, not Homebrew: a path to Homebrew's copy finds nothing
@test "configs don't run Homebrew's copies of the commands Nix provides" {
  local commands file path problems=''
  commands="$(manifest '.commands[]')"
  while IFS=: read -r file path; do
    if grep -qxF -- "${path##*/}" <<< "$commands"; then
      problems+="${file#"$DOTFILES_PATH/"}: $path"$'\n'
    fi
  done < <(grep -rEo '/opt/homebrew/bin/[A-Za-z0-9._+-]+' "$DOTFILES_PATH"/{config,home,nvim,shell,vscode})
  assert_none "$problems" 'Homebrew paths of commands from Nix'
}

#!/usr/bin/env bats
#
# app.vim: Neovim, dein.vim and the tools the config relies on

load helper

# bats file_tags=app:vim

@test "Neovim and the language tools are installed" {
  # shellcheck disable=SC2046
  assert_formulae $(role_formulae vim)
}

@test "Neovim runs" {
  run -0 "$HOMEBREW_PREFIX/bin/nvim" --headless -u NONE -i NONE +quit
}

@test "dein.vim is installed" {
  [ -f "$DOTFILES_PATH/nvim/dein/repos/github.com/Shougo/dein.vim/autoload/dein.vim" ]
}

@test "the clangd that coc.nvim is configured with runs" {
  local clangd
  clangd="$(sed -n 's/.*"clangd\.path": *"\([^"]*\)".*/\1/p' "$DOTFILES_PATH/nvim/coc-settings.json")"
  run -0 "$clangd" --version
}

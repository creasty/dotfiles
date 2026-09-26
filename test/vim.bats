#!/usr/bin/env bats
#
# Neovim, dein.vim and the tools the config relies on (nix/modules/neovim.nix)

load helper

@test "Neovim runs with the Python 3 provider" {
  # UltiSnips needs it
  run -0 login_zsh "nvim --headless -u NONE -i NONE -c 'if has(\"python3\") | qall | else | cquit | endif'"
}

@test "dein.vim is installed" {
  [ -f "$DOTFILES_PATH/nvim/dein/repos/github.com/Shougo/dein.vim/autoload/dein.vim" ]
}

@test "clangd runs" {
  run -0 login_zsh 'clangd --version'
}

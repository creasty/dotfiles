#!/usr/bin/env bats
#
# Neovim and the tools the config relies on (nix/modules/neovim.nix)

load helper

@test "Neovim runs" {
  run -0 login_zsh "nvim --headless -u NONE -i NONE -c 'if has(\"nvim-0.11.3\") | qall | else | cquit | endif'"
}

@test "clangd runs" {
  run -0 login_zsh 'clangd --version'
}

@test "the tree-sitter CLI runs" {
  # nvim-treesitter generates the latex and swift parsers with it
  run -0 login_zsh 'tree-sitter --version'
}

@test "the language servers are on PATH" {
  # (nvim/lua/user/plugin/lsp.lua starts only the ones it finds)
  for cmd in codebook-lsp lua-language-server pyright-langserver tailwindcss-language-server \
    vim-language-server vscode-css-language-server vscode-eslint-language-server \
    vscode-json-language-server yaml-language-server; do
    run -0 login_zsh "command -v $cmd"
  done
}

#!/bin/bash

[ -n "$DOTFILES_HELPER_LOADED" ] && exit

export DOTFILES_HELPER_LOADED=1

section() {
  printf "\e[33m==> $1\e[0m\n"
}

subsection() {
  printf "\e[37m--> $1\e[0m\n"
}

show_and_run() {
  echo "$@"
  exec "$@"
}

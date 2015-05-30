#!/usr/bin/env bash

set -eu

export DOTFILES_PATH="$HOME/dotfiles"


#  Section
#-----------------------------------------------
section() {
  printf "\e[33m==> $1\e[0m\n"
}

subsection() {
  printf "\e[34m--> $1\e[0m\n"
}


#  Ask
#-----------------------------------------------
ask() {
  echo -n "$1"
  read REPLY
}

ask_for_confirmation() {
  ask "$1 [yN] "
}

answer_is_yes() {
  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    return 0
  else
    return 1
  fi
}


#  Print labeled text
#-----------------------------------------------
print_error() {
  printf "\e[0;31m[Error]\e[0m $@\n" 1>&2
}

print_success() {
  printf "\e[0;32m[Success]\e[0m $@\n"
}

print_info() {
  printf "\e[0;34m[Info]\e[0m $@\n"
}

print_status() {
  if [ $1 -eq 0 ]; then
    print_success "${2:-"OK"}"
  else
    print_info "${2:-"Done with error"}"
  fi
}


#  Utils
#-----------------------------------------------
cmd_exists() {
  command -v "$1" > /dev/null 2>&1 && return 0 || return 1
}

#!/usr/bin/env bash

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

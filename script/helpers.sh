#!/bin/bash

section() {
  printf "\e[33m==> $1\e[0m\n"
}

subsection() {
  printf "\e[37m--- $1\e[0m\n"
}

show_and_run() {
  echo "$@"
  exec "$@"
}

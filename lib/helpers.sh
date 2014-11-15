#!/usr/bin/env bash


#  Section
#-----------------------------------------------
section() {
  printf "\e[33m==> $1\e[0m\n"
}

subsection() {
  printf "\e[37m--> $1\e[0m\n"
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
  printf "\e[0;31m[Error]\e[0m $@\n"
}

print_success() {
  printf "\e[0;32m[Success]\e[0m $@\n"
}

print_info() {
  printf "\e[0;35m[Info]\e[0m $@\n"
}

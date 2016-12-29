#!/usr/bin/env bash

cd "$(dirname $0)"

ARGS=()
for a in "$@"; do
  ARGS=(${ARGS[@]} "$a")
done

ansible-playbook -i 'localhost,' playbook.yml --ask-become-pass ${ARGS[@]}

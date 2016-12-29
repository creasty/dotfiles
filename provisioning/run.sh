#!/usr/bin/env bash

cd "$(dirname $0)"

ARGS=('')
for a in "$@"; do
  ARGS=(${ARGS[@]} "$a")
done

[ -f ./secrets.yml ] || cp ./secrets{.sample,}.yml

ansible-playbook \
  -i 'localhost,' \
  --extra-vars='@config.yml' \
  --extra-vars='@secrets.yml' \
  ${ARGS[@]} \
  playbook.yml

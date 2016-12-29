#!/usr/bin/env bash

cd "$(dirname $0)"

ARGS=('')
for a in "$@"; do
  ARGS=(${ARGS[@]} "$a")
done

if ! [ -f ./secrets.yml ]; then
  cp ./secrets{.sample,}.yml
  # vim ./secrets.yml
fi

ansible-playbook \
  -i 'localhost,' \
  --extra-vars='@config.yml' \
  --extra-vars='@secrets.yml' \
  ${ARGS[@]} \
  playbook.yml

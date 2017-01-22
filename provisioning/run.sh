#!/usr/bin/env bash

set -eu
set -o pipefail

cd "$(dirname $0)"

RTUN='reattach-to-user-namespace'

CMD=('ansible-playbook')
ARGS=('')
for a in "$@"; do
  ARGS=(${ARGS[@]} "$a")
done

if ! [ -f ./secrets.yml ]; then
  cp ./secrets{.sample,}.yml
  [ "${DOTFILES_NOEDIT_SECRETS:-0}" -eq 0 ] && vim ./secrets.yml
fi

if [ -n "${TMUX:-}" ] && command -v $RTUN > /dev/null 2>&1; then
  CMD=($RTUN ${CMD[@]})
fi

${CMD[@]} \
  -i 'localhost,' \
  --extra-vars='@config.yml' \
  --extra-vars='@secrets.yml' \
  ${ARGS[@]} \
  playbook.yml

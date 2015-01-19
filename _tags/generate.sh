#!/usr/bin/env bash

ctags \
  -R \
  -f ctags \
  --c-kinds=+p \
  --c++-kinds=+p \
  --fields=+ailS \
  --extra=+q \
  /usr/include

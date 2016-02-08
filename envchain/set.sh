#!/usr/bin/env bash

cd "$(dirname "$0")"
source ../lib/helpers.sh

for f in *.txt; do
  namespace="$(basename "$f" '.txt')"
  section "$namespace"
  xargs < "$f" envchain --set "$namespace"
done

#!/usr/bin/env bash

cd "$(dirname $0)"

ansible-playbook -i 'localhost,' --check playbook.yml

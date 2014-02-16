#!/usr/bin/env bash

# clone
if [ -d ~/dotfiles/.git ]; then
  echo "ok"
else
  echo "Cloning repo..."
  cd ~
  git clone --recursive git@github.com:creasty/dotfiles.git
  echo "ok"
fi

cd ~/dotfiles

# install commands
source setups/install.sh

# create symbolic links
source setups/link.sh


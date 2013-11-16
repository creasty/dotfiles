#!/usr/bin/env bash

# update repo
echo "Updating repo..."
cd ~/dotfiles
git pull origin master
echo "ok"

# neobundle
echo "Updating vim plugin..."
vim +NeoBundleInstall +qa
echo "ok"


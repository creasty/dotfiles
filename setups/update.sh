#!/usr/bin/env bash

cd ~/dotfiles

# update repo
git pull origin master

# brew
brew bundle

# macports
sh setups/macports.sh

# npm
sh setups/npm.sh

# rvm
rvm get head
rvm get latest
rvm install 1.9.3
rvm install 2.1.0

# neobundle
vim +NeoBundleInstall +qa

# osx
sh setups/osx.sh


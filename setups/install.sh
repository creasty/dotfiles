#!/usr/bin/env bash

cd ~/dotfiles

# homebrew
which brew > /dev/null 2>&1
if [ $? -ne 0 ]; then
  ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
fi

brew tap phinze/homebrew-cask
brew install brew-cask

# macports
which port > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Install MacPorts: http://www.macports.org/install.php"
  exit
fi

# rvm
which rvm > /dev/null 2>&1
if [ $? -ne 0 ]; then
  curl -L get.rvm.io | bash -s stable
fi


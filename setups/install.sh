#!/usr/bin/env bash

cd ~/dotfiles

# homebrew
which brew > /dev/null 2>&1
if [ $? -ne 0 ]; then
  ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
fi

brew tap phinze/homebrew-cask
brew install brew-cask
brew bundle

# npm
sh setups/npm.sh

# rvm
which rvm > /dev/null 2>&1
if [ $? -ne 0 ]; then
  curl -L get.rvm.io | bash -s stable
fi

# rvm
rvm get head
rvm get latest
rvm install 1.9.3
rvm install 2.1.0

# rails
gem install rails

# osx
sh setups/osx.sh

# config: massren
massren --config editor vim

# config: zsh
sudo mv /etc/zshenv /etc/_zshenv
# TODO: not working
# sudo echo "\n/usr/local/bin/zsh" >> /etc/shells
chpass -s /usr/local/bin/zsh


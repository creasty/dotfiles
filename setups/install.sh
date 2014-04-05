#!/usr/bin/env bash

cd ~/dotfiles


#  Homebrew
#-----------------------------------------------
which brew > /dev/null 2>&1
if [ $? -ne 0 ]; then
  ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
fi

# brew cask
brew tap phinze/homebrew-cask
brew install brew-cask
brew bundle


#  Node packages
#-----------------------------------------------
sh setups/npm.sh


#  RVM
#-----------------------------------------------
which rvm > /dev/null 2>&1
if [ $? -ne 0 ]; then
  curl -L get.rvm.io | bash -s stable
fi

rvm get head
rvm get latest
rvm install 1.9.3
rvm install 2.1.0


#  Gem
#-----------------------------------------------
bundle


#  Pow
#-----------------------------------------------
which pow > /dev/null 2>&1
if [ $? -ne 0 ]; then
  curl get.pow.cx | sh
fi


#  Change login shell
#-----------------------------------------------
if [ $ZSH_NAME ]; then
  sudo mv /etc/zshenv /etc/_zshenv
  # TODO: not working
  # sudo echo "\n/usr/local/bin/zsh" >> /etc/shells
  chpass -s /usr/local/bin/zsh
fi


#  OSX
#-----------------------------------------------
sh setups/osx.sh



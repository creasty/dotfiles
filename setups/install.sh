#!/usr/bin/env bash

cd ~/dotfiles


#  Homebrew
#-----------------------------------------------
which brew > /dev/null 2>&1
if [ $? -ne 0 ]; then
  ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
fi

brew bundle


#  RVM
#-----------------------------------------------
which rvm > /dev/null 2>&1
if [ $? -ne 0 ]; then
  curl -L get.rvm.io | bash -s stable
fi

rvm get head
rvm get latest
rvm install 1.9.3
rvm install 2.1.1
rvm use --default 2.1.1


#  Pow
#-----------------------------------------------
which pow > /dev/null 2>&1
if [ $? -ne 0 ]; then
  curl get.pow.cx | sh
fi


#  Node packages
#-----------------------------------------------
npm i -g


#  Gem
#-----------------------------------------------
gem install awesome_print
gem install fancy_irb
gem install git-issue
gem install hirb
gem install interactive_editor
gem install powder
gem install rails
gem install synx


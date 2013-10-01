#!/usr/bin/env bash

cd ~/

# install git
which git > /dev/null 2>&1
if [ $? -eq 0 ] ; then
  echo Success!
else
  echo Install git! >&2
  # sudo yum install -y git
  sudo brew install git
fi

# install vim
which vim > /dev/null 2>&1
if [ $? -eq 0 ] ; then
  echo Success!
else
  echo Install vim! >&2
  # sudo yum install -y vim-enhanced
  sudo brew install vim
fi

# clone
git clone --recursive git@github.com:creasty/dotfiles.git

# symbolic links
ln -s ~/dotfiles/vimfiles ~/.vim
ln -s ~/dotfiles/_vimrc ~/.vimrc
ln -s ~/dotfiles/_gitconfig ~/.gitconfig
ln -s ~/dotfiles/_gitignore ~/.gitignore

# neo bundle
vim +NeoBundleInstall +qa


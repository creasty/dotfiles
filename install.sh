#!/usr/bin/env bash

# install git
echo "Checking git..."
which git > /dev/null 2>&1
if [ $? -eq 0 ] ; then
  echo "ok"
else
  echo "Installing git..."
  sudo brew install git
  echo "ok"
fi

# install vim
echo "Checking vim..."
which vim > /dev/null 2>&1
if [ $? -eq 0 ] ; then
  echo "ok"
else
  echo "Installing vim..."
  sudo brew install vim
  echo "ok"
fi

# clone / update
if [ -d ~/dotfiles/.git ]; then
  echo "Updating repo..."
  cd ~/dotfiles
  git pull origin master
else
  echo "Cloning repo..."
  cd ~
  git clone --recursive git@github.com:creasty/dotfiles.git
fi
echo "ok"

# symbolic links
echo "Creating symbolic links..."
cd ~
ln -s ~/dotfiles/_bashrc ~/.bashrc
ln -s ~/dotfiles/_bash_profile ~/.bash_profile
ln -s ~/dotfiles/_aliases ~/.aliases
ln -s ~/dotfiles/vimfiles ~/.vim
ln -s ~/dotfiles/_vimrc ~/.vimrc
ln -s ~/dotfiles/_gitconfig ~/.gitconfig
ln -s ~/dotfiles/_gitignore ~/.gitignore
ln -s ~/dotfiles/_railsrc ~/.railsrc
ln -s ~/dotfiles/_ackrc ~/.ackrc
ln -s ~/dotfiles/scripts/git-prompt.sh ~/.git-prompt.sh
echo "ok"

# neo bundle
echo "Updating vim plugin..."
vim +NeoBundleInstall +qa
echo "ok"


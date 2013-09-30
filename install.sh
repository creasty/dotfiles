#!/usr/bin/env bash
#
cd ~

# install git
which git > /dev/null 2>&1
if [ $? -eq 0 ] ; then
  echo Success!
else
  echo Install git! >&2
  sudo yum install -y git
fi

# install vim
which vim > /dev/null 2>&1
if [ $? -eq 0 ] ; then
  echo Success!
else
  echo Install vim! >&2
  sudo yum install -y vim-enhanced
fi


# git submodule init
# git submodule update

ln -s .vimrc ~/.vimrc
ln -s .gitconfig ~/.gitconfig

vim +NeoBundleInstall +qa

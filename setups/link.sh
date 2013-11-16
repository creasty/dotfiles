#!/usr/bin/env bash

# symbolic links
echo "Creating symbolic links..."
cd ~

ln -s ~/dotfiles/_bashrc       ~/.bashrc
ln -s ~/dotfiles/_bash_profile ~/.bash_profile
ln -s ~/dotfiles/_zshrc        ~/.zshrc
ln -s ~/dotfiles/_zshenv       ~/.zshenv
ln -s ~/dotfiles/_aliases      ~/.aliases
ln -s ~/dotfiles/vimfiles      ~/.vim
ln -s ~/dotfiles/_vimrc        ~/.vimrc
ln -s ~/dotfiles/_gitconfig    ~/.gitconfig
ln -s ~/dotfiles/_gitignore    ~/.gitignore
ln -s ~/dotfiles/_agignore     ~/.agignore
ln -s ~/dotfiles/_railsrc      ~/.railsrc
ln -s ~/dotfiles/_ackrc        ~/.ackrc
ln -s ~/dotfiles/_tmux.conf    ~/.tmux.conf

echo "ok"


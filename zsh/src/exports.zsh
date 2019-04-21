#  General
#-----------------------------------------------
export LC_ALL=ja_JP.UTF-8
export LANG=ja_JP.UTF-8
export EDITOR=vim

export LSCOLORS='Gxfxcxdxbxegedabagacad'

#  Path
#-----------------------------------------------
# Dotfiles
export DOTFILES_PATH="$HOME/dotfiles"

# Golang
export GOPATH=$HOME/go

# Android
export ANDROID_HOME=/usr/local/opt/android-sdk

# Anyenv
export ANYENV_DIR=$HOME/.anyenv

#  Search path
#-----------------------------------------------
# Local
export PATH=/usr/local/bin:$PATH

# Anyenv
export PATH=$ANYENV_DIR/bin:$PATH

# Dotfiles
export PATH=$DOTFILES_PATH/bin:$PATH

# Golang
export PATH=$PATH:$GOPATH/bin

# libxml2
export PATH=/usr/local/opt/libxml2/bin:$PATH

# Wantedly
export PATH=$PATH:$HOME/.wantedly/bin

# VSCode
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

# Rust
export PATH=$PATH:$HOME/.cargo/bin

#  Other config
#-----------------------------------------------
# Git
export GIT_MERGE_AUTOEDIT='no'

# Rails
export DISABLE_SPRING=1

# Rust
export RUST_BACKTRACE=1

# Go
export GO111MODULE=on

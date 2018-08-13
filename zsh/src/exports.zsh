#  General
#-----------------------------------------------
export LANG=ja_JP.UTF-8
export EDITOR=vim

export LSCOLORS='Gxfxcxdxbxegedabagacad'


#  Path
#-----------------------------------------------
# dotfiles
export DOTFILES_PATH="$HOME/dotfiles"

# golang
export GOPATH=$HOME/go

# android
export ANDROID_HOME=/usr/local/opt/android-sdk

# anyenv
export ANYENV_DIR=$HOME/.anyenv

# tmux
export TMUX_RESURRECT_SCRIPTS_PATH=~/.tmux/plugins/tmux-resurrect/scripts


#  Search path
#-----------------------------------------------
# local
export PATH=/usr/local/bin:$PATH

# anyenv
export PATH=$ANYENV_DIR/bin:$PATH

# dotfiles
export PATH=$DOTFILES_PATH/bin:$PATH

# golang
export PATH=$PATH:$GOPATH/bin

# wantedly
export PATH=$PATH:$HOME/.wantedly/bin


#  Git
#-----------------------------------------------
export GIT_MERGE_AUTOEDIT='no'


#  Rails
#-----------------------------------------------
export DISABLE_SPRING=1

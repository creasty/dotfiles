export LANG=ja_JP.UTF-8
export EDITOR=vim

export DOTFILES_PATH="$HOME/dotfiles"

export NODE_PATH=/usr/local/lib/node_modules
export RBENV_ROOT=$HOME/.rbenv

export GOROOT=`/usr/local/bin/go env GOROOT`
export GOPATH=$HOME/go

export PATH=/usr/local/bin:$PATH
export PATH=$PATH:/opt/local/bin
export PATH=$PATH:$HOME/.cabal/bin
export PATH=$RBENV_ROOT/bin:$PATH
export PATH=$PATH:/usr/local/heroku/bin
export PATH=$PATH:$HOME/.npm/node_modules/bin
export PATH=$PATH:$HOME/dotfiles/bin
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
export PATH=$PATH:/Applications/TeXLive/Library/texlive/2013/bin/x86_64-darwin

# no need to edit merge commit message, bitch
export GIT_MERGE_AUTOEDIT='no'

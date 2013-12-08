#!/usr/bin/env bash

# install mercurial
echo "Checking mercurial..."
which hg > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "ok"
else
  echo "Installing mercurial..."
  brew install mercurial
  echo "ok"
fi

# install zsh
echo "Checking zsh..."
which zsh > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "ok"
else
  echo "Installing zsh..."
  brew install zsh --disable-etcdir zsh
  sudo mv /etc/zshenv /etc/_zshenv
  sudo echo "\n/usr/local/bin/zsh" >> /etc/shells # TODO: not working
  chpass -s /usr/local/bin/zsh
fi
if [ -d ~/.oh-my-zsh ]; then
  echo "Installing oh-my-zsh..."
  curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh
fi

# install git
echo "Checking git..."
which git > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "ok"
else
  echo "Installing git..."
  brew install git
  echo "ok"
fi

# install tmux
echo "Checking tmux..."
which tmux > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "ok"
else
  echo "Installing tmux..."
  brew install tmux
  echo "ok"
fi

# install ag
echo "Checking ag..."
which ag > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "ok"
else
  echo "Installing ag..."
  brew install the_silver_searcher
  echo "ok"
fi

# install vim
echo "Checking vim..."
which vim > /dev/null 2>&1
if [[ ($? -eq 0) && ($(vim --version) == *\+lua\ *) ]]; then
  echo "ok"
else
  echo "Installing vim..."
  brew install macvim --with-cscope --with-lua --HEAD
  echo "ok"
fi

# install neobundle
echo "Updating vim plugin..."
vim +NeoBundleInstall +qa
echo "ok"


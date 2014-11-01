#!/bin/bash

# update homebrew
brew update

# upgrade already-installed packages
brew upgrade

# add repositories
brew tap caskroom/versions || true
brew tap homebrew/dupes || true
brew tap homebrew/science || true
brew tap josegonzalez/php || true
brew tap laurent22/massren || true
brew tap peco/peco || true
brew tap phinze/homebrew-cask || true
brew tap supermomonga/homebrew-splhack || true

# cask
brew install brew-cask || true

# install cask-packages
brew cask install adobe-creative-cloud || true
brew cask install alfred || true
brew cask install dropbox || true
brew cask install firefox || true
brew cask install flip4mac || true
brew cask install google-chrome || true
brew cask install google-hangouts || true
brew cask install google-japanese-ime || true
brew cask install growlnotify || true
brew cask install imagealpha || true
brew cask install imageoptim || true
brew cask install iterm2 || true
brew cask install java7 || true
brew cask install karabiner || true
brew cask install ngrok || true
brew cask install seil || true
brew cask install sequel-pro || true
brew cask install skype || true
brew cask install sophos-antivirus-home-edition || true
brew cask install transmission || true
brew cask install truecrypt || true
brew cask install vagrant || true
brew cask install virtualbox || true
brew cask install xquartz || true

# install brew-packages
brew install ansible || true
brew install cabal-install || true
brew install chrome-cli || true
brew install clib || true
brew install clisp || true
brew install ctags || true
brew install ctags-objc-ja --HEAD --enable-japanese-support || true
brew install direnv || true
brew install eot-utils || true
brew install fontconfig || true
brew install fontforge || true
brew install freetype || true
brew install gdbm || true
brew install gettext || true
brew install gh || true
brew install ghc || true
brew install ghostscript || true
brew install git || true
brew install git-flow || true
brew install go || true
brew install gpg || true
brew install graphviz || true
brew install haskell-platform || true
brew install httpie || true
brew install hub || true
brew install imagemagick || true
brew install irssi --with-perl=yes --with-proxy --with-socks || true
brew install jbig2dec || true
brew install jpeg || true
brew install jq || true
brew install lua || true
brew install luarocks || true
brew install luajit || true
brew install macvim --HEAD --with-cscope --with-lua --override-system-vi || true
brew install massren && massren --config editor vim || true
brew install mercurial || true
brew install mysql || true
brew install ngrep || true
brew install node || true
brew install optipng || true
brew install osquery || true
brew install pcre || true
brew install peco || true
brew install phantomjs || true
brew install php55 || true
brew install python3 || true
brew install q || true
brew install r || true  # require xquartz to be installed
brew install rbenv || true
brew install rbenv-gem-rehash || true
brew install reattach-to-user-namespace || true
brew install ruby-build || true
brew install sqlite || true
brew install sshrc || true
brew install the_silver_searcher || true
brew install tig || true
brew install tmux || true
brew install tree || true
brew install w3m || true
brew install webkit2png || true
brew install wget --enable-iri || true
brew install xctool || true
brew install zsh || true

# for alfred
brew cask alfred link

# applications
brew linkapps

# remove outdated versions from the cellar
brew cleanup

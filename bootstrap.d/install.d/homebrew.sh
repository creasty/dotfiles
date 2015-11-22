section "Fix SIP on /usr/local"
sudo -v  # ask for the administrator password upfront
[ -d /usr/local ] || sudo mkdir /usr/local
sudo chflags norestricted /usr/local
sudo chown $(whoami):admin /usr/local
sudo chown -R $(whoami):admin /usr/local


section "Installing homebrew"
if cmd_exists brew; then
  print_info "Installed"
else
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  print_status $?
fi

section "Update formula"
brew update


section "Upgrade installed packages"
brew upgrade


section "Add repositories"
cat $DOTFILES_PATH/brew/tap.txt \
  | sed 's/\s*#.*$//' \
  | {
    while read -r line; do
      if ! [ -z "$line" ]; then
        subsection "Tapping $line"
        brew tap $line || true
      fi
    done
  }


section "Install applications"

subsection "Installing cask"
brew install caskroom/cask/brew-cask || true

cat $DOTFILES_PATH/brew/cask.txt \
  | sed 's/\s*#.*$//' \
  | {
    while read -r line; do
      if ! [ -z "$line" ]; then
        subsection "Installing $line"
        brew cask install $line || true
      fi
    done
  }


section "Fixate versions"
PREFIX=$(brew --prefix)
cat $DOTFILES_PATH/brew/version_fixations.txt \
  | sed 's/\s*#.*$//' \
  | {
    while read -r line; do
      if ! [ -z "$line" ]; then
        version="$(cut -d' ' -f 1 <<< "$line")"
        path="$(cut -d' ' -f 2 <<< "$line")"

        git --gitdir=$PREFIX checkout $version -- $PREFIX/Library/$path
      fi
    done
  }


section "Install packages"
cat $DOTFILES_PATH/brew/packages.txt \
  | sed 's/\s*#.*$//' \
  | {
    while read -r line; do
      if ! [ -z "$line" ]; then
        subsection "Installing $line"
        brew install $line || true
      fi
    done
  }


section "Link applications"
brew cask alfred link
brew linkapps


section "Remove outdated versions"
brew cleanup

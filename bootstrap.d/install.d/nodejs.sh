DEFAULT_VERSION="$(< $DOTFILES_PATH/nodejs/.node-version)"

INSTALLED_NODE_VERSIONS="$(node ls)"

section "Installing nodejs"

subsection "Setup nvm"

export NVM_DIR=$HOME/.nvm

if ! [ -d "$NVM_DIR" ]; then
  ln -sf "$(brew --prefix nvm)" "$NVM_DIR"
fi


cat $DOTFILES_PATH/nodejs/packages.txt \
| {
  while read -r line; do
    if ! [ -z "$line" ]; then
      version="$line"
      subsection "Install $version"

      if [ -z "$(echo -n "$INSTALLED_NODE_VERSIONS" | grep $version)" ]; then
        nvm install $version
        print_status $?
      else
        print_info "Installed"
      fi
    fi
  done
}

section "Set default version"
nvm alias default $DEFAULT_VERSION
nvm use default

section "Installing nodejs packages"
cat $DOTFILES_PATH/nodejs/packages.txt | xargs -n 1 npm i -g

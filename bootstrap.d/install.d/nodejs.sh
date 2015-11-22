DEFAULT_VERSION="$(< $DOTFILES_PATH/nodejs/.node-version)"

INSTALLED_NODE_VERSIONS="$(node ls)"

subsection "Install ndenv"

anyenv install ndenv

section "Installing nodejs"

cat $DOTFILES_PATH/nodejs/packages.txt \
| {
  while read -r line; do
    if ! [ -z "$line" ]; then
      version="$line"
      subsection "Install $version"

      if [ -z "$(echo -n "$INSTALLED_NODE_VERSIONS" | grep $version)" ]; then
        ndenv install $version
        print_status $?
      else
        print_info "Installed"
      fi
    fi
  done
}

section "Set default version"
ndenv global $DEFAULT_VERSION

section "Installing nodejs packages"
cat $DOTFILES_PATH/nodejs/packages.txt | xargs -n 1 npm i -g

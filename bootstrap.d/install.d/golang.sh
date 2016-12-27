section "Installing goenv"

anyenv install goenv
exec $SHELL -l
print_status "Installed"

section "Installing golang"

INSTALLED_VERSIONS="$(goenv versions)"
DEFAULT_VERSION="$(< $DOTFILES_PATH/golang/.go-version)"

cat $DOTFILES_PATH/golang/versions.txt \
  | {
    while read -r line; do
      if ! [ -z "$line" ]; then
        version="$line"

        subsection "Golang v$version"

        if [ -z "$(echo -n "$INSTALLED_VERSIONS" | grep $version)" ]; then
          goenv install $version
          print_status $?
        else
          print_info "Installed"
        fi
      fi
    done
  }


section "Set global golang to v$DEFAULT_VERSION"
goenv global $DEFAULT_VERSION
print_status $?

section "Installing Golang packages"

cat $DOTFILES_PATH/golang/packages.txt | xargs -n 1 go get

section "Set gocode options"
gocode set autobuild true

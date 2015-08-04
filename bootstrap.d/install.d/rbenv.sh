DEFAULT_VERSION="$(< $DOTFILES_PATH/ruby/.ruby-version)"

INSTALLED_RUBY_VERSIONS="$(rbenv versions --bare)"

section "Installing ruby"

subsection "Upgrading ruby-build"
brew upgrade ruby-build > /dev/null 2>&1
print_success "OK"

cat $DOTFILES_PATH/ruby/versions.txt \
  | {
    while read -r line; do
      if ! [ -z "$line" ]; then
        version="$line"

        subsection "Ruby v$version"

        if [ -z "$(echo -n "$INSTALLED_RUBY_VERSIONS" | grep $version)" ]; then
          rbenv install $version
          print_status $?
        else
          print_info "Installed"
        fi
      fi
    done
  }


section "Set global ruby to v$DEFAULT_VERSION"
rbenv global $DEFAULT_VERSION
print_status $?

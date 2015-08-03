DEFAULT_VERSION="$(< $DOTFILES_PATH/.ruby-version)"

INSTALLED_RUBY_VERSIONS="$(rbenv versions --bare)"

section "Installing ruby"

subsection "Upgrading ruby-build"
brew upgrade ruby-build > /dev/null 2>&1
print_success "OK"

_install_ruby() {
  local version=$1

  subsection "Ruby v$version"

  if [ -z "$(echo -n "$INSTALLED_RUBY_VERSIONS" | grep $version)" ]; then
    rbenv install $version
    print_status $?
  else
    print_info "Installed"
  fi
}

cat $DOTFILES_PATH/ruby/versions.txt | xargs -n 1 _install_ruby

subsection "Set global ruby to v$DEFAULT_VERSION"
rbenv global $DEFAULT_VERSION
print_status $?

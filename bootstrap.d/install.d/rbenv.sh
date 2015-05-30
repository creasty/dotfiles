ruby_versions=(
  2.1.5
  2.2.0
)
default_version="$(< $DOTFILES_PATH/.ruby-version)"

installed_ruby_versions="$(rbenv versions --bare)"

section "Installing ruby"

subsection "Upgrading ruby-build"
brew upgrade ruby-build > /dev/null 2>&1
print_success "OK"

for version in "${ruby_versions[@]}"; do
  installed="$(echo -n "$installed_ruby_versions" | grep $version)"

  subsection "Ruby v$version"

  if [ "$installed" == "" ]; then
    rbenv install $version
    print_status $?
  else
    print_info "Installed"
  fi
done

subsection "Set global ruby to v$version"
rbenv global $version
print_status $?

DEFAULT_VERSION="$(< $DOTFILES_PATH/ruby/.ruby-version)"
PLUGINS_DIR=$HOME/.anyenv/envs/rbenv/plugins

section "Install rbenv"

subsection "Installing rbenv"
anyenv install rbenv
exec $SHELL -l
print_success "OK"

subsection "Installing rbenv-binstubs"
if [ -d $PLUGINS_DIR/rbenv-binstubs ]; then
  print_info "Installed"
else
  git clone https://github.com/ianheggie/rbenv-binstubs.git $PLUGINS_DIR/rbenv-binstubs
fi

subsection "Installing sstephenson/rbenv-default-gems"
if [ -d $PLUGINS_DIR/rbenv-default-gems ]; then
  print_info "Installed"
else
  git clone https://github.com/sstephenson/rbenv-default-gems.git $PLUGINS_DIR/rbenv-default-gems
fi

subsection "Installing rbenv-gem-rehash"
if [ -d $PLUGINS_DIR/rbenv-gem-rehash ]; then
  print_info "Installed"
else
  git clone https://github.com/sstephenson/rbenv-gem-rehash.git $PLUGINS_DIR/rbenv-gem-rehash
fi


section "Installing ruby"

INSTALLED_RUBY_VERSIONS="$(rbenv versions --bare)"
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

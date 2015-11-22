section "Install rbenv"

anyenv install rbenv
exec $SHELL -l
print_success "OK"


section "Installing rbenv plugins"

PLUGINS_DIR=$HOME/.anyenv/envs/rbenv/plugins

cat $DOTFILES_PATH/ruby/rbenv/plugins.txt \
  | {
    while read -r repo; do
      if ! [ -z "$repo" ]; then
        subsection "Installing $repo"
        dir="$PLUGINS_DIR/$(basename "$repo")"

        if [ -d "$dir" ]; then
          git --git-dir="$dir" reset --hard HEAD
          git --git-dir="$dir" pull origin master
          print_success 'Updated'
        else
          git clone "https://github.com/${repo}.git" "$dir"
          print_success 'Installed'
        fi
      fi
    done
  }


section "Installing ruby"

INSTALLED_RUBY_VERSIONS="$(rbenv versions --bare)"
DEFAULT_VERSION="$(< $DOTFILES_PATH/ruby/.ruby-version)"

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

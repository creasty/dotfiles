section "Installing nodejs"

subsection "Installing nvm"
if cmd_exists nvm; then
  print_info "Installed"
else
  curl https://raw.githubusercontent.com/creationix/nvm/v0.17.3/install.sh | bash
fi

subsection "Installing nodejs"
nvm install 0.10.33
print_status $?

subsection "Set default version"
nvm alias default 0.10.33
nvm use default

section "Installing nodejs packages"
(cd $DOTFILES_PATH/nodejs && npm i -g)

section "Installing nodejs"

subsection "Installing nvm"
if cmd_exists nvm; then
  print_info "Installed"
else
  curl https://raw.githubusercontent.com/creationix/nvm/v0.17.3/install.sh | bash
fi

subsection "Installing nvm"
nvm install 0.10
print_status $?

section "Installing nodejs packages"

(cd $DOTFILES_PATH/nodejs && npm i -g)

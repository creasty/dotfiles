section "Installing nodejs"

subsection "Setup nvm"

export NVM_DIR=$HOME/.nvm

if ! [ -d "$NVM_DIR" ]; then
  ln -sf "$(brew --prefix nvm)" "$NVM_DIR"
fi

subsection "Installing nodejs"
nvm install 0.10.33
print_status $?

subsection "Set default version"
nvm alias default 0.10.33
nvm use default

section "Installing nodejs packages"
(cd $DOTFILES_PATH/nodejs && npm i -g)

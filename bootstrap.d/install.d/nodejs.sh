section "Installing nodejs"

subsection "Installing nodejs"
nvm install 0.10.33
print_status $?

subsection "Set default version"
nvm alias default 0.10.33
nvm use default

section "Installing nodejs packages"
(cd $DOTFILES_PATH/nodejs && npm i -g)

section "Installing Lua packages"

cat $DOTFILES_PATH/lua/requirements.txt | each luarocks install

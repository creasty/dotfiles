section "Installing Lua packages"

cat $DOTFILES_PATH/lua/requirements.txt | xargs -n 1 luarocks install

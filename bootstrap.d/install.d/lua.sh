section "Installing Lua packages"

cat $DOTFILES_PATH/lua/packages.txt | xargs -n 1 luarocks install

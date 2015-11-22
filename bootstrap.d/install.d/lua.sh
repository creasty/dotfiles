section "Installing luaenv"

anyenv install luaenv
exec $SHELL -l
print_status "Installed"


section "Installing Lua packages"

cat $DOTFILES_PATH/lua/packages.txt | xargs -n 1 luarocks install

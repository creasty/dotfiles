section "Installing goenv"

anyenv install goenv
exec $SHELL -l
print_status "Installed"


section "Installing Golang packages"

cat $DOTFILES_PATH/golang/packages.txt | xargs -n 1 go get

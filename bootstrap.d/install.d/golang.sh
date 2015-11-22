section "Installing Golang packages"

cat $DOTFILES_PATH/golang/packages.txt | xargs -n 1 go get

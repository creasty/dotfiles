section "Installing Golang packages"

cat $DOTFILES_PATH/golang/requirements.txt | each go get

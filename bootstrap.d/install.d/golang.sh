section "Installing Golang packages"

cat $DOTFILES_PATH/golang/requirements.txt | xargs -n 1 go get

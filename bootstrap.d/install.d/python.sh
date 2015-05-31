section "Installing Python packages"

cat $DOTFILES_PATH/lua/requirements.txt | each pip install --upgrade

section "Installing Python packages"

cat $DOTFILES_PATH/lua/requirements.txt | xargs -n 1 pip install --upgrade

section "Installing pyenv"

anyenv install pyenv
exec $SHELL -l
print_status "Installed"


section "Installing Python packages"

cat $DOTFILES_PATH/lua/requirements.txt | xargs -n 1 pip3 install --upgrade

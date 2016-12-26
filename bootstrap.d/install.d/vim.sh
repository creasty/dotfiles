DEIN_REPO="github.com/Shougo/dein.vim"
INSTALL_DIR="$DOTFILES_PATH/vim/dein/repos/$DEIN_REPO"

if ! [ -d "$INSTALL_DIR" ]; then
  mkdir -p "$INSTALL_DIR"
  git clone "https://$DEIN_REPO" "$INSTALL_DIR"
fi

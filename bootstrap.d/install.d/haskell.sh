section "Installing Haskell packages"

subsection "Updating cabal"
cabal update
print_status $?

subsection "Installing packages"
cat $DOTFILES_PATH/haskell/requirements.txt | xargs -n 1 cabal install --allow-newer=base

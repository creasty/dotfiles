section "Installing Haskell packages"

subsection "Updating cabal"
cabal update
print_status $?

subsection "Installing packages"
cat $DOTFILES_PATH/haskell/requirements.txt | each cabal install

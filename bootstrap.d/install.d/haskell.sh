section "Updating cabal"
cabal update
print_status $?

section "Installing haskell packages"
cat $DOTFILES_PATH/haskell/packages.txt | xargs -n 1 cabal install --allow-newer=base

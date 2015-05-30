section "Installing Haskell packages"

subsection "Updating cabal"
cabal update
print_status $?

subsection "Installing packages"
cabal install cabal-install
cabal install erd

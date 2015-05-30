section "Installing homebrew"

if cmd_exists brew; then
  print_info "Installed"
else
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  print_status $?
fi

section "Installing brew packages"
bash < ./Brewfile

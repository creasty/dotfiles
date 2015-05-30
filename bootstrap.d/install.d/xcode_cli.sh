section "Installing Xcode command line tool"
xcode-select --install > /dev/null 2>&1

if [ $? -ne 0 ]; then
  print_info "Installed"
else
  print_success "OK"
fi

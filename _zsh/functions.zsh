cdd() {
  if [ $# -gt 0 ]; then
    cd "$HOME/Develop/$1"
  else
    cd ~/Develop
  fi
}
compctl -f -W ~/Develop cdd

cdh() {
  if [ $# -gt 0 ]; then
    cd "$HOME/$1"
  else
    cd ~
  fi
}
compctl -f -W ~ cdh

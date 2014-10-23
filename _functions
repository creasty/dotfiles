#  Development directory
#-----------------------------------------------
cdd() {
  if [ $# -gt 0 ]; then
    cd "$HOME/Develop/$1"
  else
    cd ~/Develop
  fi
}

compctl -f -W ~/Develop cdd


#  Home directory
#-----------------------------------------------
cdh() {
  if [ $# -gt 0 ]; then
    cd "$HOME/$1"
  else
    cd ~
  fi
}

compctl -f -W ~ cdh


#  SSH
#-----------------------------------------------
sshc() {
  cat ~/.ssh/config.d/* > ~/.ssh/config

  [ $# -gt 0 ] && sshrc $1
}

compctl -f -W ~/.ssh/config.d sshc


#  Peco cd
#-----------------------------------------------
pd() {
  local DIR_TMP=""
  local DIR_PATH="$1"

  while true; do
    DIR_TMP=$(ls -1aF $DIR_PATH | sed -e 's/@$/\//' | grep / | peco)

    if [ "$DIR_TMP" = "./" ]; then
      cd "$DIR_PATH"
      return
    elif [ "$DIR_TMP" = "" ]; then
      return
    else
      DIR_PATH="${DIR_PATH}${DIR_TMP}"
    fi
  done
}

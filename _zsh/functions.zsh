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

peco_insert_path() {
  local cmd

  if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    cmd='git ls-files'
  else
    cmd='find .'
  fi

  local filepath="$(eval "$cmd" | peco --rcfile=$HOME/.pecorc)"

  if [ "$LBUFFER" -eq "" ]; then
    if [ -d "$filepath" ]; then
      BUFFER="cd $filepath"
    elif [ -f "$filepath" ]; then
      BUFFER="$EDITOR $filepath"
    fi
  else
    BUFFER="$LBUFFER$filepath"
  fi

  CURSOR=$#BUFFER
  zle clear-screen
}

zle -N peco_insert_path
bindkey '^q' peco_insert_path

peco_insert_branch() {
  local branch="$(git branch --color=never | cut -c 3- | peco --rcfile=$HOME/.pecorc)"

  BUFFER="$LBUFFER$branch"
  CURSOR=$#BUFFER

  zle clear-screen
}

zle -N peco_insert_branch
bindkey '^o' peco_insert_branch

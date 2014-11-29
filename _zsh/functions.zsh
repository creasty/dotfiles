#  cd ~/Develop
#-----------------------------------------------
cdd() {
  if [ $# -gt 0 ]; then
    cd "$HOME/Develop/$1"
  else
    cd ~/Develop
  fi
}

compctl -f -W ~/Develop cdd


#  cd ~
#-----------------------------------------------
cdh() {
  if [ $# -gt 0 ]; then
    cd "$HOME/$1"
  else
    cd ~
  fi
}

compctl -f -W ~ cdh


#  cd to the project root
#-----------------------------------------------
cdrt() {
  if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    cd `git rev-parse --show-toplevel`
  fi
}


#  Make directory and enter to it
#-----------------------------------------------
mkd() {
  mkdir -p "$@" && cd "$@"
}


#  Peco insert path
#-----------------------------------------------
peco_insert_path() {
  local cmd

  if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    cmd='git ls-files .'
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
}

zle -N peco_insert_path
bindkey '^i^p' peco_insert_path


#  Peco insert branch
#-----------------------------------------------
peco_insert_branch() {
  local branch="$(git branch --color=never | cut -c 3- | peco --rcfile=$HOME/.pecorc)"

  BUFFER="$LBUFFER$branch"
  CURSOR=$#BUFFER
}

zle -N peco_insert_branch
bindkey '^i^b' peco_insert_branch


#  Peco insert commit id
#-----------------------------------------------
peco_insert_commit() {
  local commit="$(git log --oneline --color=never | peco --rcfile=$HOME/.pecorc | cut -c -7)"

  BUFFER="$LBUFFER$commit"
  CURSOR=$#BUFFER
}

zle -N peco_insert_commit
bindkey '^i^l' peco_insert_commit

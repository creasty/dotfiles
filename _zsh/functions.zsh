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

  if [ "$LBUFFER" = "" ] && [ $(wc -l <<< "$filepath") -eq 1 ]; then
    if [ -d "$filepath" ]; then
      BUFFER="cd $filepath"
    elif [ -f "$filepath" ]; then
      BUFFER="$EDITOR $filepath"
    fi
  else
    filepath=$(tr "\n" ' ' <<< "$filepath")
    BUFFER="$LBUFFER$filepath"
  fi

  CURSOR=$#BUFFER
}

zle -N peco_insert_path
bindkey '^o^p' peco_insert_path


#  Peco insert modified files
#-----------------------------------------------
peco_modified_file() {
  local filepath="$(git status -s | cut -b 4- | peco --rcfile=$HOME/.pecorc | tr "\n" ' ')"

  local rbuf="$RBUFFER"
  BUFFER="$LBUFFER$filepath"
  CURSOR=$#BUFFER
  BUFFER="$BUFFER$rbuf"
}

zle -N peco_modified_file
bindkey '^o^m' peco_modified_file


#  Peco insert branch
#-----------------------------------------------
peco_insert_branch() {
  local branch="$(git branch --color=never | cut -c 3- | peco --rcfile=$HOME/.pecorc | tr "\n" ' ')"

  local rbuf="$RBUFFER"
  BUFFER="$LBUFFER$branch"
  CURSOR=$#BUFFER
  BUFFER="$BUFFER$rbuf"
}

zle -N peco_insert_branch
bindkey '^o^b' peco_insert_branch


#  Peco insert commit id
#-----------------------------------------------
peco_insert_commit() {
  local commit="$(git log --oneline --color=never | peco --rcfile=$HOME/.pecorc | cut -c -7 | tr "\n" ' ')"

  local rbuf="$RBUFFER"
  BUFFER="$LBUFFER$commit"
  CURSOR=$#BUFFER
  BUFFER="$BUFFER$rbuf"
}

zle -N peco_insert_commit
bindkey '^o^l' peco_insert_commit


#  Peco insert issue
#-----------------------------------------------
peco_insert_issue() {
  local issue="$(git issue-list | peco --rcfile=$HOME/.pecorc | tr "\n" ' ')"

  if [ "${LBUFFER[$CURSOR]}" = '#' ]; then
    issue=$(echo "$issue" | cut -d ' ' -f 1 | cut -c 2-)
  fi

  local rbuf="$RBUFFER"
  BUFFER="$LBUFFER$issue"
  CURSOR=$#BUFFER
  BUFFER="$BUFFER$rbuf"
}

zle -N peco_insert_issue
bindkey '^o^i' peco_insert_issue


#  Peco history
#-----------------------------------------------
function peco_history() {
  local tac

  if which tac > /dev/null; then
    tac='tac'
  else
    tac='tail -r'
  fi

  BUFFER=$(\history -n 1 | eval $tac | peco --query "$LBUFFER")
  CURSOR=$#BUFFER
}

zle -N peco_history
bindkey '^r' peco_history

#=== Helper
#==============================================================================================
_register_keycommand() {
  zle -N $2
  bindkey "$1" $2
}

_buffer_insert() {
  local rbuf="$RBUFFER"
  BUFFER="$LBUFFER$(cat)"
  CURSOR=$#BUFFER
  BUFFER="$BUFFER$rbuf"
}
_buffer_insert_lines() {
  cat \
    | {
      lines=()

      while read -r line; do
        if ! [ -z "$line" ]; then
          lines=(${lines[@]} "${(q)line}")
        fi
      done

      echo -n "${lines[@]}"
    } \
    | _buffer_insert
}
_buffer_replace() {
  BUFFER="$(cat)"
  CURSOR=$#BUFFER
}


#=== General
#==============================================================================================
#  Move to project root
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


#  Refresh without restart
#-----------------------------------------------
_refresh_screen() {
  zle clear-screen
  rehash
  zle reset-prompt
}

_register_keycommand '^l' _refresh_screen


#  Reload
#-----------------------------------------------
reload() {
  exec zsh -l
  [ -n "$TMUX" ] && tmux source-file ~/.tmux.conf
}


#  Update all repos managed by ghq
#-----------------------------------------------
ghq-update() {
  ghq list | xargs -n 1 -P 10 ghq get -u
}


#  Tmux
#-----------------------------------------------
# kill all non-attached sessions
tmk() {
  tmux ls | grep -v attached | cut -d: -f 1 | xargs -n 1 tmux kill-session -t
}


#=== Peco
#==============================================================================================
_peco_select() {
  local tx="$(cat)"
  local query="$1"

  if [ "$tx" = '' ]; then
    tx=' '
    query='(nothing)'
  fi

  peco --query "$query" <<< "$tx"
}


#  Insert path
#-----------------------------------------------
peco_insert_path() {
  local cmd

  if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    cmd='git ls-files .'
  else
    cmd='find .'
  fi

  eval "$cmd" \
    | _peco_select \
    | {
      file="$(cat)"

      if [ "$LBUFFER" != "" ]; then
        echo "$file" | _buffer_insert_lines
      elif [ -d "$file" ]; then
        echo "cd $file" | _buffer_insert
      elif [ -f "$file" ]; then
        echo "$EDITOR $file" | _buffer_insert
      else
        echo "$file" | _buffer_insert_lines
      fi
    }
}

_register_keycommand '^o^p' peco_insert_path


#  Insert modified files
#-----------------------------------------------
peco_modified_file() {
  git status -s \
    | cut -b 4- \
    | _peco_select \
    | _buffer_insert_lines
}

_register_keycommand '^o^m' peco_modified_file


#  Insert branch
#-----------------------------------------------
peco_insert_branch() {
  git branch --color=never \
    | cut -c 3- \
    | _peco_select \
    | {
      branch="$(cat)"

      if [[ -z "$LBUFFER" && `echo "$branch" | wc -l` -eq 1 ]]; then
        echo "g k $branch" | _buffer_insert
      else
        echo "$branch" | _buffer_insert_lines
      fi
    }
}

_register_keycommand '^o^b' peco_insert_branch


#  Insert commit id
#-----------------------------------------------
peco_insert_commit() {
  git log --oneline --color=never -1000 \
    | _peco_select \
    | cut -d ' ' -f 1 \
    | _buffer_insert_lines
}

_register_keycommand '^o^l' peco_insert_commit


#  Insert issue
#-----------------------------------------------
peco_insert_issue() {
  git github ls-issue \
    | _peco_select \
    | cut -d ' ' -f 1 \
    | cut -c 2- \
    | _buffer_insert_lines
}

_register_keycommand '^o^i' peco_insert_issue


#  History
#-----------------------------------------------
peco_history() {
  \history -n 1 \
    | tail -r \
    | awk '!a[$0]++' \
    | _peco_select "$LBUFFER" \
    | _buffer_replace
}

_register_keycommand '^r' peco_history


#  GHQ
#-----------------------------------------------
peco_cd_repo() {
  ghq list \
    | _peco_select \
    | {
      repo="$(cat)"

      if ! [ -z "$repo" ]; then
        echo 'cd' "$(ghq root)/$repo" | _buffer_replace
        zle accept-line
      fi
    }
}

_register_keycommand '^q' peco_cd_repo

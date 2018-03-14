#=== Key bindings
#==============================================================================================
# Make sure that the terminal is in application mode when zle is active, since
# only then values from $terminfo are valid
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
  function zle-line-init() {
    echoti smkx
  }
  function zle-line-finish() {
    echoti rmkx
  }
  zle -N zle-line-init
  zle -N zle-line-finish
fi

# emacs like keybind
bindkey -e

# do history expansion by <Space>
bindkey ' ' magic-space

# delete backward by <Backspace>
bindkey '^?' backward-delete-char

# delete forward by <Delete>
bindkey "^[[3~" delete-char
bindkey "^[3;5~" delete-char
bindkey "\e[3~" delete-char

# Edit the current command line in $EDITOR
autoload -U edit-command-line
zle -N edit-command-line
bindkey '\C-x\C-e' edit-command-line

# paste last word
bindkey '^o^w' copy-prev-shell-word


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
  tmux ls \
    | grep -v attached \
    | cut -d: -f 1 \
    | xargs -n 1 tmux kill-session -t
}


#  Load .env
#-----------------------------------------------
load-env() {
  set -o allexport
  source .env
  set +o allexport
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
  ag --follow --nocolor --nogroup -g '' \
    | _peco_select \
    | {
      file="$(cat)"

      if [ "$LBUFFER" != "" ]; then
        _buffer_insert_lines <<< "$file"
      elif [ -d "$file" ]; then
        _buffer_insert <<< "cd $file"
      elif [ -f "$file" ]; then
        buf="$file"

        if ! [ -x "$file" ]; then
          case "$file" in
            *_spec.rb)
              buf="be rspec $file"
              ;;

            *)
              buf="$EDITOR $file"
              ;;
          esac
        fi

        _buffer_insert <<< "$buf"
      else
        _buffer_insert_lines <<< "$file"
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
        _buffer_insert <<< "g k $branch"
      else
        _buffer_insert_lines <<< "$branch"
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
        _buffer_replace <<< "cd $(ghq root)/$repo"
        zle accept-line
      fi
    }
}

_register_keycommand '^q' peco_cd_repo


#  Insert resource
#-----------------------------------------------
peco_insert_resource() {
  local resource

  case "$LBUFFER" in
    'wtd-kube tags '*)            resource='kube-deployment' ;;
    'wtd-kube edit deployment '*) resource='kube-deployment' ;;
    'wtd-kube scale '*)           resource='kube-deployment' ;;
    'wtd-kube '*)                 resource='kube-pod' ;;
  esac

  case "$resource" in
    kube-deployment)
      wtd-kube get deployment \
        | _peco_select \
        | awk '{ print $1 }' \
        | _buffer_insert
      ;;

    kube-pod)
      wtd-kube get po \
        | _peco_select \
        | awk '{ print $1 }' \
        | _buffer_insert
      ;;
  esac
}

_register_keycommand '^o^r' peco_insert_resource

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
  zle autosuggest-clear
  local rbuf="$RBUFFER"
  BUFFER="$LBUFFER$(cat)"
  CURSOR=$#BUFFER
  BUFFER="$BUFFER$rbuf"
}
_buffer_insert_lines() {
  cat \
    | {
      local lines=()

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

_buffer_insert_files() {
  local file="$(cat)"

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
  local envchain_ns="${1:-}"

  set -o allexport
  [ -r .env ] && source .env
  [ -n "$envchain_ns" ] && envchain -l -v "$envchain_ns"
  set +o allexport
}


#  which + edit
#-----------------------------------------------
whiche() {
  vim "$(which $1)"
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
  if [ "$(pwd)" = "$HOME" ]; then
    ls -AF \
      | sed -E 's/@$//g' \
      | _peco_select \
      | _buffer_insert_files
  else
    ag --follow --nocolor --nogroup --hidden -U -g '' \
      | _peco_select \
      | _buffer_insert_files
  fi
}

_register_keycommand '^o^p' peco_insert_path


#  Insert modified files
#-----------------------------------------------
peco_modified_file() {
  git status -s \
    | sed -E $'s/ -> /\\\n-> /g' \
    | _peco_select \
    | cut -b 4- \
    | _buffer_insert_files
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
    'kube tags '*)            resource='kube-deployment' ;;
    'kube edit deployment '*) resource='kube-deployment' ;;
    'kube scale '*)           resource='kube-deployment' ;;
    'kube '*)                 resource='kube-pod' ;;
  esac

  case "$resource" in
    kube-deployment)
      kube get deployment \
        | _peco_select \
        | awk '{ print $1 }' \
        | _buffer_insert
      ;;

    kube-pod)
      kube get po \
        | _peco_select \
        | awk '{ print $1 }' \
        | _buffer_insert
      ;;
  esac
}

_register_keycommand '^o^r' peco_insert_resource

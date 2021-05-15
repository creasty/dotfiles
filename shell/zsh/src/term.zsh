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

# word motion
bindkey '^g' forward-word

_register_keycommand() {
  zle -N $2
  bindkey "$1" $2
}

# Refresh without restart
_refresh_screen() {
  zle clear-screen
  rehash
  zle reset-prompt
}
_register_keycommand '^l' _refresh_screen

#=== Helper
#==============================================================================================
_buffer_insert() {
  zle autosuggest-clear
  local rbuf="$RBUFFER"
  BUFFER="$LBUFFER$(cat)"
  CURSOR=$#BUFFER
  BUFFER="$BUFFER$rbuf"
}

_buffer_replace() {
  BUFFER="$(cat)"
  CURSOR=$#BUFFER
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
  {
    git status -s | sed -E $'s/ -> /\\\n-> /g'
    git ls-files -v | sed -n -E '/^[Sh]/s/^/-/gp' # S = skip-worktree, h = assume-unchanged
  } \
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
peco_docker_image() {
  docker images \
    | _peco_select \
    | awk '{ print $3 }' \
    | _buffer_insert_lines
}

peco_docker_container() {
  docker ps \
    | _peco_select \
    | awk '{ print $1 }' \
    | _buffer_insert_lines
}

peco_kube_deployment() {
  local cluster="$1"

  kube "$cluster" get deployment \
    | _peco_select \
    | awk '{ print $1 }' \
    | _buffer_insert_lines
}

peco_kube_pod() {
  local cluster="$1"

  kube "$cluster" get po \
    | _peco_select \
    | awk '{ print $1 }' \
    | _buffer_insert_lines
}

peco_insert_resource() {
  local args=($(tr ' ' '\n' <<< "$LBUFFER"))

  case "${args[1]}" in
    'docker'|'dk')
      case "${args[2]}" in
        'rmi') peco_docker_image ;;
        *)     peco_docker_container ;;
      esac
      ;;

    'kube')
      local cluster="${args[2]}"
      [ -z "$cluster" ] && return

      case "${args[3]}" in
        'scale') peco_kube_deployment "$cluster" ;;
        'tags')  peco_kube_deployment "$cluster" ;;
        'edit')  peco_kube_deployment "$cluster" ;;
        *)       peco_kube_pod "$cluster" ;;
      esac
      ;;
  esac
}

_register_keycommand '^o^r' peco_insert_resource

#=== UI
#==============================================================================================
#  Title
#-----------------------------------------------
title() {
  emulate -L zsh
  setopt prompt_subst

  [[ "$EMACS" == *term* ]] && return

  : ${2=$1}

  case "$TERM" in
    cygwin|xterm*|putty*|rxvt*|ansi)
      print -Pn "\e]2;$2:q\a" # set window name
      print -Pn "\e]1;$1:q\a" # set tab name
      ;;
    screen*)
      print -Pn "\ek$1:q\e\\" # set screen hardstatus
      ;;
    *)
      if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
        print -Pn "\e]2;$2:q\a" # set window name
        print -Pn "\e]1;$1:q\a" # set tab name
      else
        # try to use terminfo to set the title
        # if the feature is available set title
        if [[ -n "$terminfo[fsl]" ]] && [[ -n "$terminfo[tsl]" ]]; then
          echoti tsl
          print -Pn "$1"
          echoti fsl
        fi
      fi
      ;;
  esac
}

title_precmd() {
  emulate -L zsh

  title '%~' '%n@%m: %~'
}
title_preexec() {
  emulate -L zsh
  setopt extended_glob

  # cmd name only, or if this is sudo or ssh, the next cmd
  local cmd=${1[(wr)^(*=*|sudo|ssh|mosh|rake|-*)]:gs/%/%%}
  local line="${2:gs/%/%%}"

  title '$cmd' '%100>...>$line%<<'
}

add-zsh-hook precmd title_precmd
add-zsh-hook preexec title_preexec

#  Nortify done
#-----------------------------------------------
local notify_prev_command=""
local notify_prev_timestamp=0

notify_preexec() {
  notify_prev_command="$1"
  notify_prev_timestamp=`date +'%s'`
}

notify_precmd() {
  local code=$?

  local command="$notify_prev_command"
  local timestamp=$notify_prev_timestamp
  notify_prev_command=""
  notify_prev_timestamp=0

  [ $timestamp -eq 0 ] && return
  [ $code -ne 130 ] && [ $code -ne 146 ] || return
  command -v 'envchain' > /dev/null 2>&1 || return

  local elapsed_time=$((`date +'%s'` - $timestamp))
  [ $elapsed_time -gt 30 ] || return

  if [ $code -eq 0 ]; then
    command="✅ $command"
  else
    command="⚠️ $command"
  fi

  localpush "$command" "$elapsed_time seconds" > /dev/null 2>&1
}

add-zsh-hook precmd notify_precmd
add-zsh-hook preexec notify_preexec

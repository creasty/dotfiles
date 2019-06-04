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


#  Blank line
#-----------------------------------------------
echo_blank() {
  if [ -z "$NEW_LINE_BEFORE_PROMPT" ]; then
    NEW_LINE_BEFORE_PROMPT=1
  elif [ "$NEW_LINE_BEFORE_PROMPT" -eq 1 ]; then
    echo
  fi
}
add-zsh-hook precmd echo_blank

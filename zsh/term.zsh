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

  title '%~%<<' '%n@%m: %~'
}
title_preexec() {
  emulate -L zsh
  setopt extended_glob

  # cmd name only, or if this is sudo or ssh, the next cmd
  local cmd=${1[(wr)^(*=*|sudo|ssh|mosh|rake|-*)]:gs/%/%%}
  local line="${2:gs/%/%%}"

  title '$cmd' '%100>...>$line%<<'
}

precmd_functions+=(title_precmd)
preexec_functions+=(title_preexec)


#  Nortify done
#-----------------------------------------------
local COMMAND=""
local COMMAND_TIME=""

notify_precmd() {
  if [ "$COMMAND_TIME" -ne "0" ] ; then
    local d=`date +%s`
    d=`expr $d - $COMMAND_TIME`
    if [ "$d" -ge "30" ] ; then
      COMMAND="$COMMAND "
      which growlnotify > /dev/null 2>&1 && growlnotify -t "${${(s: :)COMMAND}[1]}" -m "$COMMAND";
    fi
  fi
  COMMAND="0"
  COMMAND_TIME="0"
}
notify_preexec() {
  COMMAND="${1}"
  if [ "`perl -e 'print($ARGV[0]=~/ssh|^vi/)' $COMMAND`" -ne 1 ] ; then
    COMMAND_TIME=`date +%s`
  fi
}

precmd_functions+=(notify_precmd)
preexec_functions+=(notify_preexec)

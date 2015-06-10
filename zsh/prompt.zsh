autoload colors

GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWUNTRACKEDFILES=1
GIT_PS1_SHOWUPSTREAM=1

__gitdir() {
  if [ -z "${1-}" ]; then
    if [ -n "${__git_dir-}" ]; then
      echo "$__git_dir"
    elif [ -n "${GIT_DIR-}" ]; then
      test -d "${GIT_DIR-}" || return 1
      echo "$GIT_DIR"
    elif [ -d .git ]; then
      echo .git
    else
      git rev-parse --git-dir 2>/dev/null
    fi
  elif [ -d "$1/.git" ]; then
    echo "$1/.git"
  else
    echo "$1"
  fi
}

__git_ps1() {
  local g="$(__gitdir)"
  [ -z "$g" ] && return

  local r=""
  local b=""
  local step=""
  local total=""

  if [ -d "$g/rebase-merge" ]; then
    b="$(cat "$g/rebase-merge/head-name")"
    step=$(cat "$g/rebase-merge/msgnum")
    total=$(cat "$g/rebase-merge/end")

    if [ -f "$g/rebase-merge/interactive" ]; then
      r=" rebase-i"
    else
      r=" rebase-m"
    fi
  else
    if [ -d "$g/rebase-apply" ]; then
      step=$(cat "$g/rebase-apply/next")
      total=$(cat "$g/rebase-apply/last")
      if [ -f "$g/rebase-apply/rebasing" ]; then
        r=" rebase"
      elif [ -f "$g/rebase-apply/applying" ]; then
        r=" am"
      else
        r=" am/rebase"
      fi
    elif [ -f "$g/MERGE_HEAD" ]; then
      r=" merging"
    elif [ -f "$g/CHERRY_PICK_HEAD" ]; then
      r=" cherry-picking"
    elif [ -f "$g/REVERT_HEAD" ]; then
      r=" reverting"
    elif [ -f "$g/BISECT_LOG" ]; then
      r=" bisecting"
    fi

    b="$(git symbolic-ref --short HEAD 2>/dev/null)" ||
    b="$(git describe --tags --exact-match HEAD 2> /dev/null)" ||
    b="$(cut -c1-7 "$g/HEAD" 2>/dev/null)..." ||
    b="unknown"
  fi

  if [ -n "$step" ] && [ -n "$total" ]; then
    r="$r $step/$total"
  fi

  local w=""
  local i=""
  local s=""
  local u=""
  local c=""

  if [ "true" = "$(git rev-parse --is-inside-git-dir 2>/dev/null)" ]; then
    if [ "true" = "$(git rev-parse --is-bare-repository 2>/dev/null)" ]; then
      c="bare:"
    else
      b="gitdir!"
    fi
  elif [ "true" = "$(git rev-parse --is-inside-work-tree 2>/dev/null)" ]; then
    if [ -n "${GIT_PS1_SHOWDIRTYSTATE-}" ] &&
        [ "$(git config --bool bash.showDirtyState)" != "false" ]
    then
      git diff --no-ext-diff --quiet --exit-code || w="*"
      if git rev-parse --quiet --verify HEAD >/dev/null; then
        git diff-index --cached --quiet HEAD -- || i="+"
      else
        i="#"
      fi
    fi
    if [ -n "${GIT_PS1_SHOWSTASHSTATE-}" ]; then
      git rev-parse --verify refs/stash >/dev/null 2>&1 && s="$"
    fi

    if [ -n "${GIT_PS1_SHOWUNTRACKEDFILES-}" ] &&
      [ "$(git config --bool bash.showUntrackedFiles)" != "false" ] &&
      [ -n "$(git ls-files --others --exclude-standard)" ]
    then
      u="%${ZSH_VERSION+%}"
    fi
  fi

  printf -- " ${fg[blue]}on${fg[white]} %s ${fg[red]}%s%s%s${reset_color}" "$c${b##refs/heads/}" "$w$i$s$u" "$r"
}

PROMPT="
%F{blue}in %f%F{white}\${(%):-%~}%f\$(__git_ps1)%f
%F{blue}❯ %f"

PROMPT2="%F{white}❯ %f"

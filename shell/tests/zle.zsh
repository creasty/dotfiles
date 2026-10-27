# Types into a new terminal's zsh, on a pty as zle needs, for helper.bash's zle_type:
#
#   zsh -f zle.zsh <out dir> <keys>...
#
# Waits for the prompt, then types each <keys> a moment apart, so that zle reads it alone and its async work (a
# suggestion) lands. Ends with F12, which ~/.zlogin binds to write the command line to <out dir>/line, then writes
# what the shell printed to <out dir>/screen.

zmodload zsh/zpty zsh/datetime
local out=$1
shift

local screen='' chunk
# Reads what the shell prints, for a while: drain <seconds>
drain() {
  local until=$(( EPOCHREALTIME + $1 ))
  while (( EPOCHREALTIME < until )); do
    zpty -rt shell chunk && screen+=$chunk || sleep 0.02
  done
}

zpty shell "${(q)SHELL} -il"

# The prompt: zle turns bracketed paste on as it starts reading a line
local until=$(( EPOCHREALTIME + 15 ))
while [[ $screen != *$'\e[?2004h'* ]]; do
  if (( EPOCHREALTIME > until )); then
    print -r -- "zle.zsh: no prompt; the shell printed: ${(V)screen}" >&2
    exit 1
  fi
  drain 0.05
done

local keys
for keys; do
  zpty -w -n shell "$keys"
  drain 0.5
done

zpty -w -n shell $'\e[24~'
until=$(( EPOCHREALTIME + 15 ))
while [[ ! -e $out/line ]]; do
  if (( EPOCHREALTIME > until )); then
    print -r -- "zle.zsh: F12 wrote no line; the shell printed: ${(V)screen}" >&2
    exit 1
  fi
  drain 0.05
done
print -rn -- "$screen" > "$out/screen"
zpty -d shell

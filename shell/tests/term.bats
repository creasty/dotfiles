#!/usr/bin/env bats
#
# What zsh's line editor does in a terminal: the key bindings, the widgets that pick with peco, and the title and
# notifications around commands (shell/zsh/src/term.zsh, with the settings of shell/zsh/zshrc)

load helper

# Keys, by the bytes a terminal sends
C_A=$'\ca' C_E=$'\ce' C_G=$'\cg' C_L=$'\cl' C_Q=$'\cq' C_R=$'\cr' C_V=$'\cv'
C_O_B=$'\co\cb' C_O_L=$'\co\cl' C_O_M=$'\co\r' C_O_P=$'\co\cp' C_O_R=$'\co\cr' C_O_W=$'\co\cw'
C_X_E=$'\cx\ce'
BACKSPACE=$'\x7f' DELETE=$'\e[3~' CTRL_DELETE=$'\e[3;5~' RETURN=$'\r'

setup() {
  zsh_home
  cd "$BATS_TEST_TMPDIR" || return
  export GIT_CONFIG_GLOBAL="$BATS_TEST_TMPDIR/gitconfig" GIT_CONFIG_NOSYSTEM=1
  git config --global user.name test
  git config --global user.email test@example.com
  git config --global init.defaultBranch master
}

# peco, faked: it picks the lines of its input that match the given extended regular expressions, or none:
# peco_picks [<regex>...]. Its input goes to $BATS_TEST_TMPDIR/peco.in.
peco_picks() {
  local picks="$BATS_TEST_TMPDIR/peco.picks"
  : > "$picks"
  [ $# -eq 0 ] || printf '%s\n' "$@" > "$picks"
  fake peco "cat > $(q "$BATS_TEST_TMPDIR/peco.in"); grep -E -f $(q "$picks") $(q "$BATS_TEST_TMPDIR/peco.in") || true"
}

peco_input() {
  cat "$BATS_TEST_TMPDIR/peco.in"
}

# The shell's history, oldest first: history_of <command>...
history_of() {
  local command
  for command; do
    printf ': 1700000000:0;%s\n' "$command"
  done > "$ZSH_HOME/.zsh_history"
}

# Asserts that the shell printed a string: assert_printed <string> [<message>]
assert_printed() {
  [[ "$(cat "$BATS_TEST_TMPDIR/screen")" == *"$1"* ]] && return
  printf '%s, not found in:\n%s\n' "${2:-$1}" "$(cat -v "$BATS_TEST_TMPDIR/screen")" >&2
  return 1
}

#  Editing
#-----------------------------------------------
@test "the line edits as in Emacs" {
  run -0 zle_type 'world' "$C_A" 'hello ' "$C_E" '!'
  assert_equal "$output" 'hello world!|'
}

@test "C-g moves to the next word" {
  run -0 zle_type 'one two' "$C_A" "$C_G"
  assert_equal "$output" 'one |two'
}

@test "Space expands a history reference" {
  run -0 zle_type "echo one$RETURN" '!! '
  assert_equal "$output" 'echo one |'
}

@test "Backspace deletes the character before the cursor, Delete and C-Delete the one under it" {
  run -0 zle_type 'abcde' "$BACKSPACE" "$C_A" "$DELETE" "$CTRL_DELETE"
  assert_equal "$output" '|cd'
}

@test "C-o C-w copies the word before the cursor" {
  run -0 zle_type 'mv long-name ' "$C_O_W"
  assert_equal "$output" 'mv long-name long-name|'
}

@test "C-x C-e edits the line in Neovim" {
  fake nvim 'eval "file=\${$#}"; echo "echo edited" > "$file"'
  run -0 zle_type 'echo typed' "$C_X_E"
  assert_equal "${output/|/}" 'echo edited'
  run -0 calls
  assert_like "$output" "nvim -c 'normal! 11go' -- *"
}

@test "C-v pastes the clipboard at the cursor" {
  fake pbpaste 'printf pasted'
  run -0 zle_type 'echo []' $'\cb' "$C_V"
  assert_equal "$output" 'echo [pasted|]'
}

@test "C-l clears the screen and finds the commands installed since the shell started" {
  local cmd
  cmd="$(q "$BATS_TEST_TMPDIR/fakes/freshcmd")"
  run -0 zle_type 'freshcm' $'\t' $'\cu' ": > $cmd; chmod +x $cmd$RETURN" "$C_L" 'freshcm' $'\t'
  assert_equal "$output" 'freshcmd |'
  assert_printed $'\e[H\e[2J' 'the clear sequence'
}

# zle_highlight=(paste:none)
@test "pasted text shows as typed, without a highlight" {
  run -0 zle_type $'\e[200~echo pasted\e[201~'
  assert_equal "$output" 'echo pasted|'
  # After the prompt, which starts with a % in standout where the previous output left a line unfinished
  local typed
  typed="$(cat "$BATS_TEST_TMPDIR/screen")"
  typed="${typed#*$'\e[?2004h'}"
  [[ $typed != *$'\e[7m'* ]] || {
    echo "highlighted (standout): $(cat -v <<< "$typed")" >&2
    return 1
  }
}

@test "while the line is edited, the terminal is in application mode, which \$terminfo's keys are for" {
  run -0 zle_type "true$RETURN"
  assert_printed $'\e[?1h\e=' 'application mode (smkx)'
  assert_printed $'\e[?1l\e>' 'back to normal mode (rmkx)'
}

#  Picking with peco
#-----------------------------------------------
@test "C-r puts a command of the history, newest first, in place of the line, which peco starts with" {
  history_of 'echo one' 'echo two' 'echo one' 'ls'
  peco_picks '^echo two$'
  run -0 zle_type 'echo' "$C_R"
  assert_equal "$output" 'echo two|'
  assert_equal "$(peco_input)" $'ls\necho one\necho two'
  run -0 calls
  assert_line 'peco --query echo'
}

# ZSH_AUTOSUGGEST_IGNORE_WIDGETS=(... peco_\*)
@test "a line peco filled gets no suggestion" {
  history_of 'echo hello' 'echo hello world'
  peco_picks '^echo hello$'
  run -0 zle_type "$C_R"
  assert_equal "$output" 'echo hello|'
  assert_equal "$(cat "$BATS_TEST_TMPDIR/suggestion")" ''
}

@test "with nothing to pick, peco says so" {
  git init -q "$ZSH_HOME/repo"
  peco_picks
  run -0 zle_type "cd repo$RETURN" "$C_O_L"
  assert_equal "$output" '|'
  run -0 calls
  assert_line 'peco --query (nothing)'
}

@test "C-o C-p, on an empty line, puts the picked file below the directory in Neovim's command line" {
  mkdir -p "$ZSH_HOME/project/src/.hidden"
  touch "$ZSH_HOME/project/src/app.ts" "$ZSH_HOME/project/src/.hidden/file"
  peco_picks '^src/app.ts$'
  run -0 zle_type "cd project$RETURN" "$C_O_P"
  assert_equal "$output" 'nvim src/app.ts|'
  assert_equal "$(peco_input | sort)" $'src/.hidden/file\nsrc/app.ts'
}

@test "C-o C-p runs a picked spec with RSpec, and a picked executable as is" {
  mkdir -p "$ZSH_HOME/project/spec" "$ZSH_HOME/project/bin"
  touch "$ZSH_HOME/project/spec/user_spec.rb"
  install -m 755 /dev/null "$ZSH_HOME/project/bin/run"
  peco_picks 'user_spec'
  run -0 zle_type "cd project$RETURN" "$C_O_P"
  assert_equal "$output" 'be rspec spec/user_spec.rb|'
  peco_picks '^bin/run$'
  run -0 zle_type "cd project$RETURN" "$C_O_P"
  assert_equal "$output" 'bin/run|'
}

@test "C-o C-p, in the home directory, picks from its entries: a directory to cd into, a link by its name" {
  mkdir "$ZSH_HOME/Projects"
  peco_picks '^Projects'
  run -0 zle_type "$C_O_P"
  assert_equal "$output" 'cd Projects/|'
  run -0 peco_input
  assert_line '.zshrc'
  assert_line 'Projects/'
}

@test "C-o C-p, after words on the line, adds the picked files, quoted" {
  mkdir -p "$ZSH_HOME/project"
  touch "$ZSH_HOME/project/a b.txt" "$ZSH_HOME/project/c.txt"
  peco_picks '^a b.txt$' '^c.txt$'
  run -0 zle_type "cd project$RETURN" 'cat ' "$C_O_P"
  assert_equal "$output" 'cat a\ b.txt c.txt|'
}

@test "C-o Return picks from the changed files, the files git skips and the new names of the renamed" {
  local repo="$ZSH_HOME/repo"
  git init -q "$repo"
  (
    cd "$repo"
    touch changed renamed skipped
    git add . && git commit -q -m init
    echo change > changed
    git mv renamed new-name
    git update-index --skip-worktree skipped
    touch untracked
  )
  peco_picks '^-> new-name$'
  run -0 zle_type "cd repo$RETURN" "$C_O_M"
  assert_equal "$output" 'nvim new-name|'
  assert_equal "$(peco_input)" $' M changed\nR  renamed\n-> new-name\n?? untracked\n-S skipped'
}

@test "C-o C-b checks out the picked branch, or goes to the worktree that has it" {
  local repo="$ZSH_HOME/repo"
  git init -q "$repo"
  git -C "$repo" commit -q --allow-empty -m init
  git -C "$repo" branch feature
  git -C "$repo" worktree add -q -b 'in-tree' "$ZSH_HOME/tree dir"
  peco_picks feature
  run -0 zle_type "cd repo$RETURN" "$C_O_B"
  assert_equal "$output" 'g k feature|'
  run -0 peco_input
  assert_like "${lines[0]}" '  feature*'
  assert_like "${lines[1]}" "+ in-tree  *$ZSH_HOME/tree dir"
  assert_like "${lines[2]}" "\\* master  *$ZSH_HOME/repo"
  peco_picks in-tree
  run -0 zle_type "cd repo$RETURN" "$C_O_B"
  assert_equal "$output" "cd $(q "$ZSH_HOME/tree dir")|"
}

@test "C-o C-b, after words on the line, adds the picked branches" {
  local repo="$ZSH_HOME/repo"
  git init -q "$repo"
  git -C "$repo" commit -q --allow-empty -m init
  git -C "$repo" branch feature
  peco_picks feature master
  run -0 zle_type "cd repo$RETURN" 'git log ' "$C_O_B"
  assert_equal "$output" 'git log feature master|'
}

@test "C-o C-l adds the picked commits' hashes" {
  local repo="$ZSH_HOME/repo"
  git init -q "$repo"
  git -C "$repo" commit -q --allow-empty -m first
  git -C "$repo" commit -q --allow-empty -m second
  local first second
  first="$(git -C "$repo" log --format=%h -1 HEAD~)" second="$(git -C "$repo" log --format=%h -1)"
  peco_picks ' first$'
  run -0 zle_type "cd repo$RETURN" 'git show ' "$C_O_L"
  assert_equal "$output" "git show $first|"
  assert_equal "$(peco_input)" "$second second"$'\n'"$first first"
}

@test "C-q goes to the picked repository of ghq" {
  mkdir -p "$BATS_TEST_TMPDIR/ghq/github.com/acme/app"
  fake ghq "case \$1 in
    root) echo $(q "$BATS_TEST_TMPDIR/ghq") ;;
    list) printf '%s\n' github.com/acme/app github.com/acme/lib ;;
  esac"
  peco_picks app
  run -0 zle_type "$C_Q"
  assert_equal "$output" '|'
  assert_equal "$(cat "$BATS_TEST_TMPDIR/pwd")" "$BATS_TEST_TMPDIR/ghq/github.com/acme/app"
}

@test "C-o C-r adds the picked images to docker rmi, and the picked containers to other docker commands" {
  fake docker "case \$1 in
    images) printf '%s\n' 'REPOSITORY TAG IMAGE ID' 'redis alpine 1a2b3c4d' ;;
    ps) printf '%s\n' 'CONTAINER ID IMAGE' 'f00dcafe redis:alpine' ;;
  esac"
  peco_picks '^redis'
  run -0 zle_type 'docker rmi ' "$C_O_R"
  assert_equal "$output" 'docker rmi 1a2b3c4d|'
  peco_picks '^f00dcafe'
  run -0 zle_type 'dk logs ' "$C_O_R"
  assert_equal "$output" 'dk logs f00dcafe|'
}

@test "C-o C-r picks nothing for other commands" {
  peco_picks
  run -0 zle_type 'ls ' "$C_O_R"
  assert_equal "$output" 'ls |'
  assert_equal "$(calls)" ''
}

#  Title
#-----------------------------------------------
@test "at the prompt, the tab's title is the directory and the window's the user, host and directory" {
  run -0 zle_type
  assert_printed $'\e]1;~\a' "the tab's title"
  assert_printed $'\e]2;'"$(id -un)@$(hostname -s): ~"$'\a' "the window's title"
}

@test "while a command runs, the tab's title is its name and the window's its line" {
  run -0 zle_type "LANG=C true --flag 100%$RETURN"
  assert_printed $'\e]1;true\a' "the tab's title"
  assert_printed $'\e]2;LANG=C true --flag 100%\a' "the window's title"
}

@test "in Neovim's terminal, the title is zsh at the prompt and the command's name while it runs, with the directory in OSC 7" {
  ZLE_ENV="NVIM=$BATS_TEST_TMPDIR/nvim.sock" run -0 zle_type "true$RETURN"
  assert_printed $'\e]2;zsh\a' 'zsh at the prompt'
  assert_printed $'\e]2;true\a' "the command's name"
  assert_printed $'\e]7;file://'"$(hostname)$ZSH_HOME"$'\e\\' 'the directory'
}

#  Notifications
#-----------------------------------------------
# date, faked: a clock in seconds that the commands typed set
fake_clock() {
  echo 1000 > "$BATS_TEST_TMPDIR/now"
  fake date "cat $(q "$BATS_TEST_TMPDIR/now")"
  fake localpush
}

# A command that takes the given seconds on the clock, then exits with the given status: takes <seconds> [<status>]
takes() {
  echo "echo \$(( \$(< $(q "$BATS_TEST_TMPDIR/now")) + $1 )) > $(q "$BATS_TEST_TMPDIR/now"); (exit ${2:-0})"
}

@test "a command that takes over 30 seconds notifies how it ended" {
  fake_clock
  run -0 zle_type "$(takes 31)$RETURN" "$(takes 40 1)$RETURN"
  run -0 calls
  assert_line "localpush '✅ $(takes 31)' '31 seconds'"
  assert_line "localpush '⚠️ $(takes 40 1)' '40 seconds'"
}

@test "a command that takes 30 seconds or less, or is interrupted, notifies nothing" {
  fake_clock
  run -0 zle_type "$(takes 30)$RETURN" "$(takes 60 130)$RETURN" "$(takes 60 146)$RETURN"
  run -0 calls
  [[ "$output" != *localpush* ]] || {
    echo "notified: $output" >&2
    return 1
  }
}

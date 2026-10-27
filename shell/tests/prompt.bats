#!/usr/bin/env bats
#
# zsh's prompt: the directory, and in a git repository its branch, changes and the operation in progress
# (shell/zsh/src/prompt.zsh)

# The prompt shows ~ for the home directory
# shellcheck disable=SC2088

load helper

setup() {
  zsh_home
  export GIT_CONFIG_GLOBAL="$BATS_TEST_TMPDIR/gitconfig" GIT_CONFIG_NOSYSTEM=1
  git config --global user.name test
  git config --global user.email test@example.com
  git config --global init.defaultBranch master
  git config --global advice.detachedHead false
  cd "$ZSH_HOME" || return
}

# The prompt in a directory below the shell's home, without its colors: prompt_in <dir>
prompt_in() {
  zsh_run "cd $(q "$1") && print -rP -- \"\$PROMPT\"" | sed $'s/\e\\[[0-9;]*m//g'
}

# A repository with a commit of a file: repo <dir>
repo() {
  git init -q "$1"
  echo one > "$1/file"
  git -C "$1" add file
  git -C "$1" commit -q -m one
}

@test "the prompt shows the directory, and \$ on a line of its own" {
  mkdir plain
  run -0 prompt_in plain
  assert_equal "${lines[0]}" '~/plain'
  assert_equal "${lines[1]}" '$ '
}

@test "in a repository, the prompt adds the branch" {
  repo app
  run -0 prompt_in app
  assert_equal "${lines[0]}" '~/app @ master '
}

@test "the prompt marks unstaged changes *, staged ones +, untracked files % and the files git skips -" {
  repo app
  (
    cd app
    touch skipped && git add skipped && git commit -q -m skipped
    git update-index --skip-worktree skipped
    echo two > file
    touch staged && git add staged
    touch untracked
  )
  run -0 prompt_in app
  assert_equal "${lines[0]}" '~/app @ master *+%-'
}

@test "the prompt marks a repository without commits #" {
  git init -q new
  run -0 prompt_in new
  assert_equal "${lines[0]}" '~/new @ master #'
}

@test "with HEAD detached, the prompt shows its tag, or its hash" {
  repo app
  git -C app tag v1.0.0
  git -C app commit -q --allow-empty -m two
  git -C app checkout -q v1.0.0
  run -0 prompt_in app
  assert_equal "${lines[0]}" '~/app @ v1.0.0 '
  git -C app checkout -q master~0
  run -0 prompt_in app
  assert_equal "${lines[0]}" "~/app @ $(git -C app rev-parse --short=7 HEAD) "
}

# A conflict leaves changes both staged and not: *+
@test "the prompt shows a merge, cherry-pick, revert or bisect in progress" {
  repo app
  (
    cd app
    git checkout -q -b topic
    echo topic > file && git commit -q -am topic
    git checkout -q master
    echo master > file && git commit -q -am master
  )
  local start stop expected shown problems=''
  while IFS='|' read -r start stop expected; do
    # shellcheck disable=SC2086 # git's arguments
    git -C app $start > /dev/null 2>&1 || true
    shown="$(prompt_in app | head -n 1)"
    [ "$shown" = "~/app @ master $expected" ] || problems+="$start: $shown"$'\n'
    # shellcheck disable=SC2086
    git -C app $stop > /dev/null 2>&1
  done <<'EOF'
merge topic|merge --abort|*+ merging
cherry-pick topic|cherry-pick --abort|*+ cherry-picking
revert --no-edit HEAD~|revert --abort|*+ reverting
bisect start|bisect reset| bisecting
EOF
  assert_none "$problems" 'not shown as expected'
}

@test "during an interactive rebase, the prompt shows the branch being rebased and the step" {
  repo app
  (
    cd app
    git checkout -q -b topic
    git commit -q --allow-empty -m two
    git commit -q --allow-empty -m three
    GIT_SEQUENCE_EDITOR="sed -i.bak s/^pick/edit/" git rebase -q -i HEAD~2 > /dev/null 2>&1
  )
  run -0 prompt_in app
  assert_equal "${lines[0]}" '~/app @ topic  rebase-i 1/2'
}

@test "in a repository's .git, the prompt says so, and in a bare repository marks the branch bare:" {
  repo app
  git clone -q --bare app app.git
  run -0 prompt_in app/.git
  assert_equal "${lines[0]}" '~/app/.git @ gitdir! '
  run -0 prompt_in app.git
  assert_equal "${lines[0]}" '~/app.git @ bare:master '
}

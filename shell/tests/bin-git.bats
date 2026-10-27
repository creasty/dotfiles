#!/usr/bin/env bats
#
# The git subcommands in bin/ (`git <name>` runs bin/git-<name>), on repositories in the test's directory, with bare
# repositories there as origin, and fakes for the browser, the clipboard and peco

load helper

setup() {
  PATH="$BATS_TEST_TMPDIR/fakes:$DOTFILES_PATH/bin:$PATH"
  export GIT_CONFIG_GLOBAL="$BATS_TEST_TMPDIR/gitconfig" GIT_CONFIG_NOSYSTEM=1
  cat > "$GIT_CONFIG_GLOBAL" <<'EOF'
[user]
  name = Test
  email = test@example.com
[init]
  defaultBranch = main
[advice]
  detachedHead = false
EOF
  cd "$BATS_TEST_TMPDIR" || return
}

# Makes a repository with an empty first commit, and goes into it: repo <dir> [<git init option>...]
repo() {
  git init --quiet "${@:2}" "$1" && cd "$1" && git commit --quiet --allow-empty -m init
}

# Makes origin.git and a clone of it, whose main tracks origin's, and goes into the clone: clone <dir>
clone() {
  git init --quiet --bare origin.git
  git clone --quiet origin.git "$1" 2> /dev/null # that it's empty
  cd "$1" && git commit --quiet --allow-empty -m init && git push --quiet --set-upstream origin main
}

# Writes a file and commits it: commit <file> <content> [<message>]
commit() {
  printf '%s\n' "$2" > "$1"
  git add "$1"
  git commit --quiet -m "${3:-$1}"
}

# The local branches, a line each
branches() {
  git for-each-ref --format='%(refname:short)' refs/heads/
}

# The names of the worktrees' directories, a line each
worktrees() {
  git worktree list --porcelain | sed -n 's|^worktree .*/||p' | sort
}

# Runs a command, with what it prints to stderr too, without colors
uncolored() {
  (
    set -o pipefail
    "$@" 2>&1 | sed $'s/\e\\[[0-9;]*m//g'
  )
}

#  git branch-delete-merged (git dmb)
#-----------------------------------------------
@test "git branch-delete-merged deletes the branches merged with a merge commit or a fast-forward" {
  repo r
  git checkout --quiet -b fast-forwarded
  commit a 1
  git checkout --quiet main
  git merge --quiet --ff-only fast-forwarded
  git checkout --quiet -b merged
  commit b 1
  git checkout --quiet main
  commit c 1
  git merge --quiet --no-ff -m merge merged
  run -0 git branch-delete-merged
  assert_equal "$(branches)" main
}

@test "git branch-delete-merged deletes a squash-merged branch, though the base changed its lines since" {
  repo r
  git checkout --quiet -b squashed
  commit a 1
  commit a 2
  git checkout --quiet main
  commit b 1
  git merge --quiet --squash squashed
  git commit --quiet -m squash
  commit a 3
  run -0 git branch-delete-merged
  assert_equal "$(branches)" main
}

@test "git branch-delete-merged deletes a squash-merged branch whose patch differs, as the base changed lines near it" {
  repo r
  commit f "$(seq 7)"
  git checkout --quiet -b squashed
  commit f "$(seq 7 | sed 's/^4$/four/')"
  git checkout --quiet main
  commit f "$(seq 7 | sed 's/^2$/two/')"
  git merge --quiet --squash squashed
  git commit --quiet -m squash
  run -0 git branch-delete-merged
  assert_equal "$(branches)" main
}

@test "git branch-delete-merged deletes a rebase-merged branch" {
  repo r
  git checkout --quiet -b rebased
  commit a 1
  commit c 1
  git checkout --quiet main
  commit b 1
  git cherry-pick rebased~1 rebased > /dev/null
  run -0 git branch-delete-merged
  assert_equal "$(branches)" main
}

@test "git branch-delete-merged keeps the branches with changes HEAD hasn't, or no history in common with it" {
  repo r
  git checkout --quiet -b wip
  commit a 1
  git checkout --quiet --orphan unrelated
  git commit --quiet -m unrelated
  git checkout --quiet main
  run -0 git branch-delete-merged
  assert_equal "$(branches)" $'main\nunrelated\nwip'
}

@test "git branch-delete-merged keeps master, main, develop and the branches checked out in worktrees" {
  repo r
  git branch master
  git branch develop
  git branch merged
  git worktree add --quiet -b elsewhere ../elsewhere
  git checkout --quiet -b current
  run -0 git branch-delete-merged
  assert_equal "$(branches)" $'current\ndevelop\nelsewhere\nmain\nmaster'
}

@test "git branch-delete-merged with a base deletes the branches merged into it, but not the base" {
  repo r
  git checkout --quiet -b feature
  commit a 1
  git checkout --quiet -b release main
  git merge --quiet --no-ff -m merge feature
  git checkout --quiet main
  run -0 git branch-delete-merged release
  assert_equal "$(branches)" $'main\nrelease'
}

@test "git branch-delete-merged with a base that isn't a commit fails, and deletes nothing" {
  repo r
  git branch merged
  run -1 git branch-delete-merged nothing
  assert_equal "$output" 'git-branch-delete-merged: not a valid commit: nothing'
  assert_equal "$(branches)" $'main\nmerged'
}

#  git checkout-origin (git fok)
#-----------------------------------------------
# Pushes a commit to origin's branch feature from another clone
push_feature() {
  local dir="$BATS_TEST_TMPDIR/elsewhere"
  [ -d "$dir" ] || git clone --quiet "$BATS_TEST_TMPDIR/origin.git" "$dir" -b main
  git -C "$dir" checkout --quiet -B feature
  git -C "$dir" commit --quiet --allow-empty -m feature
  git -C "$dir" push --quiet origin feature
}

@test "git checkout-origin checks out a branch origin has" {
  clone c
  push_feature
  run -0 uncolored git checkout-origin feature
  assert_line '==> Fetching feature...'
  assert_line '==> Checking out...'
  assert_equal "$(git rev-parse --abbrev-ref '@{upstream}')" origin/feature
  assert_equal "$(git rev-parse HEAD)" "$(git -C ../origin.git rev-parse feature)"
}

@test "git checkout-origin brings a branch that's behind origin's up to date" {
  clone c
  push_feature
  git fetch --quiet
  git branch --quiet feature origin/feature
  push_feature
  run -0 uncolored git checkout-origin feature
  assert_line '==> Pulling...'
  assert_equal "$(git rev-parse HEAD)" "$(git -C ../origin.git rev-parse feature)"
}

@test "git checkout-origin without a branch picks one of origin's with peco" {
  clone c
  push_feature
  fake peco "cat > $(q "$BATS_TEST_TMPDIR/choices"); echo feature"
  run -0 git checkout-origin
  assert_equal "$(cat "$BATS_TEST_TMPDIR/choices")" $'feature\nmain'
  assert_equal "$(git branch --show-current)" feature
}

@test "git checkout-origin with nothing picked in peco fetches and checks out nothing" {
  clone c
  push_feature
  fake peco 'cat > /dev/null'
  run -1 git checkout-origin
  assert_equal "$output" ''
  assert_equal "$(git branch --show-current)" main
}

#  git compare (git cmp)
#-----------------------------------------------
@test "git compare summarizes the commits of the current branch that the default branch hasn't" {
  repo r
  commit a 1
  git checkout --quiet -b topic
  GIT_AUTHOR_DATE="@$(($(date +%s) - 3 * 86400)) +0000" commit b 1 two
  commit a $'x\ny' three
  run -0 uncolored git compare
  assert_equal "$output" "     Commits  2
       Files  2
     Changes  +3 -1
First commit  3 days ago

a
b

+ $(git rev-parse HEAD~) two
+ $(git rev-parse HEAD) three"
}

@test "git compare takes the head, then the base" {
  repo r
  git checkout --quiet -b release
  commit a 1 released
  git checkout --quiet -b topic
  commit b 1 new
  git checkout --quiet main
  run -0 uncolored git compare topic release
  assert_line '     Commits  1'
  assert_line "+ $(git rev-parse topic) new"
}

#  git get-default-branch
#-----------------------------------------------
@test "git get-default-branch prints develop when there's one, before main" {
  repo r
  git branch develop
  run -0 git get-default-branch
  assert_equal "$output" develop
}

@test "git get-default-branch prints main when there's no develop" {
  repo r
  run -0 git get-default-branch
  assert_equal "$output" main
}

@test "git get-default-branch prints origin's default branch when there's neither" {
  repo src -b trunk
  git clone --quiet . ../c
  cd ../c
  git checkout --quiet -b topic
  git branch --quiet -D trunk
  run -0 git get-default-branch
  assert_equal "$output" trunk
}

@test "git get-default-branch prints master when nothing tells" {
  repo r -b trunk
  run -0 git get-default-branch
  assert_equal "$output" master
}

#  git github-compare (git pr)
#-----------------------------------------------
# A repository on the branch topic, whose origin is on GitHub, but takes pushes in origin.git: github_repo <url>
github_repo() {
  git init --quiet --bare origin.git
  repo r
  git remote add origin "$1"
  git remote set-url --push origin "$BATS_TEST_TMPDIR/origin.git"
  git checkout --quiet -b topic
}

@test "git github-compare pushes the branch and opens the page to make its pull request" {
  github_repo git@github.com:user/repo.git
  git push --quiet --set-upstream origin topic
  commit a 1
  fake open
  run -0 git github-compare
  assert_line https://github.com/user/repo/pull/new/topic
  assert_equal "$(calls)" 'open https://github.com/user/repo/pull/new/topic'
  assert_equal "$(git -C ../origin.git rev-parse topic)" "$(git rev-parse HEAD)"
}

@test "git github-compare takes origin's URL over SSH, git or HTTPS" {
  # A name that ends in git, which only the suffix .git is to lose
  github_repo git@github.com:user/legit.git
  git push --quiet --set-upstream origin topic
  fake open
  local url
  for url in git@github.com:user/legit.git git://github.com/user/legit.git https://github.com/user/legit.git \
    https://github.com/user/legit; do
    git remote set-url origin "$url"
    run -0 git github-compare
    assert_line https://github.com/user/legit/pull/new/topic
  done
}

@test "git github-compare with an origin not on GitHub fails, and pushes nothing" {
  github_repo https://gitlab.com/user/repo.git
  fake open
  run -1 git github-compare
  assert_equal "$output" 'Remote origin is not hosted at github.com'
  assert_equal "$(calls)" ''
  run -1 git -C ../origin.git rev-parse --verify --quiet topic
}

#  git hash
#-----------------------------------------------
@test "git hash prints the SHA-1 of the modes, blobs and paths of HEAD's files, which it lists on stderr" {
  repo r
  commit a 1
  commit run 1
  chmod +x run
  git commit --quiet -am 'make run executable'
  mkdir sub
  commit sub/b 1
  echo uncommitted > a
  local listing
  listing="100644:$(git rev-parse HEAD:a):a
100755:$(git rev-parse HEAD:run):run
100644:$(git rev-parse HEAD:sub/b):sub/b"
  run -0 --separate-stderr git hash
  # shellcheck disable=SC2154 # set by run
  assert_equal "$stderr" "$listing
-----------------------------------------------"
  assert_like "$output" "*$(printf '%s\n' "$listing" | shasum | cut -d ' ' -f 1)"
}

@test "git hash prints the same SHA-1 for the same files, whatever their history, and another for others" {
  repo one
  commit a 1
  commit b 1
  cd ..
  repo two
  commit b 1
  commit a 1
  run -0 --separate-stderr git hash
  local two="$output"
  run -0 --separate-stderr git -C ../one hash
  assert_equal "$output" "$two"
  commit a 2
  run -0 --separate-stderr git hash
  [ "$output" != "$two" ]
}

@test "git hash with a path covers the files under it" {
  repo r
  commit a 1
  mkdir sub
  commit sub/b 1
  run -0 --separate-stderr git hash sub
  assert_equal "$stderr" "100644:$(git rev-parse HEAD:sub/b):sub/b
-----------------------------------------------"
}

#  git info
#-----------------------------------------------
@test "git info summarizes the repository's age, active days, files, commits and contributors" {
  git init --quiet r
  cd r
  local now
  now="$(date +%s)"
  GIT_AUTHOR_NAME=Alice GIT_AUTHOR_DATE="@$((now - 3 * 86400)) +0000" commit a 1
  GIT_AUTHOR_NAME=Bob GIT_AUTHOR_DATE="@$((now - 86400)) +0000" commit b 1
  GIT_AUTHOR_NAME=Alice GIT_AUTHOR_DATE="@$((now - 86400)) +0000" commit a 2
  # From a script, with no terminal for input
  run -0 uncolored git info < /dev/null
  assert_like "${lines[0]}" '         Age  3 days*'
  assert_equal "${output#*$'\n'}" "      Active  2 days
       Files  2
     Commits  3
Contributors  2

           2  Alice
           1  Bob"
}

#  git prlookup
#-----------------------------------------------
# A repository on master with commits that pull requests #12 and #13 merged, the first of which is $FIRST
pull_requests() {
  repo r -b master
  git remote add origin "$1"
  git checkout --quiet -b first
  commit a 1
  FIRST="$(git rev-parse HEAD)"
  git checkout --quiet master
  git merge --quiet --no-ff -m 'Merge pull request #12 from user/first' first
  git checkout --quiet -b second
  commit b 1
  git checkout --quiet master
  git merge --quiet --no-ff -m 'Merge pull request #13 from user/second' second
  fake pbcopy "cat > $(q "$BATS_TEST_TMPDIR/clipboard")"
}

@test "git prlookup prints and copies the URL of the pull request that merged a commit" {
  pull_requests https://github.com/user/repo.git
  run -0 git prlookup "$FIRST"
  assert_equal "$output" https://github.com/user/repo/pull/12
  assert_equal "$(cat "$BATS_TEST_TMPDIR/clipboard")" https://github.com/user/repo/pull/12
}

@test "git prlookup takes origin's URL over SSH" {
  pull_requests git@github.com:user/repo.git
  run -0 git prlookup "$FIRST"
  assert_equal "$output" https://github.com/user/repo/pull/12
}

@test "git prlookup for a commit no pull request merged says so, and copies nothing" {
  pull_requests https://github.com/user/repo.git
  commit c 1
  run -0 git prlookup HEAD
  assert_equal "$output" "Couldn't find any pull request for the commit"
  assert_equal "$(calls)" ''
}

@test "git prlookup with an origin not on GitHub fails" {
  pull_requests https://gitlab.com/user/repo.git
  run -1 git prlookup "$FIRST"
  assert_equal "$output" 'Remote origin is not hosted at github.com'
  assert_equal "$(calls)" ''
}

#  git release-range
#-----------------------------------------------
# Makes origin.git and a clone of it in <dir> with commits $C1 to $C5, of which v1.0.0 released C1, v1.9.0 C3,
# v1.10.0 C4, and v2.0.0-rc.1, not a release, C5: releases <dir>
releases() {
  git init --quiet --bare "$BATS_TEST_TMPDIR/origin.git"
  git clone --quiet "$BATS_TEST_TMPDIR/origin.git" "$1" 2> /dev/null # that it's empty
  cd "$1" || return
  local i
  for i in 1 2 3 4 5; do
    git commit --quiet --allow-empty -m "c$i"
  done
  C1="$(git rev-parse HEAD~4)" C2="$(git rev-parse HEAD~3)" C3="$(git rev-parse HEAD~2)"
  C4="$(git rev-parse HEAD~)" C5="$(git rev-parse HEAD)"
  git tag v1.0.0 "$C1"
  git tag v1.9.0 "$C3"
  git tag v1.10.0 "$C4"
  git tag v2.0.0-rc.1 "$C5"
  git push --quiet origin main --tags
}

@test "git release-range turns a range of commits into the range of the releases that shipped them" {
  releases r
  run -0 --separate-stderr git release-range "$C2..$C4"
  assert_equal "$output" v1.9.0..v1.10.0
  assert_like "$stderr" "*Start:  $C2 -> v1.9.0*"
  assert_like "$stderr" "*End:    $C4 -> v1.10.0*"
}

@test "git release-range ends a range that runs past the latest release there" {
  releases r
  run -0 --separate-stderr git release-range "$C1...$C5"
  assert_equal "$output" v1.0.0..v1.10.0
  assert_like "$stderr" "*End:    $C5 -> N/A*"
}

@test "git release-range prints no releases for a range after the latest" {
  releases r
  run -0 --separate-stderr git release-range "$C5..$C5"
  assert_equal "$output" ''
  assert_like "$stderr" "*Start:  $C5 -> N/A*"
}

@test "git release-range fetches origin's releases first" {
  releases r
  git -C ../origin.git tag v1.11.0 "$C5"
  run -0 --separate-stderr git release-range "$C1..$C5"
  assert_equal "$output" v1.0.0..v1.11.0
}

@test "git release-range - reads the range from stdin" {
  releases r
  run -0 --separate-stderr git release-range - <<< "$C2..$C4"
  assert_equal "$output" v1.9.0..v1.10.0
}

@test "git release-range takes a GitHub compare URL, and works in ghq's clone of the repository" {
  releases ghq/github.com/org/repo
  cd "$BATS_TEST_TMPDIR"
  fake ghq "echo $(q "$BATS_TEST_TMPDIR/ghq")"
  run -0 --separate-stderr git release-range "https://github.com/org/repo/compare/$C2...$C4"
  assert_equal "$output" v1.9.0..v1.10.0
  assert_like "$stderr" "*Repo found at $BATS_TEST_TMPDIR/ghq/github.com/org/repo*"
}

@test "git release-range with a compare URL of a repository ghq hasn't works in the current one" {
  releases r
  fake ghq "echo $(q "$BATS_TEST_TMPDIR/ghq")"
  run -0 --separate-stderr git release-range "https://github.com/org/other/compare/$C2...$C4"
  assert_equal "$output" v1.9.0..v1.10.0
  assert_like "$stderr" "*Repo not found at $BATS_TEST_TMPDIR/ghq/github.com/org/other (Using the current directory instead)*"
  cd ..
  run -1 --separate-stderr git release-range "https://github.com/org/other/compare/$C2...$C4"
  assert_like "$stderr" '*Not in git repository'
}

@test "git release-range with -h or no range prints its usage, and fails" {
  run -1 git release-range -h
  assert_equal "${lines[0]}" 'Convert a range of commits to a range of release tags'
  run -1 git release-range
  assert_equal "${lines[0]}" 'Convert a range of commits to a range of release tags'
}

@test "git release-range with a range of names fails" {
  run -1 uncolored git release-range main..topic
  assert_equal "$output" '[Error] Invalid syntax: main..topic'
}

#  git rtlookup
#-----------------------------------------------
@test "git rtlookup prints the commit a branch forked from master at" {
  repo r -b master
  commit a 1
  local fork
  fork="$(git rev-parse HEAD)"
  git checkout --quiet -b topic
  commit b 1
  git checkout --quiet master
  commit c 1
  run -0 git rtlookup topic
  assert_equal "$output" "$fork"
  git checkout --quiet topic
  run -0 git rtlookup
  assert_equal "$output" "$fork"
}

#  git split
#-----------------------------------------------
@test "git split moves the commits ahead of the upstream to a new branch, which tracks that upstream" {
  clone c
  commit a 1
  commit b 1
  local head upstream
  head="$(git rev-parse HEAD)"
  upstream="$(git rev-parse origin/main)"
  run -0 git split topic
  assert_line "[${head:0:7}...${upstream:0:7}] main"
  assert_line "[0000000...${head:0:7}] topic"
  assert_equal "$(git branch --show-current)" topic
  assert_equal "$(git rev-parse HEAD)" "$head"
  assert_equal "$(git rev-parse main)" "$upstream"
  assert_equal "$(git rev-parse --abbrev-ref 'topic@{upstream}')" origin/main
}

@test "git split without a name prints its usage" {
  run -0 git split
  assert_equal "${lines[0]}" 'Usage: git split <name>'
}

@test "git split on a detached HEAD fails, and creates no branch" {
  clone c
  git checkout --quiet --detach
  run -1 git split topic
  assert_equal "$output" "you're not on a branch"
  assert_equal "$(branches)" main
}

@test "git split on a branch that tracks nothing fails, and creates no branch" {
  repo r
  run -1 git split topic
  assert_equal "$output" 'main is not tracking anything'
  assert_equal "$(branches)" main
}

@test "git split with uncommitted changes fails, and changes nothing" {
  clone c
  commit a 1
  local head
  head="$(git rev-parse HEAD)"
  echo 2 > a
  run -1 git split topic
  assert_equal "$output" 'cannot cut branch with changes to index or working directory'
  assert_equal "$(branches)" main
  assert_equal "$(git rev-parse HEAD)" "$head"
}

#  git submodule-rm
#-----------------------------------------------
# A repository with the repository sub-src as its submodule sub
with_submodule() {
  repo sub-src
  cd ..
  repo r
  git -c protocol.file.allow=always submodule --quiet add ../sub-src sub
  git commit --quiet -m 'add sub'
}

# Asserts that the repository has no submodule sub: not in the index, .gitmodules nor its config
assert_no_submodule() {
  assert_equal "$(git ls-files --stage sub)" ''
  assert_equal "$(git config --file .gitmodules --get-regexp '^submodule\.' || true)" ''
  assert_equal "$(git config --local --get-regexp '^submodule\.' || true)" ''
}

@test "git submodule-rm removes a submodule from the index, .gitmodules and the repository's config, but not its files" {
  with_submodule
  run -0 git submodule-rm sub
  assert_no_submodule
  [ -f sub/.git ]
}

@test "git submodule-rm takes the paths from the top of the repository, wherever it runs" {
  with_submodule
  mkdir docs
  run -0 git -C docs submodule-rm sub
  assert_no_submodule
}

@test "git submodule-rm removes a submodule that was never initialized" {
  with_submodule
  git clone --quiet . ../c
  cd ../c
  run -0 git submodule-rm sub
  assert_no_submodule
}

@test "git submodule-rm works in a linked worktree" {
  with_submodule
  git worktree add --quiet ../wt
  cd ../wt
  run -0 git submodule-rm sub
  assert_no_submodule
}

@test "git submodule-rm fails outside a repository, without .gitmodules, and without a path" {
  run -1 git submodule-rm sub
  assert_equal "$output" 'Not in git repository'
  repo r
  run -1 git submodule-rm sub
  assert_equal "$output" 'No .gitmodules found'
  touch .gitmodules
  run -1 git submodule-rm
  assert_equal "$output" 'Usage: git submodule-rm <path ...>'
}

#  git worktree-remove-detached (git wtrd)
#-----------------------------------------------
@test "git worktree-remove-detached removes the detached worktrees whose HEAD is on a local or remote branch" {
  repo r
  git worktree add --quiet --detach ../detached
  git worktree add --quiet -b feature ../on-branch
  git worktree add --quiet --detach '../on remote'
  git -C '../on remote' commit --quiet --allow-empty -m remote
  git update-ref refs/remotes/origin/remote "$(git -C '../on remote' rev-parse HEAD)"
  run -0 git worktree-remove-detached
  assert_equal "$(worktrees)" $'on-branch\nr'
}

@test "git worktree-remove-detached keeps a detached worktree whose HEAD is on no branch, unless -f" {
  repo r
  git worktree add --quiet --detach ../orphan
  git -C ../orphan commit --quiet --allow-empty -m orphan
  local head
  head="$(git -C ../orphan rev-parse HEAD)"
  run -0 git worktree-remove-detached
  assert_like "$output" '*skipped, HEAD not on any branch: */orphan'
  assert_equal "$(worktrees)" $'orphan\nr'
  run -0 git worktree-remove-detached -f
  assert_like "$output" "*removing, HEAD not on any branch: */orphan (was $head)"
  assert_equal "$(worktrees)" r
}

@test "git worktree-remove-detached keeps a worktree with changes, and fails, unless -f" {
  repo r
  git worktree add --quiet --detach ../changed
  touch ../changed/new
  run -1 git worktree-remove-detached
  assert_equal "$(worktrees)" $'changed\nr'
  run -0 git worktree-remove-detached -f
  assert_equal "$(worktrees)" r
}

@test "git worktree-remove-detached keeps the worktree it runs in, and the main one, detached too" {
  repo r
  git worktree add --quiet --detach ../here
  git worktree add --quiet --detach ../other
  git checkout --quiet --detach
  cd ../here
  run -0 git worktree-remove-detached
  assert_equal "$(worktrees)" $'here\nr'
}

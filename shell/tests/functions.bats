#!/usr/bin/env bats
#
# The functions zsh has in a terminal (shell/zsh/src/functions.zsh)

load helper

setup() {
  zsh_home
  cd "$ZSH_HOME" || return
}

@test "reload replaces the shell with a new login shell" {
  run -0 zsh_run 'unloaded=no; reload' <<< 'print -r -- ${unloaded-yes}; [[ -o login ]] && print login'
  assert_equal "$output" $'yes\nlogin'
}

@test "cdrt goes to the top of the repository" {
  git init -q 'my app'
  mkdir -p 'my app/src/lib'
  run -0 zsh_run 'cd "my app/src/lib" && cdrt && print -r -- $PWD'
  assert_equal "$output" "$ZSH_HOME/my app"
}

@test "cdrt outside a repository stays" {
  mkdir plain
  run -0 zsh_run 'cd plain && cdrt; print -r -- $PWD'
  assert_equal "$output" "$ZSH_HOME/plain"
}

@test "mkd makes a directory, its parents included, and goes there" {
  run -0 zsh_run 'mkd a/b/c && print -r -- $PWD'
  assert_equal "$output" "$ZSH_HOME/a/b/c"
}

@test "load-env exports the variables of .env" {
  printf '%s\n' 'GREETING="hello world"' 'NAME=env' > .env
  run -0 zsh_run 'load-env && sh -c "echo \$GREETING, \$NAME"'
  assert_equal "$output" 'hello world, env'
}

@test "load-env with a namespace of envchain exports its variables too, and prints none" {
  printf '%s\n' 'NAME=env' > .env
  fake envchain "printf '%s\n' 'TOKEN=a secret' 'NAME=keychain'"
  run -0 zsh_run 'load-env app && sh -c "echo \$TOKEN, \$NAME"'
  assert_equal "$output" 'a secret, keychain'
  run -0 calls
  assert_equal "$output" 'envchain -l -v app'
}

@test "whiche opens a command's file in Neovim" {
  fake mycmd
  fake nvim
  run -0 zsh_run 'whiche mycmd'
  assert_equal "$(calls)" "nvim $BATS_TEST_TMPDIR/fakes/mycmd"
}

@test "whiche prints what a command is when it has no file" {
  fake nvim
  run -0 zsh_run 'whiche mkd'
  assert_like "$output" 'mkd () {*mkdir -p*'
  assert_equal "$(calls)" ''
}

@test "whichs lists a command's file" {
  fake mycmd
  run -0 zsh_run 'whichs mycmd'
  assert_like "$output" ".rwx* $BATS_TEST_TMPDIR/fakes/mycmd"
}

@test "openx opens the Xcode workspace, or else the project" {
  fake open
  mkdir app && cd app
  mkdir App.xcodeproj App.xcworkspace
  run -0 zsh_run 'cd app && openx'
  assert_equal "$output" 'Opening workspace...'
  rmdir App.xcworkspace
  run -0 zsh_run 'cd app && openx'
  assert_equal "$output" 'Opening project...'
  # (mark_dirs adds the / to the directories a glob matches)
  assert_equal "$(calls)" $'open App.xcworkspace/\nopen App.xcodeproj/'
}

@test "openx without a project says so, and fails, but keeps the shell" {
  run -0 zsh_run 'openx; print -r -- "status $?"'
  assert_equal "$output" $'Nothing found\nstatus 1'
}

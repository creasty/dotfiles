#!/usr/bin/env bats
#
# lang.golang: Go and its tools

load helper

# bats file_tags=lang:golang

@test "go and its tools are installed" {
  # shellcheck disable=SC2046
  assert_formulae $(role_formulae golang)
}

@test "go builds and runs a program" {
  require_linked .profile .zshenv
  cd "$BATS_TEST_TMPDIR"
  printf 'package main\n\nimport "fmt"\n\nfunc main() { fmt.Println("hello") }\n' > hello.go
  run -0 login_zsh 'go run hello.go'
  assert_equal "$output" hello
}

@test "gopls and golangci-lint run" {
  run -0 "$HOMEBREW_PREFIX/bin/gopls" version
  run -0 "$HOMEBREW_PREFIX/bin/golangci-lint" version
}

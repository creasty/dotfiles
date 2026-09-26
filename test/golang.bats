#!/usr/bin/env bats
#
# Go and its tools (nix/modules/go.nix)

load helper

@test "go builds and runs a program" {
  cd "$BATS_TEST_TMPDIR"
  printf 'package main\n\nimport "fmt"\n\nfunc main() { fmt.Println("hello") }\n' > hello.go
  run -0 login_zsh 'go run hello.go'
  assert_equal "$output" hello
}

@test "gopls and golangci-lint run" {
  run -0 login_zsh 'gopls version && golangci-lint version'
}

# Go and its tools
{ pkgs, username, ... }:
{
  home-manager.users.${username}.home.packages = with pkgs; [
    go
    golangci-lint # Fast linters runner for Go
    gopls # Language server for the Go language
  ];
}

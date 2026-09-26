# 1Password, which keeps the SSH keys (ssh.nix): the app, and its CLI where the app integrates with it
{ lib, ... }:
{
  homebrew.casks = [ "1password" ];

  # Copies `op` to /usr/local/bin, the path the app's integration requires
  programs._1password.enable = true;

  nixpkgs.config.allowUnfreePredicate = pkg: lib.elem (lib.getName pkg) [ "1password-cli" ];
}

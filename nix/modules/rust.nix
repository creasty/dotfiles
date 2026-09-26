# rustup, with a default toolchain and these components. `rustup update` updates the toolchain.
{ pkgs, username, ... }:
let
  components = [
    "clippy" # https://github.com/rust-lang/rust-clippy
    "rust-src" # https://github.com/rust-lang/rust
    "rust-analyzer" # https://github.com/rust-lang/rust-analyzer
  ];
in
{
  home-manager.users.${username} =
    { lib, ... }:
    {
      home.packages = [ pkgs.rustup ];

      # `rustup default` reports an implicit stable even when nothing is installed
      home.activation.installRustToolchain = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        rustup=${pkgs.rustup}/bin/rustup
        "$rustup" toolchain list | grep -q default || run "$rustup" default stable
        run "$rustup" component add ${lib.escapeShellArgs components}
      '';
    };

  dotfiles.manifest.rust.components = components;
}

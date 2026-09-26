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

      # `rustup default` reports an implicit stable even when nothing is installed. The list is matched
      # as a whole: `grep -q` could end the pipe early and fail it (pipefail) even with a default.
      home.activation.installRustToolchain = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        rustup=${pkgs.rustup}/bin/rustup
        # e.g. `stable-aarch64-apple-darwin (active, default)`, or `no installed toolchains`
        case "$("$rustup" toolchain list)" in
          *default*) ;;
          *) run "$rustup" default stable ;;
        esac
        run "$rustup" component add ${lib.escapeShellArgs components}
      '';
    };

  dotfiles.manifest.rust.components = components;
}

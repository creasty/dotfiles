# mise, and the runtimes and npm tools of config/mise/config.toml. Ruby's postinstall hook adds the default gems.
{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  verifyPythonAttestations = config.dotfiles.verifyPythonAttestations;
in
{
  options.dotfiles.verifyPythonAttestations = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Whether mise verifies the attestations of the Python it installs, through GitHub's API without a token.";
  };

  config = {
    # Ruby is built against Homebrew's libraries (ruby.compile). Each is installed on its own: Homebrew removes a
    # library that was installed as another formula's dependency along with that formula, and Ruby then fails to start
    # (as with gmp, which ruby-build builds against whenever it finds it).
    homebrew.brews = [
      "gmp"
      "libyaml"
      "openssl@3"
      "zlib"
    ];

    home-manager.users.${username} =
      { lib, ... }:
      let
        # mise and git, Homebrew's libraries, and the compiler of the Command Line Tools
        path = "${
          lib.makeBinPath [
            pkgs.mise
            pkgs.git
          ]
        }:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin";

        rubyConfigureOpts = lib.concatStringsSep " " [
          "--with-gmp-dir=/opt/homebrew/opt/gmp"
          "--with-openssl-dir=/opt/homebrew/opt/openssl@3"
          "--with-libyaml-dir=/opt/homebrew/opt/libyaml"
          "--with-zlib-dir=/opt/homebrew/opt/zlib"
        ];
      in
      {
        home.packages = [ pkgs.mise ];

        # After the JDKs are registered, which mise would otherwise download
        home.activation.installRuntimes = lib.hm.dag.entryAfter [ "writeBoundary" "linkJdks" ] ''
          (
            export PATH=${path}
            export CFLAGS=-Wno-error=implicit-function-declaration
            export RUBY_CONFIGURE_OPTS=${lib.escapeShellArg rubyConfigureOpts}
            ${lib.optionalString (!verifyPythonAttestations) "export MISE_PYTHON_GITHUB_ATTESTATIONS=false"}
            run mise install --yes
          )
        '';
      };
  };
}

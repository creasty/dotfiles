# mise, and the runtimes of config/mise/config.toml. Its postinstall hooks add the default gems and npm packages.
{ pkgs, username, ... }:
{
  # Ruby is built against Homebrew's libraries (ruby.compile), like rbenv did
  homebrew.brews = [
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
          run mise install --yes
        )
      '';
    };
}

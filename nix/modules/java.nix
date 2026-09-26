# Homebrew's JDKs, which mise selects (config/mise/config.toml, or a project's .java-version), and JVM tools
{ pkgs, username, ... }:
let
  # The first is macOS's default JDK
  versions = [
    "21"
    "17"
  ];

  jdk = version: "/opt/homebrew/opt/openjdk@${version}/libexec/openjdk.jdk";
in
{
  homebrew.brews = map (version: "openjdk@${version}") versions;

  # For /usr/libexec/java_home, and the apps that use it
  system.activationScripts.postActivation.text = ''
    mkdir -p /Library/Java/JavaVirtualMachines
    ln -sfn ${jdk (builtins.head versions)} /Library/Java/JavaVirtualMachines/openjdk.jdk
  '';

  home-manager.users.${username} =
    { lib, ... }:
    {
      home.packages = with pkgs; [
        gradle # Open-source build automation tool based on the Groovy and Kotlin DSL
        pre-commit # Framework for managing multi-language pre-commit hooks
        coursier # Launcher for Coursier (required by pre-commit)
        kotlin-language-server # Intelligent Kotlin support for any editor/IDE using the Language Server Protocol
      ];

      # As `N` and `N.0`, the forms .java-version files written by jenv usually contain
      home.activation.linkJdks = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        lib.concatMapStrings (version: ''
          for name in java@${version} java@${version}.0; do
            run ${pkgs.mise}/bin/mise link --force "$name" ${jdk version}/Contents/Home
          done
        '') versions
      );
    };

  dotfiles.manifest.java.versions = versions;
}

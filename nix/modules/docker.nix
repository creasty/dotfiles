# Docker Desktop, with its command-line tools in /usr/local/bin ("System" in Settings > Advanced)
{ pkgs, username, ... }:
let
  # What Docker Desktop starts with the first time. In "User" mode, its default for a new installation, it links
  # the tools into ~/.docker/bin and, on every start, adds that to PATH at the top of ~/.zprofile, ~/.bash_profile
  # and ~/.profile, which link into this checkout.
  settings = {
    DockerBinInstallPath = "system";
  };
  settingsFile = pkgs.writeText "settings-store.json" (builtins.toJSON settings);
in
{
  homebrew.casks = [ "docker-desktop" ];

  home-manager.users.${username} =
    { lib, ... }:
    {
      # Only before the first start: Docker Desktop reads the file when it starts, and saves its own settings
      # over it. test/docker.bats checks an installation that already started.
      home.activation.configureDockerDesktop = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        settings="$HOME/Library/Group Containers/group.com.docker/settings-store.json"
        if [ ! -e "$settings" ]; then
          run install -D -m 644 $VERBOSE_ARG ${settingsFile} "$settings"
        fi
      '';
    };

  dotfiles.manifest.docker.settings = settings;
}

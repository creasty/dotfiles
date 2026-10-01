# The Mac, as a nix-darwin configuration. Each module configures one topic, for both the system and the
# user's home (home-manager).
{ username, ... }:
{
  imports = [
    ./1password.nix
    ./appstore.nix
    ./links.nix
    ./homebrew.nix
    ./packages.nix
    ./shell.nix
    ./ssh.nix
    ./macos.nix
    ./hammerspoon.nix
    ./kitty.nix
    ./neovim.nix
    ./vscode.nix
    ./skills.nix
    ./docker.nix
    ./mise.nix
    ./java.nix
    ./go.nix
    ./rust.nix
    ./swift.nix
    ./flutter.nix
    ./verify.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  # Determinate Nix manages Nix itself: the daemon and /etc/nix/nix.conf
  nix.enable = false;

  system.stateVersion = 6;
  system.primaryUser = username;

  users.users.${username}.home = "/Users/${username}";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # Files in the way of a link are kept with this suffix
    backupFileExtension = "before-nix";
    users.${username}.home.stateVersion = "26.05";
  };

  # Touch ID for sudo, which darwin-rebuild and the installers of some casks ask for
  security.pam.services.sudo_local.touchIdAuth = true;
}

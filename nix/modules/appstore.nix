# Apps from the Mac App Store, which Homebrew Bundle installs with mas. Installing needs an Apple Account signed in
# to the App Store (mas can't sign in), and mas asks for sudo itself.
{ config, lib, ... }:
let
  # `mas list` shows the IDs of installed apps, and `mas search <name>` those of others
  apps = {
    "Bear" = 1091189122;
    "Fantastical" = 975937182;
    "The Unarchiver" = 425424353;
    "Things" = 904280696;
    "Toggl Track" = 1291898086;
    "Xcode" = 497799835;
  };
in
{
  options.dotfiles.appStore = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Whether to install the App Store apps, which needs an Apple Account signed in to the App Store.";
  };

  config = {
    homebrew.masApps = lib.mkIf config.dotfiles.appStore apps;

    # brew bundle runs the first mas on its PATH, which starts with Homebrew's, so keep that one current
    homebrew.brews = [ "mas" ];

    dotfiles.manifest.appStore = {
      install = config.dotfiles.appStore;
      # As `<id> <name>` lines
      apps = lib.mapAttrsToList (name: id: "${toString id} ${name}") apps;
    };
  };
}

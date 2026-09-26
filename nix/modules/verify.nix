# What ./verify checks the machine against: /etc/dotfiles/manifest.json, written with the configuration that was
# activated
{
  config,
  lib,
  username,
  ...
}:
let
  home = config.home-manager.users.${username};
in
{
  options.dotfiles.manifest = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = { };
    description = "What the modules want ./verify to check, besides what this module collects.";
  };

  config.environment.etc."dotfiles/manifest.json".text = builtins.toJSON (
    config.dotfiles.manifest
    // {
      links = home.dotfiles.link;

      homebrew = {
        taps = map (tap: tap.name) config.homebrew.taps;
        brews = map (brew: brew.name) config.homebrew.brews;
        casks = map (cask: cask.name) config.homebrew.casks;
      };

      # The commands of the packages installed with Nix
      commands = lib.unique (
        lib.concatMap (pkg: lib.optional (pkg ? meta.mainProgram) pkg.meta.mainProgram) home.home.packages
      );

      defaults = config.system.defaults.CustomUserPreferences;
    }
  );
}

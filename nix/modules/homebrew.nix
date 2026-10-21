# Apps (casks). The formulae nixpkgs doesn't have or can't replace are in the modules that need them. ./apply installs
# Homebrew itself.
{ ... }:
let
  # brew upgrade leaves the casks that update themselves (auto_updates) to their own updaters: upgrading one replaces
  # the app under its running process, which breaks Chrome's new tabs until it restarts
  env.HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS = "1";
in
{
  environment.variables = env;

  homebrew = {
    enable = true;

    # Everything at its latest on every switch, but the apps that update themselves. Nothing is ever uninstalled.
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "none";
      extraEnv = env;
    };

    # brew list --cask --full-name
    casks = [
      "adobe-creative-cloud" # https://creative.adobe.com/products/creative-cloud
      "appcleaner" # https://freemacsoft.net/appcleaner/
      "figma" # https://www.figma.com/
      "gcloud-cli" # https://cloud.google.com/cli/
      "google-chrome" # https://www.google.com/chrome/
      "google-drive" # https://www.google.com/drive/
      "google-japanese-ime" # https://www.google.co.jp/ime/
      "imageoptim" # https://imageoptim.com/mac
      "istat-menus" # https://bjango.com/mac/istatmenus/
      "ngrok" # https://ngrok.com/
      "proxyman" # https://proxyman.io/
      "qlmarkdown" # https://github.com/sbarex/QLMarkdown
      "raycast" # https://raycast.app/
      "rightfont" # https://rightfontapp.com/
      "spotify" # https://www.spotify.com/
      "syntax-highlight" # https://github.com/sbarex/SourceCodeSyntaxHighlight
      "tableplus" # https://tableplus.io/
      "tunnelbear" # https://www.tunnelbear.com/
    ];
  };
}

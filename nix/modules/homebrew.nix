# Apps (casks). The formulae nixpkgs doesn't have or can't replace are in the modules that need them. ./apply installs
# Homebrew itself.
{ username, ... }:
let
  # brew upgrade leaves the casks that update themselves (auto_updates) to their own updaters: upgrading one replaces
  # the app under its running process, which breaks Chrome's new tabs until it restarts
  env.HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS = "1";

  brew = "sudo --user=${username} --set-home /opt/homebrew/bin/brew";
in
{
  environment.variables = env;

  # Google Japanese Input updates itself too, though its cask doesn't say so: pinned, brew upgrade leaves it alone.
  # Upgrading it uninstalls the input method first, which leaves macOS without it.
  system.activationScripts.postActivation.text = ''
    if ! ${brew} list --pinned --cask | grep -qx google-japanese-ime; then
      ${brew} pin --cask google-japanese-ime
    fi
  '';

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
      "chatgpt" # https://chatgpt.com/
      "claude" # https://claude.com/download
      "figma" # https://www.figma.com/
      "gcloud-cli" # https://cloud.google.com/cli/
      "google-chrome" # https://www.google.com/chrome/
      "google-drive" # https://www.google.com/drive/
      "google-japanese-ime" # https://www.google.co.jp/ime/
      "imageoptim" # https://imageoptim.com/mac
      "insomnia" # https://insomnia.rest/
      "intellij-idea-ce" # https://www.jetbrains.com/idea/
      "istat-menus" # https://bjango.com/mac/istatmenus/
      "ngrok" # https://ngrok.com/
      "phocus" # https://www.hasselblad.com/phocus/
      "proxyman" # https://proxyman.io/
      "qlmarkdown" # https://github.com/sbarex/QLMarkdown
      "raycast" # https://raycast.app/
      "rightfont" # https://rightfontapp.com/
      "smoothcsv" # https://smoothcsv.com/
      "spotify" # https://www.spotify.com/
      "syntax-highlight" # https://github.com/sbarex/SourceCodeSyntaxHighlight
      "tableplus" # https://tableplus.io/
      "tunnelbear" # https://www.tunnelbear.com/
      "typeless" # https://typeless.com/
    ];
  };
}

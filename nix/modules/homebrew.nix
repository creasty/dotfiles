# Apps (casks), and the formulae nixpkgs doesn't have or can't replace. ./provision installs Homebrew itself.
{ ... }:
{
  homebrew = {
    enable = true;

    # Everything at its latest on every switch. Nothing is ever uninstalled.
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "none";
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

    brews = [
      "icu4c" # for the charlock_holmes gem (home/bundle/config)
      "libiconv" # Conversion library
      "libpq" # psql and pg_dump of the latest PostgreSQL (on PATH through shell/profile)
    ];
  };
}

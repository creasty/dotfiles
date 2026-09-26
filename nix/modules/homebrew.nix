# Apps (casks), and the formulae nixpkgs doesn't have or can't replace. ./provision installs Homebrew itself.
{ ... }:
{
  homebrew = {
    enable = true;

    # Like the Ansible playbook's `state: latest`. Nothing is ever uninstalled.
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "none";
    };

    # Homebrew 6+ ignores third-party taps unless they are trusted
    taps =
      map
        (name: {
          inherit name;
          trusted = true;
        })
        [
          "creasty/tools" # for keyboard, rid
          "hashicorp/tap" # for terraform
        ];

    # brew list --cask --full-name
    casks = [
      "1password" # https://1password.com/
      "1password-cli" # https://developer.1password.com/docs/cli
      "adobe-creative-cloud" # https://creative.adobe.com/products/creative-cloud
      "appcleaner" # https://freemacsoft.net/appcleaner/
      "creasty/tools/keyboard" # https://github.com/creasty/Keyboard
      "docker-desktop" # https://www.docker.com/products/docker-desktop
      "figma" # https://www.figma.com/
      "gcloud-cli" # https://cloud.google.com/cli/
      "google-chrome" # https://www.google.com/chrome/
      "google-drive" # https://www.google.com/drive/
      "google-japanese-ime" # https://www.google.co.jp/ime/
      "imageoptim" # https://imageoptim.com/mac
      "istat-menus" # https://bjango.com/mac/istatmenus/
      "kitty" # https://github.com/kovidgoyal/kitty
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
      "creasty/tools/rid" # Run commands in container as if were native
      "hashicorp/tap/terraform" # nixpkgs has it as unfree (BUSL), outside the binary cache
      "icu4c" # for the charlock_holmes gem (home/bundle/config)
      "libiconv" # Conversion library
      "libpq" # psql and pg_dump of the latest PostgreSQL (on PATH through shell/profile)
    ];
  };
}

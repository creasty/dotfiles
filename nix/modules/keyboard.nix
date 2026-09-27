# Keyboard (https://github.com/creasty/Keyboard), from its GitHub release instead of the creasty/tools cask: Homebrew
# quarantines what casks install, and Gatekeeper won't open a quarantined app that isn't notarized, as Keyboard isn't,
# until it's allowed in System Settings > Privacy & Security. home-manager copies the app, unquarantined, into
# ~/Applications/Home Manager Apps.
{
  lib,
  pkgs,
  username,
  ...
}:
let
  keyboard = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "keyboard";
    version = "1.4.2";

    # The same archive as the cask's
    src = pkgs.fetchurl {
      url = "https://github.com/creasty/Keyboard/releases/download/v${finalAttrs.version}/keyboard.zip";
      hash = "sha256-Fbq4hUS5d6MVwsLubEmHeWg61NmaJJW1BIoejmDqhIU=";
    };

    nativeBuildInputs = [ pkgs.unzip ];

    # The app as released: its (ad-hoc) signature covers every file
    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out/Applications
      unzip -d $out/Applications $src
      runHook postInstall
    '';

    meta = {
      homepage = "https://github.com/creasty/Keyboard";
      license = lib.licenses.mit;
      platforms = lib.platforms.darwin;
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
  });
in
{
  home-manager.users.${username}.home.packages = [ keyboard ];
}

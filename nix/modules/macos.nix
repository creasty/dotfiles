# macOS preferences. What can't be scripted is set by hand: docs/system_preference.md
{ username, ... }:
{
  # Written with `defaults write <domain> <key>` for the user
  system.defaults.CustomUserPreferences = {
    NSGlobalDomain = {
      #=== General
      NSTableViewDefaultSizeMode = 1; # small sidebar icons
      NSWindowResizeTime = 0.001; # faster window resizing
      NSNavPanelExpandedStateForSaveMode = true; # expanded save panels
      PMPrintingExpandedStateForPrint = true; # expanded print panels
      NSAutomaticQuoteSubstitutionEnabled = false; # no smart quotes
      NSAutomaticDashSubstitutionEnabled = false; # no smart dashes
      "com.apple.keyboard.fnState" = false;
      "com.apple.trackpad.scaling" = 3.0;
      "com.apple.springing.delay" = 0.5;
      "com.apple.springing.enabled" = true;
      AppleAntiAliasingThreshold = 4;
      AppleAquaColorVariant = 6;
      AppleEnableMenuBarTransparency = true;
      AppleEnableSwipeNavigateWithScrolls = false;
      AppleInterfaceStyle = "Dark";
      "com.apple.sound.uiaudio.enabled" = false; # no UI sound effects

      #=== Input devices
      KeyRepeat = 1; # 16.7ms
      InitialKeyRepeat = 12; # 200ms
      ApplePressAndHoldEnabled = false; # no accents popup
      AppleKeyboardUIMode = 3; # full keyboard access for all controls
      AppleLocale = "en_JP@currency=JPY";
      AppleMeasurementUnits = "Centimeters";
      AppleMetricUnits = true;
      AppleICUForce24HourTime = true;
      NSAutomaticSpellingCorrectionEnabled = false;

      #=== Finder
      AppleShowAllExtensions = true;
    };

    "com.apple.print.PrintingPrefs"."Quit When Finished" = true; # quit the printer app when done
    "com.apple.LaunchServices".LSQuarantine = false; # no "Are you sure you want to open this application?"
    "com.apple.CrashReporter".DialogType = "none";
    "com.apple.touchbar.agent".PresentationModeGlobal = "fullControlStrip";

    "com.apple.screencapture" = {
      location = "/Users/${username}/Desktop";
      type = "png";
      disable-shadow = true;
    };

    "com.apple.finder" = {
      AppleShowAllFiles = true; # show hidden files
      ShowStatusBar = true;
      ShowPathbar = true;
      QLEnableTextSelection = true; # text selection in Quick Look
      FXDefaultSearchScope = "SCcf"; # search the current folder
      FXEnableExtensionChangeWarning = false;
      CreateDesktop = false; # no icons on the desktop
    };
    "com.apple.desktopservices".DSDontWriteNetworkStores = true; # no .DS_Store on network volumes

    "com.apple.dock" = {
      tilesize = 16.0;
      minimize-to-application = true;
      expose-animation-duration = 0;
      workspaces-swoosh-animation-off = true;
      springboard-show-duration = 0;
      springboard-hide-duration = 0;
      dashboard-in-overlay = true;
      mru-spaces = false; # don't rearrange Spaces by recent use
      autohide = true;
      showhidden = true; # translucent icons of hidden apps
    };
    "com.apple.dashboard".mcx-disabled = true;
  };

  system.startup.chime = false;

  system.activationScripts.postActivation.text = ''
    chflags nohidden /Users/${username}/Library
    # Picks up the Quick Look extensions of casks, and restarts what reads the preferences above
    launchctl asuser "$(id -u -- ${username})" sudo --user=${username} -- qlmanage -r > /dev/null 2>&1 || true
    killall -u ${username} Dock Finder 2> /dev/null || true
  '';
}

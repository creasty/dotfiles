# macOS preferences
{
  config,
  lib,
  username,
  ...
}:
let
  # For the built-in trackpad and a Magic Trackpad, which read them at login
  trackpad = {
    Clicking = true; # tap to click
    # Three fingers swipe between pages (two don't: AppleEnableSwipeNavigateWithScrolls), and four between full-screen
    # apps and up for Mission Control
    TrackpadThreeFingerHorizSwipeGesture = 1;
    TrackpadThreeFingerVertSwipeGesture = 1;
    TrackpadFourFingerHorizSwipeGesture = 2;
    TrackpadFourFingerVertSwipeGesture = 2;
    # No Notification Center, Launchpad or Show Desktop
    TrackpadTwoFingerFromRightEdgeSwipeGesture = 0;
    TrackpadFourFingerPinchGesture = 0;
    TrackpadFiveFingerPinchGesture = 0;
  };

  # dotfiles.hotKeys as the entries of AppleSymbolicHotKeys
  hotKeys = lib.mapAttrs (
    _: parameters:
    if parameters == null then
      { enabled = false; }
    else
      {
        enabled = true;
        value = {
          inherit parameters;
          type = "standard";
        };
      }
  ) config.dotfiles.hotKeys;

  # For `defaults write ... -dict-add`: the IDs, each followed by its entry
  hotKeyArgs = lib.concatLists (
    lib.mapAttrsToList (id: entry: [
      id
      (lib.generators.toPlist { escape = true; } entry)
    ]) hotKeys
  );
in
{
  options.dotfiles.hotKeys = lib.mkOption {
    type = lib.types.attrsOf (lib.types.nullOr (lib.types.listOf lib.types.int));
    default = { };
    description = ''
      Shortcuts of System Settings > Keyboard > Keyboard Shortcuts, by their IDs in com.apple.symbolichotkeys: the
      character (65535 for none), key code and modifier flags of their keys, or null to turn them off. The others stay
      as they are.
    '';
  };

  config = {
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
        # The Multicolor theme, and an automatic highlight color, which set no AppleAccentColor or AppleHighlightColor
        AppleAquaColorVariant = 1;
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

      "com.apple.AppleMultitouchTrackpad" = trackpad;
      "com.apple.driver.AppleBluetoothMultitouch.trackpad" = trackpad;

      "com.apple.HIToolbox".AppleFnUsageType = 0; # the Fn (Globe) key does nothing on its own
      "com.apple.TextInputMenu".visible = true; # the input menu in the menu bar

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
        # The trackpad's gestures (above): Mission Control's, but not Launchpad's or Show Desktop's
        showMissionControlGestureEnabled = true;
        showLaunchpadGestureEnabled = false;
        showDesktopGestureEnabled = false;
      };
      "com.apple.dashboard".mcx-disabled = true;
    };

    # Caps Lock is Control, on every keyboard: hidutil maps it, and nix-darwin runs it again at boot
    system.keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };

    dotfiles.hotKeys."52" = null; # no shortcut for Launchpad & Dock > Turn Dock hiding on/off

    system.startup.chime = false;

    # The preferences above, for the next switch to tell whether they changed
    environment.etc."dotfiles/preferences.json".text =
      builtins.toJSON config.system.defaults.CustomUserPreferences;

    system.activationScripts.postActivation.text = ''
      chflags nohidden /Users/${username}/Library
      # Picks up the Quick Look extensions of casks
      launchctl asuser "$(id -u -- ${username})" sudo --user=${username} -- qlmanage -r > /dev/null 2>&1 || true
      # Restarts what reads the preferences above once they changed, not on every switch: a restarted Finder opens its
      # windows. (/run/current-system is still the previous system here.)
      if ! cmp -s /run/current-system/etc/dotfiles/preferences.json "$systemConfig/etc/dotfiles/preferences.json"; then
        killall -u ${username} Dock Finder 2> /dev/null || true
      fi
    ''
    + lib.optionalString (hotKeys != { }) ''
      # Adds the shortcuts to the user's, where CustomUserPreferences would replace them all. macOS reads them at login.
      launchctl asuser "$(id -u -- ${username})" sudo --user=${username} -- \
        defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add ${lib.escapeShellArgs hotKeyArgs}
    '';

    dotfiles.manifest.hotKeys = hotKeys;
  };
}

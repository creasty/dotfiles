#!/usr/bin/env bash

# ask for the administrator password upfront
sudo -v


#  General
#-----------------------------------------------
# disable the sound effects on boot
sudo nvram SystemAudioVolume=' '

# menu bar: hide the Time Machine, Volume, User, and Bluetooth icons
defaults write ~/Library/Preferences/ByHost/com.apple.systemuiserver.* dontAutoLoad -array \
  '/System/Library/CoreServices/Menu Extras/TimeMachine.menu' \
  '/System/Library/CoreServices/Menu Extras/Volume.menu' \
  '/System/Library/CoreServices/Menu Extras/User.menu' \
  '/System/Library/CoreServices/Menu Extras/Bluetooth.menu'

# set sidebar icon size to small
defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 1

# increase window resize speed for Cocoa applications
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# expand filer panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true

# automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs 'Quit When Finished' -bool true

# disable the "Are you sure you want to open this application?" dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# disable the crash reporter
defaults write com.apple.CrashReporter DialogType -string 'none'

# disable smart quotes and dashes as they're annoying when typing code
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false


#  Input devices
#-----------------------------------------------
# enable full keyboard access for all controls
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# set a blazingly fast keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# set language and text formats
defaults write NSGlobalDomain AppleLanguages -array 'en' 'ja'
defaults write NSGlobalDomain AppleLocale -string 'en_US@currency=JPY'
defaults write NSGlobalDomain AppleMeasurementUnits -string 'Centimeters'
defaults write NSGlobalDomain AppleMetricUnits -bool true

# disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false


#  Screenshots
#-----------------------------------------------
# Save to the desktop
defaults write com.apple.screencapture location -string "${HOME}/Desktop"

# Save screenshots in PNG format
defaults write com.apple.screencapture type -string 'png'

# disable shadow
defaults write com.apple.screencapture disable-shadow -bool true


#  Finder
#-----------------------------------------------
# show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# show path bar
defaults write com.apple.finder ShowPathbar -bool true

# allow text selection in Quick Look
defaults write com.apple.finder QLEnableTextSelection -bool true

# search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string 'SCcf'

# disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# avoid creating .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# show the ~/Library folder
chflags nohidden ~/Library

# don't create desktop
defaults write com.apple.finder CreateDesktop -bool false

# display line numbers and wrap text
defaults write org.n8gray.QLColorCode extraHLFlags '-l -W'


#  Dock
#-----------------------------------------------
# set the icon size of Dock items to 25 pixels
defaults write com.apple.dock tilesize -int 25

# minimize windows into their application's icon
defaults write com.apple.dock minimize-to-application -bool true

# speed up Mission Control animations
defaults write com.apple.dock expose-animation-duration -float 0.1

# disable Dashboard
defaults write com.apple.dashboard mcx-disabled -bool true

# don't show Dashboard as a Space
defaults write com.apple.dock dashboard-in-overlay -bool true

# don't automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true

# make Dock icons of hidden applications translucent
defaults write com.apple.dock showhidden -bool true


#  Kill affected app
#-----------------------------------------------
for app in 'Dock' 'Finder'; do
  killall "${app}" > /dev/null 2>&1
done


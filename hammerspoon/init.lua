-- Hammerspoon's config (https://www.hammerspoon.org), linked as ~/.hammerspoon: see README.md

-- Starts at login, as Keyboard did
if not hs.autoLaunch() then hs.autoLaunch(true) end

-- A global, for the console
keyboard = require('keyboard')
keyboard.start()

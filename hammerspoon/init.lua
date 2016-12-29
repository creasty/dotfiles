local window = require("window")

hs.window.animationDuration = 0

hs.hotkey.bind({"cmd", "shift"}, "K", function()
    hs.alert.show(hs.application.frontmostApplication():bundleID())
end)

hs.hotkey.bind({"cmd", "alt"}, "/", window:resize(""))
hs.hotkey.bind({"cmd", "alt"}, "Left", window:resize("L"))
hs.hotkey.bind({"cmd", "alt"}, "Up", window:resize("T"))
hs.hotkey.bind({"cmd", "alt"}, "Right", window:resize("R"))
hs.hotkey.bind({"cmd", "alt"}, "Down", window:resize("B"))
hs.hotkey.bind({"cmd", "alt", "shift"}, "Left", window:resize("TL"))
hs.hotkey.bind({"cmd", "alt", "shift"}, "Up", window:resize("TR"))
hs.hotkey.bind({"cmd", "alt", "shift"}, "Right", window:resize("BR"))
hs.hotkey.bind({"cmd", "alt", "shift"}, "Down", window:resize("BL"))

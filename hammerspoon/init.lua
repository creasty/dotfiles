local window = require("window")

hs.window.animationDuration = 0

hs.hotkey.bind({"cmd", "alt"}, "/", window:resize(""))
hs.hotkey.bind({"cmd", "alt"}, "left", window:resize("L"))
hs.hotkey.bind({"cmd", "alt"}, "up", window:resize("T"))
hs.hotkey.bind({"cmd", "alt"}, "right", window:resize("R"))
hs.hotkey.bind({"cmd", "alt"}, "down", window:resize("B"))
hs.hotkey.bind({"cmd", "alt", "shift"}, "left", window:resize("TL"))
hs.hotkey.bind({"cmd", "alt", "shift"}, "up", window:resize("TR"))
hs.hotkey.bind({"cmd", "alt", "shift"}, "right", window:resize("BR"))
hs.hotkey.bind({"cmd", "alt", "shift"}, "down", window:resize("BL"))

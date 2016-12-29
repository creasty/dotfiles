local window = require("window")
local util = require("util")
local superkey = require("superkey")

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

util:toggleApp({"cmd"}, "'", "com.apple.finder")
util:toggleApp({"cmd", "ctrl"}, "'", "com.evernote.Evernote")

-- util:emacsRemapKey({"ctrl"}, "c", {}, "escape")
-- util:emacsRemapKey({"ctrl"}, "h", {}, "delete")
-- util:emacsRemapKey({"ctrl"}, "d", {}, "forwarddelete")
-- util:emacsRemapKey({"ctrl"}, "j", {}, "return")
-- util:emacsRemapKey({"ctrl"}, "p", {}, "up")
-- util:emacsRemapKey({"ctrl"}, "n", {}, "down")
-- util:emacsRemapKey({"ctrl"}, "f", {}, "left")
-- util:emacsRemapKey({"ctrl"}, "b", {}, "right")
-- util:emacsRemapKey({"ctrl"}, "a", {"cmd"}, "left")
-- util:emacsRemapKey({"ctrl"}, "a", {"cmd"}, "right")

-- superkey("t", {
--     h = function(e)
--         print('th')
--     end,
-- })


-- hs.alert.show(hs.application.frontmostApplication():bundleID())
--hs.hotkey.bind({}, "K", function()
--    print(superKeyFlag["t"])
--end)

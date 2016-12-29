local Util = {}

function Util:keyCode(modifiers, key)
    return function()
        hs.eventtap.event.newKeyEvent(modifiers, string.lower(key), true):post()
        hs.timer.usleep(1000)
        hs.eventtap.event.newKeyEvent(modifiers, string.lower(key), false):post()
    end
end

function Util:remapKey(lModifiers, lKey, rModifiers, rKey)
    keyCode = Util:keyCode(rModifiers, rKey)
    hs.hotkey.bind(lModifiers, lKey, keyCode, nil, keyCode)
end

return Util

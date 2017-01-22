local util = require("util")

local EVENTS = {
    hs.eventtap.event.types.keyDown,
    hs.eventtap.event.types.keyUp,
}

return function(baseKey, handlers)
    local isActive = false
    local isConsumed = false
    local isLocked = false

    hs.eventtap.new(EVENTS, function(e)
        local flags = e:getFlags()
        if (flags.cmd or flags.alt or flags.shift or flags.ctrl or flags.fn) then
            return
        end

        local key = e:getCharacters()
        local isUp = (e:getType() == hs.eventtap.event.types.keyUp)
        local wasConsumed = isConsumed

        if isLocked then
            if key == baseKey then
                if isUp then
                    isLocked = false
                end
            end

            return
        end

        if isUp then
            isConsumed = false
        end

        if key == baseKey then
            isActive = not isUp

            if isUp and not wasConsumed then
                isLocked = true
                hs.eventtap.keyStroke({}, key, 80)
                return true, true
            end

            return true, true
        end

        if isActive and not isUp and not isConsumed and handlers[key] then
            isConsumed = true
            handlers[key](e)
            return true, true
        end
    end):start()
end

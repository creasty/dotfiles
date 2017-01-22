local Window = {}

function Window:resize(pos)
    return function()
        local win = hs.window.focusedWindow()
        local f = win:frame()
        local screen = win:screen()
        local max = screen:frame()

        f.x = max.x
        f.y = max.y
        f.w = max.w
        f.h = max.h

        if pos == "" then
            -- full
        elseif pos == "L" then
            f.w = max.w / 2
        elseif pos == "T" then
            f.h = max.h / 2
        elseif pos == "R" then
            f.x = max.x + (max.w / 2)
            f.w = max.w / 2
        elseif pos == "B" then
            f.y = max.y + (max.h / 2)
            f.h = max.h / 2
        elseif pos == "TL" then
            f.h = max.h / 2
            f.w = max.w / 2
        elseif pos == "TR" then
            f.h = max.h / 2
            f.x = max.x + (max.w / 2)
            f.w = max.w / 2
        elseif pos == "BR" then
            f.y = max.y + (max.h / 2)
            f.h = max.h / 2
            f.x = max.x + (max.w / 2)
            f.w = max.w / 2
        elseif pos == "BL" then
            f.y = max.y + (max.h / 2)
            f.h = max.h / 2
            f.w = max.w / 2
        end

        win:setFrame(f)
    end
end

return Window

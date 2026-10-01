-- Switching the input source (Ctrl-;)
local M = {}

-- Selects the next input source of the input menu, taking keyboard layouts before input methods
function M.select_next()
  local layouts, sources, cjkv = hs.keycodes.layouts(true), {}, {}
  for _, id in ipairs(layouts) do table.insert(sources, id) end
  for _, id in ipairs(hs.keycodes.methods(true)) do
    table.insert(sources, id)
    cjkv[id] = true
  end
  local current = hs.keycodes.currentSourceID()
  for i, id in ipairs(sources) do
    if id == current then
      local following = sources[i % #sources + 1]
      -- As Keyboard: switching to a CJKV input method from a layout (TIS) may only change the menu's icon, unless a
      -- layout was selected just before
      if not cjkv[current] and cjkv[following] then hs.keycodes.currentSourceID(layouts[1]) end
      hs.keycodes.currentSourceID(following)
      return
    end
  end
end

return M

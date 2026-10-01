-- Moving and focusing windows (S+D+…, S+N, S+B)
local function move_window(unit)
  local win = hs.window.focusedWindow()
  if win then win:moveToUnit(unit, 0) end
end

-- Focuses the app's next window, or its previous one (step -1): going around its windows on the current space in the
-- order they opened, skipping panels and the like
local function focus_window(step)
  local focused = hs.window.focusedWindow()
  if not focused then return end
  local windows = {}
  for _, win in ipairs(focused:application():visibleWindows()) do
    if win:isStandard() or win == focused then table.insert(windows, win) end
  end
  -- Window IDs grow as windows open
  table.sort(windows, function(a, b) return a:id() < b:id() end)
  for i, win in ipairs(windows) do
    if win == focused then
      windows[(i - 1 + step) % #windows + 1]:focus()
      return
    end
  end
end

return { move = move_window, focus = focus_window }

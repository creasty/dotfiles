-- Switching between apps (;+…)
local kitty = require('kitty')

local M = {}

-- The window each app had in front as M.toggle hid it: brought back on another space, an app on every space may
-- show another of its windows in front
local hidden_windows = {}

-- What brings an app's windows to the current space before M.toggle shows it, calling back once done
local bring_windows = { ['net.kovidgoyal.kitty'] = kitty.bring_windows }

-- Brings the app to the front, launching it if needed, or hides it when it's already there. Brought back while still
-- hidden, it shows the window it had in front.
function M.toggle(bundle_id)
  local app = hs.application.frontmostApplication()
  if app and app:bundleID() == bundle_id then
    hidden_windows[bundle_id] = app:focusedWindow()
    app:hide()
    return
  end
  local win = hidden_windows[bundle_id]
  hidden_windows[bundle_id] = nil
  app = hs.application.applicationsForBundleID(bundle_id)[1]
  -- (shown since, it may have had another window in front)
  if not (app and app:isHidden()) then win = nil end
  local function show()
    hs.application.launchOrFocusByBundleID(bundle_id)
    if win then win:focus() end
  end
  if app and bring_windows[bundle_id] then
    bring_windows[bundle_id](app, show)
  else
    show()
  end
end

return M

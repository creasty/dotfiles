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

-- Shows 1Password's Quick Access, or hides it when it has the focus. Clicking 1Password's menu bar icon does so, its
-- action set to Show Quick Access, in about 30 ms. Without the icon, its executable started again with --quick-access
-- does, in about 190 ms: started through Launch Services instead (`open -n -b`), Quick Access loses the focus as it
-- shows, which hides it. 1Password acts on neither while it isn't running, so this launches it then.
function M.quick_access()
  local bundle_id = 'com.1password.1password'
  local app = hs.application.applicationsForBundleID(bundle_id)[1]
  if not app then
    hs.application.launchOrFocusByBundleID(bundle_id)
    return
  end
  local menu_bar = hs.axuielement.applicationElement(app):attributeValue('AXExtrasMenuBar')
  local icon = menu_bar and (menu_bar:attributeValue('AXChildren') or {})[1]
  if icon then
    icon:performAction('AXPress')
  else
    hs.task.new(app:path() .. '/Contents/MacOS/1Password', nil, { '--quick-access' }):start()
  end
end

return M

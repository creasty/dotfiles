-- The guard on Cmd-Q (Cmd-Q, Cmd-Q): an app quits on a second Cmd-Q, not on one pressed by mistake
local key = require('keycodes')

local M = {}

-- How soon the second Cmd-Q follows the first, in seconds: Keyboard's
local interval = 0.3

-- Apps whose own guard on Cmd-Q takes a second press or a hold, which get it as it is: held back, a double press would
-- reach them as one, and a hold not at all. Chrome (Warn Before Quitting, on by default) quits on Cmd-Q held for half a
-- second, or pressed again within a second.
local self_guarding_apps = { ['com.google.Chrome'] = true }

-- When the Cmd-Q held back went down, in seconds
local held_back_at

-- Handles a key the super keys let through: returns whether to swallow it
function M.guard(code, is_down, is_repeat, flags)
  if code ~= key.q or not is_down or not flags.cmd or flags.alt or flags.ctrl or flags.shift then return false end
  local app = hs.application.frontmostApplication()
  if app and self_guarding_apps[app:bundleID()] then return false end
  -- Its repeats would quit the app that comes to the front next
  if is_repeat then return true end
  local now = hs.timer.absoluteTime() / 1e9
  if held_back_at and now - held_back_at < interval then
    held_back_at = nil
    return false
  end
  held_back_at = now
  return true
end

return M

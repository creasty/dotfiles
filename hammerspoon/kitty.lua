-- kitty's windows on other spaces (;+M)
local M = {}

local log = hs.logger.new('keyboard', 'warning')

-- Whether the window, by its ID, is on the current space
local function on_current_space(id)
  local current = hs.spaces.focusedSpace()
  for _, space in ipairs(hs.spaces.windowSpaces(id) or {}) do
    if space == current then return true end
  end
  return false
end

-- Runs `kitten @` against the kitty app (config/kitty/kitty.conf's listen_on), then `fn` with its output, or nil
local function kitten(app, args, fn)
  local socket = ('unix:%skitty-%d'):format(os.getenv('TMPDIR'), app:pid())
  hs.task.new(app:path() .. '/Contents/MacOS/kitten', function(code, stdout, stderr)
    if code ~= 0 then log.e(('kitten @ %s: %s'):format(table.concat(args, ' '), stderr)) end
    fn(code == 0 and stdout or nil)
  end, { '@', '--to', socket, table.unpack(args) }):start()
end

-- Brings kitty's windows on other spaces to the current one, then calls `done`. kitty takes the windows it opens off
-- every space (Dock > Options > Assign To > All Desktops), but hiding and showing one adds it to the current space.
function M.bring_windows(app, done)
  kitten(app, { 'ls' }, function(out)
    local ok, os_windows = pcall(hs.json.decode, out or '')
    local matches = {}
    for _, os_window in ipairs(ok and os_windows or {}) do
      if not on_current_space(os_window.platform_window_id) then
        -- (by a window in it: --match picks the OS windows of the windows it matches)
        table.insert(matches, 'id:' .. os_window.tabs[1].windows[1].id)
      end
    end
    if #matches == 0 then return done() end
    local match = table.concat(matches, ' or ')
    kitten(app, { 'resize-os-window', '--match', match, '--action', 'hide' }, function()
      kitten(app, { 'resize-os-window', '--match', match, '--action', 'show' }, done)
    end)
  end)
end

return M

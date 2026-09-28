-- A fake of the parts of Hammerspoon's API the config uses. Keys typed on it go through the event taps the config
-- started, as macOS routes them, and it records what reaches the apps, and what else the config does.
local fake = {}

local types = { keyDown = 10, keyUp = 11, flagsChanged = 12 }
local props = { keyboardEventAutorepeat = 8, keyboardEventKeycode = 9, eventSourceUserData = 42 }

-- Virtual key codes, by the names the specs and the records use
local codes = {
  a = 0x00, s = 0x01, d = 0x02, f = 0x03, h = 0x04, g = 0x05, x = 0x07, c = 0x08, v = 0x09, b = 0x0b, w = 0x0d,
  e = 0x0e, r = 0x0f, t = 0x11, o = 0x1f, p = 0x23, l = 0x25, j = 0x26, k = 0x28, [';'] = 0x29, n = 0x2d, m = 0x2e,
  ['return'] = 0x24, tab = 0x30, space = 0x31, delete = 0x33, escape = 0x35, cmd = 0x37, eisu = 0x66,
  forwarddelete = 0x75, f1 = 0x7a, left = 0x7b, right = 0x7c, down = 0x7d, up = 0x7e,
}
local names = {}
for name, code in pairs(codes) do names[code] = name end

-- The modifiers, in the order the records name them, and their names in newKeyEvent's modifiers
local modifiers = { 'ctrl', 'alt', 'shift', 'cmd', 'fn' }
local aliases = { control = 'ctrl', option = 'alt', command = 'cmd' }

-- Routing
--------------------------------------------------
local depth = 0 -- of the tap callbacks running

-- An event going through the taps after the `after`th, then to the apps, as macOS routes events
local function deliver(event, after)
  for i = (after or 0) + 1, #fake.taps do
    local tap = fake.taps[i]
    if tap.types[event.type] then
      depth = depth + 1
      local ok, swallow, posted = pcall(tap.fn, event)
      depth = depth - 1
      if not ok then
        -- Hammerspoon drops the event, and logs the error
        table.insert(fake.logged, swallow)
        return
      end
      -- Returned to Hammerspoon, which posts them with CGEventTapPostEvent: right after the tap, ahead of the event
      for _, e in ipairs(posted or {}) do deliver(e, i) end
      if swallow then return end
    end
  end
  table.insert(fake.received, fake.describe(event))
end

local function route(event)
  deliver(event)
  -- Then what the callbacks posted meanwhile
  while depth == 0 and #fake.queue > 0 do
    deliver(table.remove(fake.queue, 1))
  end
end

-- An event as the records name it: e.g. 'ctrl+fn+left↓', or 'cmd↑' for Command released on its own
function fake.describe(event)
  local name = names[event.code] or ('#' .. event.code)
  if event.type == types.flagsChanged then return name .. (next(event.flags) and '↓' or '↑') end
  local parts = {}
  for _, mod in ipairs(modifiers) do
    if event.flags[mod] then table.insert(parts, mod) end
  end
  table.insert(parts, name .. (event.type == types.keyDown and '↓' or '↑'))
  return table.concat(parts, '+')
end

-- Events
--------------------------------------------------
local Event = {}
Event.__index = Event

local function new_event(type, code, flags)
  return setmetatable({ type = type, code = code, flags = flags or {}, props = {} }, Event)
end

function Event:getKeyCode() return self.code end
function Event:getType() return self.type end
function Event:setType(type) self.type = type return self end
function Event:getProperty(prop) return self.props[prop] or 0 end
function Event:setProperty(prop, value) self.props[prop] = value return self end
-- CGEventPost, into the stream ahead of every tap: as the event a tap callback handles goes on first, what the
-- callback posts waits for it
function Event:post()
  if depth > 0 then
    table.insert(fake.queue, self)
  else
    route(self)
  end
  return self
end

function Event:getFlags()
  local flags = {}
  for mod in pairs(self.flags) do flags[mod] = true end
  return flags
end

function Event:setFlags(flags)
  self.flags = {}
  for mod, on in pairs(flags) do
    assert(on == true, 'flags: ' .. tostring(mod))
    self.flags[mod] = true
  end
  return self
end

-- newKeyEvent([mods], key, isDown), or newKeyEvent(modifierKey, isDown) for a modifier's own event
local function new_key_event(mods, key, is_down)
  if type(key) == 'boolean' then mods, key, is_down = nil, mods, key end
  assert(math.type(key) == 'integer', 'keys by their key code, which the layout does not change: ' .. tostring(key))
  local flags = {}
  for _, mod in ipairs(mods or {}) do
    mod = aliases[mod] or mod
    assert(fake.contains(modifiers, mod), 'modifier: ' .. mod)
    flags[mod] = true
  end
  return new_event(is_down and types.keyDown or types.keyUp, key, flags)
end

-- The fake
--------------------------------------------------
function fake.contains(list, value)
  for _, v in ipairs(list) do
    if v == value then return true end
  end
  return false
end

local function record(call) table.insert(fake.calls, call) end

function fake.reset()
  fake.now = 0 -- in milliseconds
  fake.timers = {}
  fake.taps = {}
  fake.queue = {} -- the events posted while a tap callback runs
  fake.received = {} -- what reached the apps
  fake.calls = {} -- what else the config did
  fake.logged = {} -- errors
  fake.front = 'com.google.Chrome' -- the frontmost app
  fake.window = true -- whether it has a focused window
  fake.layouts = { 'com.apple.keylayout.ABC' }
  fake.methods = { 'com.google.inputmethod.Japanese.base' }
  fake.source = 'com.apple.keylayout.ABC'
  fake.autolaunch = false

  local logger = {}
  function logger.e(...) table.insert(fake.logged, table.concat({ ... }, ' ')) end
  logger.w, logger.i, logger.d, logger.f = logger.e, function() end, function() end, function() end

  local timer_seq = 0

  hs = {
    autoLaunch = function(on)
      if on ~= nil then fake.autolaunch = on end
      return fake.autolaunch
    end,

    logger = { new = function() return logger end },

    eventtap = {
      event = { types = types, properties = props, newKeyEvent = new_key_event },
      new = function(tap_types, fn)
        local tap = { types = {}, fn = fn }
        for _, t in ipairs(tap_types) do tap.types[t] = true end
        function tap:start()
          if not fake.contains(fake.taps, self) then table.insert(fake.taps, self) end
          return self
        end
        function tap:stop()
          for i, t in ipairs(fake.taps) do
            if t == self then
              table.remove(fake.taps, i)
              break
            end
          end
          return self
        end
        function tap:isEnabled() return fake.contains(fake.taps, self) end
        return tap
      end,
    },

    timer = {
      absoluteTime = function() return fake.now * 1000000 end,
      doAfter = function(seconds, fn)
        timer_seq = timer_seq + 1
        local timer = { at = fake.now + math.floor(seconds * 1000 + 0.5), seq = timer_seq, fn = fn }
        function timer:stop()
          for i, t in ipairs(fake.timers) do
            if t == self then
              table.remove(fake.timers, i)
              break
            end
          end
          return self
        end
        table.insert(fake.timers, timer)
        return timer
      end,
    },

    application = {
      frontmostApplication = function()
        local id = fake.front
        if not id then return nil end
        return {
          bundleID = function() return id end,
          hide = function()
            record('hide ' .. id)
            fake.front = nil
            return true
          end,
        }
      end,
      launchOrFocusByBundleID = function(id)
        record('focus ' .. id)
        fake.front = id
        return true
      end,
    },

    window = {
      focusedWindow = function()
        if not fake.window then return nil end
        return {
          moveToUnit = function(_, unit, duration)
            assert(duration == 0, 'animated')
            record(('move %g,%g,%g,%g'):format(table.unpack(unit)))
          end,
        }
      end,
    },

    spaces = { toggleMissionControl = function() record('mission control') end },

    keycodes = {
      layouts = function(ids)
        assert(ids == true)
        return { table.unpack(fake.layouts) }
      end,
      methods = function(ids)
        assert(ids == true)
        return { table.unpack(fake.methods) }
      end,
      currentSourceID = function(id)
        if id == nil then return fake.source end
        record('select ' .. id)
        fake.source = id
        return true
      end,
    },
  }
end

-- Time passing, with the timers due firing in order
function fake.wait(ms)
  local till = fake.now + ms
  while true do
    table.sort(fake.timers, function(a, b) return a.at < b.at or (a.at == b.at and a.seq < b.seq) end)
    local timer = fake.timers[1]
    if not timer or timer.at > till then break end
    table.remove(fake.timers, 1)
    fake.now = timer.at
    -- Hammerspoon logs the error of a timer's callback
    local ok, err = pcall(timer.fn)
    if not ok then table.insert(fake.logged, err) end
  end
  fake.now = till
end

-- Typing, as a line of keys: 's↓' presses S, 's↑' releases it, 's⟳' repeats it while held, 'ctrl+c↓' presses C
-- with Control held, and '200ms' waits
function fake.type(line)
  for token in line:gmatch('%S+') do
    local ms = token:match('^(%d+)ms$')
    if ms then
      fake.wait(tonumber(ms))
    else
      local arrow = token:sub(-3)
      local parts = {}
      for part in token:sub(1, -4):gmatch('[^+]+') do table.insert(parts, part) end
      local code = assert(codes[table.remove(parts)], token)
      local flags = {}
      for _, mod in ipairs(parts) do
        assert(fake.contains(modifiers, mod), token)
        flags[mod] = true
      end
      local event
      if arrow == '↓' or arrow == '⟳' then
        event = new_event(types.keyDown, code, flags)
        if arrow == '⟳' then event:setProperty(props.keyboardEventAutorepeat, 1) end
      else
        assert(arrow == '↑', token)
        event = new_event(types.keyUp, code, flags)
      end
      route(event)
    end
  end
end

return fake

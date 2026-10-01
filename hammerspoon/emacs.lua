-- Emacs mode, and switching the input source
local key = require('keycodes')
local events = require('events')
local input_source = require('input_source')

local emit, key_event, stroke = events.emit, events.key_event, events.stroke
local select_next_input_source = input_source.select_next

local function set(list)
  local t = {}
  for _, v in ipairs(list) do t[v] = true end
  return t
end

-- Apps that keep their own Ctrl-C: terminals and Vim
local escape_key_disabled_apps = set({
  'com.apple.Terminal',
  'net.sourceforge.iTerm',
  'com.googlecode.iterm2',
  'co.zeit.hyperterm',
  'co.zeit.hyper',
  'io.alacritty',
  'org.alacritty',
  'net.kovidgoyal.kitty',
  'com.mitchellh.ghostty',
  'com.ident.goneovim',
  'com.qvacua.VimR',
})

-- Apps that keep their own Ctrl-D, Ctrl-H, Ctrl-A and Ctrl-E
local advanced_cursor_keys_disabled_apps = set({
  'com.microsoft.VSCode',
})

-- Apps that keep their own Emacs keys
local all_cursor_keys_disabled_apps = set({
  -- Eclipse
  'org.eclipse.eclipse',
  'org.eclipse.platform.ide',
  'org.eclipse.sdk.ide',
  'com.springsource.sts',
  'org.springsource.sts.ide',

  -- Emacs
  'org.gnu.Emacs',
  'org.gnu.AquamacsEmacs',
  'org.gnu.Aquamacs',
  'org.pqrs.unknownapp.conkeror',

  -- Remote desktops
  'com.microsoft.rdc',
  'com.microsoft.rdc.mac',
  'com.microsoft.rdc.osx.beta',
  'net.sf.cord',
  'com.thinomenon.RemoteDesktopConnection',
  'com.itap-mobile.qmote',
  'com.nulana.remotixmac',
  'com.p5sys.jump.mac.viewer',
  'com.p5sys.jump.mac.viewer.web',
  'com.vmware.horizon',
  'com.2X.Client.Mac',
  'karabiner.remotedesktop.microsoft',
  'karabiner.remotedesktop',

  -- Terminals
  'com.apple.Terminal',
  'iTerm',
  'net.sourceforge.iTerm',
  'com.googlecode.iterm2',
  'co.zeit.hyperterm',
  'co.zeit.hyper',
  'io.alacritty',
  'org.alacritty',
  'net.kovidgoyal.kitty',
  'com.mitchellh.ghostty',

  -- Vim
  'org.vim.MacVim',
  'com.ident.goneovim',
  'com.qvacua.VimR',

  -- Virtual machines
  'com.vmware.fusion',
  'com.vmware.view',
  'com.parallels.desktop',
  'com.parallels.vm',
  'com.parallels.desktop.console',
  'org.virtualbox.app.VirtualBoxVM',

  -- X11
  'org.x.X11',
  'com.apple.x11',
  'org.macosforge.xquartz.X11',
  'org.macports.X11',
})

-- Ctrl-<key> to key: `mods` added to it; `shift`: Shift-Ctrl-<key> too, adding Shift; `advanced`: not for the apps
-- that keep the advanced ones
local emacs_keys = {
  [key.d] = { to = key.forward_delete, advanced = true },
  [key.h] = { to = key.backspace, advanced = true },
  [key.j] = { to = key.enter },
  [key.p] = { to = key.up, shift = true },
  [key.n] = { to = key.down, shift = true },
  [key.b] = { to = key.left, shift = true },
  [key.f] = { to = key.right, shift = true },
  [key.a] = { to = key.left, mods = { 'cmd' }, shift = true, advanced = true }, -- beginning of line
  [key.e] = { to = key.right, mods = { 'cmd' }, shift = true, advanced = true }, -- end of line
}

local function eisu() stroke(key.eisu) end

local function frontmost_app()
  local app = hs.application.frontmostApplication()
  return app and app:bundleID()
end

-- Handles a key the super keys let through: returns whether to swallow it
local function remap(code, is_down, is_repeat, flags)
  if flags.alt or flags.cmd then return false end

  if not flags.ctrl then
    -- Escape switches to English first (EISUU), for Vim's normal mode
    if code == key.escape and is_down and not flags.shift then eisu() end
    return false
  end

  if code == key[';'] and not flags.shift then
    if not is_down then return false end
    if not is_repeat then select_next_input_source() end
    return true
  end

  if code == key.c and not flags.shift then
    if is_down then eisu() end
    -- Ctrl-C is Escape, but where it's Ctrl-C's own
    if escape_key_disabled_apps[frontmost_app()] then return false end
    emit(key_event(key.escape, is_down))
    return true
  end

  local emacs = emacs_keys[code]
  if not emacs or (flags.shift and not emacs.shift) then return false end
  local app = frontmost_app()
  if all_cursor_keys_disabled_apps[app] then return false end
  if emacs.advanced and advanced_cursor_keys_disabled_apps[app] then return false end
  local mods = { table.unpack(emacs.mods or {}) }
  if flags.shift then table.insert(mods, 'shift') end
  emit(key_event(emacs.to, is_down, mods))
  return true
end

return { remap = remap }

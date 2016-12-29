local Util = {}

local EMACS_APPLICATIONS = {
    -- eclipse
    ["org.eclipse.eclipse"]      = true,
    ["org.eclipse.platform.ide"] = true,
    ["org.eclipse.sdk.ide"]      = true,
    ["com.springsource.sts"]     = true,
    ["org.springsource.sts.ide"] = true,

    -- emacs
    ["org.gnu.Emacs"]                = true,
    ["org.gnu.AquamacsEmacs"]        = true,
    ["org.gnu.Aquamacs"]             = true,
    ["org.pqrs.unknownapp.conkeror"] = true,

    -- remote desktop connection
    ["com.microsoft.rdc"]                      = true,
    ["com.microsoft.rdc.mac"]                  = true,
    ["com.microsoft.rdc.osx.beta"]             = true,
    ["net.sf.cord"]                            = true,
    ["com.thinomenon.RemoteDesktopConnection"] = true,
    ["com.itap-mobile.qmote"]                  = true,
    ["com.nulana.remotixmac"]                  = true,
    ["com.p5sys.jump.mac.viewer"]              = true,
    ["com.p5sys.jump.mac.viewer.web"]          = true,
    ["com.vmware.horizon"]                     = true,
    ["com.2X.Client.Mac"]                      = true,
    ["karabiner.remotedesktop.microsoft"]      = true,
    ["karabiner.remotedesktop"]                = true,

    -- TERMINAL
    ["com.apple.Terminal"]    = true,
    ["iTerm"]                 = true,
    ["net.sourceforge.iTerm"] = true,
    ["com.googlecode.iterm2"] = true,
    ["co.zeit.hyperterm"]     = true,
    ["co.zeit.hyper"]         = true,

    -- vi
    ["org.vim.MacVim"] = true,

    -- virtualmachine
    ["com.vmware.fusion"]               = true,
    ["com.vmware.horizon"]              = true,
    ["com.vmware.view"]                 = true,
    ["com.parallels.desktop"]           = true,
    ["com.parallels.vm"]                = true,
    ["com.parallels.desktop.console"]   = true,
    ["org.virtualbox.app.VirtualBoxVM"] = true,

    -- x11
    ["org.x.X11"]                  = true,
    ["com.apple.x11"]              = true,
    ["org.macosforge.xquartz.X11"] = true,
    ["org.macports.X11"]           = true,
}

function Util:remapKey(lmodifiers, lkey, rmodifiers, rkey)
    local handler = function()
        hs.eventtap.keyStroke(rmodifiers, rkey)
    end
    hs.hotkey.bind(lmodifiers, lkey, handler, nil, handler)
end

function Util:toggleApp(modifiers, key, bundleId)
    hs.hotkey.bind(modifiers, key, function()
        local app = hs.application.frontmostApplication()

        if app:bundleID() == bundleId then
            app:hide()
        else
            hs.application.launchOrFocusByBundleID(bundleId)
        end
    end)
end

function Util:withinApp(modifiers, key, appName, fn)
    local wf = hs.window.filter.new(false)
        :setAppFilter(appName, { allowTitles = 1 })

    local handler = hs.hotkey.new(modifiers, key, function()
        fn()
    end)

    wf:subscribe(hs.window.filter.windowFocused, function() handler:enable() end)
    wf:subscribe(hs.window.filter.windowUnfocused, function() handler:disable() end)
end

-- function Util:emacsRemapKey(lmodifiers, lkey, rmodifiers, rkey)
--     hs.hotkey.new(lmodifiers, lkey, function()
--         hs.eventtap.keyStroke(rmodifiers, rkey)
--     end)
-- end
--
-- local function handleGlobalAppEvent(name, event, app)
--     local bundleId = app:bundleID()
--
--     if event == hs.application.watcher.activated and not EMACS_APPLICATIONS[bundleId] then
--         handler:enable()
--     else
--         handler:disable()
--     end
-- end
--

-- hs.application.watcher.new(handleGlobalAppEvent):start()

return Util

--/lib/luaX/lxClient.lua
--luaX manager, manages libraries and other things

if not _G['LX_SERVER_LOADED'] then
    os.ferror("lxClient: lxServer not loaded")
    return 0
end

local windows = {}
local focused = nil

function loadWindow(window)
    windows[window.lxwFile] = window
    window:load_itself()
end

function libroutine()
    _G['LX_CLIENT_LOADED'] = true
end


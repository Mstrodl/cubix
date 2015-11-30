--/lib/luaX/lxServer.lua
--luaX "makes forms" part

if not _G['LX_LUA_LOADED'] then
    os.ferror("lxServer: to load lxServer, you need lx.lua loaded as well")
    return 0
end

--[[

write_box

SSS
S S
SSS

SSSS
S  S
S  S
SSSS

]]

function write_rectangle(lX, lY, tX, tY, colorR)

end

function write_box(lX, lY, l, colorR)
    return write_rectangle(lX, lY, l, l, colorR)
end

function lxError(lx_type, emsg)
    os.ferror(lx_type..': '..emsg)
end

function libroutine()
    _G['LX_SERVER_LOADED'] = true
    _G['lxError'] = lxError
end


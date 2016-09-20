--[[
    dman.lua - device manager
]]
RELOADABLE = false

local udev_devices = {}
local early_fs = {} -- supply that to devfs later

local function add_device(node, device_obj)
    if (type(node) ~= 'string') or (type(device_obj) ~= 'table') then
        return ferror("add_device: invalid arguments")
    end

    devices[node] = device_obj

    -- setup FS node
    local stripped = string.sub(node, 6, #node)
    early_fs['/dev'][stripped] = {
        perm='750',
        owner='root'
        device=device_obj,
    }

    syslog.serlog(syslog.S_INFO, "udev", "new device: "..path)

    return true
end

function libroutine()
end

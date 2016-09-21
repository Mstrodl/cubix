--[[
    dman.lua - device manager
]]
RELOADABLE = false

local udev_devices = {}
local early_fs = {} -- supply that to devfs later

function add_device(node, device_obj)
    if (type(node) ~= 'string') or (type(device_obj) ~= 'table') then
        return ferror("add_device: invalid arguments")
    end

    udev_devices[node] = device_obj

    -- setup FS node
    local stripped = string.sub(node, 6, #node)
    early_fs[stripped] = {
        perm='750',
        owner='root',
        device=device_obj
    }

    syslog.serlog(syslog.S_INFO, "udev", rprintf("new device: %s" ,node))

    return true
end

Device = class(function(self)
    self.cursor = 0
end)

function Device:read(bytes)
    return ferror("read: Not Implemented")
end

function Device:write(bytes)
    return ferror("write: Not Implemented")
end

function libroutine()
    print("udev")
end

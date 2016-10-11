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
    --[[
        lib.udev.Device:read(bytes : number)

        returns a string with `bytes` length, containing the data
        from the object being opened
    ]]
    if not tonumber(bytes) then
        return ferror("read: bytes is not a number")
    end

    if not self._read_bytes then
        return ferror("_read_bytes: Not Implemented")
    end
    return self:_read_bytes(bytes)
end

function Device:write(bytestr)
    --[[
        lib.udev.Device:write(bytestr : string)

        returns the number of bytes written to the device
    ]]
    if type(bytestr) ~= 'string' then
        return ferror("write: bytestr is not a string")
    end

    if not self._write_bytes then
        return ferror("_write_bytes: Not Implemented")
    end
    return self:_write_bytes(bytestr)
end

-------------DEVFS--------------

local udevfs_mounts = {}

udevfs = class(function(self, oldfs)
    syslog.serlog_info('devfs', 'init')
    self.inode = oldfs.inode
end)

function udevfs:mount(source, target)
    print(source, target)
    sleep(.3)
    self.name = source
    self.target = target
    udevfs_mounts[target] = self
    return true
end

function udevfs:umount(source, target)
    mounts[target] = nil
    return true
end

function udevfs:make(source, options)
    return ferror("tmpfs: no formatting needed")
end

--TODO: the rest of devfs

function user_mount(uid)
    return uid == 0
end

-------------END DEVFS----------

function libroutine()
    print("udev")
end

#!/usr/bin/env lua
--[[
    null_device.lua
]]

null_device = class(lib.udev.Device, function(self)
    self.description = 'Null Device'
    self.dev_path = '/dev/null'
end)

function null_device:_read_bytes(bytes)
    return ferror("nulldev: error reading")
end

function null_device:_write_bytes(bytestr)
    return #bytestr
end

function make_device()
    return null_device()
end

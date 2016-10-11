#!/usr/bin/env lua
--full_device.lua

full_device = class(lib.udev.Device, function(self)
    self.description = 'Full Device'
    self.dev_path = '/dev/full'
end)

function full_device:_write_bytes(bytes)
    return ferror("zerodev: full")
end

function make_device()
    return full_device()
end

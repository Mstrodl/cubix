#!/usr/bin/env lua
--zero_device.lua

zero_device = class(lib.udev.Device, function(self)
    self.description = 'Zero Device'
    self.dev_path = '/dev/zero'
end)

function zero_device:_read_bytes(bytes)
    return string.rep('/0', bytes)
end

function make_device()
    return zero_device()
end

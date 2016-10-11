#!/usr/bin/env lua
--random device

random_device = class(lib.udev.Device, function(self)
    self.description = 'Random Device'
    self.dev_path = '/dev/random'
end)

function random_device:_read_bytes(bytes)
    if lib.rand then
        -- use rand syscalls
        local res = ''
        for i=1,bytes do
            res = res .. getrandombyte()
        end
        return res
    else
        -- no lib.rand
        return ferror("_read_bytes: lib.rand not loaded")
    end
end

function make_device()
    return random_device()
end

#!/usr/bin/env lua
--full_device.lua

dev_full = {}
dev_full.name = '/dev/full'
dev_full.device = {}
dev_full.device.device_read = function (bytes)
    if bytes == nil then
        return 0
    else
        result = ''
        for i = 0, bytes do
            result = result .. safestr(0)
        end
        return result
    end
    return 0
end

dev_full.device.device_write = function(s)
    ferror("devwrite: disk full")
    os.sys_signal(os.signals.SIGILL)
    return 1
end

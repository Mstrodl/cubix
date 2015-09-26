#!/usr/bin/env lua
--zero_device.lua

function safestr(s)
    if string.byte(s) > 191 then
        return '#'
    end
    return s
end

dev_zero = {}
dev_zero.name = '/dev/zero'
dev_zero.device = {}
dev_zero.device.read = function (bytes)
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

dev_zero.device.devwrite = function(s)
    return 0
end


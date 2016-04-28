#!/usr/bin/env lua
--random device

local rnd_running = true

function check_key()
    local evt, key = os.pullEvent("key")
    if evt and (key == 46) then
        rnd_running = false
    end
end

dev_random = {}
dev_random.device = {}
dev_random.name = '/dev/random'

dev_random.device.device_write = function (message)
    print("cannot write to random devices")
end

dev_random.device.device_read = function (bytes)
    if bytes == nil then
        local randchar
        local randchar_num
        while rnd_running do
            randchar_num = getrandombyte(true)
            randchar = string.char(randchar_num)
            io.write(randchar)

            check_key()
        end
        return randchar
    else
        local res = ''
        for i=1,bytes do
            local b = getrandombyte(true)
            res = res .. string.char(b)
        end
        return res
    end
    return -1
end

return dev_random

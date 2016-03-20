#!/usr/bin/env lua
--urandom device
function rawread()
    while true do
        local sEvent, param = os.pullEvent("key")
        if sEvent == "key" then
            if param == 28 then
                break
            end
        end
    end
end

local RANDOM_BLOCKS = 256

local function getRandomString()
    local cache = ''
    for i=0, RANDOM_BLOCKS do
        cache = cache .. string.char(math.random(0, 255))
    end
    return cache
end

function print_rndchar()
    local newseed = ''
    while true do
        newseed = getRandomString()
        math.randomseed(newseed)
        io.write(os.safestr(s))
    end
end

dev_urandom = {}
dev_urandom.device = {}
dev_urandom.name = '/dev/urandom'

dev_urandom.device.device_write = function (message)
    print("cannot write to /dev/urandom")
end

dev_urandom.device.device_read = function (bytes)
    local crand = {}
    local cache = tostring(os.clock())
    local seed = 0
    for i=1,#cache do
        seed = seed + string.byte(string.sub(cache,i,i))
    end
    math.randomseed(tostring(seed))
    if bytes == nil then
        crand = coroutine.create(print_rndchar)
        coroutine.resume(crand)
        while true do
            local event, key = os.pullEvent( "key" )
            if event and key then
                break
            end
        end
    else
        result = ''
        for i = 0, bytes do
            s = string.char(math.random(0, 255))
            result = result .. os.safestr(s)
        end
        return result
    end
    return 0
end

return dev_random

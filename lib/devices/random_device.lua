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

function print_rndchar()
    local cache = tostring(os.clock())
    local seed = 0
    for i=1,#cache do
        seed = seed + string.byte(string.sub(cache,i,i))
    end
    math.randomseed(tostring(seed))
    while true do
        s = string.char(math.random(0, 255))
        io.write(s)
    end
end

dev_random = {}
dev_random.device = {}
dev_random.name = '/dev/random'

dev_random.device.device_write = function (message)
    print("cannot write to /dev/random")
end

dev_random.device.device_read = function (bytes)
    local crand = {}
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
        local cache = tostring(os.clock())
        local seed = 0
        for i=1,#cache do
            seed = seed + string.byte(string.sub(cache,i,i))
        end
        math.randomseed(tostring(seed))
        result = ''
        for i = 0, bytes do
            s = string.char(math.random(0, 255))
            result = result .. s
        end
        return result
    end
    return 0
end

return dev_random

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
    while true do
        s = string.char(math.random(0, 255))
        io.write(os.safestr(s))
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
    math.randomseed(os.clock())
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

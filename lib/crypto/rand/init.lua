--[[
    rand/init.lua - initialize random functions
]]

-- load MT19937
local mtrand = lib.get("/lib/crypto/rand/mt_rand.lua")
local isaac = lib.get("/lib/crypto/rand/isaac.lua")

function libroutine()
    -- initialize MT19937
    local sys_mtrand = mtrand.MT19937(os.time())

    local rand = function() -- get number from MT's state
        return sys_mtrand:extract_num()
    end

    -- try to initialize ISAAC

    if isaac.isaac_seed(tostring(rand())) then
        rand = function() -- overwrite MT's syscall
            return isaac.isaac_rand()
        end
    end

    -- randrange and getrandombyte doesn't depend on any specific generator
    -- they only need rand()

    _G['randrange'] = function(a, b)
        --generate from a to b inclusive
        return (rand() % (b+1)) + a
    end

    _G['getrandombyte'] = function()
        --return a byte, from 0 to 255
        return randrange(0, 256 - 1)
    end

    _G['getrandom'] = function(buffer, length)
        length = length or #buffer
        for i=1,length do
            buffer[i] = rand()
        end
        return buffer
    end

    _G['getrandombytes'] = function(len)
        local res = {}
        for i=1,len do
            table.insert(res, getrandombyte())
        end
        return res
    end

    _G['getrandomstr'] = function(len)
        local tbl_rand = getrandombytes(len)
        local res = ''
        for i=1,len do
            res = res .. string.char(tbl_rand[i])
        end
        return res
    end

    _G['getrandomnum'] = function(length)
        cap = 999999999
        if not cap then
            cap = 999999999
        end

        local randomString = tostring(randrange(100000000, cap))
        local bigint = lib.bigint.bigint

        while true do
            randomString = randomString ..
                tostring(math.random(100000000, cap))
            if #randomString >= length then
                local finalRandom = randomString:sub(1, length)
                if finalRandom:sub(-1, -1) == "2" then
                    return bigint(finalRandom:sub(1, -2) .. "3")
                elseif finalRandom:sub(-1, -1) == "4" then
                    return bigint(finalRandom:sub(1, -2) .. "5")
                elseif finalRandom:sub(-1, -1) == "6" then
                    return bigint(finalRandom:sub(1, -2) .. "7")
                elseif finalRandom:sub(-1, -1) == "8" then
                    return bigint(finalRandom:sub(1, -2) .. "9")
                elseif finalRandom:sub(-1, -1) == "0" then
                    return bigint(finalRandom:sub(1, -2) .. "1")
                else
                    return bigint(finalRandom)
                end
            end
        end
    end

    _G['rand'] = rand
end

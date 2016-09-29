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

    _G['rand'] = rand
    _G['randrange'] = randrange
    _G['getrandombyte'] = getrandombyte
end

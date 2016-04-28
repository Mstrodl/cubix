#!/usr/bin/env lua

-- Entropy Manager: Gets events and organizes them in a pool of entropy

local entropyman = {}

local evtpool = {}
local pool_lock = false
local evtpool_i = 1
local evtpool_counter = 0

function mix_num(a, b, c, d)
end

function evt_num(evt)
    return rand()
end

function evt_quality(evt)
    return 1
end

function pool_add(event)
    if not pool_lock then
        if (not permission.grantAccess(fs.perms.SYS)) then
            ferror("isaac_seed: not enough permission")
            return false
        end
    end
    evtpool[#evtpool + 1] = evt_num(event)
    evtpool_counter = evtpool_counter + evt_quality(event)
end
entropyman.pool_add = poll_add

function pool_export()
    return evtpool
end
entropyman.pool_export = pool_export

function pool_seed()
    local r = bigint.bigint(1)
    for i=1, #evtpool do
        r = (r + bigint.bigint(evtpool[i]))
        sleep(0)
    end
    return r
end
entropyman.pool_seed = pool_seed

function load_pool(pth)
    os.debug.debug_write("[entropyman] load_pool", false)
    pth = pth or "/var/rand/evtpool"
    h = fs.open(pth, 'r')
    if h == nil then
        ferror("load_pool: error loading pool file")
        sleep(1)
        evtpool = table_fgen(rand, 20)
        return true
    end
    local a = h.readAll()
    h.close()

    evtpool = textutils.unserialise(a)
    return true
end
entropyman.load_pool = load_pool

function save_pool(pth)
    os.debug.debug_write("[entropyman] save_pool")
    pth = pth or "/var/rand/evtpool"
    h = fs.open(pth, 'w')
    h.write(textutils.serialise(evtpool))
    h.close()
end
entropyman.save_pool = save_pool

function libroutine()
    _G['entropyman'] = entropyman

    entropyman.load_pool("/var/rand/evtpool")
    isaac.isaac_seed_entpool()

    while true do
        local evt = {os.pullEvent()}

        pool_lock = true
        pool_add(evt)
        pool_lock = false
    end
end

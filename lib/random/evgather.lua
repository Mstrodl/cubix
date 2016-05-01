#!/usr/bin/env lua

-- Entropy Manager: Gets events and organizes them in a pool of entropy

local EVPOOL_SIZE = 256 -- 256 events
local EVPOOL_PATH = "/var/rand/evtpool"
local INT_MASK = 2^32 -1

local evgather = {} -- api object

--event pool, time pool and pool lock
local evtpool = {}
local evtpool_time = {}
local evtpool_state = {}
local pool_lock = false

local a,b,c,d = 0x9e3779b9, 0x9e3779b9, 0x9e3779b9, 0x9e3779b9

function evt_num(evt)
    local evt_type = evt[1]
    if evt_type == 'alarm' then
    elseif evt_type == 'char' then
        local character = evt[2]
        return string.byte(character)
    elseif evt_type == 'http_failure' then
        local url = evt[2]
        local res = 0
        for i=1,#url do
            res = res + string.byte(url[i])
        end
        return res

    elseif evt_type == 'key' then
        local key = evt[2]
        local pressed = evt[3] -- number
        return string.byte(key)
    elseif evt_type == 'key_up' then
        local key = evt[2] -- number
        return string.byte(key)

    elseif evt_type == 'modem_message' then
        local modem_side = evt[2] -- string
        local sender_channel = evt[3] -- number
        local reply_channel = evt[4] -- number
        local message = evt[5] -- number or string or table
        local distance = evt[6] -- number

        local msg_res = 0
        for i=1,#message do
            msg_res = msg_res + string.byte(message[i])
        end

        return ((sender_channel + reply_channel) * distance) * msg_res
    elseif evt_type == 'monitor_touch' then
        local monitor_side = evt[2] -- side
        local touch_x = evt[3] -- number
        local touch_y = evt[4] -- number

        return touch_x + touch_y
    elseif evt_type == 'mouse_click' then
        local mouse_button = evt[2] -- 1 for left, 2 right, 3 middle
        local click_x = evt[3]
        local click_y = evt[4]
        return mouse_button * (click_x + click_y)
    elseif evt_type == 'mouse_drag' then
        local mouse_button = evt[2] -- 1 for left, 2 right, 3 middle
        local click_x = evt[3]
        local click_y = evt[4]
        return mouse_button * (click_x + click_y)
    elseif evt_type == 'mouse_scroll' then
        local direction_scroll = evt[2] -- 1 up, -1 down
        local click_x = evt[3]
        local click_y = evt[4]
        return (click_x + click_y)
    elseif evt_type == 'rednet_message' then
        local sender_id = evt[2] -- number
        local message = evt[3] -- any
        local distance = evt[4] -- number

        local msg_res
        if type(message) == 'string' then
            for i=1,#message do
                msg_res = msg_res + string.byte(message[i])
            end
        elseif type(message) == 'number' then
            msg_res = message
        else
            msg_res = math.floor(rand() / (10^7))
        end

        return msg_res * sender_id * distance
    else
        return math.floor(rand() / (10^7))
    end
end

function mix(a,b,c,d)
    -- based of ISAAC mix function
    a = a or math.floor(rand() / (10^7))
    b = b or math.floor(rand() / (10^7))
    c = c or math.floor(rand() / (10^7))
    d = d or math.floor(rand() / (10^7))

    a = a % (INT_MASK)
    b = b % (INT_MASK)
    c = c % (INT_MASK)
    d = d % (INT_MASK)

    a = bit.bxor(a, bit.blshift(b, 11))
    d = d + a
    b = b + c

    b = bit.bxor(b, bit.brshift(c, 2))
    a = a + d
    c = c + a

    c = bit.bxor(c, bit.brshift(d, 8))
    d = d + a
    b = b + c

    d = bit.bxor(d, bit.blshift(a, 16))
    b = b + a
    c = c + d

    a = a % (INT_MASK)
    b = b % (INT_MASK)
    c = c % (INT_MASK)
    d = d % (INT_MASK)

    return a,b,c,d
end

local function evtpool_mix()
    --mix all events of evtpool
    for i=1,EVPOOL_SIZE,4 do
        a = evtpool[i] + a
        b = evtpool[i+1] + b
        c = evtpool[i+2] + c
        d = evtpool[i+3] + d

        a,b,c,d = mix(a,b,c,d)

        evtpool[i] = a
        evtpool[i+2] = b
        evtpool[i+3] = c
        evtpool[i+4] = d
    end
end

function pool_add(event)
    if not pool_lock then
        if (not permission.grantAccess(fs.perms.SYS)) then
            ferror("pool_add: not enough permission")
            return false
        end
    end

    evtpool_time[(#evtpool + 1) % EVPOOL_SIZE] = os.clock()
    evtpool[(#evtpool + 1) % EVPOOL_SIZE] = evt_num(event)
end
evgather.pool_add = poll_add

function pool_export()
    copypool = deepcopy(evtpool)

    --mix pool events
    pool_lock = true
    evtpool_mix()
    pool_lock = false

    return copypool
end
evgather.pool_export = pool_export

function pool_seed()
    local copypool = pool_export()
    local coef = evt_time_coef()
    return reduce(function(a,b) return a+b end, copypool, 0)
end
evgather.pool_seed = pool_seed

function load_pool(pth)
    os.debug.debug_write("[evgather] load_pool", false)
    pth = pth or EVPOOL_PATH
    h = fs.open(pth, 'r')
    if h == nil then
        ferror("load_pool: error loading pool file")
        sleep(1)
        evtpool = table_fgen(rand, EVPOOL_SIZE)
        return true
    end
    local a = h.readAll()
    h.close()

    evtpool = textutils.unserialise(a)
    return true
end
evgather.load_pool = load_pool

function save_pool(pth)
    os.debug.debug_write("[evgather] save_pool")
    pth = pth or EVPOOL_PATH
    h = fs.open(pth, 'w')
    h.write(textutils.serialise(evtpool))
    h.close()
    return true
end
evgather.save_pool = save_pool

function tick_event()
    local evt = {os.pullEvent()}

    pool_lock = true
    pool_add(evt)
    pool_lock = false
end
evgather.tick_event = tick_event

function libroutine()
    _G['evgather'] = evgather

    evgather.load_pool()
    isaac.isaac_seed_entpool()
end

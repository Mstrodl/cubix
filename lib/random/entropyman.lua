#!/usr/bin/env lua

--Entropy Manager: Gets events and organizes them in a pool of entropy

local entropyman = {}
local evtpool = {}

function entropize(evt)
    local evt_type = evt[0]
    local entropy = 0
    if evt_type == 'char' then
        entropy = entropy + string.byte(evt[1])
    elseif evt_type == 'key' or evt_type == 'key_up' then
        entropy = entropy + tonumber("0x" + os.lib.hash.hash.sha256(evt[1]))
    else
        entropy = entropy + rand()
    end
    return entropy
end

function evtpool_add(evt, pool)
    pool = pool or evtpool
    pool[#pool + 1] = entropize(evt)
end
entropyman.evt_add = evtpool_add

function get_evtpool()
    local c = deepcopy(evtpool)
    evtpool = {}
    return c
end
entropyman.evt_getpool = get_evtpool

function sentropy(t)
    local timer = os.startTimer(t)
    local pool = {}
    while true do
        local evt = {os.pullEvent()}
        if evt[1] == 'timer' and evt[2] == timer then break end
        evtpool_add(evt, pool)
    end
    return pool
end
entropyman.sentropy = sentropy

function libroutine()
    _G['entropyman'] = entropyman
    while true do
        local evt = {os.pullEvent()}
        evtpool_add(evt)
        sleep(0)
    end
end

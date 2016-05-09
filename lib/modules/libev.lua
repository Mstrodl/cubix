#!/usr/bin/env lua

--libev: library for event handling

libev = {}

local signalers = {}
local eid_last = 1

local oldqueueEvent = os.queueEvent
local oldpullEvent = os.pullEvent

os.send_ev = function(event)
    local who_did_it = libproc.thread.rtid()
    if not signalers[who_did_it] then
        signalers[who_did_it] = {}
    end

    local len = signalers[who_did_it]

    --update and get EID
    local eid = eid_last + 1
    eid_last = eid_last + 1

    signalers[who_did_it][len] = {eid, evt}
    return oldqueueEvent(unpack(event))
end

os.get_ev = function()
    return {oldpullEvent()}
end

os.queueEvent = function(...)
    return os.send_ev({...})
end

os.pullEvent = function()
    return os.get_ev()
end

libev.get_signalers = function()
    return deepcopy(signalers)
end

libev.push = os.send_ev
libev.pull = os.get_ev

libev.send = libev.push
libev.get = libev.pull

function libroutine()
    _G['libev'] = libev
end

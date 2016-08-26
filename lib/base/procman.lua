#!/usr/bin/env lua

--[[
    procman.lua: the process manager
]]

local thr_normal = {}
local thr_starting = {}
local thr_tidlast = 0

threading = {}

threading.new_thread = function(pid, id, fn, bt)
    --[[
        threading.new_thread(
            pid : int,
            id : str,
            fn : function
        ) : thread

        Creates and returns a thread, the thread is going to start immediately
    ]]
    local thread = {
        tid = thr_tidlast + 1,
        id = id,
        cr = coroutine.create(fn),
        blocked = bt or false,
        error = nil,
        filter = nil,
        dead = false,
        pid = pid,

        --clock stuff
        st_time = 0.0,
        nd_time = 0.0,
        delta = 0.0
    }

    thr_tidlast = thr_tidlast + 1
    table.insert(thr_starting, thread)
    return thread
end

local function tick_one(t, evt, ...)
    if t.dead then return end
    if t.filter ~= nil and evt ~= t.filter then return end
    if evt == 'terminate' and t.blockTerm then return end

    running_tid = t.tid

    t.st_time = os.clock()
    coroutine.resume(t.cr, evt, ...)
    t.nd_time = os.clock()

    -- calculate the time that the thread made to execute
    t.delta = t.nd_time - t.st_time

    -- set dead status
    t.dead = (coroutine.status(t.cr) == "dead")
end

local function compare_ttime(t1, t2)
    return t1.delta < t2.delta
end

local function ev_tick_all()
    if #thr_starting > 0 then
        -- copy starting threads
        local c = thr_starting
        thr_starting = {}

        -- for all threads that are going to start, tick them
        for _,v in ipairs(c) do
            table.insert(thr_normal, v)
            tick_one(v)
        end
    end

    -- If I get an event, use that event in all threads(by tick)
    local evt = {coroutine.yield()}

    -- The scheduler algorithim.
    local dead = nil

    -- threads with less time to execute come first
    table.sort(thr_normal, compare_ttime)

    for k, thread in pairs(thr_normal) do
        -- tick thread with unpacked event
        tick_one(thread, unpack(evt))

        -- if dead, remove him from threads list
        if thread.dead then
            if dead == nil then dead = {} end
            table.insert(dead, k - #dead) -- catalogue thread as dead
            -- killpid(thread.pid) -- kill proces related to the thread
        end
    end

    -- remove all dead threads
    if dead ~= nil then
        for _,v in ipairs(dead) do
            table.remove(thr_normal, v)
        end
    end
end

local threading_started = false
threading.evloop_start = function()
    if threading_started then
        return ferror("evloop: already started")
    end
    threading_started = true

    while #thr_normal > 0 or #thr_starting > 0 do
        ev_tick_all()
    end

    -- shouldn't happen in a beautiful enviroment
    return ferror("evloop: ended")
end

function libroutine()
    _G['threading'] = threading
end

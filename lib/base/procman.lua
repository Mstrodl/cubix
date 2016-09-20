#!/usr/bin/env lua

--[[
    procman.lua: the process manager
]]

RELOADABLE = false

local tid_last = -1
local THR_ALREADY_STARTED = false
local thread_starting = {}
local thread_normal = {}

local threading = {}

local function create_thread(thread_function, thread_name, pid, bt)
    tid_last = tid_last + 1
    local thread = {
        tid = tid_last,
        pid = pid,
        name = name,
        coro = coroutine.create(thread_function),
        dead = false,
        filter = nil,
        block_term = bt or false,


        time_start = 0,
        time_end = 0,
        time_delta = 0,
    }
    table.insert(thread_starting, thread)
    return thread
end
threading.new_thread = create_thread

local function start_thread(fn, n, pid, bt)
    local thread = create_thread(fn, n, pid, bt)

    if not THR_ALREADY_STARTED then
        -- start thread manager
        thread_start_all()
    end

    return thread
end
threading.start_thread = start_thread

local function start_thread_s(fn)
    return start_thread(fn, 'thread', nil, nil)
end
threading.start_thread_s = start_thread_s

local function nthreads()
    return #thread_normal
end
threading.nthreads = nthreads

-- now to the thread scheduler
local thread_running_tid = 0

threading.rtid = function()
    return thread_running_tid
end

local function thread_tick(t, evt, ...)
    --[[
    thread_tick(
        t : thread,
        evt : event,
        ... : ...,
    )

    Ticks one thread
    ]]

    if t.dead then return end
    if t.filter ~= nil and evt ~= t.filter then return end
    if evt == 'terminate' and t.block_Term then return end

    local tst = os.clock()
    thread_running_tid = t.tid
    coroutine.resume(t.coro, evt, ...)

    --calculate time that the thread made to execute
    local tend = os.clock()
    t.time_start = tst
    t.time_end = tend
    t.delta = tend - tst

    --set dead status
    t.dead = (coroutine.status(t.coro) == "dead")
end

local function thread_tick_all()
    --[[
    thread_tick_all()
    Ticks all threads in order:
        threads in thread_starting,
        normal threads(in thread_normal),
    ]]
    if #thread_starting > 0 then
        local c = thread_starting
        thread_starting = {}
        for _,v in ipairs(c) do
            table.insert(thread_normal, v)
            thread_tick(v)
        end
    end

    --If I get an event, use that event in all threads(by tick)
    local evt = {coroutine.yield()}

    --The scheduler algorithim.
    local dead = nil

    function compare_ttime(t1, t2)
        return t1.delta < t2.delta
    end

    --threads with less time to execute come first(kindof FPTP)
    table.sort(thread_normal, compare_ttime)

    for k, thread in pairs(thread_normal) do
        --tick thread with unpacked event
        if libev then
            thread_tick(thread, unpack(evt))
            -- if sys_signal(evt) then
            --     thread.dead = true
            -- end
        else
            thread_tick(thread, unpack(evt))
        end

        --if dead, remove him from threads list
        if thread.dead then
            if dead == nil then dead = {} end
            table.insert(dead, k - #dead) --catalogue thread as dead
            --killpid(thread.pid) --kill proces related to the thread
        end
    end

    --remove all dead threads
    if dead ~= nil then
        for _,v in ipairs(dead) do
            table.remove(thread_normal, v) --remove all dead threads
        end
    end
end

function thread_start_all()
    if not THR_ALREADY_STARTED then
        THR_ALREADY_STARTED = true
        while #thread_normal > 0 or #thread_starting > 0 do
            thread_tick_all()
        end
        return ferror("thread_man: all threads ended(shouldn't happen)")
    else
        return ferror("thread_man: already started")
    end
end

function libroutine()
    print("process manager")
    _G["threading"] = threading
end

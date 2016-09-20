#!/usr/bin/env lua

--[[
    procman.lua: the process manager
]]

RELOADABLE = false

local tid_last = -1
local THR_ALREADY_STARTED = false
local thread_starting = {}
local thread_threads = {}

local threading = {}

local function empty_thread(thread_function, thread_name, pid, bt)
    tid_last = tid_last + 1
    local thread = {
        tid = tid_last,
        pid = pid,
        name = name,
        coro = coroutine.create(thread_function),
        dead = false,
        block_term = bt or false,
    }
    table.insert(thread_starting, thread)
    return thread
end
threading.new_thread = empty_thread

local function start_thread(fn, n, pid, bt)
    local thread = create_thread(fn, n, pid, bt)

    if not THR_ALREADY_STARTED then
        -- start thread manager
        thread_start_all()
    end

    return thread
end
threading.start_thread = start_thread

function libroutine()
    print("process manager")
    _G["threading"] = threading
end

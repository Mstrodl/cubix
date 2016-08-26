#!/usr/bin/env lua

--[[
    procman.lua: the process manager
]]

--[[
    Thread manager
]]

RELOADABLE = false

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

threading.start_thread = function(fn, id, pid)
    return threading.new_thread(pid, id, fn, nil)
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
            -- print("dead", thr_normal[v].id)
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

--[[
    Process Manager
]]

local pid_last = 0

Process = function(file)
    local self = {}
    pid_last = pid_last + 1

    -- Set basic stuff that identifies a process
    --[[
        pid : int
        file : str
        parent : Process
        childs : table of Process
    ]]
    self.pid = pid_last
    self.file = file
    self.parent = nil
    self.childs = {}

    -- Set more stuff that represents who and what (the process) is going to do
    --[[
        Who is running the process
        user : str
        uid : int

        What is it's arguments and TTY
        lineargs : str
        tty : str
    ]]
    self.user = ''
    self.uid = -1
    self.lineargs = ''
    self.tty = ''

    -- Thread that represents the process
    self.thread = nil

    syslog.log("[pm] new: "..self.file, syslog.INFO)
    return self
end

local processes = {}
local running = 0
local cc_os_run = os.run

function pr_run(process, args, pipe, env, use_thread)

    if not env then
        env = {}
    end
    -- lib.pam.default()

    --[[local cur_user = lib.pam.current_user()

    if not fs.verifyPerm(process.file, cur_user, 'x') then
        return ferror("pm.run: perm error")
    end

    if cur_user == '' then
        process.user = 'root'
    else
        process.user = cur_user
    end

    process.uid = lib.pam.userUID()
    processes[process.pid] = process

    local ctty = lib.tty.getcurrentTTY()
    if ctty == nil or ctty == {} or ctty == '' then
        process.tty = '/dev/netty' -- Non-Existing TTY
    else
        process.tty = ctty.id
    end]]

    -- same logic as old proc_manager
    local function handler()
        local iowrapper = lib.get("/lib/modules/io_wrapper.lua")

        -- manage pipes
        if type(pipe) == 'table' then
            env['program_pipe'] = pipe

            env['term'] = tmerge({}, term)
            env['term']['write'] = function(str)
                return pipe:write(str)
            end

            env['io'] = tmerge({}, io)
            env['io']['write'] = function(str)
                return pipe:write(str)
            end

            function write_pipe(d)
                return pipe.write(pipe, d)
            end

            env['print'] = function(...)
                return iowrapper.print_wrapped(write_pipe, unpack({...}))
            end
            env['write'] = function(str)
                return iowrapper.wrapped_write(write_pipe, str)
            end

            env['read'] = function()
                return pipe:readLine()
            end
        end

        os.run(env, process.file, unpack(args, 1))
    end


    running = process.pid
    if not use_thread then
        handler()
        --killproc(process)
    else
        process.thread = threading.start_thread(handler,
            tostring(process.pid)..':'..tostring(process.file),
            process.pid)
    end

    return
end

--[[
    Implement lib functions(fork, etc..)
]]

function fork(f)
    --[[
        fork(
            f : str
        ) : Process

        Creates a Process based on the filepath to the program given
    ]]
    local p = Process(f)
    local fpid = running
    p.parent = processes[fpid]
    --set_parent(p, processes[fpid])
    return p
end

function prexec(process, args, pipe, env, use_thread)
    return pr_run(process, args, pipe, env, use_thread)
end

function libroutine()
    _G['fork'] = fork
    _G['prexec'] = prexec
    _G['threading'] = threading
end

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
threading.start = thread_start_all

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

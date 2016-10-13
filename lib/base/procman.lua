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
    pid = pid or 1
    local thread = {
        tid = tid_last,
        pid = pid,
        name = thread_name,
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

local function copy_threads()
    return deepcopy(thread_normal)
end
threading.copy_threads = copy_threads

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

local function thread_kill_thread(t)
    if thread_starting[t.tid] then
        thread_starting[t.tid] = nil
    end

    if thread_normal[t.tid] then
        thread_normal[t.tid] = nil
    end

    t.coro = nil
    t.dead = true
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

local pm_processes = {}
local pid_last = 0

Process = function(file)
    pid_last = pid_last + 1
    local p = {
        pid = pid_last,
        -- Set basic stuff that identifies a process
        --[[
            pid : int
            file : str
            parent : Process
            childs : table of Process
        ]]
        pid = pid_last,
        file = file,
        parent = nil,
        childs = {},
        -- Set more stuff that represents who and what (the process) is going to do
        --[[
            Who is running the process
            user : str
            uid : int

            What is it's arguments and TTY
            lineargs : str
            tty : str
        ]]
        user = '',
        uid = -1,
        lineargs = '',
        tty = '',
        thread = nil,
        env = {},
    }
    pm_processes[pid_last] = p

    -- syslog.log("[pm] new: "..p.file, syslog.INFO)
    return p
end

local function proc_make_dir(pr)
    local folder = rprintf('/proc/%d', pr.pid)
    fs.makeDir(folder)

    local sp = string.split(pr.file, '/')
    local pr_name = sp[#sp]

    fs_writedata(folder..'/pid', tostring(pr.pid))
    fs_writedata(folder..'/name', pr_name)
    fs_writedata(folder..'/path', pr.file)
    fs_writedata(folder..'/args', pr.lineargs)
end

local function proc_del_dir(pr)
    fs.delete(rprintf('/proc/%d', pr.pid))
end

local running_pid = -1 -- pid of running process
local cc_os_run = os.run -- normal os.run from CC

local function pr_run(process, args, pipe, env)

    if not env then
        env = {}
    end

    if not args then
        args = {}
    end

    --process.env = env
    --process.env['__CWD'] = getenv("__CWD") -- latest __CWD is new __CWD
    tmerge(env, process.env)

    process.uid = 0
    process.runflag = true
    process.lineargs = string.join(' ', args)

    proc_make_dir(process)
    if lib.fs then
        if not fs.cverify_perm(process.file, 'x') then
            return ferror("pr_run: Access Denied")
        end
    end

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

        env['fs_resolve'] = function(pth)
            if pth == nil then return nil end
            if string.sub(pth, 1, 1) == '/' then return pth end
            return fs.combine(process.env['__CWD'], '/'..pth)
        end

        env['_setcwd'] = function(new_wd)
            process.env['__CWD'] = new_wd
        end

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

        --process.env = env
        while process.runflag do
            os.run(env, process.file, unpack(args, 1))
            process.runflag = false
        end
    end


    running_pid = process.pid
    if not use_thread then
        while process.runflag do
            handler()
        end
        --killproc(process)
    else
        --TODO: simpler method to use threads
        process.thread = threading.new_thread(handler,
            tostring(process.pid)..':'..tostring(process.file),
            process.pid)
    end

    proc_del_dir(process)

    return
end

local function _kill(process)
    for k,child in pairs(process.childs) do
        return _kill(child)
    end

    if process.thread then
        thread_kill_thread(process.thread)
    else
        process.runflag = false
    end

    pm_processes[process.pid] = nil
    os.send_ev({"terminate"})
    return true
end

local function set_child(parent, child)
    -- set child as parent of parent
    table.insert(parent.childs, child)

    -- set parent as parent of child
    child.parent = parent

    child.env = deepcopy(parent.env)
end

function new_child(filepath)
    --[[
        new_child(
            filepath : string
        ) : Process

        Creates a Process based on the filepath to the program given
    ]]
    local child = Process(filepath)

    if running_pid ~= -1 then
        set_child(pm_processes[running_pid], child)
    else
        -- init process, set __CWD to /
        child.env['__CWD'] = '/'
    end

    return child
end

--[[
    Implement libproc functions(fork, execv, etc..)
]]

function kill(pid_to_kill)
    local whos_killing = pm_processes[running_pid]
    local to_be_killed = pm_processes[pid_to_kill]

    if not whos_killing then
        return ferror("kill: whos_killing == nil")
    end

    if not to_be_killed then
        return ferror("kill: to_be_killed == nil")
    end

    if to_be_killed.uid <= whos_killing.uid or whos_killing.uid == 0 then
        return _kill(to_be_killed)
    else
        return ferror("kill: Access Denied")
    end
end

function execg(process, args, env, pipe)
    return pr_run(process, args, pipe, env)
end

function execv(path, args)
    return pr_run(new_child(path), args, nil, nil)
end

function execve(path, args, env)
    return pr_run(new_child(path), args, env, nil)
end

function execvp(path, args, env)
    local p = new_child(fs.combine(getenv("__CWD"), path))
    return pr_run(p, args, env, nil)
end

function getenv(name)
    if running_pid == -1 and name == '__CWD' then
        -- this only happens at (very) early boot
        if name == '__CWD' then return '/' end
        return nil
    end

    if pm_processes[running_pid].env[name] then
        return pm_processes[running_pid].env[name]
    end
    return nil
end

function currentuid()
    if running_pid == -1 then return 0 end
    return pm_processes[running_pid].uid
end

function currentpid()
    return running_pid
end

function libroutine()
    -- _G['fork'] = fork
    _G['kill'] = kill
    _G['execv'] = execv
    _G['threading'] = threading
end


local syslog = {}

syslog.DEBUG = 1
syslog.INFO = 2
syslog.ERROR = 3

syslog.BOOT = syslog.INFO

RELOADABLE = false

local log_buffer = ''
local syslog_boot_flag = false

function pad(s, width, padder)
    padder = string.rep(padder or " ", math.abs(width))
    if width < 0 then return string.sub(padder .. s, width) end
    return string.sub(s .. padder, 1, width)
end

function syslog_log(message)
    --pad pc clock time
    local clk = os.clock()
    local _c = tostring(clk)
    local p = 4
    if clk > 10 then
        p = 5
    elseif clk > 100 then
        p = 7
    elseif clk > 1000 then
        p = 9
    elseif clk > 10000 then
        p = 11
    end
    local c = pad(_c, p)

    local message_to_write = string.format('[%s] %s', c, message)

    local a = fs.open("/var/log/syslog", 'a')
    if not a then
        print("syslog: warning! error opening syslog file")
        return false
    end
    a.write(string.format("%s\n", message_to_write))
    a.close()

    --[[if syslog_boot_flag then
        local a = fs.open("/var/log/dmesg", 'a')
        a.write('['..c..'] '..message..'\n')
        a.close()
    end]]

    if not noscreen then
        print(message_to_write)
    end
    log_buffer = log_buffer .. (message_to_write..'\n')

    --os.sleep(math.random() / 16.)
    sleep(0)
end

function syslog_boot()
    syslog_boot_flag = true
end

function close_bflag()
    syslog_boot_flag = false
end

syslog.log = function(msg, level, screen_flag, color)
    if cubix.boot_flag then
        return syslog_log(msg)
    end

    if level == syslog.ERROR then
        term.set_term_color(colors.red)
    end

    if color then
        term.set_term_color(color)
    end

    if not level then level = syslog.ERROR end

    if screen_flag == nil or (screen_flag == false and
    cubix.boot_flag or _G['CUBIX_REBOOTING'] or
    _G['CUBIX_TURNINGOFF']) then
        syslog_log(msg, level < syslog.INFO)
    end

    term.set_term_color(colors.white)
    return true
end

--[[
syslog.debug_write = function(msg, screen_flag, error_flag)
    local level = syslog.DEBUG
    if error_flag then
        level = syslog.ERROR
    end
    syslog.log(msg, level, screen_flag)
end
]]

syslog.get_buffer = function()
    return log_buffer
end

syslog.S_OK = syslog.INFO
syslog.S_ERR = syslog.ERROR
syslog.S_INFO = syslog.DEBUG

syslog.serlog = function(...)
    local args = {...}

    local logtype, service_name = args[1], args[2]
    local message = rprintf(unpack(args, 3))

    local serlog_type = ''
    local color = colors.orange

    if logtype == syslog.S_OK then
        serlog_type = '[ OK ] '
        color = colors.green
    elseif logtype == syslog.S_ERR then
        serlog_type = '[ ERR ] '
        color = colors.red
    else
        serlog_type = '[ INFO ] '
        color = colors.lightBlue
    end

    local serlog_str = rprintf("%s[%s] %s", serlog_type, service_name, message)
    return syslog.log(serlog_str, logtype, nil, color)
end

syslog.serlog_info = function(sname, msg)
    return syslog.serlog(syslog.S_INFO, sname, msg)
end

syslog.panic = function(...)
    if lib.pm.currentuid() ~= 0 then
        return ferror("Access Denied")
    end

    local args = {...}
    local service_name = args[1]
    local message = rprintf(unpack(args, 2))

    printf("=== SYSLOG PANIC ===")
    printf("ERR: [%s] %s", service_name, message)

    write("MOD: ")
    for k,v in pairs(lib) do
        if type(v) == 'table' then write(k..' ') end
    end

    while true do sleep(1000) end -- hlt
end

syslog.getbuffer = function()
    return log_buffer
end

function libroutine()
    -- syslog.kpanic = os.debug.kpanic

    _G['os']['debug'] = syslog
    _G['debug'] = syslog
    _G['syslog'] = syslog
end

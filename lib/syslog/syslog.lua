
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

    local a = fs.open("/var/log/syslog", 'a')
    a.write('['..c..'] '..message..'\n')
    a.close()

    --[[if syslog_boot_flag then
        local a = fs.open("/var/log/dmesg", 'a')
        a.write('['..c..'] '..message..'\n')
        a.close()
    end]]

    printf('[%s] %s', c, message)
    log_buffer = log_buffer .. ('['..c..'] '..message..'\n')

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

    if screen_flag == nil or (screen_flag == false and
    cubix.boot_flag or _G['CUBIX_REBOOTING'] or
    _G['CUBIX_TURNINGOFF']) then
        syslog_log(msg)
    end

    term.set_term_color(colors.white)
    return true
end

syslog.debug_write = function(msg, screen_flag, error_flag)
    local level = syslog.DEBUG
    if error_flag then
        level = syslog.ERROR
    end
    syslog.log(msg, level, screen_flag)
end

syslog.get_log = function()
    return log_buffer
end

syslog.testcase = function(message, correct)
    syslog.log(message, syslog.INFO, nil, colors.orange)
end

syslog.S_OK = syslog.INFO
syslog.S_ERR = syslog.ERROR
syslog.S_INFO = syslog.DEBUG

syslog.serlog = function(logtype, service_name, message)
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

function syskpanic(msg)
    local cxt = lx.get_screen()
    local x, y = cxt:draw_rectangle(5, 5, 20, 5, colors.red)
    cxt:draw_text(x+1, y+1, 'kpanic')
    cxt:draw_text(x+1, y+2, msg)
    khalt()
end

function libroutine()
    -- syslog.kpanic = os.debug.kpanic

    _G['os']['debug'] = syslog
    _G['debug'] = syslog
    _G['syslog'] = syslog
end

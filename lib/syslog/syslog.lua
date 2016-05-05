
local syslog = {}

syslog.DEBUG = 1
syslog.INFO = 2
syslog.ERROR = 3

syslog.BOOT = syslog.INFO

RELOADABLE = false

local log_cnt = 0
local log_buffer = ''

function syslog_log(message)
    local a = fs.open("/var/log/syslog", 'a')
    a.write('['..log_cnt..'] '..message..'\n')
    a.close()

    print('['..log_cnt..'] '..message)
    log_buffer = log_buffer .. ('['..log_cnt..'] '..message..'\n')
    log_cnt = log_cnt + 1

    os.sleep(math.random() / 16.)
end

syslog.log = function(msg, level, screen_flag)
    if cubix.boot_flag then
        return syslog_log(msg)
    end

    if level == syslog.ERROR then
        term.set_term_color(colors.red)
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
    term.set_term_color(colors.orange)
    syslog.log(message, syslog.INFO)
    term.set_term_color(colors.white)
end

syslog.S_OK = syslog.INFO
syslog.S_ERR = syslog.ERROR
syslog.S_INFO = syslog.DEBUG

syslog.serlog = function(logtype, service_name, message)
    local serlog_str = "["..service_name.."] "

    if logtype == syslog.S_OK then
        serlog_str = serlog_str .. '[ OK ] '
    elseif logtype == syslog.S_ERR then
        serlog_str = serlog_str .. '[ ERR ] '
    else
        serlog_str = serlog_str .. '[ INFO ] '
    end

    serlog_str = serlog_str .. message
    return syslog.log(serlog_str, logtype)
end

function libroutine()
    syslog.kpanic = os.debug.kpanic

    _G['os']['debug'] = syslog
    _G['debug'] = syslog
    _G['syslog'] = syslog
end

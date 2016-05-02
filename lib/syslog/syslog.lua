
local syslog = {}

syslog.DEBUG = 1
syslog.INFO = 2
syslog.ERROR = 3

syslog.log = function(msg, level)
    if level == syslog.DEBUG then
    end
end

syslog.get_log = function()
    return syslog_log
end

function libroutine()
    _G['os']['debug'] = syslog
    _G['debug'] = syslog
    _G['syslog'] = syslog
end

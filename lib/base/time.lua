
--[[
    time.lua - manages time functions and /dev/time
]]


local fallback2 = "http://luca.spdns.eu/time.php"
local fallback1 = 'http://www.timeapi.org/utc/now?format=%7B%25d%2C%25m%2C%25Y%2C%25H%2C%25M%2C%25S%7D'

local servers = {}

local function read_servers()
    local ts_file = fs.open("/etc/time-servers", 'r')
    local ts_data = ts_file.readAll()
    ts_file.close()
    servers = {}
    local data = os.strsplit(ts_data, '\n')
    for k,v in ipairs(data) do
        table.insert(servers, v)
    end
    table.insert(servers, fallback1)
    table.insert(servers, fallback2)
end

local function get_time_data()
    local res = ''
    for k,v in pairs(servers) do
        os.debug.debug_write("[time] getting time data from "..v, false)
        local connection = http.get(v)
        if connection ~= nil then
            local data = connection.readAll()
            connection.close()
            if d ~= nil then
                return d
            else
                os.debug.debug_write("get_time_data: data == nil", true, true)
            end
        else
            os.debug.debug_write("get_time_data: connection == nil", true, true)
        end
    end
    return nil
end

local function default_tz()
    local h = fs.open("/etc/timezone", 'r')
    if h == nil then return ferror('deafult_tz: error opening timezone') end
    local d = h.readAll()
    h.close()

    local data = string.split(d, ':')
    return {tonumber(data[1]), tonumber(data[2])}
end

function get_time_unser(_tZoneH, _tZoneM)
    read_servers()
    local dtz = default_tz()
    if dtz == nil then
        ferror("get_time_unser: default timezone is nil")
        return {0,0,0,0,0,0,0}
    end
    local tZoneH = _tZoneH or dtz[1]
    local tZoneM = _tZoneM or dtz[2]
    local d = get_time_data()
    if d == nil then
        ferror("get_time_unser: get_time_data returned nil")
        return {0,0,0,0,0,0,0}
    end

    local t = textutils.unserialise(d)
    if t == nil then
        ferror("get_time_unser: error unserializing data")
        return {0,0,0,0,0,0,0}
    end

    -- calculate timezones based on it
    local day, month, year = t[1], t[2], t[3]
    local gh, gm, s = t[4], t[5], t[6]

    local m = gm + tZoneM
    local h = gh + tZoneH + math.floor(m / 60)
    local m = m % 60
    h = h % 24
    return {day, month, year, h, m, s}
end

function localtime(tz1, tz2)
    local k = get_time_unser(tz1, tz2)
    return {day=k[1], month=k[2], year=k[3],
            hours=k[4], minutes=k[5], seconds=k[6]}
end

function asctime(tm)
    local h,m,s = tm.hours, tm.minutes, tm.seconds
    local d,mon,y = tm.day, tm.month, tm.year
    local formatted_1 = string.format("%d-%d-%d",d,mon,y)
    local formatted = string.format("%2d:%2d:%2d",h,m,s):gsub(" ","0")
    return formatted_1 .. ' '..formatted
end

function strtime(tz1, tz2)
    return asctime(localtime(tz1,tz2))
end

TimeDevice = class(lib.udev.Device, function(self)
end)

function TimeDevice:read(bytes)
    return get_time_unser()
end

function libroutine()
    if lib.udev then
        lib.udev.add_device("/dev/time.http", TimeDevice())
    end
    --install functions in _G
    _G['localtime'] = localtime
    _G['asctime'] = asctime
    _G['strtime'] = strtime
    --os.debug.debug_write("[time] testing time")
    --os.debug.debug_write("[time] time at tz 0,0: "..strtime(0,0))
    --os.debug.debug_write("[time] time at default tz: "..strtime())
end

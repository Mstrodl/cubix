
--[[
    time.lua - manages time functions and /dev/time
]]

TimeDevice = class(Device, function(self)
end)

function TimeDevice:read(bytes)
    return getTime_fmt()
end

function libroutine()
    if udev then
        udev.add_device("/dev/time", TimeDevice())
    end
end

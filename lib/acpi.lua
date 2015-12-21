#!/usr/bin/env lua
--ACPI module
--Advanced Configuration and Power Interface

RELOADABLE = false

local _shutdown = os.shutdown
local _reboot = os.reboot

local __clear_temp = function()
    os.debug.debug_write("[acpi] cleaning temporary")
    fs.delete("/tmp")
    for _,v in ipairs(fs.list("/proc")) do
        local k = os.strsplit(v, '/')
        --os.debug.debug_write(k[#k]..";"..tostring(fs.isDir("/proc/"..v)), false)
        if tonumber(k[#k]) ~= nil and fs.isDir("/proc/"..v) then
            fs.delete("/proc/"..v)
        end
    end
    fs.makeDir("/tmp")
end

local function acpi_shutdown()
    if permission.grantAccess(fs.perms.SYS) then
        os.debug.debug_write("[shutdown] shutting down for system halt")
        _G['CUBIX_TURNINGOFF'] = true
        os.debug.debug_write("[shutdown] sending SIGKILL to all processes")
        if not os.__boot_flag then --still without proper userspace
            os.lib.proc.__killallproc()
        end
        os.sleep(1)
        __clear_temp()
        os.debug.debug_write("[shutdown] sending HALT.")
        os.sleep(.5)
        _shutdown()
    else
        os.ferror("acpi_shutdown: cannot shutdown without SYSTEM permission")
    end
    permission.default()
end

local function acpi_reboot()
    if permission.grantAccess(fs.perms.SYS) then
        os.debug.debug_write("[reboot] shutting down for system reboot")
        _G['CUBIX_REBOOTING'] = true
        os.debug.debug_write("[reboot] sending SIGKILL to all processes")
        if not os.__boot_flag then --still without proper userspace
            os.lib.proc.__killallproc()
        end
        os.sleep(1)
        __clear_temp()
        os.debug.debug_write("[reboot] sending RBT.")
        os.sleep(.5)
        _reboot()
    else
        os.ferror("acpi_reboot: cannot reboot without SYSTEM permission")
    end
    permission.default()
end

local function acpi_suspend()
    while true do
        term.clear()
        term.setCursorPos(1,1)
        local event, key = os.pullEvent('key')
        if key ~= nil then
            break
        end
    end
end

local function acpi_hibernate()
    --[[
        So, to hibernate we need to write the RAM into a file, and then
        in boot, read that file...
    ]]
    --after that, black magic happens (again)
    os.debug.debug_write("[acpi_hibernate] starting hibernation")
    local ramimg = fs.open("/dev/ram", 'w')
    ramimg.close()
    os.debug.debug_write("[acpi_hibernate] complete, shutting down.")
    acpi_shutdown()
end

function acpi_hwake()
    os.debug.debug_write("[acpi_hibernate] waking")
    fs.delete("/dev/ram")
    --local ramimg = fs.open("/dev/ram", 'r')
    --ramimg.close()
    acpi_reboot()
end

function libroutine()
    os.shutdown = acpi_shutdown
    os.reboot = acpi_reboot
    os.suspend = acpi_suspend
    os.hibernate = acpi_hibernate
end

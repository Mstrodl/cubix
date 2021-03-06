#!/usr/bin/env lua
--ACPI module
--Advanced Configuration and Power Interface

RELOADABLE = false

local _shutdown = os.shutdown
local _reboot = os.reboot

local __clear_temp = function()
    syslog.serlog(syslog.S_INFO, "acpi", "cleaning temporary")

    fs.delete("/tmp")
    fs.delete("/var/log/dmesg")
    for _,v in ipairs(fs.list("/proc")) do
        local k = os.strsplit(v, '/')
        --os.debug.debug_write(k[#k]..";"..tostring(fs.isDir("/proc/"..v)), false)
        if tonumber(k[#k]) ~= nil and fs.isDir("/proc/"..v) then
            fs.delete("/proc/"..v)
        end
    end
    fs.makeDir("/tmp")

    syslog.serlog(syslog.S_INFO, "acpi", "save entropy pool")
    -- evgather.save_pool()
end

local function acpi_shutdown()
    syslog.log(syslog.S_INFO, "acpi_shutdown", "")
    if lib.auth.grant(lib.auth.system_perm) then
        syslog.serlog(syslog.S_OK, "shutdown", "shutting down for system halt")
        _G['CUBIX_TURNINGOFF'] = true

        syslog.serlog(syslog.S_OK, "shutdown", "sending SIGKILL to all processes")
        if not cubix.boot_flag then --proper userspace
            --lib.proc.__killallproc()
            --lib.fs.shutdown_procedure()
        end

        os.sleep(1)
        __clear_temp()
        syslog.serlog(syslog.S_INFO, "shutdown", "sending HALT.")
        os.sleep(.5)
        _shutdown()
    else
        os.ferror("acpi_shutdown: cannot shutdown without system permission")
    end
end

local function acpi_reboot()
    --[[
    if not lib.auth.grant(perm.sys) then
        return ferror("Access Denied")
    end
    ]]
    syslog.serlog(syslog.S_INFO, 'acpi_reboot', '')
    --if permission.grantAccess(fs.perms.SYS) then
    if lib.auth.grant(lib.auth.system_perm) then
        syslog.serlog(syslog.S_INFO, 'reboot', "system reboot")
        _G['CUBIX_REBOOTING'] = true
        syslog.serlog(syslog.S_INFO, 'reboot', "sending SIGKILL to all processes")
        if not os.__boot_flag then --still without proper userspace
            -- lib.proc.__killallproc()
            syslog.serlog(syslog.S_INFO, 'reboot', "unmounting drives")
            -- lib.fs.shutdown_procedure()
        end
        sleep(1)
        __clear_temp()
        syslog.serlog(syslog.S_OK, 'reboot', "sending RBT.")
        sleep(.5)
        _reboot()
    else
        os.ferror("acpi_reboot: cannot reboot without SYSTEM permission")
    end
end

local function acpi_suspend()
    os.debug.debug_write('[suspend] starting', true)
    while true do
        term.clear()
        term.setCursorPos(1,1)
        local event, key = os.pullEvent('key')
        if key ~= nil then
            break
        end
    end
    os.debug.debug_write('[suspend] ending', true)
end

local function acpi_hibernate()
    --[[
        So, to hibernate we need to write the RAM into a file, and then
        in boot, read that file... WTF?
    ]]
    --after that, black magic happens (again)
    --[[
        Dear future Self,

        I don't know how to do this,
        Please, finish.
    ]]
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

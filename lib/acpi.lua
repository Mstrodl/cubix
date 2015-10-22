#!/usr/bin/env lua
--ACPI module
--Advanced Configuration and Power Interface

local _shutdown = os.shutdown
local _reboot = os.reboot

local __clear_temp = function()
    os.runfile("rm /tmp")
    os.runfile("mkdir /tmp")
end

local function acpi_shutdown()
    os.debug.debug_write("[shutdown] shutting down for system halt")
    os.debug.debug_write("[shutdown] sending SIGKILL to all processes")
    if not os.__boot_flag then --still without proper userspace
        os.lib.proc.__killallproc()
    end
    os.sleep(1)
    os.debug.debug_write("[shutdown] deleting temporary")
    __clear_temp()
    os.debug.debug_write("[shutdown] sending HALT.")
    os.sleep(.5)
    _shutdown()
end

local function acpi_reboot()
    os.debug.debug_write("[reboot] shutting down for system reboot")
    os.debug.debug_write("[reboot] sending SIGKILL to all processes")
    if not os.__boot_flag then --still without proper userspace
        os.lib.proc.__killallproc()
    end
    os.sleep(1)
    os.debug.debug_write("[reboot] sending RBT.")
    os.debug.debug_write('\n')
    os.sleep(.5)
    _reboot()
end

local function acpi_suspend()

end

local function acpi_hibernate()
    --[[
        So, to hibernate we need to write the RAM into a file, and then
        in boot, read that file...
    ]]
    os.debug.debug_write("[HIBERNATION] starting hibernation")
    local ramimg = fs.open("/dev/ram", 'w')
    ramimg.close()
    os.debug.debug_write("[HIBERNATION] complete, shutting down.")
    acpi_shutdown()
end

function acpi_hwake()
    os.debug.debug_write("[WAKING FROM HIBERNATION]")
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


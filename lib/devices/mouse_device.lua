#!/usr/bin/env lua
--mouse device

dev_mouse = {}
dev_mouse.name = '/dev/mouse'
dev_mouse.device = {}
dev_mouse.device.device_read = function(bytes)
    local event, button, x, y = os.pullEvent('mouse_click')
    return 'click:'..x..','..y..','..button
end

dev_mouse.device.device_write = function(s)
    ferror("devmouse: cant write to mouse device")
    os.sys_signal(os.signals.SIGILL)
    return 1
end

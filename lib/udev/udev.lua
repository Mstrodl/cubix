-- udev: device manager(better than /boot/cubix)

loadmodule_ret("")

function tick_event()
    local evt = {os.pullEvent()}
    if evt[1] == 'udev_new' then
        udev_add_device(evt[2], evt[3])
    elseif evt[1] == 'udev_del' then
        udev_rmv_device(evt[2], evt[3])
    end
end

function libroutine()
    print("udev.")
end

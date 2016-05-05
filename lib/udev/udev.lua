-- udev: device manager(better than /boot/cubix)

loadmodule_ret("")

local paths = {}

local udev = {} --udev namespace

local function udev_add_dev(path, devobj)
    devices[path] = devobj
    syslog.serlog(syslog.S_OK, "udev", "got device in "..path)
end
udev.new_device = udev_add_dev

function get_nodes()
    return paths
end
udev.get_nodes = get_nodes

------DEVFS------

devfs = {}

devfs.open = function(mountpath, path)
    return {}
end

devfs.exists = function(mountpath, path)
    return false
end

udev.devfs = devfs

------LIBROUTINE------

function tick_event()
    local evt = {os.pullEvent()}
    if evt[1] == 'udev_new' then
        udev_add_device(evt[2], evt[3])
    elseif evt[1] == 'udev_del' then
        udev_rmv_device(evt[2], evt[3])
    end
end

function libroutine()
    _G['udev'] = udev
    print("udev.")
end

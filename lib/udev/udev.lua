-- udev: device manager

loadmodule_ret("")

local device_nodes = {}
local devices = {}

local udev = {} --udev namespace

local function udev_add_dev(path, devobj)
    if (type(path) ~= 'string') or (type(devobj) ~= 'table') then
        return ferror("udev_add_dev: invalid arguments")
    end

    devices[path] = devobj

    local stripped = string.sub(path, 5, #path)
    device_nodes['/dev'][stripped] = {perm=077, device=devobj}

    os.lib.syslog.syslog_boot()
    syslog.serlog(syslog.S_INFO, "udev", "new device: "..path)
    os.lib.syslog.close_bflag()

    return true
end
udev.new_device = udev_add_dev

function get_nodes()
    return device_nodes
end
udev.get_nodes = get_nodes

function get_devices()
    return devices
end
udev.get_devices = get_devices

udev.device_write = function(path, data)
    return devices[path].device.device_write(data)
end

udev.device_read = function(path, bytes)
    return devices[path].device.device_read(bytes)
end

udev.hotplug = {}

udev.hotplug.add = function(type)
    if type == 'peri' then
        print("hotplug.add: peripheral")
    elseif type == 'printer' then
        print("hostplug.add: printer")
    end
end

udev.hotplug.remove = function(path)

end

------DEVFS------

devfs = {}

devfs.loadFS = function(mountpath)
    syslog.serlog(syslog.S_INFO, "devfs", "loading at "..mountpath)
    if not device_nodes[mountpath] then
        device_nodes[mountpath] = {}
    end
    return {}, true
end

function getInfo(mountpath, path)
    local data = device_nodes[mountpath][path]
    return {
        owner = data.owner,
        perms = data.perm
    }
end

function vPerm(mountpath, path, mode)
    local info = getInfo(mountpath, path)
    local norm = fsmanager.normalizePerm(info.perms)
    if user == info.owner then
        if mode == "r" then return string.sub(norm[1], 1, 1) == "r" end
        if mode == "w" then return string.sub(norm[1], 2, 2) == "w" end
        if mode == "x" then return string.sub(norm[1], 3, 3) == "x" end
    elseif os.lib.login.isInGroup(user, info.gid) then
        if mode == "r" then return string.sub(norm[2], 1, 1) == "r" end
        if mode == "w" then return string.sub(norm[2], 2, 2) == "w" end
        if mode == "x" then return string.sub(norm[2], 3, 3) == "x" end
    else
        if mode == "r" then return string.sub(norm[3], 1, 1) == "r" end
        if mode == "w" then return string.sub(norm[3], 2, 2) == "w" end
        if mode == "x" then return string.sub(norm[3], 3, 3) == "x" end
    end
end

local function general_file(mountpath, path, mode)
    return {
        _perm = deepcopy(device_nodes[mountpath][path].perm),
        _cursor = 1,
        _closed = false,

        write = function(data)
            if vPerm(mountpath, path, 'w') and mode == 'a' then
                return udev.device_write(mountpath..'/'..path, data)
            elseif vPerm(mountpath, path, 'w') and mode == 'w' then
                return udev.device_write(mountpath..'/'..path, data)
            else
                ferror("devfs: cant write to file")
            end
        end,

        writeLine = function(data)
            if vPerm(mountpath, path, 'w') and mode == 'a' then --append
                return udev.device_write(mountpath..'/'..path, data .. '\n')
            elseif vPerm(mountpath, path, 'w') and mode == 'w' then --write from start
                return udev.device_write(mountpath..'/'..path, data .. '\n')
            else
                ferror("devfs: cant writeLine to file")
            end
        end,

        read = function(bytes)
            if vPerm(mountpath, path, 'r') and mode == 'r' then
                return udev.device_read(mountpath..'/'..path, bytes)
            else
                ferror("devfs: cant read file")
            end
        end,

        readAll = function()
            if vPerm(mountpath, path, 'r') then
                return udev.device_read(mountpath..'/'..path, nil)
            else
                ferror('devfs: cant read file')
            end
        end,

        close = function()
            _perm = 0
            _cursor = 0
            _closed = true
            write = nil
            read = nil
            writeLine = nil
            readAll = nil
            return true
        end,
    }
end

local function file_object(mpath, path, mode)
    local new_perm = 0
    if not device_nodes[mpath][path] then
        new_perm = '777'
    else
        new_perm = device_nodes[mpath][path].perm
    end

    if not device_nodes[mpath][path] then
        device_nodes[mpath][path] = {
            perm=new_perm,
            owner=0,
        }
    end

    return general_file(mpath, path, mode)
end

function really_list_files(mountpath)
    local result = {}
    for k,v in pairs(device_nodes[mountpath]) do
        table.insert(result, k)
    end
    return result
end

function list_files(mountpath)
    --show one level of things
    local result = {}
    for k,v in pairs(device_nodes[mountpath]) do
        if k:find("/") then
            if string.sub(k,1,1) == '/' and strcount(k, '/') == 1 then
                table.insert(result, string.sub(k, 1))
            end
        else
            table.insert(result, k)
        end
    end
    return result
end

devfs.list = function(mountpath, path)
    if path == '/' or path == '' or path == nil then
        --all files in mountpath
        return list_files(mountpath)
    else
        --get relevant ones
        local all = really_list_files(mountpath)
        local res = {}
        for k,v in ipairs(all) do
            local cache = string.sub(v, 1, #path)
            if string.sub(v, 1, #path) == string.sub(path, 2)..'/' and cache ~= '' then
                table.insert(res, string.sub(v, #path + 1))
            end
        end
        return res
    end
end

devfs.exists = function(mountpath, path)
    --print("exists: "..path)
    if path == nil or path == '' then
        if device_nodes[mountpath] then
            return true
        else
            return false
        end
    end
    --os.viewTable(paths[mountpath][path])
    return device_nodes[mountpath][path] ~= nil
end

devfs.open = function(mountpath, path, mode)
    return file_object(mountpath, path, mode)
end

devfs.exists = function(mountpath, path)
    return false
end

devfs.getSize = function(mountpath, path)
    return 0
end

udev.devfs = devfs

------LIBROUTINE------

function tick_event()
    local evt = {os.pullEvent()}
    if evt[1] == 'hotplug_new' then
        udev.hotplug.add(evt[2])
    elseif evt[1] == 'hotplug_del' then
        udev.hotplug.remove(evt[2])
    end
end

function libroutine()
    _G['udev'] = udev
end

--[[
    fs.lua - manage filesystems
        mounting, etc.
]]

RELOADABLE = false

--TODO: implementation of VFS, the virtual file system

local mounted_devices = {}

--[[
fs.open = function(path, mode)

end
]]

function mount(source, target, fstype, mountflags, data)
end

function fs_readall(fpath, external_fs)
    external_fs = external_fs or fs
    local h = external_fs.open(fpath, 'r')
    if h == nil then return nil end
    local data = h:readAll()
    h:close()
    return data
end

function fs_writedata(fpath, data, flag, external_fs)
    flag = flag or false
    external_fs = external_fs or fs
    local h = nil
    if flag then
        h = external_fs.open(fpath, 'a')
    else
        h = external_fs.open(fpath, 'w')
    end
    if h == nil then return nil end
    local data = h:readAll()
    h:close()
    return data
end

function libroutine()
    _G['fs_readall'] = fs_readall
    _G['fs_writedata'] = fs_writedata
end

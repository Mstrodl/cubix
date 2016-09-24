--[[
    fs.lua - manage filesystems
        mounting, etc.
]]

RELOADABLE = false

--TODO: implementation of VFS, virtual file system

--[[
fs.open = function(path, mode)

end
]]

function fs_readall(fpath)
    local h = fs.open(fpath, 'r')
    if h == nil then return nil end
    local data = h:readAll()
    h:close()
    return data
end

function fs_writedata(fpath, data, flag)
    flag = flag or false
    local h = nil
    if flag then
        h = fs.open(fpath, 'a')
    else
        h = fs.open(fpath, 'w')
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

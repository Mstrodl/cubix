--Cubix File System

local res = {}

function canMount(uid)
    if uid == 0 then
        return true
    else
        return false
    end
end

function collectFiles(dir, stripPath, table)
    if not table then table = {} end
    dir = dir
    local fixPath = fsmanager.stripPath(stripPath, dir)
    table[dir] = fsmanager.getInformation(dir)
    local files = fs.list(dir)
    if dir == '/' then dir = '' end
    if fixPath == '/' then fixPath = '' end
    for k, v in pairs(files) do
        if string.sub(v, 1, 1) == '/' then v = string.sub(v, 2, #v) end
        table[fixPath .. "/" .. v] = fsmanager.getInformation(dir .. "/" .. v)
        if oldfs.isDir(dir .. "/" .. v) then collectFiles(dir .. "/" .. v, stripPath, table) end
    end
    return table
end

function _test()
    return collectFiles("/", "/", {})
end

function getSize(path)end

function saveFS(mountpath, dev)
    local p = dev
    if p == '/' then p = '' end
    local FSDATA = oldfs.open(p .. "/CFSDATA", "w")
    local WRITEDATA = ""
    for k, v in pairs(collectFiles(mountpath, mountpath, {})) do
        if string.sub(k, 1, 4) ~= '.git' and string.sub(k, 1, 5) ~= '/.git' and string.sub(k, 1, 6) ~= '/.git/' then
            WRITEDATA = WRITEDATA .. k .. ":" .. v.owner .. ":" .. v.perms .. ":"
            if v.linkto then WRITEDATA = WRITEDATA .. v.linkto end
            WRITEDATA = WRITEDATA .. ":" .. v.gid .. "\n"
        end
    end
    print("saveFS: ok")
    FSDATA.write(WRITEDATA)
    FSDATA.close()
end

function loadFS(mountpath, dev)
    local p = dev
    if p == '/' then p = '' end
    if not fs.exists(p..'/CFSDATA') then saveFS(mountpath, dev) end
    local _fsdata = oldfs.open(p..'/CFSDATA', 'r')
    local fsdata = _fsdata.readAll()
    _fsdata.close()
    local splitted = os.strsplit(fsdata, "\n")
    local res = {}
    for k,v in ipairs(splitted) do
        local tmp = os.strsplit(v, ":")
        if #tmp == 5 then
            res[tmp[1]] = {
                owner = tonumber(tmp[2]),
                perms = tmp[3],
                linkto = tmp[4],
                gid = tonumber(tmp[5])
            }
        elseif #tmp == 4 then
            res[tmp[1]] = {
                owner = tonumber(tmp[2]),
                perms = tmp[3],
                linkto = nil,
                gid = tonumber(tmp[4])
            }
        end
        if tmp[4] == "" then
            res[tmp[1]].linkto = nil
        end
        --os.viewTable(res[tmp[1]])
    end
    return res, true
end

function list(mountpath, path)
    return oldfs.list(path)
end

function exists(mountpath, path)
    return oldfs.exists(path)
end

function isDir(mountpath, path)
    return oldfs.isDir(path)
end

function delete(mountpath, path)
    return oldfs.delete(path)
end

function makeDir(mountpath, path)
    return oldfs.makeDir(path)
end

function open(mountpath, path, mode)
    --print("cfs open here "..path..' '..mode)
    return oldfs.open(path, mode)
end

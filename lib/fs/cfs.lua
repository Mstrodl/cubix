--Cubix File System

local res = {}

function collectFiles(dir, stripPath, table)
    if not table then table = {} end
    dir = dir
    local fixPath = fsmanager.stripPath(stripPath, dir)
    table[dir] = fsmanager.getInformation(dir)
    --[[
    local err, files = pcall(fs.list, dir, true)
    os.viewTable(files)
    print("lol")
    if not err then return table end
    if dir == "/" then dir = "" end
    print("lel")
    ]]
    --os.viewTable(files)
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
    local FSDATA = oldfs.open(p .. "/UFSDATA", "w")
    local WRITEDATA = "" 
    for k, v in pairs(collectFiles(mountpath, mountpath, {})) do
        if v.perms ~= '777' then
            print(k)
            os.viewTable(v)
            --sleep(1.5)
        end
        WRITEDATA = WRITEDATA .. k .. ":" .. v.owner .. ":" .. v.perms .. ":"
        if v.linkto then WRITEDATA = WRITEDATA .. v.linkto end
        WRITEDATA = WRITEDATA .. ":" .. v.gid .. "\n"
    end
    print("saveFS: ok")
    FSDATA.write(WRITEDATA)
    FSDATA.close()
end

function loadFS(mountpath, dev)
    local p = dev
    if p == '/' then p = '' end
    if not fs.exists(p..'/UFSDATA') then saveFS(mountpath, dev) end
    local _fsdata = fs.open(p..'/UFSDATA', 'r')
    local fsdata = _fsdata.readAll()
    _fsdata.close()
    local splitted = os.strsplit(fsdata, "\n")
    local res = {}
    for k,v in ipairs(splitted) do
        local tmp = os.strsplit(v, ":")
        os.viewTable(tmp)
        --sleep(1)
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

--loadFS('/', '/')

function list(path)end

function exists(path)end

function isDir(path)end

function open(path, mode)end

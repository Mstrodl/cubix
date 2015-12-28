--Temporary File System

local res = {}
local files = {}

--[[
files(table of tables):
each table:
    KEY = filename - filename

    perm - permission
    file - actual file
]]

function list_files()
    local result = {}
    for k,v in pairs(files) do
        table.insert(result, k)
    end
    return result
end

function collectFiles(dir, stripPath, table)
    if not table then table = {} end
    local fixPath = fsmanager.stripPath(stripPath, dir)
    table[dir] = fsmanager.getInformation(dir)
    local files = list_files()
    if dir == '/' then dir = '' end
    if fixPath == '/' then fixPath = '' end
    for k, v in pairs(files) do
        if string.sub(v, 1, 1) == '/' then v = string.sub(v, 2, #v) end
        table[fixPath .. "/" .. v] = fsmanager.getInformation(dir .. "/" .. v)
        if oldfs.isDir(dir .. "/" .. v) then collectFiles(dir .. "/" .. v, stripPath, table) end
    end
    return table
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
        if string.sub(k, 1, 4) ~= '.git' then
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
    if not fs.exists(p..'/UFSDATA') then saveFS(mountpath, dev) end
    local _fsdata = fs.open(p..'/UFSDATA', 'r')
    local fsdata = _fsdata.readAll()
    _fsdata.close()
    local splitted = os.strsplit(fsdata, "\n")
    local res = {}
    for k,v in ipairs(splitted) do
        local tmp = os.strsplit(v, ":")
        --os.viewTable(tmp)
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

function list(path)
    return fs.list(path)
end

function exists(path)
    return fs.exists(path)
end

function isDir(path)
    return fs.isDir(path)
end

function makeObject(path, mode)
    if files[path] then --file already exists
        if mode == 'w' then files[path].file = '' end
        return {
            _file = files[path].file,
            _perm = files[path].perm,
            _cursor = 1,
            write = function(data)
                if _perm.writeperm then
                    _file = _file .. data
                    return data
                else
                    ferror("tmpfs: cant write to file")
                end
            end,
            read = function(bytes)
                if _perm.readperm then
                    local res = string.sub(_file, _cursor, _cursor + bytes)
                    _cursor = _cursor + bytes
                    return res
                else
                    ferror("tmpfs: cant read file")
                end
            end,
            readAll = function()
                if _perm.readperm then
                    local bytes = #_file
                    local res = string.sub(_file, 1, bytes)
                    return res
                else
                    ferror('tmpfs: cant read file')
                end
            end,
        }
    else
        --create file
        files[path] = {file='', perm=0}
        if mode == 'r' then
            ferror("tmpfs: file does not exist")
        elseif mode == 'w' then
            --create a file
        elseif mode == 'a' then
            --actualization
        end
    end
end

function open(path, mode)
    return makeObject(path, mode)
end

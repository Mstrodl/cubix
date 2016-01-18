--Temporary File System

paths = {}

--[[
files(table of tables):
each table:
    KEY = filename - filename

    type - ("dir", "file")
    perm - permission (string)
    file - actual file (string)
]]

--using tmpfs(making a device first):
--mount /dev/loop2 /mnt/tmpfs tmpfs

function list_files(mountpath)
    --show one level of things
    local result = {}
    for k,v in pairs(paths[mountpath]) do
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

function really_list_files(mountpath)
    local result = {}
    for k,v in pairs(paths[mountpath]) do
        table.insert(result, k)
    end
    return result
end

function canMount(uid)
    return true
end

function getSize(mountpath, path) return 0 end

function loadFS(mountpath)
    print("tmpfs: loading at "..mountpath)
    if not paths[mountpath] then
        paths[mountpath] = {}
    end
    return {}, true
end

function list(mountpath, path)
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

function test()
    local k = fs.open("/root/mytmp/helpme", 'w')
    k.writeLine("help me i think i am lost")
    k.close()
    os.viewTable(fs.list("/root/mytmp"))
end

function exists(mountpath, path)
    --print("exists: "..path)
    if path == nil or path == '' then
        if paths[mountpath] then
            return true
        else
            return false
        end
    end
    --os.viewTable(paths[mountpath][path])
    return paths[mountpath][path] ~= nil
end

function isDir(mountpath, path)
    --os.viewTable(paths[mountpath][path])
    if path == nil or path == '' then
        if paths[mountpath] then
            return true
        else
            return false
        end
    end
    if paths[mountpath][path] == nil then
        ferror("tmpfs: path does not exist")
        return false
    end
    return paths[mountpath][path].type == 'dir'
end

function makeDir(mountpath, path)
    if not paths[mountpath][path] then
        paths[mountpath][path] = {
            type='dir',
            perm=permission.fileCurPerm(),
            owner=os.currentUID(),
        }
    end
end

function getInfo(mountpath, path)
    local data = paths[mountpath][path]
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

function general_file(mountpath, path, mode)
    local new_perm = 0
    if not paths[mountpath][path] then
        new_perm = fsmanager.fileCurPerm()
    else
        new_perm = paths[mountpath][path].perm
    end
    return {
        _perm = new_perm,
        --_mode = mode,
        _cursor = 1,
        _closed = false,
        write = function(data)
            if vPerm(mountpath, path, 'w') and mode == 'a' then --append
                paths[mountpath][path].file = paths[mountpath][path].file .. data
                return data
            elseif vPerm(mountpath, path, 'w') and mode == 'w' then --write from start
                paths[mountpath][path].file = paths[mountpath][path].file .. data
                return data
            else
                ferror("tmpfs: cant write to file")
            end
        end,
        writeLine = function(data)
            if vPerm(mountpath, path, 'w') and mode == 'a' then --append
                paths[mountpath][path].file = paths[mountpath][path].file .. data .. '\n'
                return data
            elseif vPerm(mountpath, path, 'w') and mode == 'w' then --write from start
                paths[mountpath][path].file = paths[mountpath][path].file .. data .. '\n'
                return data
            else
                ferror("tmpfs: cant writeLine to file")
            end
        end,
        read = function(bytes)
            if vPerm(mountpath, path, 'r') and mode == 'r' then
                local res = string.sub(paths[mountpath][path].file, _cursor, _cursor + bytes)
                _cursor = _cursor + bytes
                return res
            else
                ferror("tmpfs: cant read file")
            end
        end,
        readAll = function()
            if vPerm(mountpath, path, 'r') then
                local bytes = #paths[mountpath][path].file
                local res = string.sub(paths[mountpath][path].file, 1, bytes)
                return res
            else
                ferror('tmpfs: cant read file')
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

function makeObject(mountpath, path, mode)
    if paths[mountpath][path] ~= nil then --file already exists
        if mode == 'w' then paths[mountpath][path].file = '' end
        return general_file(mountpath, path, mode)
    else
        --create file
        paths[mountpath][path] = {
            type='file',
            file='',
            perm=permission.fileCurPerm(),
            owner=os.currentUID()
        }
        if mode == 'r' then
            ferror("tmpfs: file does not exist")
            return nil
        elseif mode == 'w' then
            --create a file
            return general_file(mountpath, path, mode)
        elseif mode == 'a' then
            return general_file(mountpath, path, mode)
        end
    end
end

function open(mountpath, path, mode)
    return makeObject(mountpath, path, mode)
end

function delete(mountpoint, path)
    if vPerm(mountpath, path, 'w') then
        --remove file from paths
        paths[mountpath][path] = nil
        return true
    else
        ferror("tmpfs: not enough permission.")
        return false
    end
end

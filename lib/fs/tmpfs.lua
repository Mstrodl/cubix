--Temporary File System

paths = {}

--[[
files(table of tables):
each table:
    KEY = filename - filename

    type - ("dir", "file")
    perm - permission
    file - actual file
]]

--using tmpfs(making a device first):
--mkvdisk /dev/tmpdev
--mkfs.tmpfs /dev/tmpdev
--mount /dev/tmpdev /mnt/temporaryfs tmpfs

function list_files(mountpath)
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
    print("tmpfs: "..mountpath)
    if not paths[mountpath] then
        paths[mountpath] = {}
    end
    return {}, true
end

function list(mountpath, path)
    if path == '/' or path == '' or path == nil then
        return list_files(mountpath)
    else
        local all = list_files(mountpath)
        local res = {}
        for k,v in ipairs(all) do
            if string.sub(v, 1, #path) == path then
                table.insert(res, string.sub(v, #path))
            end
        end
        return res
    end
end

function exists(mountpath, path)
    return paths[mountpath][path] ~= nil
end

function isDir(mountpath, path)
    return paths[path].type == 'dir'
end

function makeDir(mountpath, path)
    if not paths[mountpath][path] then
        print("new folder")
        paths[mountpath][path] = {
            type='dir',
            perm=777
        }
    end
end

function makeObject(mountpath, path, mode)
    if paths[mountpath][path] then --file already exists
        if mode == 'w' then paths[mountpath][path].file = '' end
        return {
            _file = paths[mountpath][path].file,
            _perm = paths[mountpath][path].perm,
            _mode = mode,
            _cursor = 1,
            write = function(data)
                if _perm.writeperm and _mode == 'a' then --append
                    _file = _file .. data
                    return data
                elseif _perm.writeperm and _mode == 'w' then --write from start
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

function open(mountpath, path, mode)
    print("tmpfs: new file!")
    return makeObject(mountpath, path, mode)
end

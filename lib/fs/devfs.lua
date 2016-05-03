-- devfs: device file system

local device_nodes = {}

function loadFS(mountpath)
    os.debug.debug_write("devfs: loading at "..mountpath)
    if not device_nodes[mountpath] then
        device_nodes[mountpath] = {}
    end
    return {}, true
end

function canMount(uid)
    return uid == 0
end

function exists(mountpath, pth)
    if device_nodes[pth] then
        return true
    else
        return false
    end
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

function make_object(pth, mode)
    local node = device_nodes[pth]
    if not node then
        return ferror("devfs: node doesn't exist")
    end

    return {
        _perm = new_perm,
        _cursor = 1,
        _closed = false,
        write = function(data)
            if vPerm(mountpath, path, 'w') and mode == 'a' then --append
                -- device_nodes[mountpath][path].file = device_nodes[mountpath][path].file .. data
                dev_write(node['path'], data)
                return data
            elseif vPerm(mountpath, path, 'w') and mode == 'w' then --write from start
                -- device_nodes[mountpath][path].file = device_nodes[mountpath][path].file .. data
                dev_write(node['path'], data)
                return data
            else
                ferror("devfs: can't write to node")
            end
        end,
        writeLine = function(data)
            if vPerm(mountpath, path, 'w') and mode == 'a' then --append
                -- device_nodes[mountpath][path].file = device_nodes[mountpath][path].file .. data .. '\n'
                dev_write(node['path'], data .. '\n')
                return data
            elseif vPerm(mountpath, path, 'w') and mode == 'w' then --write from start
                -- device_nodes[mountpath][path].file = device_nodes[mountpath][path].file .. data .. '\n'
                dev_write(node['path'], data .. '\n')
                return data
            else
                ferror("devfs: can't writeLine to node")
            end
        end,
        read = function(bytes)
            if vPerm(mountpath, path, 'r') and mode == 'r' then
                -- local res = string.sub(device_nodes[mountpath][path].file, _cursor, _cursor + bytes)
                local res = dev_read(node['path'], bytes)
                _cursor = _cursor + bytes
                return res
            else
                ferror("devfs: can't read file")
            end
        end,
        readAll = function()
            if vPerm(mountpath, path, 'r') then
                local bytes = #device_nodes[mountpath][path].file
                local res = string.sub(device_nodes[mountpath][path].file, 1, bytes)
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

function general_file(mountpath, path, mode)
    if device_nodes[mountpath][path] ~= nil then --file already exists
        if mode == 'w' then device_nodes[mountpath][path].file = '' end
        return general_file(mountpath, path, mode)
    else
        --create file
        device_nodes[mountpath][path] = {
            type='file',
            file='',
            perm=permission.fileCurPerm(),
            owner=os.currentUID()
        }
        if mode == 'r' then
            ferror("devfs: file does not exist")
            return nil
        elseif mode == 'w' then
            --create a file
            return general_file(mountpath, path, mode)
        elseif mode == 'a' then
            return general_file(mountpath, path, mode)
        end
    end
end

function open(mountpath, pth, mode)
    return general_file(mountpath, pth, mode)
end

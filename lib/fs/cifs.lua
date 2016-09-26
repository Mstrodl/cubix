--[[
    cifs.lua - Cubix Integration File System driver
        Adds funcionality to create and manage cifs devices

    cifs is a file systam using oldfs to manage files, so it doesn't have many
    of the features I want it to have: permissions, timestamps, etc

    cifs serves as the basic implementation of a file system driver Cubix's VFS
]]

local mounts = {}

-- file system manager
CiFS = class(function(self, oldfs)
    syslog.serlog(syslog.S_INFO, "cifs", "init")
    self.name = ''
    self.oldfs = oldfs
end)

--(receives device name)
function CiFS:mount(source, target)
    self.name = fs_readall("/.cbxname", self.oldfs) or "cifs.generic"
    mounts[source] = self
    return true
end

function CiFS:umount(source)
    mounts[source] = nil
    return true
end

function CiFS:make(source, options)
    if options['name'] then
        fs_writeall(source.."/.cbxname", options['name'], nil, self.oldfs)
    end
    return true
end

function CiFS:list(mountsource, path)
    return self.oldfs.list(path, mode)
end

function CiFS:exists(mountsource, path)
    return self.oldfs.exists(path, mode)
end

function CiFS:isDir(mountsource, path)
    return self.oldfs.isDir(path, mode)
end

function CiFS:isReadOnly(mountsource, path)
    return self.oldfs.isReadOnly(path, mode)
end

function CiFS:getSize(mountsource, path)
    return self.oldfs.getSize(path, mode)
end

function CiFS:makeDir(mountsource, path)
    return self.oldfs.makeDir(path, mode)
end

function CiFS:delete(mountsource, path)
    return self.oldfs.delete(path)
end

function CiFS:open(mountsource, path, mode)
    return self.oldfs.open(path, mode)
end

function user_mount(uid)
    return uid == 0
end

--[[
    cifs.lua - Cubix Integration File System
        Adds funcionality to create and manage cifs devices

    cifs is a file systam using oldfs to manage files, so it doesn't have many
    of the features I want it to have: permissions, timestamps, etc

    cifs serves as the basic implementation of a file system driver to the VFS
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

function CiFS:list(mountsource, target, path)
    return self.oldfs.list(path)
end

function CiFS:exists(mountsource, target, path)
    return self.oldfs.exists(path)
end

function CiFS:isDir(mountsource, target, path)
    return self.oldfs.isDir(path)
end

function CiFS:isReadOnly(mountsource, target, path)
    return self.oldfs.isReadOnly(path)
end

function CiFS:getSize(mountsource, target, path)
    return self.oldfs.getSize(path)
end

function CiFS:makeDir(mountsource, target, path)
    return self.oldfs.makeDir(path)
end

function CiFS:delete(mountsource, target, path)
    return self.oldfs.delete(path)
end

function CiFS:open(mountsource, target, path, mode)
    return self.oldfs.open(path, mode)
end

function user_mount(uid)
    return uid == 0
end

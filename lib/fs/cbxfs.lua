--[[
    cbxfs.lua - Cubix File System driver
        Adds funcionality to create and manage cbxfs devices

    cbxfs is a file systam using oldfs to manage files, so it doesn't have many
    of the features I want it to have: permissions, timestamps, etc

    cbxfs serves as the basic implementation of a file system driver to the VFS
]]

local mounts = {}

-- file system manager
CubixFS = class(function(self, oldfs)
    self.name = ''
    self.oldfs = oldfs
end)

--(receives device name)
function CubixFS:mount(dev)
    self.name = fs_readall("/.cbxname", self.oldfs) or "cbxfs.generic"
    mounts[dev] = self
    return true
end

function CubixFS:umount(dev)
    mounts[dev] = nil
    return true
end

function CubixFS:make(dev, options)
    if options['name'] then
        fs_writeall(dev.."/.cbxname", options['name'], nil, self.oldfs)
    end
    return true
end

function CubixFS:list(mountsource, path)
    return self.oldfs.list(path, mode)
end

function CubixFS:exists(mountsource, path)
    return self.oldfs.exists(path, mode)
end

function CubixFS:isDir(mountsource, path)
    return self.oldfs.isDir(path, mode)
end

function CubixFS:isReadOnly(mountsource, path)
    return self.oldfs.isReadOnly(path, mode)
end

function CubixFS:getSize(mountsource, path)
    return self.oldfs.getSize(path, mode)
end

function CubixFS:makeDir(mountsource, path)
    return self.oldfs.makeDir(path, mode)
end

function CubixFS:delete(mountsource, path)
    return self.oldfs.delete(path)
end

function CubixFS:open(mountsource, path, mode)
    return self.oldfs.open(path, mode)
end

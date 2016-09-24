--[[
    cbxfs.lua - Cubix File System driver
        Adds funcionality to create and manage cbxfs devices

    cbxfs is a file systam using oldfs to manage files, so it doesn't have many
    of the features I want it to have: permissions, timestamps, etc

    cbxfs serves as the basic implementation of a file system driver to the VFS
]]

local mounts = {}

-- file system manager
CubixFS = class(function(self)
    self.name = ''
end)

--(receives device name)
function CubixFS:mount(dev)
    self.name = fs_readall("/.cbxname") or "cbxfs.generic"
    mounts[dev] = self
    return true
end

function CubixFS:make(dev, options)
    if options['name'] then
        fs_writeall(dev.."/.cbxname", options['name'])
    end
end

function CubixFS:umount(dev)
    mounts[dev] = nil
    return true
end

--TODO: read, write, seek, etc

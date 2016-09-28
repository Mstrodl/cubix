--[[
    cbxfs.lua - Cubix File System

    cbxfs implementes inode support, so it has permissions
]]

local nodes = {}

CubixFS = class(function(self, oldfs)
    self.oldfs = oldfs
end)

function CubixFS:mount(source, target)
    -- load CFSDATA
    local cfsdata = fs_readall(fs.combine(source, 'CFSDATA'))
    mounts[source] = {}

    for k,line in ipairs(string.split(cfsdata)) do
        local inode_spl = string.split(line, ':')
        local inode = self.oldfs.inode(
            {path = spl[1], perm = spl[2], owner = spl[3], gid = spl[4]}
        )

        mounts[source][inode.path] = inode
        print(splitted)
    end

    return true
end

function CubixFS:sync(source, target)
    local to_write
    for k,v in pairs(mounts[source]) do
        to_write = to_write ..
    end
    return fs_writeall(fs.combine(source, 'CFSDATA'), to_write)
end

function CubixFS:umount(source, target)
    mounts[source] = nil
    return true
end

function CubixFS:open(source, target, path, mode)
    if self.oldfs.inodes.verify_permission(inode, mode) then
        return oldfs.open(inode.path, mode)
    end
end

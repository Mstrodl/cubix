--ext2.lua, implementation of EXT2 FS in Cubix

inode = class(function(self, data)
    local d = strsplit(data, ':')
    self.data = d
    self.name = d[1]
    self.perm = d[2]
    self.owner = d[3]
end)

function loadFS(mountpath, dev)
end

function saveFS(mountpath, dev)
end

function open(mountpath, path)
end

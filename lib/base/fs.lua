--[[
    fs.lua - manage filesystems
        mounting, etc.
]]

RELOADABLE = false

-- first of all, get the CC fs
local oldfs = deepcopy(fs)

-- initialize inode table
local inodes = {}

-- implement inodes
oldfs.inode = class(function(self, init_inode)
    self.name = ''
    self.data = ''
    self.owner = 0
    self.group = 0
    self.perm = '755'

    if init_inode then
        self.path = init_inode.path
        self.perm = init_inode.perm
        self.owner = init_inode.uid
        self.group = init_inode.gid
    end
end)

local fs_drivers = {}

-- Load filesystem drivers
local function load_filesystem(fsname, fs_class, driver_path)
    syslog.serlog(syslog.S_INFO, 'fs', 'load_fs: '..fsname)
    fs_drivers[fsname] = {
        ["classname"] = fs_class,
        ["driver"] = lib.get(driver_path)
    }
end

local function load_all_filesystems()
    load_filesystem("cifs", 'CiFS', '/lib/fs/cifs.lua')
    load_filesystem("cbxfs", 'CubixFS', '/lib/fs/cbxfs.lua')
    load_filesystem("tmpfs", 'TmpFS', '/lib/fs/tmpfs.lua')
end

-- Helpers for permissions
function perm_to_arr(perm_num)
    local tmp = tostring(perm_num)
    local arr = {}
    for i = 1, 3 do
        local n = tonumber(string.sub(tmp, i, i))
        if n == 0 then arr[i] = "---" end
        if n == 1 then arr[i] = "--x" end
        if n == 2 then arr[i] = "-w-" end
        if n == 3 then arr[i] = "-wx" end
        if n == 4 then arr[i] = "r--" end
        if n == 5 then arr[i] = "r-x" end
        if n == 6 then arr[i] = "rw-" end
        if n == 7 then arr[i] = "rwx" end
    end
    return arr
end

function perm_to_str(perm_num)
    local k = perm_to_arr(perm_num)
    return printf("%s%s%s", unpack(k, 1))
end

local inodes = {}

inodes.get_inode = function(inode_path)
    if inode_path == '/' then
        return oldfs.inode({
            path = '/',
            perm = '755',
            uid = 0,
            gid = 0
        })
    end

    inode = inodes[inode_path]
    if inode then
        return deepcopy(inode)
    end

    return oldfs.inode({
        perm = '755', uid = lib.pm.currentuid(), gid = 0
    })
end

inodes.verify_perm = function(inode, perm)
    return true -- TODO
end

inodes.set_inode = function(old_inode, new_inode)
    if old_inode.path == '/' then
        inodes['/'] = {path = '/', owner = 0, perms = '755', gid = 0}
        return true
    end

    if old_inode.path ~= new_inode.path then
        return ferror("inodes.set_inode: Different inodes being modified")
    end

    if not inodes[old_inode.path] then
        --create inode
        if inodes.verify_perm(old_inode, 'w') then
            inodes[old_inode.path] = deepcopy(inodes.get_inode(old_inode.path))
        else
            ferror("inodes.set_inode [verify_perm]: Access Denied")
            return false
        end
    end

    if inodes[old_inode.path] == owner then
        --for k,v in pairs(new_inode) do
        --    old_inode[k] = v
        --end

        inodes[new_inode.path] = new_inode
        return true
    else
        ferror("inodes.set_inode [owner]: Access Denied")
        return false
    end
end

oldfs.inodes = inodes

local fs_mounts = {}

function mount(source, target, fstype, mountflags, data)
    -- check if filesystem driver exist
    if not fs_drivers[fstype] then
        return ferror(rprintf("mount: %s: %s not loaded",
            source, fstype))
    end

    if not fs_drivers[fstype]['driver'].user_mount(lib.pm.currentuid()) then
        return ferror("mount: current user can't mount "..filesystem)
    end

    if fs_mounts[target] then
        return ferror("mount: already mounted")
    end

    if not fs.exists(target) then
        return ferror("mount: target "..target.." doesn't exist")
    end

    if not fs.isDir(target) then
        return ferror("mount: target is not a folder")
    end

    syslog.serlog(syslog.S_INFO, "mount", rprintf(
        "mounting %s(%s) at %s",
        source, fstype, target))

    -- load FS for that mounting
    local fs_obj = fs_drivers[fstype]
    local fs_constructor = fs_obj['driver'][fs_obj['classname']]

    local fs_object = fs_constructor(oldfs)
    fs_mounts[target] = {
        ["fs"] = fstype,
        ["source"] = source,
        ["obj"] = fs_object
    }
    r = fs_object:mount(source, target)
    if r then
        syslog.serlog(syslog.S_OK, "mount", rprintf("mounted %s to %s(%s)",
            source, target, fstype))
        return true
    end

    -- damn.
    fs_mounts[target] = nil
    return ferror("mount: unable to mount")
end

local function umount_source(source)
    syslog.serlog(syslog.S_INFO, "umount_source", "umounting %s", source)
    for k,v in pairs(fs_mounts) do
        if v['source'] == source then
            local ok, err = v['obj']:umount(source, k)
            if ok then
                fs_mounts[target] = nil
                return true
            end

            return false, err
        end
    end
    return false
end

local function umount_target(target)
    syslog.serlog(syslog.S_INFO, "umount_target", "umounting %s", target)
    local mountobj = fs_mounts[target]
    if mountobj then
        local ok, err = mountobj['obj']:umount(mountobj['source'], target)
        if ok then
            fs_mounts[target] = nil
            return true
        end

        return false, err
    end
    return false
end

function umount(source, target)
    if not source then
        return umount_target(target)
    end
    return umount_source(source)
end

--TODO: implementation of VFS, the virtual file system

fs.combine = function(a, b)
    if string.sub(b, 1, 1) == '/' and a == '/' then
        return b
    end
    return a..b
end

local function fs_abs_wrap_1a(method)
    local fs_abs_any = function(path)
        if string.sub(path, 1, 1) ~= '/' then
            return false
        end

        local source, target = '', ''

        for k,v in pairs(fs_mounts) do
            if string.sub(path, 1, #k) == k and k ~= '/' then
                source = v['source']
                target = k

                tpath = string.sub(path, #k + 1)
                obj = fs_mounts[target]['obj']
                return obj[method](obj, source, target, tpath, mode)
            end
        end

        if fs_drivers['cifs'] then
            local obj = fs_mounts['/']['obj']
            return obj[method](obj, '/', target, path, mode)
        else
            print('[vfs.'..method..'] using oldfs')
            return oldfs[method](path, mode)
        end

        return ferror("vfs."..method..": no fs detected")
    end

    return fs_abs_any
end

local function fs_rev_wrap_1a(abs_func)
    local fs_rev_any = function(path)
        return abs_func(fs.combine(lib.pm.getenv("__CWD"), path))
    end
    return fs_rev_any
end

local function fs_abs_open(path, mode)
    -- analyze path
    if string.sub(path, 1, 1) ~= '/' then
        return false
    end

    local source, target = '', ''

    for k,v in pairs(fs_mounts) do
        if string.sub(path, 1, #k) == k and k ~= '/' then
            source = v['source']
            target = k

            tpath = string.sub(path, #k + 1)
            return fs_mounts[target]['obj']:open(source, target, tpath, mode)
        end
    end

    if fs_drivers['cifs'] then
        return fs_mounts['/']['obj']:open('/', target, path, mode)
    else
        print('[vfs.open] using oldfs')
        return oldfs.open(path, mode)
    end

    return ferror("fs_abs_open: error opening(no fs detected)")
end

local function fs_rev_open(path, mode)
    local combined = fs.combine(lib.pm.getenv("__CWD"), path)
    return fs_abs_open(combined, mode)
end

local fs_abs_list = fs_abs_wrap_1a('list')
local fs_rev_list = fs_rev_wrap_1a(fs_abs_list)

local fs_abs_getsize = fs_abs_wrap_1a('getSize')
local fs_rev_getsize = fs_rev_wrap_1a(fs_abs_getsize)

local fs_abs_exists = fs_abs_wrap_1a('exists')
local fs_rev_exists = fs_rev_wrap_1a(fs_abs_exists)

local fs_abs_delete = fs_abs_wrap_1a('delete')
local fs_rev_delete = fs_rev_wrap_1a(fs_abs_delete)

local fs_abs_makedir = fs_abs_wrap_1a('makeDir')
local fs_rev_makedir = fs_rev_wrap_1a(fs_abs_makedir)

local fs_abs_isdir = fs_abs_wrap_1a('isDir')
local fs_rev_isdir = fs_rev_wrap_1a(fs_abs_isdir)


-- Helper functions(doesn't depend on any FS sorcery)
function fs_readall(fpath, external_fs)
    external_fs = external_fs or fs
    local h = external_fs.open(fpath, 'r')
    if h == nil then return nil end
    local data = h:readAll()
    h:close()
    return data
end

function fs_writedata(fpath, data, flag, external_fs)
    flag = flag or false
    external_fs = external_fs or fs
    local h = nil
    if flag then
        h = external_fs.open(fpath, 'a')
    else
        h = external_fs.open(fpath, 'w')
    end
    if h == nil then return nil end
    local data = h:readAll()
    h:close()
    return data
end

-- add /etc/fstab management
local function run_fstab(fstab_path)
    syslog.serlog(syslog.S_INFO, 'fstab', 'running at '..fstab_path)

    local fstab_data = fs_readall(fstab_path)
    if not fstab_data then
        syslog.panic("error opening fstab")
    end

    local lines = string.splitlines(fstab_data)
    for _,v in ipairs(lines) do
        local spl = string.split(v, ';')

        local source, target, fs = spl[1], spl[2], spl[3]
        mount(source, target, fs)
    end
end

function libroutine()
    _G['fs_readall'] = fs_readall
    _G['fs_writedata'] = fs_writedata

    load_all_filesystems()

    -- mount /proc, /dev and /dev/shm
    mount('procfs', '/proc', 'procfs')
    mount('udevfs', '/dev', 'devfs')
    mount("tmpfs", "/dev/shm", 'tmpfs')

    -- mount devices in /etc/fstab
    run_fstab("/etc/fstab")

    if umount(nil, '/dev/shm') then
        mount("tmpfs", "/dev/shm", 'tmpfs')
    else
        print("[umount_test] error umounting")
    end

    -- TODO: add enviroment variables so fs_rev_open works
    fs.open = fs_rev_open
    fs.list = fs_rev_list
    fs.delete = fs_rev_delete
    fs.makeDir = fs_rev_makedir

    fs.getSize = fs_rev_getsize
    fs.exists = fs_rev_exists
    fs.isDir = fs_rev_isDir
end

--[[
    fs.lua - manage filesystems
        mounting, etc.
]]

RELOADABLE = false

-- first of all, get the CC fs
local oldfs = deepcopy(fs)

local fs_drivers = {}

-- Load filesystem drivers
local function load_filesystem(fsname, fs_class, driver_path)
    syslog.serlog(syslog.S_INFO, 'fs', 'load_fs: '..fsname)
    fs_drivers[fsname] = {
        ["classname"] = fs_class,
        ["driver"] = cubix.load_file(driver_path)
    }
end

local function load_all_filesystems()
    load_filesystem("cbxfs", 'CubixFS', '/lib/fs/cbxfs.lua')
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

local fs_mounts = {}

function mount(source, target, fstype, mountflags, data)
    -- check if filesystem driver exist
    if not fs_drivers[fstype] then
        return ferror("mount: "..source..": filesystem not loaded")
    end

    if not fs_drivers[fstype]['driver'].user_mount(lib.pm.currentuid()) then
        return ferror("mount: current user can't mount "..filesystem)
    end

    if fs_mounts[target] then
        return ferror("mount: already mounted")
    end

    if not oldfs.exists(target) then
        return ferror("mount: target "..path.." doesn't exist")
    end

    if not oldfs.isDir(target) then
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
        return true
    end

    -- damn.
    fs_mounts[target] = nil
    return ferror("mount: unable to mount")
end

--TODO: implementation of VFS, the virtual file system

local function fs_abs_open(path, mode)
    -- analyze path
    if string.sub(path, 1, 1) ~= '/' then
        return false
    end

    for k,v in pairs(fs_mounts) do
        if string.sub(path, 1, #k) == k then
            local source, target = k, string.sub(path, #k + 1)
            return fs_mounts[source]['obj']:open(source, target, mode)
        end
    end

    return ferror("fs_abs_open: error opening(no fs detected)")
end

local function fs_rev_open(path, mode)
    return fs_abs_open(fs.combine(os.getenv("CPTH"), path), mode)
end

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
    --[[/dev/hda;/;cfs;;
    /dev/loop1;/dev/shm;tmpfs;;]]
    syslog.serlog(syslog.S_INFO, 'fstab', 'running '..fstab_path)
    local h = fs.open("/etc/fstab", 'r')
    local fstab_data = fs_readall(fstab_path)
    if not h then
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
    load_all_filesystems()
    _G['fs_readall'] = fs_readall
    _G['fs_writedata'] = fs_writedata
    run_fstab("/etc/fstab")

    -- TODO: add enviroment variables so fs_rev_open works
    fs.open = fs_abs_open
end

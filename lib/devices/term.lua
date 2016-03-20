#!/usr/bin/env lua
--term device

local devname = ''
local devpath = ''

function device_read(bytes)
    ferror("term: cannot read from term deivces")
    os.sys_signal(os.signals.SIGILL)
    return 1
end

function device_write(data)
    write(data)
end

function setup(name, path)
    devname = name
    devpath = path
    fs.open(path, 'w').close()
end

function libroutine()end

#!/usr/bin/env lua
--keyboard device

local devname = ''
local devpath = ''

function mread(x)
    count = 0
    txt = ""
    repeat
        id,chr = os.pullEvent()
        if id == "char" then
            term.write(chr)
            txt = txt..chr
            count = count + 1
        end

        if id == "key" and chr == 28 then
            return txt
        end
    until count == x
    write('\n')
    return txt
end

function device_read(bytes)
    return mread(bytes)
end

function device_write(data)
end

function setup(name, path)
    devname = name
    devpath = path
    fs.open(path, 'w').close()
end

function libroutine()end

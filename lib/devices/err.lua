
local devname = ''
local devpath = ''

function device_read(bytes)
    ferror("err: cannot read from err devices")
    os.sys_signal(os.signals.SIGILL)
    return 1
end

function device_write(message)
    term.set_term_color(colors.red)
    write(message)
    term.set_term_color(colors.white)
end

function setup(name, path)
    devname = name
    devpath = path
    fs.open(path, 'w').close()
end

function libroutine()end

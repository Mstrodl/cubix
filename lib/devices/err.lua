
local devname = ''
local devpath = ''
local device_buffer = ''

function device_read(bytes)
    ferror("err: cannot read from err devices")
    os.sys_signal(os.signals.SIGILL)
    return 1
end

function device_write(message)
    term.set_term_color(colors.red)
    device_buffer = device_buffer .. message
    write(message)
    device_buffer = ''
    term.set_term_color(colors.white)
end

function flush_buffer()
    write(device_buffer)
    device_buffer = ''
end

function get_buffer()
    return device_buffer
end

function setup(name, path)
    devname = name
    devpath = path
    device_buffer = ''
    fs.open(path, 'w').close()
end

function libroutine()end

--/lib/luaX/lxServer.lua
--luaX "makes forms" part

if not _G['LX_LUA_LOADED'] then
    os.ferror("lxServer: lx.lua not loaded")
    return 0
end

--term.redirect(term.native())

function write_vline(lX, lY, c, colorLine)
    term.setBackgroundColor(colorLine)
    term.setCursorPos(lX, lY)
    local tmpY = lY
    for i=0,c do
        os.lib.lx.write_pixel(c, tmpY, colorLine)
        tmpY = tmpY + 1
    end
    term.set_bg_default()
end

function write_hline(lX, lY, c, colorLine)
    term.setBackgroundColor(colorLine)
    term.setCursorPos(lX, lY)
    local tmpX = lX
    for i=0,c do
        os.lib.lx.write_pixel(tmpX, c, colorLine)
        tmpX = tmpX + 1
    end
    term.set_bg_default()
end

function write_rectangle(locX, locY, lenX, lenY, colorR)
    term.setBackgroundColor(colorR)
    term.setCursorPos(locX, locY)

    --black magic goes here
    for i=0, lenY do
        os.lib.lx.write_pixel(locX, locY+i, colorR)
    end

    for i=0, lenY do
        os.lib.lx.write_pixel(locX+lenX+1, locY+i, colorR)
    end

    for i=0, lenX do
        os.lib.lx.write_pixel(locY+i, locY, colorR)
    end

    for i=0, (lenX+1) do
        os.lib.lx.write_pixel((locY)+i, locY+lenY+1, colorR)
    end

    term.set_bg_default()
end

function write_square(lX, lY, l, colorR)
    return write_rectangle(lX, lY, l, l, colorR)
end

function write_solidRect(locX, locY, lenX, lenY, colorSR)
    write_rectangle(locX, locY, lenX, lenY, colorSR)
    for x = locX, (locX+lenX) do
        for y = locY, (locY+lenY) do
            os.lib.lx.write_pixel(x, y, colorSR)
        end
    end
    term.set_bg_default()
end

function lxError(lx_type, emsg)
    local message = lx_type..': '..emsg..'\n'
    local lxerrh = fs.open("/tmp/lxlog", 'a')
    lxerrh.write(message)
    lxerrh.close()
    if dev_available("/dev/stderr") then
        dev_write("/dev/stderr", message)
    else
        os.ferror(message)
    end
end

function demo_printMark()
    os.lib.lx.write_letter('l', 1, 1, colors.lightBlue, colors.blue)
    os.lib.lx.write_letter('x', 2, 1, colors.lightBlue, colors.blue)

    os.lib.lx.write_letter('S', 3, 1, colors.lightBlue, colors.blue)
    os.lib.lx.write_letter('e', 4, 1, colors.lightBlue, colors.blue)
    os.lib.lx.write_letter('r', 5, 1, colors.lightBlue, colors.blue)
    os.lib.lx.write_letter('v', 6, 1, colors.lightBlue, colors.blue)
    os.lib.lx.write_letter('e', 7, 1, colors.lightBlue, colors.blue)
    os.lib.lx.write_letter('r', 8, 1, colors.lightBlue, colors.blue)
end

function sv_demo()
    demo_printMark()

    write_vline(10, 10, 5, colors.green)
    os.sleep(1)

    write_hline(11, 11, 10, colors.yellow)
    os.sleep(1)

    os.lib.lx.blank()
    demo_printMark()

    write_rectangle(5, 5, 10, 5, colors.red)

    os.sleep(1)
    os.lib.lx.blank()
    demo_printMark()

    write_square(5, 5, 5, colors.red)

    os.sleep(1)
    os.lib.lx.blank()
    demo_printMark()

    for i=3,15 do
        write_square(i,i,6+i,os.lib.lx.random_color())
        sleep(.5)
    end

    sleep(3.5)

    os.lib.lx.blank()
    demo_printMark()

    os.debug.kpanic('lx kpanic test')
end

function libroutine()
    _G['LX_SERVER_LOADED'] = true
    _G['lxError'] = lxError
end

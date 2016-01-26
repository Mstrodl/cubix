--bootsplash module
bootsplash = {}

function bs_clear_screen()
    print("") --pog by jao
    term.clear()
    term.setCursorPos(1,1)
end

function textMode()
    while os.__boot_flag do
        term.clear()
        term.setCursorPos(19,9)
        write("C")
        if not os.__boot_flag then
            bs_clear_screen()
            return 0
        end
        sleep(.5)
        term.setCursorPos(20,9)
        write("u")
        if not os.__boot_flag then
            bs_clear_screen()
            return 0
        end
        sleep(.5)
        term.setCursorPos(21,9)
        write("b")
        if not os.__boot_flag then
            bs_clear_screen()
            return 0
        end
        sleep(.5)
        term.setCursorPos(22,9)
        write("i")
        if not os.__boot_flag then
            bs_clear_screen()
            return 0
        end
        sleep(.5)
        term.setCursorPos(23,9)
        write("x")
        if not os.__boot_flag then
            bs_clear_screen()
            return 0
        end
        sleep(.5)
    end
end

bootsplash.load_normal = function()
    print("loading load_normal...")
    local h = fs.open("/etc/bootsplash.default", 'r')
    if h == nil then
        os.debug.kpanic("bootsplash: error opening bootsplash.default")
    end
    local splash = h.readAll()
    h.close()
    if splash == 'text' then
        print("running text mode")
        parallel.waitForAll(textMode, cubix.boot_kernel)
    else
        os.debug.kpanic("bootsplash: invalid bootscreen")
    end
end
_G['bootsplash'] = bootsplash

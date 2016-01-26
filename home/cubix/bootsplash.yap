Name;bootsplash
Version;0.0.1
Build;2
Author;Lukas Mendes
Email-Author;lkmnds@gmail.com
Description;Boot Splash module for cubix
Dep;base
File;/lib/modules/bootsplash
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
EndFile;
File;/usr/bin/bootsplash
#!/usr/bin/env lua
--bootsplash
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        os.debug.debug_write("bootsplashd: SIGKILL'd!", false)
        return 0
    end
end
AUTHOR = "Lukas Mendes"
VERSION = '0.0.1'
function main(args)
    if args[1] == 'set-theme' then
        local theme = args[2]
        if theme == 'text' then
            local h = fs.open("/etc/bootsplash.default", 'w')
            h.write('text')
            h.close()
        elseif fs.exists("/usr/lib/bootsplash/"..theme..'.theme') then
            ferror("Still coming...")
        else
            ferror("theme not found")
            return 0
        end
    else
        print("usage: bootsplash <mode>")
    end
end
EndFile;

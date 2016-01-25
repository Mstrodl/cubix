Name;bootsplash
Version;0.0.1
Build;1
Author;Lukas Mendes
Email-Author;lkmnds@gmail.com
Description;Boot Splash module for cubix
Dep;base
File;/lib/modules/bootsplash
--bootsplash module for cubix initramfs
bootsplash = {}
bootsplash.load_normal = function()
    local h = fs.open("/etc/bootsplash.default", 'r')
    if h == nil then
        os.debug.kpanic("bootsplash: error opening bootsplash.default")
    end
    local splash = h.readAll()
    h.close()
    if splash == 'text' then
        term.clear()
        term.setCursorPos(6,6)
        print("Cubix - text animation bootscreen.")
    else
        os.debug.kpanic("bootsplash: invalid bootscreen")
    end
end
_G['bootsplash'] = bootsplash
EndFile;
File;/usr/bin/bootsplash
#!/usr/bin/env lua
--bootsplash
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
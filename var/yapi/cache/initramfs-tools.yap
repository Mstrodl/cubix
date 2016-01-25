Name;initramfs-tools
Version;0.0.1
Build;1
Author;Lukas Mendes
Email-Author;lkmnds@gmail.com
Description;tools to generate a initramfs for cubix
Dep;base
File;/usr/bin/generate-initramfs
#!/usr/bin/env lua
--generate-initramfs
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        os.debug.debug_write("yapi: SIGKILL'd!", false)
        return 0
    end
end
AUTHOR = "Lukas Mendes"
VERSION = '0.0.1'
function main(args)
    if not permission.grantAccess(fs.perms.SYS) then
        os.ferror("generate-initramfs: permission error")
        return 1
    end
    --/etc/initramfs.modules
    local h = fs.open("/etc/initramfs.modules", 'r')
    if h == nil then
        ferror("generate-initramfs: error opening initramfs.modules")
        return 0
    end
    local modules = h.readAll()
    h.close()
    print("generating initramfs in /boot/cubix-initramfs...")
    local initramfsfile = ''
    local mlines = os.strsplit(modules, '\n')
    for _,mod in ipairs(mlines) do
        if string.sub(mod, 1, 1) == '#' or mod == '' then
            --nothing
        else
            if mod == 'libcubix' then
                local h = fs.open("/boot/libcubix", 'r')
                if h == nil then
                    ferror("generate-initramfs: error opening libcubix file")
                    ferror("Aborted.")
                    return 0
                end
                local modfile = h.readAll()
                h.close()
                initramfsfile = initramfsfile..modfile..'\n\n'
            else
                if fs.exists("/lib/modules/"..mod) then
                    local h = fs.open("/lib/modules/"..mod, 'r')
                    if h == nil then
                        ferror("generate-initramfs: error opening module file")
                        ferror("Aborted.")
                        return 0
                    end
                    local modfile = h.readAll()
                    h.close()
                    initramfsfile = initramfsfile..modfile..'\n\n'
                else
                    ferror(mod..": module not found")
                    return 0
                end
            end
        end
    end
    local h = fs.open("/boot/cubix-initramfs", 'w')
    if h == nil then
        ferror("generate-initramfs: error opening cubix-initramfs")
        return 0
    end
    h.write(initramfsfile)
    h.close()
    print("generated cubix-initramfs with:.")
    for _,mod in ipairs(mlines) do
        if string.sub(mod, 1, 1) == '#' then
            --nothing
        else
            write(mod..' ')
        end
    end
    write('\n')
end
EndFile;
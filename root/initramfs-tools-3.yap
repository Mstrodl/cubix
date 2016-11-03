name=initramfs-tools
version=0.0.2
build=3
author=Lukas Mendes
email-author=lkmnds@gmail.com
description=Tools to generate initramfs for Cubix
url=http://github.com/lkmnds/cubix-initramfs-tools
license=MIT
file;/usr/bin/generate-initramfs
#!/usr/bin/env lua
--generate-initramfs: generate initramfs for cubix
AUTHOR = "Lukas Mendes"
VERSION = '0.0.2'
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
        if string.sub(mod, 1, 1) == '#' or mod == '' then else
            if mod == 'libcubix' then
                local h = fs.open("/boot/libcubix", 'r')
                if h == nil then
                    ferror("generate-initramfs: error opening libcubix")
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
                        ferror("generate-initramfs: error opening module "..mod)
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
        ferror("generate-initramfs: error opening cubix-initramfs for write")
        return 0
    end
    h.write(initramfsfile)
    h.close()
    print("generated cubix-initramfs with: ")
    for _,mod in ipairs(mlines) do
        if string.sub(mod, 1, 1) == '#' then else
            write(mod..' ')
        end
    end
    write('\n')
end
main({...})
END_FILE;
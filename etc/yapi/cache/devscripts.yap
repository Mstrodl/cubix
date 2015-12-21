#devscripts.yap

Name;devscripts
Version;0.0.2
Build;2

Author;Lukas Mendes
Email-Author;lkmnds@gmail.com

Contributors;
Email-Contri;

Description;Developer Scripts for Cubix

File;/usr/bin/testing
--/usr/bin/testing: test yapi
_handler = {}
_handler.signal_handler = function (sig)
    if sig == 'kill' then
        os.debug.debug_write("testing: SIGKILL'd!", false)
        return 0
    end
end

function main()
    print("Hello World!")
end
EndFile;
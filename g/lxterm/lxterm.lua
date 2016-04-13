--/g/lxterm/lxterm.lua
--the lxterm.lxw will load lxterm.lua, which will configure the window and register the events as expected

local windowl = ...

function main()
    if not os.lib.lxWindow then
        os.ferror("lxterm: lxWindow not loaded")
        return 0
    end
    local Main = windowl[1]

    Main:set_title("lxterm")
    local cbox1 = os.lib.lxWindow.CommandBox(10, 10, '/sbin/login')
    Main:add(cbox1, 0, 0)
    Main:set_handler(cbox1.event_handler)
    Main:set_parallel(cbox1.run_shell)
    Main:show()
end

main()

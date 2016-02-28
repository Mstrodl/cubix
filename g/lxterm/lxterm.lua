--/g/lxterm/lxterm.lua
--the lxterm.lxw will load lxterm.lua, which will configure the window and register the events as expected

local windowl = ...

function main()
    if not os.lib.lxWindow then
        os.ferror("lxterm: lxWindow not loaded")
        return 0
    end
    local Main = windowl[1]
    --local l1 = os.lib.lxWindow.Label('TestLabel', 0, 0)
    --Main:add(l1, 5, 5)
    --Main:set_handler(os.lib.lxWindow.nil_handler)
    --Main:show()

    Main:set_title("luaX Terminal")
    local cbox1 = os.lib.lxWindow.CommandBox(10, 10, '/sbin/login')
    Main:add(cbox1, 0, 0)
    Main:set_handler(cbox1.event_handler)
    --Main:show()

    while true do
        os.runfile_proc(cbox1.spath)
    end
end

main()

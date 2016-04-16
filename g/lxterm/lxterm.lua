--/g/lxterm/lxterm.lua
--the lxterm.lxw will load lxterm.lua, which will configure the window and register the events as expected

local windowl = ...

function main()
    if not os.lib.lxWindow then
        os.ferror("lxterm: lxWindow not loaded")
        return 0
    end
    --get the Main Window object
    local Main = windowl[1]

    --Set the title of the window
    Main:set_title("lxterm")

    --Add a CommandBox to the window
    local cbox1 = os.lib.lxWindow.CommandBox(5, 5, '/sbin/login')
    Main:add(cbox1, 0, 0)

    --Set an event handler for the window
    Main:set_handler(cbox1.event_handler)

    --Set a parallel function that will run alongside the window loop
    Main:set_parallel(cbox1.run_shell)

    --Finally, show the window(main event loop 'n' stuff)
    Main:show()

end

main()

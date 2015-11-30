--/g/lxterm/lxterm.lua
--the lxterm.lxw will load lxterm.lua, which will configure the window and register the events as expected

local windowl = ...

function main()
    local Main = windowl[1]
    local commandBox1 = os.lib.lxWindow.commandBox.new()
    commandBox1.stX = 0
    commandBox1.stY = 0
    commandBox1.pathToShell = '/sbin/login'
    os.runfile_proc(commandBox1.pathToShell)
    --Main.attach(commandBox1)
end

main()


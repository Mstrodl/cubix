--/g/lxterm/lxterm.lua
--the lxterm.lxw will load lxterm.lua, which will configure the window and register the events as expected

local windowl = ...

function main()
    if not os.lib.lxWindow then
        os.ferror("lxterm: lxWindow not loaded")
        return 0
    end
    local Main = windowl[1]
    local commandBox1 = os.lib.lxWindow.commandBox.new()
    commandBox1.stX = 0
    commandBox1.stY = 0
    commandBox1.pathToShell = '/sbin/login'
    os.runfile_proc(commandBox1.pathToShell)
end

--[[
function main()
    local mainWindow = windowl[1]
    local pBox1 = os.lib.lxWindow.programBox.new()
    pBox1.locationX = 0
    pBox1.locationY = 0
    pBox1.shell = '/sbin/login'
    mainWindow.attach(pBox1)
end
]]

main()

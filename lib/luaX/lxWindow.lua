--/lib/luaX/lxWindow.lua
--luaX window library

--function: create, delete, buttons, etc

if not _G['LX_CLIENT_LOADED'] then
    os.ferror("lxWindow: lxClient not loaded")
    return 0
end

local windows = {}

Window = {}
Window.__index = Window

function Window.new(path_lxw)
    local inst = {}
    setmetatable(inst, Window)
    inst.focus = false
    inst.actions = {}
    inst.lxwFile = path_lxw
    return inst
end

--[[

name:lxterm
hw:9,30
changeable:false
main:lxterm.lua

]]

function parse_lxw(path)
    local handler = fs.open(path, 'r')
    local _data = handler.readAll()
    handler.close()
    local lxwdata = {}
    local data = os.strsplit(_data, '\n')
    for k,v in pairs(data) do
        if string.sub(v, 1, 1) ~= '#' then --comments
            --comparisons here
            local splitted_line = os.strsplit(v, ':')
            if splitted_line[1] == 'name' then
                lxwdata['name'] = splitted_line[2]
            elseif splitted_line[1] == 'hw' then
                lxwdata['hw'] = os.strsplit(splitted_line[2], ',')
            elseif splitted_line[1] == 'changeable' then
                lxwdata['changeable'] = splitted_line[2]
            elseif splitted_line[1] == 'main' then
                lxwdata['mainfile'] = splitted_line[2]
            end
        end
    end
    return lxwdata
end

function main_run(file, window)
    --run a file with determined _ENV
    --it seems that i can not do this so i've put the window object into args
    os.run({}, file, {window})
end

function Window:load_itself()
    os.debug.debug_write("[lxWindow] load lxw: "..self.lxwFile, false)
    local lxwdata = parse_lxw(self.lxwFile)
    os.debug.debug_write("[lxWindow] load window: "..lxwdata['name'], false)
    main_run(lxwdata['mainfile'], self)
end

--[[

a lxWindow can have the following actions registered

focus
close
minimize
maximize
termination

]]

function Window:register_action(action, callback)
    self.actions[action] = callback
end

function Window:call_action(action)
    if self.actions[action] == nil then
        lxError("lxWindow", "action not registered in window actions table")
        return false
    elseif self.actions[action] ~= 'function' then
        lxError("lxWindow", "registered action is not a function")
        return false
    else
        self.actions[action]()
        return true
    end
end

commandBox = {}
commandBox.__index = commandBox

function commandBox.new()
    local inst = {}
    setmetatable(inst, Window)
    return inst
end

function libroutine()
end

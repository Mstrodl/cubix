--/lib/luaX/lxWindow.lua
--luaX window library

--function: create, delete, buttons, etc

if not _G['LX_CLIENT_LOADED'] then
    os.ferror("lxWindow: lxClient not loaded")
    return 0
end

local window_data = {}
local windows = {}

function unload_all()
    windows = {}
end

function get_window_location()
    return {5 + #windows, 5 + #windows}
end

Window = {}
Window.__index = Window

function Window.new(path_lxw)
    local inst = {}
    setmetatable(inst, Window)
    inst.title = 'luaX Window'
    inst.focus = false
    inst.actions = {}
    inst.coords = {}
    inst.elements = {}
    inst.lxwFile = path_lxw
    return inst
end

function Window:add(element, x, y)
    local i = #self.elements + 1
    self.coords[i] = {x,y}
    self.elements[i] = element
end

function Window:call_handler(ev)
    if self.handler == nil then
        os.lib.lxServer.lxError("lxWindow: no handler set")
        return 0
    end
    print("call self.handler "..type(ev))
    self.handler(ev)
end

function Window:set_handler(f)
    self.handler = f
end

function Window:set_title(newtitle)
    self.title = newtitle
end

function write_window(window_location, lenX, lenY, window_title)
    local locX = window_location[1]
    local locY = window_location[2]

    --basic window borders
    os.lib.lxServer.write_rectangle(locX-1, locY-1, lenY+2, lenX+2, colors.black)
    os.lib.lxServer.write_solidRect(locX, locY, lenY, lenX, colors.white)

    --window title
    os.lib.lx.write_string(window_title, locX+3, locY-1, colors.white, colors.black)
end

function Window:show()
    tx = self.lxwdata['hw'][1]
    ty = self.lxwdata['hw'][2]

    sx = get_window_location()[1]
    sy = get_window_location()[2]

    write_window(get_window_location(), tx, ty, self.title)

    for i=1,#self.elements do
        element = self.elements[i]
        coordinates = self.coords[i]
        --print("show " .. coordinates[1] ..';'.. coordinates[2])
        element:_show(sx, sy)
    end

    while true do
        local e, p1, p2, p3, p4, p5 = os.pullEvent()
        local event = {e, p1, p2, p3, p4, p5}
        print(type(event))
        self:call_handler(event)
    end
end

function nil_handler(event)
    return nil
end

--[[

name:lxterm
hw:9,30
changeable:false
main:lxterm.lua

]]

function parse_lxw(path)
    local handler = fs.open(path, 'r')
    if handler == nil then
        lxError("lxWindow", "File not found")
        return false
    end
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
    window_data[lxwdata['name']] = lxwdata
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
    if lxwdata == false then
        lxError("lxWindow", "cannot load window")
        return 1
    else
        os.debug.debug_write("[lxWindow] load window: "..lxwdata['name'], false)
        self.lxwdata = lxwdata
        main_run(lxwdata['mainfile'], self)
    end
end

Object = class(function(self, xpos, ypos, x1pos, y2pos)
    self.posX = xpos
    self.posY = ypos
    self.finX = x1pos
    self.finY = y2pos
end)

Label = class(Object, function(self, label, x1, y1)
    local lenlabel = #label
    Object.init(self, x1, y1, x1, y1+lenlabel)
    self.ltext = label
end)

function Label:_show(location_x, location_y)
    os.lib.lx.write_string(self.ltext,
    location_x,
    location_y,
    os.lib.lx.random_color(), os.lib.lx.random_color()
    )
end

EventObject = class(Object, function(self, x, y, x1, y1)
    Object.init(self, x, y, x1, y1)
end)

function EventObject:_addListener(listener_func)
    self['listener'] = listener_func
end

--TextField class
TextField = class(EventObject, function(self, x, y, tfX, tfY)
    EventObject.init(self, x, y, tfX, tfY)
end)

tf1 = TextField(0, 0)

--create CommandBox
CommandBox = class(TextField, function(self, x, y, shellPath)
    TextField.init(self, x, y, x+20, y+20)
    self.spath = shellPath
    self.cmdbuffer = ''

    local cbox_listener = {} --default event listener
    function cbox_listener:evPerformed(event)
        print(type(event))
        if event[1] == 'key' then
            if event[2] == 98 then
                self.send_command(self.cmdbuffer)
                output = self.get_data()
                self.append_text(output)
            end
        end
    end
    self.event_handler = cbox_listener['evPerformed']
    self:addEventListener(cbox_listener)
end)

function CommandBox:_show(locX, locY)
    wd = window_data['lxterm']
    os.lib.lxServer.write_solidRect(locX, locY, wd['hw'][2], wd['hw'][1], colors.blue)
end

function CommandBox:addEventListener(listener_obj)
    self:_addListener(listener_obj['evPerformed'])
end

function libroutine()
end


local LX_VERSION = '0.0.10'
local LXCHAR = ' '

local current_screen = {}
lx = {}

Screen = class(function(self, _term, x, y, width, height)
    self._term = _term
    self.term = window.create(_term, x, y, width, height)
    lx_screens[]
end)
lx.Screen = Screen

function Screen:write(str)
    self.term.write(str)
end

function Screen:pixel(x, y, color)

end

Window = class(Screen, function(self, host, x, y, width, height)
    if host == nil then
        host = current_screen
    end
    
    self.parent = host

    local k = #lx_windows[host.id]
    lx_windows[host.id][k] = self
end)

function current()
    return current_screen
end
lx.current = current

function current_window()
    return lx_cur_window
end
lx.current_win = current_window

function get_screens()
    return deepcopy(lx_screens)
end
lx.gscreens = get_screens

function libroutine()
    current_screen = Screen(term.current(), 0, 0, 59, 11)
    _G['lx'] = lx
end

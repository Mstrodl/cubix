--/lib/luaX/lx.lua
--luaX "hardware" access

_G['_LUAX_VERSION'] = '0.0.0'

--function: manage basic access to CC screen, basic pixels and etc.

--[[Maximum dimensions of CCscreen -> 19x51]]

local lxBuffer = {}
local SPECIAL_CHAR = '0'
local curX = 1
local curY = 1

function writeBuffer(character, colorchar)
    lxBuffer[curX][curY] = {colorchar, character}
end

function blank()
    term.clear()
    term.setCursorPos(1,1)
    term.set_term_color(colors.lightBlue)
    for x = 1, 51 do
        for y = 1, 19 do
            term.setCursorPos(x, y)
            write(SPECIAL_CHAR)
        end
    end
    term.set_term_color(colors.white)
    os.sleep(.5)
    term.clear()
    term.setCursorPos(1,1)
    return true
end

function sync_buffer()
    for i = 1, #lxBuffer do
        write()
    end
end

function write_pixel(locX, locY, color_pix)
    term.setTermPos(locX, locY)
    term.set_term_color(color_pix)
    writeBuffer(SPECIAL_CHAR, color_pix)
    term.set_term_color(colors.white)
end

--function initialize()
--    os.runfile_proc('/bin/lx', {"daemon"})
--end

function libroutine()
    _G['LX_LUA_LOADED'] = true
end

--/lib/luaX/lx.lua

_G['_LUAX_VERSION'] = '0.0.4'

--Task: the luaX backend

--[[Maximum dimensions of CCscreen -> 19x51]]

local SPECIAL_CHAR = ' '
local curX = 1
local curY = 1
local startColor = colors.lightBlue

lx = {}

lx = tmerge(lx, colors)

function term.set_bg_default()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
end

local _oldcursorpos = term.setCursorPos
function _setCursorPos(x,y)
    curX = x
    curY = y
    _oldcursorpos(x,y)
end

term.setCursorPos = _setCursorPos

local oldprint = print
function _print(msg)
    oldprint(msg)
    local x, y = term.getCursorPos()
    curX = x
    curY = y
end

print = _print

function blank()
    term.clear()
    term.setCursorPos(1,1)
    term.setBackgroundColor(startColor)
    for x = 1, 51 do
        for y = 1, 19 do
            term.setCursorPos(x, y)
            write(SPECIAL_CHAR)
        end
    end
    term.set_bg_default()
    os.sleep(.5)
    return true
end

function scr_clear()
    term.clear()
    term.setCursorPos(1,1)
end

function write_pixel(locX, locY, color_pix)
    term.setCursorPos(locX, locY)
    term.setBackgroundColor(color_pix)
    write(SPECIAL_CHAR)
    term.set_bg_default()
end

function write_letter(letter, locX, locY, color_b, color_letter)
    if #letter > 1 then
        return false
    end
    if color_letter == nil then
        color_letter = colors.white
    end
    term.setCursorPos(locX, locY)
    term.setBackgroundColor(color_b)
    term.setTextColor(color_letter)
    write(letter)
    term.set_bg_default()
    return true
end
lx.wletter = write_letter

function write_string(str, locx, locy, color_str, color_b)
    for i=1, #str do
        local letter = string.sub(str, i, i)
        write_letter(letter,
        locx+(i-1),
        locy,
        color_b,
        color_str)
    end
end

colorcodes = {
    ["0"] = colors.black,
    ["1"] = colors.blue,
    ["2"] = colors.lime,
    ["3"] = colors.green,
    ["4"] = colors.brown,
    ["5"] = colors.magenta,
    ["6"] = colors.orange,
    ["7"] = colors.lightGray,
    ["8"] = colors.gray,
    ["9"] = colors.cyan,
    ["a"] = colors.lime,
    ["b"] = colors.lightBlue,
    ["c"] = colors.red,
    ["d"] = colors.pink,
    ["e"] = colors.yellow,
    ["f"] = colors.white,
}

colores = {colors.black, colors.blue, colors.lime, colors.green, colors.brown, colors.magenta, colors.orange, colors.lightGray, colors.gray, colors.cyan, colors.lime, colors.red, colors.pink, colors.yellow, colors.white}

function random_color()
    return colores[math.random(1, #colores)]
end

function demo()
    write_letter('l', 1, 1, colors.lightBlue, colors.blue)
    write_letter('x', 2, 1, colors.lightBlue, colors.blue)

    --x
    --x
    --x
    --x
    --xxxxx

    write_pixel(5, 4, random_color())
    write_pixel(5, 5, random_color())
    write_pixel(5, 6, random_color())
    write_pixel(5, 7, random_color())
    write_pixel(5, 8, random_color())

    write_pixel(6, 8, random_color())
    write_pixel(7, 8, random_color())
    write_pixel(8, 8, random_color())

    --y 10
    --x   x
    -- x x
    --  x
    -- x x
    --x   x
    write_pixel(10, 4, random_color())
    write_pixel(14, 4, random_color())

    write_pixel(11, 5, random_color())
    write_pixel(13, 5, random_color())

    write_pixel(12, 6, random_color())

    write_pixel(11, 7, random_color())
    write_pixel(13, 7, random_color())

    write_pixel(10, 8, random_color())
    write_pixel(14, 8, random_color())
end

function get_status()
    if _G['LX_LUA_LOADED'] then
        return 'running'
    else
        return 'not running'
    end
end

function libroutine()
    _G['LX_LUA_LOADED'] = true
    _G['lx'] = lx
end

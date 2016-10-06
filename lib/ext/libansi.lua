--ANSI integration to CC

local libansi = {}

ansicodes_0 = {
    [30]=colors.black,
    [34]=colors.blue,
    [32]=colors.green,
    [36]=colors.cyan,
    [31]=colors.red,
    [35]=colors.purple,
    [33]=colors.brown,
    [37]=colors.lightGray,
}

ansicodes_1 = {
    [30]=colors.gray,
    [34]=colors.lightBlue,
    [32]=colors.lime,
    [36]=colors.cyan,
    [31]=colors.red,
    [35]=colors.purple,
    [33]=colors.yellow,
    [37]=colors.white,
}

coloransi = {
    [colors.black]={30, 0},
    [colors.blue]={34, 0},
    [colors.green]={32, 0},
    [colors.cyan]={36, 0},
    [colors.red]={31, 0},
}

function get(code, code_scope)
    code = tonumber(code)
    code_scope = code_scope or 0
    if code_scope == 0 then
        return ansicodes_0[code]
    elseif code_scope == 1 then
        return ansicodes_1[code]
    else
        ferror('libansi: wrong code scope')
        return colors.white
    end
end
libansi.get = get

function toAnsi(colorcode)
    return coloransi[colorcode]
end
libansi.toColor = toColor

_G['libansi'] = libansi

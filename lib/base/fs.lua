--[[
    fs.lua - manage filesystems
        mounting, etc.
]]

RELOADABLE = false

function libroutine()
    _G['fs_readall'] = fs_readall
    _G['fs_writeall'] = fs_writeall
end

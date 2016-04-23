#!/usr/bin/env lua
--cbxctr: Cubix Containers

--[[
    So... Cubix Containers...
    Sandboxing things is hard...

    VERY. HARD.
]]

RELOADABLE = false

local libctr = cubix.loadmodule_ret('/lib/cbxctr/container.lua')

if libctr then
    Container = libctr.Container
    NormalContainer = libctr.NormalContainer
else
    error("error loading libctr")
end

function libroutine()

end

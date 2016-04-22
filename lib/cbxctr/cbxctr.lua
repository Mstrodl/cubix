#!/usr/bin/env lua
--cbxctr: Cubix Containers

--[[
    So... Cubix Containers...
    Sandboxing things is hard...

    VERY. HARD.
]]

local libctr = cubix.loadmodule_ret('/lib/cbxctr/container.lua')

if libctr then
    Container = libctr.Container
    NormalContainer = libctr.NormalContainer
else
    error("cbxctr: error loading libctr")
end

if libctrimg then
    Image = libctrimg.Image
    ImagedContainer = libctrimg.ImagedContainer
else
    error("cbxctr: error loading libctrimg")
end

function libroutine()

end

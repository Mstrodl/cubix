#!/usr/bin/env lua
--multiuser library

--[[
    The task of multiuser is to load /bin/login into all ttys
    so you can have multiple users in the same computer logged at the same time!
]]

RELOADABLE = false

local framebuffers = {}
local current_fb = 1

TERM_X = 51
TERM_Y = 19

--[[
    Since trying to do this is the hell, I'll just theorize this

    The plan:
        ?????????????????????????
]]

function libroutine()
end

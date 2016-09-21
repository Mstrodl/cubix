#!/usr/bin/env lua

--[[
    cauth.lua : Cubix Authentication
]]

RELOADABLE = false

local function plain_login(user, pass)
    return true
end

local function prompt(serv_name, user)
    write("["..serv_name.."] password for "..user..": ")
    pass = read(' ')
    return plain_login(user, pass)
end

function start(name)
    return {
        ['logged'] = logged_user,
        ['serv_name'] = name
    }
end

function authenticate(hp, flags)
    if flags.user then
        return prompt(hp.serv_name, flags.user)
    else
        return prompt(hp.serv_name, hp.logged)
    end
end

function libroutine()
end

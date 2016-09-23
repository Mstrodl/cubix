#!/usr/bin/env lua

--[[
    cauth.lua : Cubix Authentication
]]

RELOADABLE = false

local SHA256_ROUNDS = 7

function proof_work(data)
    return lib.crypto.hash_sha256(data, SHA256_ROUNDS)
end

local function prompt(serv_name, user)
    write(rprintf("[%s] password for %s", serv_name, user))
    return read(' ')
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

function plain_login(hp, password)
    if not lib.hash then
        return ferror("plain_login: lib.hash not loaded")
    end

    return true
end

function grant(perm)
    return true
end

function libroutine()
end

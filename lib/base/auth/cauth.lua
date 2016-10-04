#!/usr/bin/env lua

--[[
    cauth.lua : Cubix Authentication
]]

RELOADABLE = false

local tbl_auth_tok = {}

local libsession = lib.get("/lib/base/auth/sessions.lua")
local Session = libsession.Session
local Token = libsession.Token

local SHA256_ROUNDS = 7

function proof_work(data)
    return lib.crypto.hash_sha256(data, SHA256_ROUNDS)
end

local function prompt(serv_name, user)
    write(rprintf("[%s] password for %s", serv_name, user))
    return read(' ')
end

function mk_token(username)
    local K = ''
    for i=1,32 do
        K = K .. getrandombyte()
    end
    local t = Token(username, K)
    return t
end

function start(service_name)
    return {
        --TODO
        ['logged'] = 'root',
        ['perm'] = 0,
        ['serv_name'] = service_name
    }
end

function authenticate(hp, flags)
    if flags.user then
        return prompt(hp.serv_name, flags.user)
    else
        return prompt(hp.serv_name, hp.logged)
    end
end

local function plain_login(hp, wanting_user, password)
    if not lib.crypto then
        return ferror("plain_login: lib.crypto not loaded")
    end

    local shadow_data = fs_readall("/etc/shadow")
    for k,line in ipairs(string.split(shadow_data)) do
        local spl = string.split(line, '^')
        -- user:password:salt:group
        local correct_hash = spl[2]
        local salt = spl[3]
        local group = spl[4]
        if spl[1] == wanting_user then
            -- hash and compare
            local proof = proof_work(password .. salt)
            if proof == correct_hash then
                return correct_hash
            end
            return false
        end
    end

    return false
end

local function login(hp, user_to_login, password, uses)
    local hpwd = plain_login(hp, user_to_login, password)
    if hpwd then
        local s = Session({
            ['uid'] = hp.uid,
            ['username'] = user_to_login,
            ['hashed_password'] = hpwd,
        })
        return s
    end
end

function grant(perm)
    return true
end

function libroutine()
end

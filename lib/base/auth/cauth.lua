#!/usr/bin/env lua

--[[
    cauth.lua : Cubix Authentication
]]

RELOADABLE = false

local tbl_auth_tok = {}
local tbl_sess_data = {}

local libsession = lib.get("/lib/base/auth/sessions.lua")
local Session = libsession.Session
local Token = libsession.Token

local SHA256_ROUNDS = 7

function proof_work(data)
    return lib.crypto.hash_sha256(data, SHA256_ROUNDS)
end

local function prompt(serv_name, user)
    write(rprintf("[%s] password for %s: ", serv_name, user))
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

function plain_session(hp, try_user, try_pwd)
    if hp.session then
        return hp.session:use_token()
    end

    local hpwd = plain_login(hp, try_user, try_pwd)
    if not hpwd then return false end

    --create token
    if tbl_sess_data[hp.key] then
        local ongoing_sess = tbl_sess_data[hp.key]
        if not ongoing_sess:check() then return false end
        return ongoing_sess:use_token()
    end

    local token = mk_token(try_user)

    local s = Session(hp)

    s:init({
        ['uid'] = hp.uid,
        ['username'] = try_user,
        ['hashed_password'] = hpwd,
        ['token_value'] = token,
        ['token_name'] = hp.serv_name..try_user,
        ['token_uses'] = 10,
        ['token_hash'] = lib.crypto.hash_sha256(
            hp.serv_name..try_user .. '10'),
    })

    if not s:check() then
        return ferror("Session: check failed")
    end

    hp.key = ''
    for i=1,16 do
        hp.key = hp.key .. getrandombyte()
    end

    hp.key = lib.crypto.hash_sha256(hp.key)

    tbl_sess_data[hp.key] = s

    return true
end

function authenticate(hp, flags)
    local try_pwd = ''
    local try_user = ''

    if hp.token then
        return hp.token:use()
    end

    if flags.user then
        try_user = flags.user
        try_pwd = prompt(hp.serv_name, flags.user)
    else
        try_user = hp.logged
        try_pwd = prompt(hp.serv_name, hp.logged)
    end

    return plain_session(hp, try_user, try_pwd)
end

function grant(perm)
    return true
end

function getuser(uid)
    return { -- TODO
        ['name'] = 'root',
        ['uid'] = uid
    }
end

function libroutine()
end

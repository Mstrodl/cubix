--[[
    crypto.lua - manage crypto functions(hash, random, etc)
]]
RELOADABLE = false

_mod_sha256 = cubix.load_file("/lib/hash/sha256.lua")
_mod_md5 = cubix.load_file("/lib/hash/md5.lua")

function hash_sha256(data, rounds)
    rounds = rounds or 1

    for i=1,rounds do
        sleep(0)
        data = _mod_sha256._sha256(data)
    end

    return data
end

function hash_md5(data, rounds)
    rounds = rounds or 1

    for i=1,rounds do
        sleep(0)
        data = _mod_md5.md5_sumhexa(data)
    end

    return data
end

function xorstr(a, b)
end

function hmac_sha256(data, key)
    local H = hash_sha256 -- hash to use
    local blength_block = 64
    local blength_output = 32

    if key > blenth_block then
        key = H(key)
    end

    --[[
    ipad = the byte 0x36 repeated B times
                 opad = the byte 0x5C repeated B times.

    ]]

    local opad = ''
    for i=1,blenth_block do
        opad = opad .. string.char(54)
    end

    local ipad = ''
    for i=1,blenth_block do
        ipad = ipad .. string.char(92)
    end

    return H(xorstr(key, opad), H(xorstr(key, ipad), text))
end

function libroutine()
    return true
end

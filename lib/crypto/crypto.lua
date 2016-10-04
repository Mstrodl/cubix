--[[
    crypto.lua - manage crypto functions(hash, random, etc)
]]
RELOADABLE = false

_mod_sha256 = cubix.load_file("/lib/hash/sha256.lua")
_mod_md5 = cubix.load_file("/lib/hash/md5.lua")

function hash_sha256(data, rounds, flag)
    rounds = rounds or 1

    if flag then
        for i=1,rounds do
            data = _mod_sha256.buf_sha256(data)
        end
    else
        for i=1,rounds do
            sleep(0)
            data = _mod_sha256._sha256(data)
        end
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

function hex2buf(data)
    local res = {}
    for i=1,#data,2 do
        res[i] = string.char(tonumber('0x'..string.sub(data, i, i)..
            string.sub(data, i+1, i+1)))
    end
    return res
end

function hmac_sha256(data, key)
    local H = hash_sha256 -- hash to use
    local blength_block = 64
    local blength_output = 32

    if #key > blength_block then
        key = H(key)
    end

    local bkey = hex2buf(key)
    local k_ipad, k_opad = {}, {}

    lib.io.buffer_copy(bkey, k_ipad, #bkey)
    lib.io.buffer_copy(bkey, k_opad, #bkey)

    for i=1,#k_ipad do
        k_ipad[i] = string.char(bit.bxor(string.byte(k_ipad[i]), 0x36))
        k_opad[i] = string.char(bit.bxor(string.byte(k_opad[i]), 0x5C))
    end

    local s_kipad, s_kopad = '', ''
    for i=1,#k_ipad do s_kipad = s_kipad .. k_ipad[i] end
    for i=1,#k_opad do s_kopad = s_kopad .. k_opad[i] end

    return H(s_kopad .. H(s_kipad) .. data)
end

function libroutine()
    return true
end

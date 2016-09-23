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


function libroutine()
    return true
end

--[[
    sessions.lua - manage Sessions
]]

function Token(username, key)
    local utt = username .. tostring(os.clock())
    return lib.crypto.hmac_sha256(utt, key)
end

Session = class(function(self)
    self.uid = ''
    self.username = ''
    self.hashed_password = ''
    self.login_string = ''
end)

function Session:init(init_table)
    for k,v in pairs(init_table) do
        if self[k] then
            self[k] = v
        end
    end

    self.login_string = lib.crypto.hash_sha256(
        self.hashed_password .. self.hp.serv_name
    )
end

function Session:check()
    if not self.uid then
        return false
    end

    local new_lstr = lib.crypto.hash_sha256(
        self.hashed_password .. self.hp.serv_name
    )

    -- TODO: check if lua has time constant string comparison
    return new_lstr == self.login_string
end

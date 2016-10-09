--[[
    sessions.lua - manage Sessions
]]

function Token(username, key)
    local utt = username .. tostring(os.clock())
    return lib.crypto.hmac_sha256(utt, key)
end

Session = class(function(self, hp)
    self.uid = ''
    self.username = ''
    self.hashed_password = ''
    self.login_string = ''
    self.hp = hp
end)

function Session:init(init_table)
    for k,v in pairs(init_table) do
        if self[k] then
            self[k] = v
        end
    end

    self.ctime = os.clock()

    self.login_string = lib.crypto.hash_sha256(
        self.hashed_password .. self.hp.serv_name .. tostring(self.ctime)
    )
end

function Session:check()
    if not self.uid then
        return false
    end

    local new_lstr = lib.crypto.hash_sha256(
        self.hashed_password .. self.hp.serv_name .. tostring(self.ctime)
    )

    return new_lstr == self.login_string
end

function Session:use_token()
    if self.token_uses < 0 then
        return false
    end

    if lib.crypto.hash_sha256(self.token_name .. tostring(self.token_uses))
      ~= self.token_hash then
        return false
    end

    self.token_uses = self.token_uses - 1
    local new_thash = lib.crypto.hash_sha256(self.token_name .. tostring(self.token_uses))
    self.token_hash = new_thash

    return true
end

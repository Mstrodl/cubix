--[[
    sessions.lua - manage Sessions
]]

Session = class(function(self)
    self.user_id = ''
    self.username = ''
    self.priv = ''
    self.name = ''
    self.hashed_password = ''
    self.login_string = ''
end)

function Session:init(init_table)
    for k,v in pairs(init_table) do
        if k in self then
            self[k] = v
        end
    end

    self.login_string = lib.crypto.hash_sha256(
        self.hashed_password .. self.hp.serv_name
    )
end

function Session:check()
    if not self.user_id then
        return false
    end

    local new_lstr = lib.crypto.hash_sha256(
        self.hashed_password .. self.hp.serv_name
    )

    -- TODO: check if lua has time constant string comparison
    return new_lstr == self.login_string
end

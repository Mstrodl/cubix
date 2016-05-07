
Buffer = class(function(self, btype, size)
    if btype == 'string' then
        self.obj = ''
    elseif btype == 'number' then
        self.obj = 0
    end
    self.siz = self.size
end)

function Buffer:get_size()
    return self.siz
end

function Buffer:read(size)
end

function Buffer:write(data)
end

function Buffer:all()
    return self:read(self:get_size())
end

function libroutine()
    _G["Buffer"] = Buffer
end

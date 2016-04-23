#!/usr/bin/env lua
--cbxctr: Cubix Containers - Container

--[[
    The sandbox works by overriding the CC functions and yeah
]]

Container = class(function(self, id)
    self.id = id
end)

function Container:run()
    self.func_run()
end

NormalContainer = class(Container, function(self, id, f)
    self.id = id
    self.file = f
end)

function NormalContainer:extract()
    self.func_run = function()
        p = fork(self.file)
        return prexec(p, nil, nil, nil, nil, true)
    end
    return self:run()
end

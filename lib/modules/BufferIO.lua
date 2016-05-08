
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

StringIO = class(function(self, buf)
    buf = buf or ''
    self.buf = tostring(buf)
    self.len = #buf
    self.buflist = {}
    self.pos = 0
    self.closed = false
    self.softspace = 0
end)

function StringIO:close()
    if not self.closed then
        self.closed = true
        self.buf = nil
        self.pos = nil
    end
end

function StringIO:seek(pos, mode)
    mode = mode or 0
    if self.closed then
        return ferror("StringIO: Operation on closed file")
    end
    if self.buflist then
        self.buf = self.buf .. table.concat(self.buflist, '')
        self.buflist = {}
    end
    if mode == 1 then
        pos = pos + self.pos
    elseif mode == 2 then
        pos = pos + self.len
    end
    self.pos = tmax({0, pos})
end

function StringIO:tell()
    return self.pos
end

function StringIO:read(n)
    n = n or -1
    if self.closed then
        return ferror("StringIO: Operation on closed file")
    end

    if self.buflist then
        self.buf = self.buf .. table.concat(self.buflist, '')
        self.buflist = {}
    end

    local newpos
    if n < 0 then
        newpos = self.len
    else
        newpos = tmin({self.pos+n, self.len})
    end

    r = {unpack(tstr(self.buf), self.pos, newpos)}
    self.pos = newpos
    return r
end

function StringIO:readline(length)
    length = length or nil
    if self.closed then
        return ferror("StringIO: Operation on closed file")
    end

    if self.buflist then
        self.buf = self.buf .. table.concat(self.buflist, '')
        self.buflist = {}
    end

    local i = string.find(self.buf, '\n', self.pos)
    local newpos

    if i < 0 then
        newpos = self.len
    else
        newpos = i+1
    end

    if length ~= nil then
        if self.pos + length < newpos then
            newpos = self.pos + length
        end
    end

    local r = {unpack(tstr(self.buf), self.pos, newpos)}
    self.pos = newpos
    return table.concat(r, '')
end

function StringIO:write(s)
    if self.closed then
        return ferror("StringIO: Operation on closed file")
    end
    if not s then return end

    s = tostring(s)
    if self.pos > self.len then
        self.buflist[#self.buflist + 1] = string.rep('\0', self.pos - self.len)
        self.len = self.pos
    end

    newpos = self.pos + #s

    if self.pos < self.len then
        if self.buflist then
            self.buf = self.buf .. table.concat(self.buflist, '')
            self.buflist = {}
        end
        self.buflist = {{unpack(tstr(self.buf), 1, self.pos)}, s, {unpack(tstr(self.buf), self.pos)}}
        self.buf = ''
        if newpos > self.len then
            self.len = newpos
        end
    else
        self.buflist[#self.buflist + 1] = s
        self.len = newpos
    end
    self.pos = newpos
end

function test_stringIO()
    sleep(1)

    s = StringIO()
    
    s:write("trolei você")

    print(s:read(128))

    s:close()

    sleep(2)
end

function libroutine()
    _G["Buffer"] = Buffer
    _G["StringIO"] = StringIO
    test_stringIO()
end

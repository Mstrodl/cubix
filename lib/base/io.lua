--[[
    io.lua - manage I/O operations
]]

local BufferIO = class(function(self, buf)
    self.buf = buf
    self.len = #buf
    self.cur = 1
    self.littlepos = 1
    self.closed = false
end)

StringIO = class(function(self, buf)
    buf = buf or ''
    self.buf = tostring(buf)
    self.len = #buf
    self.cur = 1
    self.littlepos = 1
    self.closed = false
end)

function StringIO:close()
    if not self.closed then
        self.closed = true
        self.buf = nil
        self.pos = nil
    end
end

function StringIO:write(str)
    self.buf = self.buf .. str
    self.len = #self.buf
end

function StringIO:read(bytes)
    local r = string.sub(self.buf, self.cur, (self.cur + bytes))
    self.cur = self.cur + #r
    return r
end

function test_stringIO()
    syslog.serlog(syslog.S_INFO, 'Buffer', 'testing')
    s = StringIO()

    s:write("trolei você")
    print('data', s:read(64))

    s:write("trolei você denovo")
    print('data', s:read(64))

    s:write("trolei você pela segunda vez")
    print('data', s:read(64))

    s:write("terceira vez q trolo abcdefghijklmnopqrs")
    print('data', s:read(16))

    print('data', s:read(16))

    s:close()

    sleep(0)
end

Buffer = class(function(self, btype, size)
    if btype == 'string' then
        self.obj = StringIO()
    elseif btype == 'buffer' then
        self.obj = BufferIO()
    end
    self.type = btype
    self.size = size
end)

function Buffer:read(size)
    if self.type == 'string' then
        return self.obj.read(self.obj, size)
    elseif self.type == 'number' then
        ---???
        return
    else
        return ferror("Buffer: buffer of undefined type")
    end
end

function Buffer:write(data)
    if (#data + #self.obj) > self.size then
        local addr = string.sub(tostring(self), 8)
        ferror("Buffer: buffer overflow at "..addr)
        os.send_ev({'buffer_overflow', addr}) --anyone can handle this.
    end

    if self.type == 'string' then
        return self.obj.write(self.obj, data)
    elseif self.type == 'number' then
        ---???
        return
    else
        return ferror("Buffer: buffer of undefined type")
    end
end

function buffer_copy(buffer_in, buffer_out, len)
    for i=1,len do
        buffer_out[i] = buffer_in[i]
    end
end

function test_buffer()
    local b = Buffer('string', 10)
    b:write('1298341093584203958230') --trigger buffer overflow

    local b2 = Buffer('string', 16)
    b2:write("abc")
    print(b2:read(2))

    sleep(3)
end

function libroutine()
end

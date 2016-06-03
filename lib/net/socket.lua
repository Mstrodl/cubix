
AF_INET = 1

SOCK_STREAM = 1

IPPROTO_IP = 1

local last_id = 0
local cxt = {}

socket = class(function(self, addr_type, _type)
    self.type = _type
    self.addr_type = addr_type
    self.sockid = last_id + 3
    self.type = ''
    self.link = {}

    self.max = 0
    self.sock_cache = {}

    last_id = last_id + 1
end)

SocketLink = class(function(self, sd_1, sd_2)
    self.b1 = StringIO()
    self.b2 = StringIO()
    self.d1 = sd_1
    self.d2 = sd_2
end)

function init_cxt(addr, port)
    if not cxt[addr] then
        cxt[addr] = {}
    end

    if not cxt[addr][port] then
        cxt[addr][port] = {['cli']={}, ['serv']={}}
    end
end

function socket:bind(server)
    self.type = 'serv'

    local addr, port = server[1], server[2]

    --start context for that port and address
    init_cxt(addr, port)

    local server_sock = cxt[addr][port]['serv']
    if server_sock ~= nil then
        return ferror("connect: serv sockets already in")
    end

    self.link = SocketLink(self.sockid, server_sock.sockid)

    return true
end

function socket:accept(numcli)
    -- accept max connection of numcli
    self.max = numcli
end

function socket:accept()
    -- return new socket if possible
    if self.sock_count > self.max_sock then
        return ferror("accept: max connections execceded")
    end

    local sock = self.sock_cache:pop()
    return sock
end

function socket:connect(server)
    self.type = 'cli'

    local addr, port = server[1], server[2]
    init_cxt(addr, port)

    -- put socket in client sock list
    local l = #cxt[addr][port]['cli']
    cxt[addr][port]['cli'][self.sockid] = self

    --link it to the only server in that port
    local server_sock = cxt[addr][port]['serv']
    if server_sock == nil then
        return ferror("connect: no serv sockets found")
    end

    cxt[addr][port]['cli'][self.sockid + 1] = SocketLink()

    return true
end

function socket:send(data)
    return self.link.b2:write(data)
end

function socket:recv(bytes)
    local data = self.link.b1:read(bytes)
    return data
end

function libroutine()
end

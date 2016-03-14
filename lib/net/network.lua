#!/usr/bin/env lua
--network library for cubix

RELOADABLE = false

local INTERFACES = {}
local R_ENTRIES = {}
local LOCAL_IP = ''
local default_context = nil

local buffer = ''

function create_interface(name, type)
    --local device = get_interf(type)
    local device = {nil}
    INTERFACES[name] = device
end

local function set_local(ip)
    LOCAL_IP = ip
end

function new_resolve_entry(name, ip)
    R_ENTRIES[name] = ip
end

function resolve_addr(addr)
    return R_ENTRIES[addr]
end

SYS_SERVER_PING = 0
SYS_SERVER_CLALL = 1

SysServer = class(function(self, sv_type)
    self.type = sv_type
    self:start()
end)

function SysServer:start()
    if self.type == SYS_SERVER_PING then
    elseif self.type == SYS_SERVER_CLALL then --server closing all connections
    end
end

function SysServer:spacket(packet)
    --return response from a packet
    if packet.type == TPACKET_PING then
        print(packet.data)
        local packet_ms = os.strsplit(packet.data, '~')[2]
        local diff = os.clock() - tonumber(packet_ms)
        return '0>>>PING~'..tostring(diff)
    else
        os.debug.debug_write("[ss_ping] packet recieved is not type PING", nil, true)
    end
end

--packet types
TPACKET_PING = 0
TPACKET_PING_RESP = 1

Packet = class(function(self, type, destination, data)
    self.type = type
    self.dest = resolve_addr(destination)
    self:parse(data)
end)

function Packet:parse(data)
    if self.type == TPACKET_PING then
        self.data = '0>>>PING~'..tostring(os.clock())
    elseif self.type == TPACKET_PING_RESP then
        self.data = data
        self.ping_ms = tonumber(os.strsplit(';')[2])
    end
end

function Packet:send()
    default_context:send_packet(self)
end

function Packet:getms()
    if self.type == TPACKET_PING_RESP then
        if self.ping_ms == nil then
            ferror("network.getms: s.ping_ms == nil")
        end
        return self.ping_ms
    else
        os.debug.debug_write("network: packet is not a ping response packet", nil, true)
        return nil
    end
end

CXT_CUBIX_PING = 1

Context = class(function(self, ctype, interf)
    self.type = type
    self.interf = interf
    self.FLAG_RECV = false
    self.recv_buffer = ''
    self.rbuf_counter = 0
end)

function Context:open_recv()
    self.FLAG_RECV = true
end

function Context:send_packet(p)
    if self.FLAG_RECV then
        --automatically handle buffer
        local rdata = ''
        --I need to send packets depending of context type
        if self.type == CXT_CUBIX_PING and self.dest == '127.0.0.1' then
            local ssp = get_sys_server(SYS_SERVER_PING)
            rdata = ssp:spacket(p)
        end
        self.recv_buffer = self.recv_buffer .. rdata
    else
        --send to the context and wait
    end
end

function Context:recv(bytes)
    os.viewTable(self)
    if bytes > #self.recv_buffer then
        bytes = #self.recv_buffer
    end
    local data = string.sub(self.recv_buffer, self.rbuf_counter, bytes)
    self.rbuf_counter = self.rbuf_counter + bytes
    return data
end

function Context:close()
    self.recv_buffer = ''
    self.rbuf_counter = 0
end

function set_context(cxt)
    default_context = cxt
end

function finish_cxt(cxt)
    default_context = nil
    cxt:close()
end

local SYS_SERVERS = {}

function add_sys_server(s, stype)
    SYS_SERVERS[stype] = s
end

function get_sys_server(stype)
    return SYS_SERVERS[stype]
end

function libroutine()
    create_interface("lo", "loopback")
    create_interface("eth0", "cable")
    create_interface("wlan0", "wireless")
    set_local("127.0.0.1")
    new_resolve_entry("localhost", '127.0.0.1')

    local sp = SysServer(SYS_SERVER_PING)
    add_sys_server(sp, SYS_SERVER_PING)

    sleep(0.5)

    --ping test
    local c = Context(CXT_CUBIX_PING, 'lo')
    set_context(c)
    local p = Packet(TPACKET_PING, 'localhost', nil)
    c:open_recv()
    p:send()
    local rd = c.recv(1024)
    local pr = Packet(TPACKET_PING_RESP, nil, rd)
    local ms = pr:getms()
    finish_cxt(c)
    os.debug.debug_write("[net] ping test: "..tostring(ms).."ms")
end

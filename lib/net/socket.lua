
AF_INET
SOCK_STREAM
IPPROTO_IP

in_addr = class(function(self)
    self.s_addr = 0
end)

sockaddr_in = class(function(self)
    self.sin_family = 0
    self.sin_port = 0
    self.in_addr = in_addr()
    self.sin_zero = '0'
end)

sockaddr = class(function(self)
    self.sa_family = 0
    self.sa_data = Buffer.new('string', 14)
end)

function socket_socket(af, type, proto)
    local descriptor = 1
    return descriptor
end

function socket_connect(desc, server)
end

function libroutine()
end


AF_INET = 1

SOCK_STREAM = 1
SOCK_NETLINK = 2

IPPROTO_IP = 1

socket = class(function(self, sockcxt, socktype)
    self.cxt = sockcxt
    self.stype = socktype
    self.in_addr = sockaddr()
end)

function socket:connect(server_data)
    self.out_addr = sockaddr()
end

function libroutine()
end

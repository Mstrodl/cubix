
--Theory of socket library
function main()
    socket = os.lib.socket

    -- create socket
    local s = socket.new(socket.AF_INET, socket.SOCK_STREAM)

    -- connect to test server
    s:connect("192.168.35.12", 2)

    -- send data to server
    s:send("GET / HTTP/1.1\r\n\r\n")

    -- recieve data from server
    print(s:recv(2048))
end

main()


--Theory of socket library
function main()
    socket = os.lib.socket

    -- create socket
    local s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    -- connect to test server
    s:connect({"0.0.0.1", 2})

    -- send data to server
    s:send("TEST_SERVER")

    -- recieve data from server
    print(s:recv(2048))
end

main()

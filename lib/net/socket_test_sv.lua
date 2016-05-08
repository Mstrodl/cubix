
--Theory of socket library
function main()
    socket = os.lib.socket

    -- create socket
    local s = socket.new(socket.AF_INET, socket.SOCK_STREAM)

    s:bind({"0.0.0.1", 2})

    if s:recv(1024) == 'TEST_SERVER' then
        s:send("TESTED.")
    end

    print(s:recv(2024))
end

main()

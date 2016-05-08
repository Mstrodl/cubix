
--Theory of socket library
function main()
    socket = os.lib.socket

    -- create socket
    local s = socket.new(socket.AF_INET, socket.SOCK_STREAM)

    s:bind({"0.0.0.1", 2})

    s:listen(1)
    local c = s:accept()

    if c:recv(1024) == 'TEST_SERVER' then
        c:send("TESTED.")
    end

    print(c:recv(2024))
    print("ded")
end

main()

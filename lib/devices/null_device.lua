dev_null = {}
dev_null.name = '/dev/null'
dev_null.device = {}

dev_null.device.device_read = function (bytes)
    print("cannot read from /dev/null")
end

dev_null.device.device_write = function(s)
    return 0
end

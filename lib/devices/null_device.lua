

dev_null = {}
dev_null.name = '/dev/null'
dev_null.device = {}

dev_null.device.read = function (bytes)
    print("cannot read from /dev/null")
end

dev_null.device.devwrite = function(s)
    return 0
end


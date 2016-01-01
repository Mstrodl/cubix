dev_dummy = {}
dev_dummy.name = '/dev/dummy'
dev_dummy.device = {}

dev_dummy.device.device_read = function (bytes)
    return nil
end

dev_dummy.device.device_write = function(s)
    return nil
end

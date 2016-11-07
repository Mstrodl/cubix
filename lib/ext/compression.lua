--[[
    compression.lua - Cubix Compression Libraries

    This is intended for libyap but any other thing can use it
]]

-- TODO: implementations etc

--Every algorithim implemented in compression.lua needs to inherit from Compressor.
Compressor = class(function(self)
end)

function Compressor:compress(data)
    return ferror("compress: Not Implemented")
end

function Compressor:decompress(data)
    return ferror("decompress: Not Implemented")
end

LZW = class(Compressor, function(self)
end)

-- generator.lua: the cubix random generator
-- uses entropyman to gather seed and then returns ISAAC iterations

function getrandom(buffer, bufferlen, flag_bytes)
    bufferlen = bufferlen or #buffer
    for i=1,bufferlen do
        if flag_bytes then
            buffer[i] = getrandombyte()
        else
            buffer[i] = rand()
        end
    end
    return buffer
end

local bigint = os.lib.bigint.bigint

function getrandombits(length, cap)
    --[[
        getrandombits:
            Generate a number with arbritary length
            Returns bigint object

        Arguments:
        length - length of desired number
        cap - maximum value of the parts to generation(default 999999999)
    ]]
	if not cap then
		cap = 999999999
	end

	local randomString = tostring(randrange(100000000, cap))

	while true do
		randomString = randomString ..
			tostring(math.random(100000000, cap))
		if #randomString >= length then
			local finalRandom = randomString:sub(1, length)
			if finalRandom:sub(-1, -1) == "2" then
				return bigint(finalRandom:sub(1, -2) .. "3")
			elseif finalRandom:sub(-1, -1) == "4" then
				return bigint(finalRandom:sub(1, -2) .. "5")
			elseif finalRandom:sub(-1, -1) == "6" then
				return bigint(finalRandom:sub(1, -2) .. "7")
			elseif finalRandom:sub(-1, -1) == "8" then
				return bigint(finalRandom:sub(1, -2) .. "9")
			elseif finalRandom:sub(-1, -1) == "0" then
				return bigint(finalRandom:sub(1, -2) .. "1")
			else
				return bigint(finalRandom)
			end
		end
	end
end

function libroutine()
    isaac.isaac_seed_mt()

    -- install syscalls
    _G['getrandom'] = getrandom
    _G['getrandombits'] = getrandombits
end

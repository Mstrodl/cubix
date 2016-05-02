function bin2hex(str)
    local val = ""
    for i = 1, str:len() do
        char = string.byte(str:sub(i, i))
        val  = string.format("%s%02X%s", val, char, "")
    end
    return val
end

function isprime(n)
    n = tonumber(n)
    if n <= 1 or ( n ~= 2 and n % 2 == 0 ) then
        return false
    end

    for i = 3, math.sqrt(n), 2 do
    	if n % i == 0 then
      	    return false
    	end
    end

    return true
end
function crypto_prime_gen(bits)
    bits = math.floor(bits)
    if bits < 24 then return end
    local ret, high, bytes = nil, 1, math.floor((bits - 7) / 8)

    for i=1,bits-bytes*8-1 do
        high = 1 + high + high
    end

    high = string.char(high)
    --low = lcrypt.random(1):byte()
    low = getrandombyte()
    if low / 2 == math.floor(low / 2) then
        low = low + 1
    end
    low = string.char(low)
    bytes = bytes - 1

    repeat
        local a = tostring(getrandombits_char(bytes))

        local a_hex = bin2hex(a)
        local high_hex = bin2hex(high)
        local low_hex = bin2hex(low)

        local c_hex = high_hex .. a_hex .. low_hex
        local c_n = tonumber(c_hex, 16)

        ret = bigint.bigint(c_n)
    until isprime(tostring(ret))

    return ret
end
_G['crypto_prime_gen'] = crypto_prime_gen

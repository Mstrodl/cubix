-- rsa library: all crypto_rsa_* calls are here

function mod_mul_inv(a, n)
	local t  = 0
    local nt = 1
    local r  = n
    local nr = a % n

    local zero = bigint.bigint(0)
    local one = bigint.bigint(1)

    if (n < zero) then
    	n = -n
    end

    if (a < 0) then
    	a = n - (-a % n)
    end

	while (nr ~= zero) do
		local quot= (r/nr) or 0
		local tmp = nt
        nt = t - quot*nt
        t = tmp
		tmp = nr
        nr = r - quot*nr
        r = tmp
	end

	if (r > one) then
        return -1
    end

	if (t < zero) then
        t = t + n;
    end
	return t;
end

function crypto_rsa_generate(ksiz)
    ksiz = ksiz or 32
    local p = crypto_prime_gen(ksiz)
    local q = crypto_prime_gen(ksiz)

    local n = p*q

    local phi_n = (p-1) * (q-1)

    --local e = crypto_prime_coprime(1, phi_n)
    local e = 65537

    --if not gcd(e, phi_n) == 1 then
    --    ferror("crypto_rsa_generate: gcd error")
    --    return false
    --end

    local d = mod_mul_inv(e, phi_n)

    return true, n, e, d
end

function powmod(a, b, c)
    local x, y, z = 1, a, b
    while z ~= 0 do
        if z%2 == 0 then
			z, y = z/2, (y^2) % c;
        else
			z, x = z-1, (x*y) % c;
        end
    end
    return x
end

function crypto_rsa_encrypt(n, e, m)
    return powmod(m, e, n)
end

function crypto_rsa_decrypt(n, d, c)
    return powmod(c, d, n)
end

function libroutine()
    _G['crypto_rsa_generate'] = crypto_rsa_generate
    _G['crypto_rsa_encrypt'] = crypto_rsa_encrypt
    _G['crypto_rsa_decrypt'] = crypto_rsa_decrypt
end

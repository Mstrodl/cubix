-- rsa library: all crypto_rsa_* calls are here

function crypto_rsa_encrypt(public, msg)
end

function crypto_rsa_decrypt(private, cip)
end

function crypto_rsa_generate(ksiz)
    ksiz = ksiz or 32
    local p = crypto_prime_gen(ksiz)
    local q = crypto_prime_gen(ksiz)

    local n = p*q

    local phi_n = (p-1) * (q-1)

    local e = crypto_prime_coprime(1, phi_n)
    if not gcd(e, phi_n) == 1 then
        ferror("crypto_rsa_generate: gcd error")
        return false
    end

    local d = crypto_solve(pow(e, -1) % phi_n)

    return true, public, private
end

function libroutine()
    _G['crypto_rsa_generate'] = crypto_rsa_generate
    _G['crypto_rsa_encrypt'] = crypto_rsa_encrypt
    _G['crypto_rsa_decrypt'] = crypto_rsa_decrypt
end

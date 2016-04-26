
os.internals.loadmodule("libprime", "/lib/random/generator/prime_gen.lua")

BBShub = class(function(self, seed, K)
    K = K or 8
    self.num = seed

    if self.num == 1 or self.num == 0 then
        os.debug.debug_write("[bbshub] num cannot be 1 or 0", nil, true)
    end

    if libprime.blen(self.num) < K or self.num == nil then
        os.debug.debug_write("[bbshub] num < K, regen", nil, true)
        self.num = randrange(math.pow(10, K), math.pow(10, K+1))
    end

    os.debug.debug_write("[bbshub] generating primes", false)
    print("Generating primes, should take some time")
    self.p = libprime.get_prime(K)
    self.q = libprime.get_prime(K)

    self.M = self.p * self.q

    while (not congruent(self.p, 3, 4)) or (not congruent(self.q, 3, 4)) do
        os.debug.debug_write("[bbshub] congruency test failed, trying again")
        self.p = libprime.get_prime(K)
        self.q = libprime.get_prime(K)
        self.M = self.p * self.q
    end

    if isfactor(self.num, self.p) then
        os.debug.debug_write("[bbshub] p is factor of num", nil, true)
        return false
    end

    if isfactor(self.num, self.q) then
        os.debug.debug_write("[bbshub] q is factor of num", nil, true)
        return false
    end

    if self.num == 1 or self.num == 0 then
        os.debug.debug_write("[bbshub] num cannot be 1 or 0", nil, true)
        return false
    end
end)

function BBShub:next_num()
    new = math.pow(self.num, 2) % self.M
    self.num = new
    return new
end

function libroutine()
    os.bbshub = BBShub(os.clock())
end

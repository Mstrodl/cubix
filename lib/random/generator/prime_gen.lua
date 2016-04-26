function get_rand(n)
    -- return int(os.urandom(n).encode('hex'), 16)
    return rand() * rand() * rand()
end

function log2(x)
    return math.log(x) / math.log(2)
end

function blen(num)
    if num % 2 == 0 then
        return math.ceil(log2(num))
    else
        return math.floor(log2(num)) + 1
    end
end

function modExp(a, b, c)
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

function setBit(int_type, offset)
    --mask = 1 << offset
    --return(int_type | mask)

    local mask = bit.blshift(1, offset)
    return bit.bor(int_type, mask)
end

_mrpt_num_trials = 5

function test_prime(n)
    if not (n >= 2) then
        ferror("assert_error: n >= 2")
        return false
    end

    if n == 2 then
        return true
    end

    -- ensure n is odd
    if n % 2 == 0 then
        return false
    end

    local s = 0
    local d = n-1
    while true do
        local quotient = math.floor(d / 2)
        local remainder = d % 2
        if remainder == 1 then
            break
        end
        s = s + 1
        d = quotient
    end

    if not (math.pow(2, s) * d == n-1) then
        ferror("assert_error: (2**s * d == n-1)")
        return false
    end

    -- test the base a to see whether it is a witness for the compositeness of n
    function try_composite(a)
        if modExp(a, d, n) == 1 then
            return False
        end

        for i=0,(s-1) do
            if modExp(a, math.pow(2, i) * d, n) == n-1 then
                return False
            end
        end
        return True
    end

    for i=0,_mrpt_num_trials do
        local a = randrange(2, n)
        if try_composite(a) then
            return False
        end
    end

    return true -- no base tested showed n as composite
end

function get_tprime(n)
    x = get_rand(n)
    setBit(x, 0)
    setBit(x, blen(x))
    return x
end

function test_tprime(x)
    b = blen(x)
    c1 = test_prime(x)
    sleep(0)
    c2 = (math.pow(2, b-1) < x) and (x < math.pow(2, b))
    return c1 and c2
end

function get_prime(x)
    p = get_tprime(x)
    while not test_tprime(p) do
        sleep(0)
        p = get_tprime(x)
    end
    return p
end

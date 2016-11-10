
Test = lib.test.Test

test_rand_0 = Test('syscall', 'testing range of rand()', function()
    local n = rand()
    return 0 <= n and n <= math.pow(2, 32-1)
end)

test_rand_1 = Test('syscall', 'testing range of randrange()', function()
    local a = rand()
    local b = rand()
    local n
    if a > b then
        local n = randrange(b, a)
        return (b <= n) and (n <= a)
    else
        local n = randrange(a, b)
        return (a <= n) and (b <= a)
    end
end)

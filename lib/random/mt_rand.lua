
local n = 624 + 1
local f = 1812433253
local w = 32

local m = 397
local r = 31

local a = 0x9908B0DF

local u = 11
local d = 0xFFFFFFFF

local s = 7
local b = 0x9D2C5680

local t = 15
local c = 0xEFC60000

local l = 18

local MT = {}
local index = n+1

local lower_mask = bit.blshift(1 , r) - 1

--MT19937

function _int32(x)
    return bit.band(0xFFFFFFFF, x)
end

MT19937 = class(function(self, seed)
    self.index = n
    self.state = table_gen(0, n)
    self.state[1] = seed
    for i=2,n do
        local t = bit.bxor(self.state[i - 1], bit.brshift(self.state[i - 1], w - 2))
        self.state[i] = _int32(f * t + i)
    end
end)

function MT19937:extract_num()
    if self.index >= n then
        self:twist()
    end

    local y = self.state[self.index]

    y = bit.bxor(y, bit.band(bit.brshift(y, u), d))
    y = bit.bxor(y, bit.band(bit.blshift(y, s), b))
    y = bit.bxor(y, bit.band(bit.blshift(y, t), c))
    y = bit.bxor(y, bit.brshift(y, l))

    self.index = self.index + 1
    return _int32(y)
end

function MT19937:twist()
    for i=1,n do
        local x = _int32((bit.band(self.state[i], 0x80000000)) +
                   (bit.band(self.state[(i % (n + 1))] , 0x7fffffff)))

        local xA = bit.brshift(x, 1)
        if (x % 2) ~= 0 then
            xA = bit.bxor(xA, a)
        end

        if self.state[((i + m) % n)] ~= nil then
            local n1 = self.state[((i + m) % n)]
            local n2 = xA
            self.state[i] = bit.bxor(n1, n2)
        end
    end
    self.index = 1
end

function libroutine()
    os.random = MT19937(os.time())
    _G['rand'] = function()
        return os.random.extract_num(os.random)
    end
    _G['randrange'] = function(a, b)
        return (rand() * b) + a
    end
end

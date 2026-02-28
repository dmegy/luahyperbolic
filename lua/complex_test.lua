local complex = require("complex")

local function assertTrue(cond, msg)
    if not cond then
        error("Test failed: " .. (msg or ""))
    end
end

local function assertClose(a, b, eps)
    if not complex.isClose(a, b, eps) then
        error("Not close: " .. tostring(a) .. " vs " .. tostring(b))
    end
end

print("Running basic tests...")

-- Constructor
local z = complex(3,4)
assertTrue(z.re == 3 and z.im == 4, "constructor")

-- Addition
assertClose(complex(1,2) + complex(3,4), complex(4,6))

-- Subtraction
assertClose(complex(5,6) - complex(1,2), complex(4,4))

-- Multiplication
assertClose(complex(1,2) * complex(3,4), complex(-5,10))

-- Division
assertClose(complex(1,2) / complex(3,4),
            complex(11/25, 2/25))

-- Conjugate
assertClose(complex.conj(complex(3,4)), complex(3,-4))

-- abs2
assertTrue(complex.abs2(complex(3,4)) == 25, "abs2")

-- abs
assertTrue(math.abs(complex.abs(complex(3,4)) - 5) < 1e-12, "abs")

-- Argument
assertTrue(math.abs(complex.arg(complex(1,0))) < 1e-12, "arg")

-- Unit
local u = complex(3,4):unit()
assertClose(u, complex(3/5,4/5))

-- Rotate90
assertClose(complex(1,0):rotate90(), complex(0,1))

-- Rotate
assertClose(complex(1,0):rotate(math.pi/2), complex(0,1))

-- exp_i
assertClose(complex.exp_i(math.pi), complex(-1,0))

-- Polar
assertClose(complex.polar(2,0), complex(2,0))

-- Log/Exp inverse
local w = complex(0.3, 0.7)
assertClose(complex.exp(complex.log(w)), w, 1e-10)

-- Power
assertClose(complex(2,0)^complex(3,0), complex(8,0))

-- Colinearity
assertTrue(complex(1,1):isColinear(complex(2,2)), "colinear")

-- Inversion (unit circle)
local a = complex(2,0)
local inv = complex.invert(a)
assertClose(inv, complex(0.5,0))

print("Basic tests passed.")

-- =========================================================

math.randomseed(os.time())

local function rand()
    return (math.random() - 0.5) * 20
end

local function randComplex()
    return complex(rand(), rand())
end


print("Running stress tests...")

-- Random algebra identities
for i = 1, 5000 do
    local a = randComplex()
    local b = randComplex()
    local c = randComplex()

    -- (a+b)+c == a+(b+c)
    assertClose((a+b)+c, a+(b+c))

    -- distributivity
    assertClose(a*(b+c), a*b + a*c)

    -- conjugation property
    assertClose(complex.conj(a*b),
                complex.conj(a)*complex.conj(b))

    -- abs^2 = z * conj(z)
    local lhs = complex.abs2(a)
    local rhs = (a * complex.conj(a)).re
    assert(math.abs(lhs - rhs) < 1e-10)

    -- unit length
    if complex.abs(a) > 1e-6 then
        local u = a:unit()
        assert(math.abs(complex.abs(u) - 1) < 1e-10)
    end
end

print("Random algebra OK.")

-- Test division by zero
do
    local ok, err = pcall(function()
        return complex(1,2) / complex.ZERO
    end)
    assert(not ok, "Division by zero should fail")
end

-- Test log(0)
do
    local ok = pcall(function()
        return complex.log(complex.ZERO)
    end)
    assert(not ok, "log(0) should fail")
end

-- Test inversion at center
do
    local ok = pcall(function()
        return complex.invert(complex(1,0), complex(1,0))
    end)
    assert(not ok, "invert at center should fail")
end

-- Test random invert consistency
for i=1,2000 do
    local z = randComplex()
    if complex.abs(z) > 1e-6 then
        local inv = complex.invert(z)
        local back = complex.invert(inv)
        assertClose(z, back, 1e-8)
    end
end

print("Inversion OK.")

-- Power consistency test
for i=1,2000 do
    local z = randComplex()
    if complex.abs(z) > 1e-6 then
        local z2 = z^complex(2,0)
        assertClose(z2, z*z, 1e-10)
    end
end

print("Power tests OK.")

print("All stress tests passed.")
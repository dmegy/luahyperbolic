-----------------------------------------------------------------------
-- @module complex
-- Pure Lua complex number library (LuaLaTeX oriented).
-- Provides arithmetic, elementary functions, geometric utilities,
-- and tolerant comparisons.
--
-- License:
--   Public Domain / CC0 1.0 Universal
--   2026 Damien Mégy
--   This software is released into the public domain.
--   You may use, modify, and distribute it freely, without restriction.
--
-- SPDX-License-Identifier: CC0-1.0
--
-----------------------------------------------------------------------



local m = {}
m.__index = m

local sin = math.sin
local cos = math.cos
local atan2 = math.atan2
local exp = math.exp
local log = math.log
local sqrt = math.sqrt
local abs = math.abs

-- precision
m.EPS_INV = 1e10
m.EPS = 1/m.EPS_INV

function m.new(re, im)
	return setmetatable({
		re = re or 0,
		im = im or 0,
	}, m)
end

--- Polar constructor.
function m.polar(r, theta)
	return m.new(r * cos(theta), r * sin(theta))
end


setmetatable(m, {
	__call = function(_, re, im)
		return m.new(re, im)
	end,
})

-- -----------------------------------------
-- Type checking and coercion
-- -----------------------------------------

function m.isComplex(z)
	return type(z) == "table" and getmetatable(z) == m
end

local function tocomplex(z)
	if m.isComplex(z) then
		return z
	elseif type(z) == "number" then
		return m.new(z, 0)
	elseif type(z) == "table" and z.re and z.im then
        return m.new(z.re, z.im)
	else
		error("Cannot coerce value to complex, got type " .. type(z))
	end
end

-- public coerce, handles various arguments

function m.coerce(...)
    local args = {...}
    for i = 1, #args do
        args[i] =tocomplex(args[i])
    end
    return table.unpack(args)
end

-- -----------------------------------------
-- Arithmetic metamethods
-- -----------------------------------------

--- Exact equality test (no tolerance).
-- Use `isClose` for numerical comparisons.
function m.__eq(a, b)
	a, b = tocomplex(a), tocomplex(b)
	return a.re == b.re and a.im == b.im
end

--- Addition metamethod.
function m.__add(a, b)
	a, b = tocomplex(a), tocomplex(b)
	return m.new(a.re + b.re, a.im + b.im)
end

--- Subtraction metamethod.
function m.__sub(a, b)
	a, b = tocomplex(a), tocomplex(b)
	return m.new(a.re - b.re, a.im - b.im)
end

--- Multiplication metamethod.
function m.__mul(a, b)
	a, b = tocomplex(a), tocomplex(b)
	return m.new(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re)
end

--- Division metamethod.
-- @error Division by zero.
function m.__div(a, b)
	a, b = tocomplex(a), tocomplex(b)
	local d = b.re * b.re + b.im * b.im
	if d == 0 then
		error("Division by zero in complex division")
	end
	return m.new((a.re * b.re + a.im * b.im) / d, (a.im * b.re - a.re * b.im) / d)
end


--- Unary minus metamethod.
function m.__unm(a)
	a = tocomplex(a)
	return m.new(-a.re, -a.im)
end

-- -----------------------------------------
-- Pretty printing
-- -----------------------------------------


--- Convert to string in the form `a+bi`.
function m.__tostring(z)
	z = tocomplex(z)
	return string.format("%g%+gi", z.re, z.im)
end

-- -----------------------------------------
-- Additional functions
-- -----------------------------------------

--- Approximate equality (L¹ norm).
-- @param a complex
-- @param b complex
-- @param eps number optional tolerance
-- @return boolean
function m.isClose(a, b, eps)
    a, b = tocomplex(a), tocomplex(b)
    eps = eps or m.EPS

    local dr = abs(a.re - b.re)
    local di = abs(a.im - b.im)

    return dr + di <= eps  -- norme L1,  rapide
end


--- Compare unordered pairs with tolerance.
function m.isClosePair(a, b, c, d)
    return
        (m.isClose(a, c) and m.isClose(b, d)) or
        (m.isClose(a, d) and m.isClose(b, c))
end


--- Test whether two numbers are distinct (tolerant).
function m.distinct(a, b)
	a, b = tocomplex(a), tocomplex(b)
	return not m.isClose(a, b)
end


--- Test whether a complex number is nonzero (tolerant).
function m.nonzero(z)
	z = tocomplex(z)
	return m.distinct(z, 0)
end

--- Determinant
function m.det(a, b)
	a, b = tocomplex(a), tocomplex(b)
	return a.re * b.im - a.im * b.re
end

--- Scalar (dot) product.
function m.dot(a, b)
	a, b = tocomplex(a), tocomplex(b)
	return a.re * b.re + a.im * b.im
end

m.scal = m.dot

--- Normalize to unit modulus.
-- @return complex|nil nil if zero
function m.unit(z)
  z = tocomplex(z)
	local r = m.abs(z)
	if r < m.EPS then
		return nil
	end
	return z / r
end


--- Complex conjugate.
function m.conj(z)
	z = tocomplex(z)
	return m.new(z.re, -z.im)
end


--- Squared modulus.
function m.abs2(z)
	z = tocomplex(z)
	return z.re * z.re + z.im * z.im
end


--- Modulus.
function m.abs(z)
	z = tocomplex(z)
	return sqrt(z.re*z.re + z.im*z.im)
end


--- Argument (principal value).
-- Returns angle in radians in (-π, π].
function m.arg(z)
	z = tocomplex(z)
	return atan2(z.im, z.re)
end


--- Complex inversion in circle.
-- @param z complex
-- @param center complex optional
-- @param R number optional radius
function m.invert(z, center, R)
    z = tocomplex(z)
    center = tocomplex(center or m.ZERO)
    R = R or 1

    local dz = z - center
    local d2 = dz.re*dz.re + dz.im*dz.im
    assert(d2 > 0, "invert: undefined at center")
    local inv = m.new(dz.re/d2, -dz.im/d2)
    return center + (R*R) * inv
end

-- -----------------------------------------
-- Comparisons (methods, with optional tolerance)
-- -----------------------------------------


--- Approximate equality (method form).
function m:isNear(w, eps)
	return m.isClose(self, w, eps)
end


--- Negated approximate comparison (method form).
function m:isNot(w, eps)
	return not m.isClose(self, w, eps)
end

-- integer check, no tolerance
function m:isInteger()
    return self.im == 0 and self.re % 1 == 0
end

--- Test whether imaginary part is approx. zero (method form).
function m:isReal(eps)
	eps = eps or m.EPS
	return abs(self.im) <= eps
end

--- Test whether real part is approx. zero (method form).
function m:isImag(eps)
	eps = eps or m.EPS
	return abs(self.re) <= eps
end

-- Integer check with tolerance
function m:isNearInteger(eps)
    eps = eps or m.EPS
    if abs(self.im) > eps then
        return false
    end
    local nearest = math.floor(self.re + 0.5)
    return abs(self.re - nearest) <= eps
end


--- Test whether modulus is approx. 1 (method form).
function m:isUnit(eps)
	eps = eps or m.EPS
	local r = m.abs(self)
	return abs(r-1) < eps
end


--- Test approx. colinearity with other number (method form).
function m:isColinear(other, eps)
    eps = eps or m.EPS
    return abs(m.det(self, other)) <= eps
end


--- Convert to polar coordinates.
-- @return r number
-- @return theta number
function m:toPolar()
	return m.abs(self), m.arg(self)
	-- Note : returns (0,0) for origin
end

--- Clone the complex number.
function m:clone()
	return m.new(self.re, self.im)
end


--- e^{iθ}
function m.exp_i(theta)
	return m.new(cos(theta), sin(theta))
end


--- Rotate by 90 degrees.
function m:rotate90()
    return m.new(-self.im, self.re)
end


--- Rotate by angle θ (radians).
function m:rotate(theta)
    local c = cos(theta)
    local s = sin(theta)
    return m.new(c*self.re - s*self.im, s*self.re + c*self.im)
end




--- Complex exponential.
function m.exp(z)
	z = tocomplex(z)
	local exp_r = exp(z.re)
	return m.new(exp_r * cos(z.im), exp_r * sin(z.im))
end


--- Principal complex logarithm.
-- @error undefined for 0
function m.log(z)
	z = tocomplex(z)
	if z.re == 0 and z.im == 0 then
		error("Logarithm undefined for 0")
	end
	-- Note : other languages return -inf+0*i
	return m.new(log(m.abs(z)), m.arg(z))
end



-- fast integer power (binary exponentiation)
local function complex_pow_int(a, n)
    if n == 0 then
        return m.new(1, 0)
    end

    if n < 0 then
        a = m.new(1, 0) / a
        n = -n
    end

    local result = m.new(1, 0)
    while n > 0 do
        if n % 2 == 1 then
            result = result * a
        end
        a = a * a
        n = math.floor(n / 2)
    end

    return result
end

function m.__pow(a, b)
    a, b = tocomplex(a), tocomplex(b)

    -- Special cases
    if a == 0 and b == 0 then
        return m.ONE
    end
    if a == 0 and (b.re < 0 or b.im ~= 0) then
        error("0 cannot be raised to a negative or complex power")
    end
    if a == 0 then
        return m.ZERO
    end
    if b == 0 then
        return m.ONE
    end

    if b:isInteger() then
        return complex_pow_int(a, b.re)
    end

    -- (approx) integer exponent. Is rounding a good idea ?
    if b:isNearInteger() then
		local n = math.floor(b.re + 0.5)  -- round
		return complex_pow_int(a, n)
    end

    -- General complex power
    return m.exp(b * m.log(a))
end

-----------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------

--- 1 + 0i
m.ONE = m.new(1, 0)

--- 0 + 0i
m.ZERO = m.new(0, 0)

--- i
m.I = m.new(0, 1)

--- Primitive cube root of unity.
m.J = m.new(-1/2, sqrt(3)/2)

return m
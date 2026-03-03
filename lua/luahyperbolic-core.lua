-----------------------------------------------------------------------
-- @module luahyperbolic-core
-- Pure Lua hyperbolic geometry
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

local complex = require("complex")
local m = {}
m.module = "hyper"

-- ================ MESSAGES =====================

function m._error(msg)
    error("[ERROR] " .. msg, 2)
end

function m._assert(cond, msg)
	if not cond then
		m._error(msg)
	end
end


function m._assert_in_disk(...)
    local points = {...}
    for _, z in ipairs(points) do
        m._assert(m._in_disk(z), "POINT NOT IN OPEN DISK : " .. complex.__tostring(z))
    end
end

function m._assert_in_closed_disk(...)
    local points = {...}
    for _, z in ipairs(points) do
        m._assert(m._in_closed_disk(z), "POINT NOT IN CLOSED DISK : " .. complex.__tostring(z))
    end
end


function m._coerce_assert_in_disk(...)
    local points = {complex.coerce(...)}
    m._assert_in_disk(table.unpack(points))
    return table.unpack(points)
end

function m._coerce_assert_in_closed_disk(...)
    local points = {complex.coerce(...)}
    m._assert_in_closed_disk(table.unpack(points))
    return table.unpack(points)
end

-- ================= HELPERS (EUCLIDEAN GEOM AND OTHER)

-- precision
m.EPS = 1e-10

local random = math.random
local min = math.min
local max = math.max
local sin = math.sin
local cos = math.cos
local atan2 = math.atan2
local exp = math.exp
local log = math.log
local sqrt = math.sqrt
local abs = math.abs
local sinh = math.sinh
local cosh = math.cosh
local tanh = math.tanh

local atanh = function(x)
	return 0.5 * log((1 + x) / (1 - x))
end

local acosh = function(x)
    return log(x + sqrt(x*x - 1))
end

local asinh = function(x)
    return log(x + sqrt(x*x + 1))
end

-- public versions :
m.cosh = cosh
m.sinh = sinh
m.tanh = tanh
m.acosh = acosh
m.asinh = asinh
m.atanh = atanh




m._ensure_order = function (x, y, z, t)
	-- if the "distance" along the circle from x to y is larger than x to z, swap
	if complex.abs(x - y) > complex.abs(x - z) or complex.abs(t - z) > complex.abs(t - y) then
		return t, x
	else
		return x, t
	end
end



-- ==== EUCLIDEAN HELPERS

local euclid = {}
function euclid.interCC(c1, r1, c2, r2)
	local d = complex.abs(c2 - c1)
	if d < m.EPS then
		return nil
	end -- même si même rayon

	if d > r1 + r2 + m.EPS or d < abs(r1 - r2) - m.EPS then
		return nil -- no intersection
	end

	if abs(d - (r1 + r2)) < m.EPS or abs(d - abs(r1 - r2)) < m.EPS then
		local p = c1 + (c2 - c1) * (r1 / d)
		return p, p
	end

	local a = (r1 ^ 2 - r2 ^ 2 + d ^ 2) / (2 * d)
	local h = sqrt(max(r1 ^ 2 - a ^ 2, 0))
	local p_mid = c1 + ((c2 - c1) / d) * a
	local offset = complex(-(c2.im - c1.im) / d * h, (c2.re - c1.re) / d * h)

	return p_mid + offset, p_mid - offset
end

function euclid.interLC(z1, z2, c0, r)
	local dir = z2 - z1
	local f = z1 - c0
	local a = complex.abs2(dir)
	local b = 2 * (f.re * dir.re + f.im * dir.im)
	local c = complex.abs2(f) - r * r

	local disc = b * b - 4 * a * c
	if disc < -m.EPS then
		return nil
	end
	disc = max(disc, 0)

	local sqrtD = sqrt(disc)
	local t1 = (-b + sqrtD) / (2 * a)
	local t2 = (-b - sqrtD) / (2 * a)

	return z1 + dir * t1, z1 + dir * t2
end

-- ==============================

function m.randomPoint(rmin, rmax)
	-- returns random point in disk or annulus with uniform density
	rmax = rmax or 1 - m.EPS
	rmax = min(rmax, 1 - m.EPS)
	rmin = rmin or 0

	m._assert(rmin >= 0 and rmax > rmin, "randomPoint: require 0 ≤ rmin < rmax")

	local theta = 2 * math.pi * random()
	local u = random()
	local r = sqrt(u * (rmax ^ 2 - rmin ^ 2) + rmin ^ 2)

	return complex(r * cos(theta), r * sin(theta))
end

-- =========================================================
-- ==================== HYPERBOLIC CALCULUS ================
-- =========================================================

function m._in_disk(z)
	return complex.abs(z) < 1 - m.EPS
end

function m._in_closed_disk(z)
	return complex.abs(z) < 1 + m.EPS
end

function m._on_circle(z)
	return abs(complex.abs(z) - 1) < m.EPS
end

function m._in_half_plane(z)
	return z.im > m.EPS
end


--------------------

function m.radial_half(r)
	return r / (1 + sqrt(1 - r * r))
end

function m.radial_scale(r, t)
	return tanh(t * atanh(r))
end

function m._distance_to_origin(z)
	return 2 * atanh(complex.abs(z))
end

function m.distance(z, w)
	return m._distance_to_origin(m.automorphism(z, 0)(w))
end


function m._same_distance(A, B, C, D)
	local phiA = m.automorphism(A,0)
	local phiC = m.automorphism(C,0)
	local BB = phiA(B)
	local DD = phiC(D)
	return abs(complex.abs2(BB) - complex.abs2(DD)) < m.EPS
end

function m._midpoint_to_origin(z)
	local r = complex.abs(z)
	if r < m.EPS then
		return complex(0, 0)
	end
	return (z / r) * m.radial_half(r)
end

function m.midpoint(a, b)
	local u = m.automorphism(a, 0)(b)
	local u_half = m._midpoint_to_origin(u)
	return m.automorphism(-a, 0)(u_half)
end

function m._metric_factor(z)
	return 2 / (1 - complex.abs2(z))
end

function m.geodesic_data(z, w)
	m._assert(complex.distinct(z, w), "geodesic_data: points z and w are identical")

	local u = w - z
	local area = z.re * w.im - z.im * w.re -- signed!
	if abs(area) < m.EPS then -- points are aligned with origin
		return {
			type = "diameter",
			center = nil,
			radius = math.huge,
			direction = (u / complex.abs(u)),
		}
	end
	local d1 = (complex.abs2(z) + 1) / 2
	local d2 = (complex.abs2(w) + 1) / 2
	local cx = (d1 * w.im - z.im * d2) / area
	local cy = (z.re * d2 - d1 * w.re) / area
	local c = complex(cx, cy)
	local R = complex.abs(c - z)
	return {
		type = "circle",
		center = c,
		radius = R,
		direction = nil,
	}
end

function m.endpoints(a, b)
	m._assert(complex.distinct(a,b), "endpoints : points must be distinct")
  if abs(complex.det(a,b)) < 100*m.EPS then
		local dir = (a-b) / complex.abs(a-b)
		local e1, e2 = -dir, dir
		return m._ensure_order(e1, a, b, e2)
  end
  

	-- should be circle case. rewrite this
  
	local g = m.geodesic_data(a, b)
  assert(g.type=="circle", "endpoints : problem with branch diameter/circle")
	local c, R = g.center, g.radius
	local e1, e2 = euclid.interCC(c, R, complex(0, 0), 1)
	return m._ensure_order(e1, a, b, e2)
end

--[[
function m._same_geodesics(a, b, c, d)
    local aa, bb = m.endpoints(a, b)
    local cc, dd = m.endpoints(c, d)
    local sameSet = complex.isSamePair(aa,bb,cc,dd)
    return sameSet
end]]



function m.endpoints_perpendicular_bisector(A, B)
	m._assert(complex.distinct(A, B), "perpendicular_bisector: A and B must be distinct")

	local M = m.midpoint(A, B)
	local phi = m.automorphism(M, 0)
	local phi_inv = m.automorphism(-M, 0)
	local A1 = phi(A)
	local u = A1 / complex.abs(A1)
	local v = complex(-u.im, u.re)
	local e1 = v
	local e2 = -v
	return phi_inv(e1), phi_inv(e2)
end

function m.endpoints_angle_bisector(A, O, B)
	m._assert(complex.distinct(A, O) and complex.distinct(O, B), "angle_bisector: O must be distinct from A and B")

	local phi = m.automorphism(O, 0)
	local phi_inv = m.automorphism(-O, 0)

	local A1 = phi(A)
	local B1 = phi(B)

	local u1 = A1 / complex.abs(A1)
	local u2 = B1 / complex.abs(B1)

	local v = u1 + u2

	if v:isNear(0) then
		-- flat angle: perpendicular to common diameter
		local perp = complex(-u1.im, u1.re)
		return phi_inv(perp), phi_inv(-perp)
	end

	v = v / complex.abs(v)

	return phi_inv(v), phi_inv(-v)
end

function m._circle_to_euclidean(z0, r)
	-- returns euclidean center and radius of hyperbolic center and radius
	local rho = tanh(r / 2)
	local mod2 = complex.abs2(z0)
	local denom = 1 - rho * rho * mod2
	local c = ((1 - rho * rho) / denom) * z0
	local R = ((1 - mod2) * rho) / denom

	return c, R
end

function m.tangentVector(z, w)
	local v
	local g = m.geodesic_data(z, w)
	if g.radius == math.huge then
		v = w - z
	else
		local u = z - g.center
		v = complex(-u.im, u.re)
		if complex.scal(v, w - z) < 0 then
            v = -v
        end
	end
	return v
end

function m.angle(A, O, B)
	-- oriented angle
    local t1 = m.tangentVector(O, A)
    local t2 = m.tangentVector(O, B)
    return complex.arg(t2/t1)
end

-- =========== HYPERBOLIC ISOMETRES  =============

function m.automorphism(a, theta)
	a = complex(a.re, a.im) -- copie
	theta = theta or 0
	m._assert_in_disk(a)
	if complex.abs(a) < m.EPS then
		return function(x)
			return x
		end
	end
	local rot = complex.exp_i(theta)
	return function(z)
		z = z -- coercion automatique
		local numerator = z - a
		local denominator = 1 - complex.conj(a) * z
		return rot * (numerator / denominator)
	end
end

function m.rotation(center, theta)
	m._assert_in_disk(center)
	theta = theta or 0
	if abs(theta) < m.EPS then
		return function(x)
			return x
		end
	end
	local phi = m.automorphism(center, 0)
	local phi_inv = m.automorphism(-center, 0)
	local rot = complex.exp_i(theta)
	return function(z)
		return phi_inv(rot * phi(z))
	end
end

function m.symmetry(center)
	return m.rotation(center, math.pi)
end

function m.symmetryAroundMidpoint(a, b)
	return m.rotation(m.midpoint(a, b), math.pi)
end

function m.parabolic_fix1(theta) -- angle in rad
	local P = (1 - complex.exp_i(-theta)) / 2 -- preimage of zero
	local phi = m.automorphism(P, 0)
	local u = phi(1)
	return function(z)
		return phi(z) / u
	end
end

function m.parabolic(idealPoint, theta)
	m._assert(idealPoint:isUnit(), "parabolic : ideal point must be at infinity")
	return function(z)
		return idealPoint * m.parabolic_fix1(theta)(z / idealPoint)
	end
end

function m.automorphismSending(z, w)
	-- (hyperbolic)
	if z:isNear(w) then
		return function(x)
			return x
		end
	end
	local phi_z = m.automorphism(z, 0)
	local phi_w_inv = m.automorphism(-w, 0)

	return function(x)
		return phi_w_inv(phi_z(x))
	end
end

function m.automorphismFromPairs(A, B, imageA, imageB)
	m._assert(complex.distinct(A, B), "automorphism_from_pairs : startpoints must be different")
	m._assert(m._same_distance(A, B, imageA, imageB), "automorphism_from_pairs : distances don't match") -- or return nil ?

	if A:isNear(imageA) and B:isNear(imageB) then
		return function(z)
			return z
		end
	end

	local B1 = m.automorphism(A, 0)(B)
	local BB1 = m.automorphism(imageA, 0)(imageB)
	local u = complex.unit(BB1 / B1)

	return function(z)
		return m.automorphism(-imageA, 0)(u * m.automorphism(A, 0)(z))
	end
end

function m.rotationFromPair(O, A, imageA)
	return m.automorphismFromPairs(O, A, O, imageA)
end

function m.reflection(z1, z2)
	-- rewrite with automorphisms ? maybe  not
	local g = m.geodesic_data(z1, z2)

	if g.radius == math.huge then
		local dir = (z2-z1) / complex.abs(z2-z1)
		return function(z)
			local proj = (dir * complex.conj(z)).re * dir
			local perp = z - proj
			return proj - perp
		end
	else
		local c, R = g.center, g.radius
		return function(z)
			local u = z - c
			local v = (R * R) / complex.conj(u)
			return c + v
		end
	end
end


function m.projection(z1, z2)
	local refl = m.reflection(z1, z2)
	return function(z)
		local z_ref = refl(z)
		return m.midpoint(z, z_ref)
	end
end

function m.pointOrbit(point, func, n)
	local points = {}
	for _ = 1, n do
		point = func(point)
		table.insert(points, point)
	end
	return points
end


function m.mobiusTransformation(a, b, c, d)
	-- general Möbius transform
	return function(z)
		return (a * z + b) / (c * z + d)
	end
end

function m.distance_to_geodesic(z, z1, z2)
	local p = (m.projection(z1, z2))(z)
	return m.distance(z, p)
end

function m._on_geodesic(z, z1, z2, eps)
	eps = eps or m.EPS
	return m.distance_to_geodesic(z, z1, z2) < eps
end

-- ========== EXPONENTIAL MAPS (vector -> point) ==========

function m.exp_map_at_origin(v)
	-- input : vector, output : point
	local norm_v = complex.abs(v)
	if norm_v < m.EPS then
		return complex(0, 0)
	end
	return v / norm_v * tanh(norm_v / 2)
end

function m.exp_map(p, v)
	if complex.abs(v) < m.EPS then
		return p
	end
	local w = m.exp_map_at_origin(v)
	if complex.abs(p) < m.EPS then
		return w
	end
	return m.automorphism(-p, 0)(w)
end


-- ============  INTERPOLATE, BARYCENTERS OF 2 POINTS =====

function m.interpolate(a, b, t)
	if a:isNear(b) then return a end
	local phi = m.automorphism(a, 0)
	local phi_inv = m.automorphism(-a, 0)

	local u = phi(b)
	local r = complex.abs(u)
	if r < m.EPS then
		return a
	end

	local r_t = m.radial_scale(r, t)
	local u_t = u * (r_t / r)

	return phi_inv(u_t)
end

function m.barycenter2(a, wa, b, wb)
	local s = wa + wb
	m._assert(abs(s) > m.EPS, "barycenter2: sum of weights must not be zero")

	local t = wb / s
	return m.interpolate(a, b, t)
end



-- ============ INTERSECTIONS ==============================

function m.interLC(z1, z2, c0, r)
	local ce, Re = m._circle_to_euclidean(c0, r)
	local g = m.geodesic_data(z1, z2)
	if g.radius == math.huge then
		return euclid.interLC(complex(0, 0), g.direction, ce, Re)
	else
		return euclid.interCC(g.center, g.radius, ce, Re)
	end
end

function m.interCC(c1, r1, c2, r2)
	local C1, R1 = m._circle_to_euclidean(c1, r1)
	local C2, R2 = m._circle_to_euclidean(c2, r2)

	return euclid.interCC(C1, R1, C2, R2)
end

function m.interLL(z1, z2, w1, w2)
	local g1 = m.geodesic_data(z1, z2)
	local g2 = m.geodesic_data(w1, w2)
	local is_diam1 = (g1.radius == math.huge)
	local is_diam2 = (g2.radius == math.huge)

	if is_diam1 and is_diam2 then
		local u = g1.direction
		local v = g2.direction

		local dot = u.re * v.re + u.im * v.im
		if abs(abs(dot) - 1) < m.EPS then
			return nil
		end

		return complex(0, 0)
	end

	if is_diam1 and not is_diam2 then
		local line_p1 = complex(0, 0)
		local line_p2 = g1.direction
		return euclid.interLC(line_p1, line_p2, g2.center, g2.radius)
	end

	if not is_diam1 and is_diam2 then
		local line_p1 = complex(0, 0)
		local line_p2 = g2.direction
		return euclid.interLC(line_p1, line_p2, g1.center, g1.radius)
	end

	local p1, p2 = euclid.interCC(g1.center, g1.radius, g2.center, g2.radius)

	if not p1 then
		return nil
	end

	local inside1 = m._in_disk(p1)
	local inside2 = m._in_disk(p2)

	if inside1 and not inside2 then
		return p1
	elseif inside2 and not inside1 then
		return p2
	else
		return nil
	end
end

----------------------------------
-- TRIANGLE GEOMETRY
---------------------------------

function m.triangleCentroid(A, B, C)
	-- Intersection des trois médianes.
	-- /!\ Pas au deux tiers des médianes
	local AA = m.midpoint(B, C)
	local BB = m.midpoint(C, A)
	local centroid = m.interLL(A, AA, B, BB)
	return centroid
end


function m.triangleIncenter(A, B, C)
	m._assert(
		complex.distinct(A, B) and complex.distinct(B, C) and complex.distinct(C, A),
		"incenter: points must be distinct"
	)

	local e1, e2 = m.endpoints_angle_bisector(A, B, C)
	local f1, f2 = m.endpoints_angle_bisector(B, C, A)
	return m.interLL(e1, e2, f1, f2)
end

----------------
-- CAUTION : orthocenter and circumcenter do not always exist

function m.triangleCircumcenter(A, B, C)
	-- WARNING returns circumcenter or nil
	m._assert(
		complex.distinct(A, B) and complex.distinct(B, C) and complex.distinct(C, A),
		"circumcenter: points must be distinct"
	)

	local e1, e2 = m.endpoints_perpendicular_bisector(A, B)
	local f1, f2 = m.endpoints_perpendicular_bisector(A, C)

	return m.interLL(e1, e2, f1, f2) -- can be nil
end


function m.triangleOrthocenter(A,B,C)
	-- Faster than projecting, no midpoint:
	local AA = m.reflection(B,C)(A)
	local BB = m.reflection(C,A)(B)
	return m.interLL(A,AA,B,BB) -- can be nil
end


return m
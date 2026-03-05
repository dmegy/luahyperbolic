local complex = require("complex")
local core = require("luahyperbolic-core")
local tikz = require("luahyperbolic-tikz")
local m = {}

m.module = "luahyperbolic-tilings"

-- for quantization (geodesic propagation)
m.QUANTIZATION_SCALE = 1e9

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




local function _quantize(x)
    return math.floor(x * m.QUANTIZATION_SCALE + 0.5)
end


local function _quantize_normalize_pair(a, b)

    local ar = _quantize(a.re)
    local ai = _quantize(a.im)
    local br = _quantize(b.re)
    local bi = _quantize(b.im)

    -- lexicographic sort on integers
    if br < ar or (br == ar and bi < ai) then
        ar, br = br, ar
        ai, bi = bi, ai
    end

    return ar .. ":" .. ai .. ":" .. br .. ":" .. bi
end


-- ================== TILINGS ==============

-- TODO : function triangleWithAngles(alpha,beta,gamma)

function m.fundamentalRightTriangle(p, q)
	-- returns right triangle A=0, B, C with angles
	-- alpha = pi/2, beta = pi/p, gamma = pi/q
    core._assert(1/p + 1/q < 0.5, "triangle must be hyperbolic")
    
    local beta = math.pi / p
    local gamma  = math.pi / q

    -- hyperbolic side lengths opposite angles
    local u = core.acosh(math.cos(gamma) / math.sin(beta))
    local v = core.acosh(math.cos(beta)  / math.sin(gamma))

    -- convert hyperbolic lengths to Euclidean radii in disk
    local r = math.tanh(u / 2)
    local s = math.tanh(v / 2)

    core._assert(r > 0 and r < 1, "B not inside disk")
    core._assert(s > 0 and s < 1, "C not inside disk")

    local A = complex(0, 0)
    local B = complex(r, 0)
    local C = complex(0, s)

    return A, B, C
end

function m.fundamentalIdealTriangle(p, q)
    core._assert(p >= 2 and q >= 2,
        "fundamentalIdealTriangle: p,q >= 2")

    local alpha = math.pi / p
    local beta  = math.pi / q

    local A = complex(0, 0)
    local C = complex(1, 0)

    -- Compute K
    local K = (math.cos(alpha)*math.cos(beta) + 1) /
              (math.sin(alpha)*math.sin(beta))

    local r2 = (K - 1) / (K + 1)
    local r = math.sqrt(r2)

    -- B in direction alpha
    local B = r* complex.exp_i(alpha)

    return A, B, C
end


-- TODO : use better algorithm... use the group and work with words
function m.propagateGeodesics(geodesics, depth, MAX_ENDPOINT_DISTANCE)
    MAX_ENDPOINT_DISTANCE = MAX_ENDPOINT_DISTANCE or 0.01
    core._assert(#geodesics > 1, "must have at least 2 geodesics")

    local reflections = {}
    for i, side in ipairs(geodesics) do
        reflections[i] = core.reflection(side[1], side[2])
    end

    local seen = {}
    local frontier = {}

    for i, g in ipairs(geodesics) do
        local key = _quantize_normalize_pair(g[1], g[2])
        if not seen[key] then
            seen[key] = true
            frontier[#frontier + 1] = {
                p1 = g[1],
                p2 = g[2],
                last = nil   -- no reflection yet
            }
        end
    end

    for _ = 1, depth do
        local new_frontier = {}
        for _, g in ipairs(frontier) do
            for i, refl in ipairs(reflections) do
                -- avoid immediate inverse reflection
                if g.last ~= i then
                    local p1_new = refl(g.p1)
                    local p2_new = refl(g.p2)
                    if complex.abs(p1_new - p2_new) > MAX_ENDPOINT_DISTANCE then
                        local key = _quantize_normalize_pair(p1_new, p2_new)
                        if not seen[key] then
                            seen[key] = true

                            new_frontier[#new_frontier + 1] = {
                                p1 = p1_new,
                                p2 = p2_new,
                                last = i
                            }
                        end
                    end
                end
            end
        end

        for _, g in ipairs(new_frontier) do
            geodesics[#geodesics + 1] = { g.p1, g.p2 }
        end
        frontier = new_frontier
    end
    return geodesics
end



-- ====================== MODULE END

return m

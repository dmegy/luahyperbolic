
-- ============ BEGIN MODULE "LUAGYPERBOLIC-TILINGS" ============

local complex = require("complex")
local core = require("luahyperbolic-core")
local tikz = require("luahyperbolic-tikz")
local m = {}

m.module = "luahyperbolic-tilings"

-- for quantization (geodesic propagation)
m.QUANTIZATION_SCALE = 1e9

local PI = 3.1415926535898
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

    for _, g in ipairs(geodesics) do
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


function m.fillTilingFromTriangle(A, B, C, depth, options)
    -- fills with "even odd rule"
    options = options or "black"
    local geodesics = {
        {core.endpoints(A,B)},
        {core.endpoints(B,C)},
        {core.endpoints(C,A)}
    }
    geodesics = m.propagateGeodesics(geodesics, depth)
    local shapes = {}
    for _,pair in ipairs(geodesics) do
        table.insert(shapes,tikz.tikz_shape_closed_line(pair[1], pair[2]))
    end
    local shapes_string = table.concat(shapes, " ")
    tikz.tikzPrintf(
        "\\fill[even odd rule, %s] (0,0) circle (1) %s ;",
        options,
        shapes_string
    )
end

function m.drawTilingFromTriangle(A, B, C, depth, options)
    options = options or "black"
    local geodesics = {
        {core.endpoints(A,B)},
        {core.endpoints(B,C)},
        {core.endpoints(C,A)}
    }
    geodesics = m.propagateGeodesics(geodesics, depth)
    local shapes = {}
    for _,pair in ipairs(geodesics) do
        table.insert(shapes,tikz.tikz_shape_segment(pair[1], pair[2]))
    end
    local shapes_string = table.concat(shapes, " ")
    tikz.tikzPrintf(
        "\\draw[%s] (0,0) circle (1) %s ;",
        options,
        shapes_string
    )
end

function m.drawTilingFromAngles(alpha, beta, gamma, depth, options)
    local A, B, C = core.triangleWithAngles(alpha, beta, gamma)
    m.drawTilingFromTriangle(A, B, C, depth, options)
end

function m.fillTilingFromAngles(alpha, beta, gamma, depth, options)
    local A, B, C = core.triangleWithAngles(alpha, beta, gamma)
    m.fillTilingFromTriangle(A, B, C, depth, options)
end


-- ============ END MODULE "TILINGS" ============

return m

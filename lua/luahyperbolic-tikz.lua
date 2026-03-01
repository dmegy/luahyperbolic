local complex = require("complex")
local core = require("luahyperbolic-core")
local m = {}

for k,v in pairs(core) do
    m[k] = v
end

m.module = "hyperbolic-tikz"

-- ========= REDEFINE ERROR (TeX error) =====================

function m.error(msg)
	tex.error("Package " .. m.module .. " Error ", { msg })
end

function m.warning(msg)
	texio.write_nl("[WARNING] " .. msg)
end

-- ================= HELPERS (EUCLIDEAN GEOM AND OTHER)

-- precision
m.DRAW_EPS_INV = 1e6
m.DRAW_EPS = 1/m.DRAW_EPS_INV

-- for quantization (geodesic propagation)

m.SCALE = 1e9
local function quantize(x)
    return math.floor(x * m.SCALE + 0.5)
end


local function quantize_normalize_pair(a, b)

    local ar = quantize(a.re)
    local ai = quantize(a.im)
    local br = quantize(b.re)
    local bi = quantize(b.im)

    -- lexicographic sort on integers
    if br < ar or (br == ar and bi < ai) then
        ar, br = br, ar
        ai, bi = bi, ai
    end

    return ar .. ":" .. ai .. ":" .. br .. ":" .. bi
end


-- put in module ?
local function isPairInTable(pair, tableOfPairs)
    for _, existing in ipairs(tableOfPairs) do
        if complex.isClosePair(
            pair[1], pair[2],
            existing[1], existing[2]
        ) then
            return true
        end
    end
    return false
end


local function parse_points_with_options(...)
	-- errors if no point provided
	local args = { ... }
	local n = #args
	local options = ""

	if n >= 1 and type(args[n]) == "string" then
		options = args[n]
		n = n - 1
	end

	local points = {}
	for i = 1, n do
		points[i] = args[i]
	end

	m.assert(#points > 0, "parse_points_with_options : no points provided")

	return points, options
end

-- TikZ API --------------------------------
m.tikzOptions = ""
m.tikzBuffer = {}
m.tikzNbPicturesExported = 0
m.TIKZ_CLIP_DISK = true
m.TIKZ_BEGIN_DISK = [[
\draw[very thick] (0,0) circle (1);
\clip (0,0) circle (1);
]]

function m.tikzGetFirstLines()
	local firstLines = string.format(
		"\\begin{tikzpicture}[%s]\n",
		m.tikzOptions
	)
	if m.TIKZ_CLIP_DISK then
		firstLines = firstLines .. m.TIKZ_BEGIN_DISK
	end
	return firstLines
end

function m.tikzBegin(options)
	-- without drawing circle and clipping disk
	m.tikzOptions = options or "scale=3"
	tex.print(m.tikzGetFirstLines())
	m.tikzClearBuffer()
end


function m.tikzClearBuffer()
	m.tikzBuffer = {}
end


function m.tikzExport(filename)
	-- works even without filename, for automated exports
	m.tikzNbPicturesExported = m.tikzNbPicturesExported+1
	filename = filename or "hyper_picture_" ..m.tikzNbPicturesExported .. ".tikz"
	local f = io.open(filename, "w")
	f:write(m.tikzGetFirstLines())
	for _, line in ipairs(m.tikzBuffer) do
	  f:write(line, "\n")
	end
	f:write("\\end{tikzpicture}\n")
	f:close()
	-- doesn't clear buffer, do it manually if wanted
	-- can be used to export different steps of the same picture
end


function m.tikzEnd(filename)
	tex.print("\\end{tikzpicture}")
	if filename ~= nil then
		m.tikzExport(filename)
	end
	m.tikzClearBuffer()
end


function m.tikzPrintf(fmt, ...)
	local line = string.format(fmt, ...)
    tex.print(line)
    table.insert(m.tikzBuffer, line)
end

function m.tikz_define_nodes(table)
	for name, z in pairs(table) do
		m.assert(z ~= nil, "nil point for " .. name)
		m.assert(z.re ~= nil and z.im ~= nil, "not a complex for " .. name)
		m.tikzPrintf("\\coordinate (%s) at (%f,%f);", name, z.re, z.im)
	end
end

-- ==== DRAW POINT(S) ===============

m.DRAW_POINT_RADIUS = 0.02 -- can be modified by user

function m.drawPoint(z, options)
	options = options or ""
	-- accept nil point (circumcenter can be nil)
	if z == nil then
		m.warning("drawPoint : point is nil, aborting")
		return
	end
	m.assert(complex.abs(z) <= 1+m.EPS, "drawPoint : point outside closed disk: " .. complex.__tostring(z))
	m.tikzPrintf("\\fill[%s] (%f,%f) circle (%s);", options, z.re, z.im, m.DRAW_POINT_RADIUS)
end


function m.drawPoints(...)
	local points, options = parse_points_with_options(...)

	for i = 1, #points do
		m.drawPoint(points[i], options)
	end
end

function m.drawPointOrbit(point, func, n, options)
	-- draws n points. Doesn't draw original point
	options = options or "black"
	local points = {}
	for _ = 1, n do
		point = func(point)
		table.insert(points, point)
	end

	for i, z in ipairs(points) do
		local alpha = i / #points
		m.drawPoint(z, options .. ", fill opacity=" .. alpha)
	end
end

-- ===== DRAW LINES, SEGMENTS ETC ========

function m.drawSegment(z, w, options)
	options = options or ""
	m.assert(z:isNot(w), "points must be distinct")
	local shape = m.shape_segment(z,w)
	m.tikzPrintf("\\draw[%s] %s;",options, shape)
end

function m.shape_segment(z, w)
	m.assert(z:isNot(w), "points must be distinct")
	local g = m.geodesic_data(z, w)

	-- If the geodesic is (almost) a diameter, draw straight segment
	if g.radius == math.huge or g.radius > 100 then
		return string.format("(%f,%f)--(%f,%f)", z.re, z.im, w.re, w.im)
	else
		local a1 = complex.arg(z - g.center)
		local a2 = complex.arg(w - g.center)
		local delta = math.atan2(math.sin(a2 - a1), math.cos(a2 - a1))
		local a_end = a1 + delta
		local deg = 180 / math.pi
		return string.format(
			"(%f,%f) ++(%f:%f) arc (%f:%f:%f)",
			g.center.re,
			g.center.im,
			a1 * deg,
			g.radius,
			a1 * deg,
			a_end * deg,
			g.radius
		)
	end
end



function m.shape_closed_line(a,b)
	-- todo : add "close" flag to decide if we close diameters ? 
	m.assert(a:isNot(b), "points must be distinct")
	if not a:isUnit() or not b:isUnit() then
		a, b = m.endpoints(a,b)
	end
	if a:isNear(-b) then
		-- WARNING :  HACK : close diameter as rectangle ! 
		-- (for filling with even-odd rule)
		local factor = 1.1
		a, b = factor*a, factor*b
		local c, d = b*complex(1,-1), a * complex(1,1)
		return  string.format("(%f,%f) -- (%f,%f) -- (%f,%f) -- (%f,%f) -- cycle ",
			a.re, a.im, b.re, b.im, c.re, c.im, d.re, d.im)
	else
		local c = 2*a*b/(a+b)
		local r = complex.abs(c-a)
		-- rest of the circle will be clipped 
		return  string.format("(%f,%f) circle (%f)", c.re, c.im, r)
		
	end
end



function m.drawLine(a, b, options)
	m.assert(not a:isNear(b), "drawLine : points must be distinct")
	options = options or ""
	local end_a, end_b = m.endpoints(a,b)

	local shape = m.shape_segment(end_a,end_b)
	m.tikzPrintf("\\draw[%s] %s;", options, shape)
end


function m.drawLinesFromTable(pairs, options)
	options = options or ""
	for _, pair in ipairs(pairs) do
		m.drawLine(pair[1], pair[2], options)
	end
end

function m.drawPerpendicularThrough(P,A,B,options)
	-- perpendicular through P to (A,B)
	options = options or ""
	m.assert_in_disk(A)
	m.assert_in_disk(B)
	m.assert_in_disk(P)
	m.assert(A:isNot(B), "A and B must be distinct")
	local H = m.projection(A,B)(P)
	m.assert(P:isNot(H), "point must not be on line")
	-- todo : fix this : should be ok.
	m.drawLine(P,H,options)
end


function m.drawPerpendicularBisector(A, B, options)
	options = options or ""

	m.assert(A:isNot(B), "drawPerpendicularBisector: A and B must be distinct")

	local e1, e2 = m.endpoints_perpendicular_bisector(A, B)
	m.drawLine(e1, e2, options)
end

function m.drawAngleBisector(A, O, B, options)
	options = options or ""

	m.assert(complex.distinct(O,A) and complex.distinct(O,B),
		"angle_bisector: O must be distinct from A and B")

	local e1, e2 = m.endpoints_angle_bisector(A, O, B)
	m.drawLine(e1, e2, options)
end

-- Draw a hyperbolic ray from two points: start at p1, through p2
function m.drawRayFromPoints(p1, p2, options)
	options = options or ""
	local _, e2 = m.endpoints(p1, p2) -- e2 is the "ahead" endpoint
	m.drawSegment(p1, e2, options)
end

m.drawRay = m.drawRayFromPoints

-- Draw a hyperbolic ray from a start point p along a tangent vector v
function m.drawRayFromVector(p, v, options)
	options = options or ""
	local q = m.exp_map(p, v) -- move along v in hyperbolic space
	local _, e2 = m.endpoints(p, q)
	m.drawSegment(p, e2, options)
end

function m.drawLineFromVector(p, v, options)
	options = options or ""
	local q = m.exp_map(p, v) -- move along v in hyperbolic space
	m.drawLine(p, q, options)
end

function m.drawTangentAt(center, point, options)
	-- draw tangent line of circle of center 'center' passing through 'point'
	options = options or ""
	local Q = m.rotation(point, math.pi / 2)(center)
	m.drawLine(point, Q, options)
end

-- function m.drawTangentFrom(center, radius, point)
	-- TODO !
--	return
-- end

-- ==== VECTORS =============


function m.shape_euclidean_segment(a,b)
	return string.format(
			"(%f,%f) -- (%f,%f)",a.re, a.im, b.re, b.im)
end

function m.drawTangentVector(p, v, options)
	options = options or ""
	local norm_v = complex.abs(v)
	m.assert(norm_v > m.EPS, "drawTangentVector : vector must not be zero")
	local u = v / norm_v
	local factor = (1 - complex.abs2(p))
	local euclid_vec = math.tanh(factor * norm_v / 2) * u
    local shape = m.shape_euclidean_segment(p, p+euclid_vec)
	m.tikzPrintf("\\draw[->,%s] %s;",options,shape)
end

-- ============= FOR CONVENIENCE (draw multiple objets/segments etc

function m.drawLines(...)
	local points, options = parse_points_with_options(...)
	m.assert(#points % 2 == 0, "drawLines expects  an even number of points, got " .. #points)

	for i = 1, #points, 2 do
		m.drawLine(points[i], points[i + 1], options)
	end
end

function m.drawSegments(...)
	local points, options = parse_points_with_options(...)

	m.assert(#points % 2 == 0, "drawSegments expects  an even number of points, got " .. #points)

	for i = 1, #points, 2 do
		m.drawSegment(points[i], points[i + 1], options)
	end
end

function m.drawTriangle(...)
	local points, options = parse_points_with_options(...)

	m.assert(#points == 3, "drawTriangle expects exactly 3 points, got " .. #points)

	local a, b, c = points[1], points[2], points[3]
	m.drawSegment(a, b, options)
	m.drawSegment(b, c, options)
	m.drawSegment(c, a, options)
end

-- Draw a polyline from a table of points (open chain)
function m.drawPolySegFromTable(points, options)
	options = options or ""
	m.assert(#points >= 2, "drawPolySegFromTable expects at least 2 points, got " .. #points)

	for i = 1, #points - 1 do
		m.drawSegment(points[i], points[i + 1], options)
	end
end

function m.drawPolySeg(...)
	local points, options = parse_points_with_options(...)
	m.assert(#points >= 2, "drawPolySeg expects at least 2 points, got " .. #points)
	m.drawPolySegFromTable(points, options)
end

m.drawPolylineFromTable = m.drawPolySegFromTable
m.drawPolyline = m.drawPolySeg

function m.drawPolygonFromTable(points, options)
	options = options or ""
	m.assert(#points >= 2, "drawPolygonFromTable expects at least 2 points, got " .. #points)

	for i = 1, #points do
		local z = points[i]
		local w = points[i % #points + 1] -- wrap around to first point
		m.drawSegment(z, w, options)
	end
end

function m.drawPolygon(...)
	local points, options = parse_points_with_options(...)

	-- a 2-gon is a polygon
	m.assert(#points >= 2, "drawPolygon expects at least 2 points, got " .. #points)
	m.drawPolygonFromTable(points, options)
end

function m.drawRegularPolygon(center, point, nbSides, options)
	options = options or ""
	m.assert(nbSides>1, "drawRegularPolygon : expects >=2 sides, got " .. nbSides)
	m.assert_in_disk(center)
	m.assert_in_disk(point)
	m.assert(complex.distinct(center, point), "drawRegularPolygon : center and point must be distinct")
	local rot = m.rotation(center, 2*math.pi/nbSides)
	local vertices = {}
	for k=1,nbSides do
		point = rot(point)
		table.insert(vertices, point)
	end
	m.drawPolygonFromTable(vertices, options)
end

-- ====== DRAW CIRCLES, SEMICIRCLES, ARCS ==========

function m.drawCircleRadius(z0, r, options)
	options = options or ""
	local c, R = m.circle_to_euclidean(z0, r)

	m.tikzPrintf("\\draw[%s] (%f,%f) circle (%f);", options, c.re, c.im, R)
end
m.drawCircle = m.drawCircleRadius

function m.drawCircleThrough(center, point, options)
	options = options or ""
	local r = m.distance(center, point)
	m.drawCircle(center, r, options)
end

function m.drawIncircle(A, B, C, options)
	options = options or ""
	local I = m.triangleIncenter(A, B, C)
	local a = m.projection(B, C)(I)
	m.drawCircleThrough(I, a, options)
end

function m.drawCircumcircle(A, B, C, options)
	options = options or ""
	local O = m.triangleCircumcenter(A, B, C)
	if O ~= nil then
		m.drawCircleThrough(O,A, options)
	else
		m.warning("drawCircumcircle : circumcenter does not exist")
	end
end



function m.drawArc(O, A, B, options)
	options = options or ""

	-- Check points are on same hyperbolic circle
	local rA = m.distance(O, A)
	local rB = m.distance(O, B)
	m.assert(math.abs(rA - rB) < m.EPS, "drawArc: points A and B are not on the same hyperbolic circle")

	local c, R = m.circle_to_euclidean(O, rA)

	-- Compute angles of A and B on the Euclidean circle
	local function angleOnCircle(p)
		return math.deg(math.atan2(p.im - c.im, p.re - c.re)) % 360
	end
	local a1 = angleOnCircle(A)
	local a2 = angleOnCircle(B)

	-- Keep increasing angles: TikZ arc goes from a1 to a2
	-- If a2 < a1, TikZ automatically interprets end > start as crossing 0°
	if a2 < a1 then
		a2 = a2 + 360
	end

	m.tikzPrintf("\\draw[%s] (%f,%f) ++(%f:%f) arc (%f:%f:%f);", options, c.re, c.im, a1, R, a1, a2, R)
end

function m.drawSemicircle(center, startpoint, options)
	options = options or ""
	local endpoint = (m.symmetry(center))(startpoint)
	m.drawArc(center, startpoint, endpoint, options)
end

function m.drawAngle(A, O, B, options, distFactor)
	distFactor = distFactor or 1/4
	options = options or ""
	m.assert_in_disk(A)
	m.assert_in_disk(O)
	m.assert_in_disk(B)

	local dOA = m.distance(O,A)
	local dOB = m.distance(O,B)
	local minDist = math.min(dOA,dOB)
	local radius= minDist*distFactor
	local AA = m.interpolate(O,A,radius / dOA)
	local BB = m.interpolate(O,B,radius/ dOB)
	m.drawArc(O,AA,BB, options)
end

function m.drawRightAngle(A, O, B, options, distFactor)
	-- assumes angle(AOB) = +90 deg !
	distFactor = distFactor or 1/5
	options = options or ""
	m.assert_in_disk(A)
	m.assert_in_disk(O)
	m.assert_in_disk(B)
	local dOA = m.distance(O,A)
	local dOB = m.distance(O,B)
	local minDist = math.min(dOA, dOB)
	local radius = minDist*distFactor
	local AA = m.interpolate(O,A,radius / dOA)
	local BB = m.interpolate(O,B,radius / dOB)

	local v = m.tangentVector(AA,A)*complex.I
	local w = m.tangentVector(BB,B)*(-complex.I)
	local VV = m.exp_map(AA,v)
	local WW = m.exp_map(BB,w)
	local P = m.interLL(AA,VV, BB, WW)
	-- fast&lazy : euclidean polyline instead of geodesic:
	m.tikzPrintf("\\draw[%s] (%f,%f) -- (%f,%f) -- (%f,%f);",
		options,
		AA.re, AA.im,
		P.re, P.im,
		BB.re, BB.im
	)
end


-- ====== HOROCYCLES =======================

function m.drawHorocycle(idealPoint, point, options)
	options = options or ""

	m.assert(complex.isClose(complex.abs(idealPoint), 1), "drawHorocycle: ideal point must be on unit circle")
	m.assert(m.in_disk(point), "drawHorocycle: second point must be in disk")
	-- rotate :
	local w = point / idealPoint
	local x, y = w.re, w.im
	-- compute center and radius
	local a = (x ^ 2 + y ^ 2 - 1) / (2 * (x - 1))
	local r = math.abs(a - 1)
	local center = complex.new(a, 0)
	-- rotate back
	center = center * idealPoint

	m.tikzPrintf("\\draw[%s] (%f,%f) circle (%f);", options, center.re, center.im, r)
end

-- ===== LABEL OBJETS ==================

function m.drawLabeledPoint(z, options, label, label_options)
	options = options or ""
	m.tikzPrintf("\\fill[%s] (%f,%f) circle (0.02) node[%s]{%s};", options, z.re, z.im, label_options, label)
end

function m.labelPoint(z, label, options)
	options = options or "above left"
	-- accept nil point (circumcenter can be nil)
	if z == nil then
		m.warning("labelPoint : point is nil, aborting")
		return
	end
	m.tikzPrintf("\\node[%s] at (%f,%f) {%s};", options, z.re, z.im, label)
end

function m.labelPoints(...)
	local args = { ... }
	local n = #args
	local options = "above left"

	if n >= 3 and type(args[n]) == "string" and (n % 2 == 1) then
		options = args[n]
		n = n - 1
	end

	m.assert(n % 2 == 0, "labelPoints expects pairs: (point, label)")

	for i = 1, n, 2 do
		m.labelPoint(args[i], args[i + 1], options)
	end
end


-- ================== TILINGS ==============

-- TODO : function triangleWithAngles(alpha,beta,gamma)

function m.fundamentalRightTriangle(p, q)
	-- returns right triangle A=0, B, C with angles
	-- alpha = pi/2, beta = pi/p, gamma = pi/q
    m.assert(1/p + 1/q < 0.5, "triangle must be hyperbolic")
    
    local beta = math.pi / p
    local gamma  = math.pi / q

    -- hyperbolic side lengths opposite angles
    local u = m.acosh(math.cos(gamma) / math.sin(beta))
    local v = m.acosh(math.cos(beta)  / math.sin(gamma))

    -- convert hyperbolic lengths to Euclidean radii in disk
    local r = math.tanh(u / 2)
    local s = math.tanh(v / 2)

    m.assert(r > 0 and r < 1, "B not inside disk")
    m.assert(s > 0 and s < 1, "C not inside disk")

    local A = complex(0, 0)
    local B = complex(r, 0)
    local C = complex(0, s)

    return A, B, C
end

function m.fundamentalIdealTriangle(p, q)
    m.assert(p >= 2 and q >= 2,
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

function m.propagate_geodesics(geodesics, depth, MAX_ENDPOINT_DISTANCE)
    MAX_ENDPOINT_DISTANCE = MAX_ENDPOINT_DISTANCE or 0.01
    m.assert(#geodesics > 1, "must have at least 2 geodesics")

    local reflections = {}
    for i, side in ipairs(geodesics) do
        reflections[i] = m.reflection(side[1], side[2])
    end

    local seen = {}
    local frontier = {}

    for i, g in ipairs(geodesics) do
        local key = quantize_normalize_pair(g[1], g[2])
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
                        local key = quantize_normalize_pair(p1_new, p2_new)
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

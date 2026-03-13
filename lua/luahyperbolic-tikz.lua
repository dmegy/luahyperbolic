
-- ============ BEGIN MODULE "LUAHYPERBOLIC-TIKZ" ============

local complex = require("complex")
local core = require("luahyperbolic-core")
local m = {}

m.module = "luahyperbolic-tikz"

m.TIKZ_CLIP_DISK = true -- can be modified by user.
m.TIKZ_BEGIN_DISK = [[
\begin{scope}
\clip (0,0) circle (1);
]]

m.GEODESIC_STYLE = "black"
m.CIRCLE_OSTYLE = "black"
m.HOROCYCLE_OSTYLE = "black"
m.HYPERCYCLE_STYLE = "black"
m.ANGLE_STYLE = "black"
m.MARKING_STYLE = "black"
m.LABEL_STYLE = "above left"


m._DRAW_POINT_DEFAULT_RADIUS = 0.02
m._DRAW_POINT_DEFAULT_STYLE = "white, draw=black"

m.DRAW_POINT_RADIUS = m._DRAW_POINT_DEFAULT_RADIUS -- can be modified by user
m.DRAW_POINT_STYLE = m._DRAW_POINT_DEFAULT_STYLE -- can be modified by user

m.DRAW_ANGLE_DIST = 1/5

m._DRAW_STYLE_BOUNDARY_CIRCLE = "very thick, black"



-- ========= REDEFINE ERROR (TeX error) 

function m._error(msg)
	tex.error("Package " .. m.module .. " Error ", { msg })
end

function m._warning(msg)
	texio.write_nl("[WARNING] " .. msg)
end

-- ========= HELPERS (EUCLIDEAN GEOM AND OTHER)

local PI = 3.1415926535898
local deg = math.deg
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


local function euclidean_circumcenter(a, b, c)
	a, b, c = complex.coerce(a, b, c)
    core._assert(abs(complex.det(b-a,c-a)) > core.EPS, "points must not be aligned")
    local ma2 = complex.abs2(a)
    local mb2 = complex.abs2(b)
    local mc2 = complex.abs2(c)
    local num = a*(mb2 - mc2) + b*(mc2 - ma2) + c*(ma2 - mb2)
    local den = a*complex.conj(b - c) + b*complex.conj(c - a) + c*complex.conj(a - b)

    return num / den
end




local function parse_points_with_options(...)
	-- errors if no point provided
	local args = { ... }
	local n = #args
	local options = nil

	if n >= 1 and type(args[n]) == "string" then
		options = args[n]
		n = n - 1
	end

	local points = {}
	for i = 1, n do
		points[i] = args[i]
	end

	core._assert(#points > 0, "parse_points_with_options : no points provided")

	return points, options
end


-- ========== TikZ API 

m.tikzpictureOptions = ""
m.tikzBuffer = {}
m.tikzNbPicturesExported = 0


function m.tikzGetFirstLines()
	local firstLines = string.format(
		"\\begin{tikzpicture}[%s]\n",
		m.tikzpictureOptions
	)
	if m.TIKZ_CLIP_DISK then
		firstLines = firstLines .. m.TIKZ_BEGIN_DISK
	end
	return firstLines
end

function m.tikzBegin(options)
	-- without drawing circle and clipping disk
	m.tikzpictureOptions = options or "scale=3"
	tex.print(m.tikzGetFirstLines())
	m.tikzClearBuffer()
	-- reset point styles:
	m.DRAW_POINT_RADIUS = m._DRAW_POINT_DEFAULT_RADIUS
	m.DRAW_POINT_STYLE = m._DRAW_POINT_DEFAULT_STYLE

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
	f:write("\\end{scope}\n")
	f:write("\\draw[".. m._DRAW_STYLE_BOUNDARY_CIRCLE .."] (0,0) circle (1);\n")
	f:write("\\end{tikzpicture}\n")
	f:close()
	-- doesn't clear buffer, do it manually if wanted
	-- can be used to export different steps of the same picture
end


function m.tikzEnd(filename)
	tex.print("\\end{scope}")
	tex.print("\\draw[".. m._DRAW_STYLE_BOUNDARY_CIRCLE .."] (0,0) circle (1);")
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

function m.tikzDefineNodes(table)
	-- table of complex numbers
	for name, z in pairs(table) do
		core._assert(z ~= nil, "nil point for " .. name)
		core._assert(z.re ~= nil and z.im ~= nil, "not a complex for " .. name)
		m.tikzPrintf("\\coordinate (%s) at (%f,%f);", name, z.re, z.im)
	end
end

-- ========== DRAW POINT(S) ==========


function m.drawPoint(z, options)
    options = options or m.DRAW_POINT_STYLE
    -- accept nil point (circumcenter can be nil)
    if z == nil then
        m._warning("drawPoint : point is nil, aborting")
        return
    end
    z = core._coerce_assert_in_closed_disk(z)
    m.tikzPrintf("\\fill[%s] (%f,%f) circle (%f);", options, z.re, z.im, m.DRAW_POINT_RADIUS)
end


function m.drawPoints(...)
	local points, options = parse_points_with_options(...)
	options = options or m.DRAW_POINT_STYLE

	for i = 1, #points do
		m.drawPoint(points[i], options)
	end
end



function m.drawPointOrbit(point, func, n, options)
	-- draws n points. Doesn't draw original point
	options = options or "black"
	local points = core.pointOrbit(point, func, n)

	for i, z in ipairs(points) do
		local alpha = i / #points
		m.drawPoint(z, options .. ", fill opacity=" .. alpha)
	end
end

-- ========== DRAW LINES, SEGMENTS ETC ==========

function m.drawSegment(z, w, options)
	options = options or m.GEODESIC_STYLE
	z,w = complex.coerce(z,w)
	core._assert(z:isNot(w), "points must be distinct")
	local shape = m.tikz_shape_segment(z,w)
	m.tikzPrintf("\\draw[%s] %s;",options, shape)
end

function m.markSegment(z, w, markString, position)
	position = position or 0.5
	size ="small" -- add to function input ?
	z,w = complex.coerce(z,w)
	core._assert(z:isNot(w), "points must be distinct")
	local shape = m.tikz_shape_segment(z,w)
	m.tikzPrintf("\\path[postaction={decorate,decoration={markings, mark=at position %f with {\\node[transform shape,sloped,font=\\%s] {%s};}}}] %s;",
  		position,
  		size,
  		markString,
  		shape
  	)
end

function m.tikz_shape_segment(z, w)
	core._assert(z:isNot(w), "points must be distinct")
	local g = core._geodesic_data(z, w)

	-- If the geodesic is (almost) a diameter, draw straight segment
	if g.radius == math.huge or g.radius > 100 then
		return string.format("(%f,%f)--(%f,%f)", z.re, z.im, w.re, w.im)
	else
		local a1 = complex.arg(z - g.center)
		local a2 = complex.arg(w - g.center)
		local delta = atan2(sin(a2 - a1), cos(a2 - a1))
		local a_end = a1 + delta
		local degPerRad = 180 / PI
		return string.format(
			"(%f,%f) ++(%f:%f) arc (%f:%f:%f)",
			g.center.re,
			g.center.im,
			a1 * degPerRad,
			g.radius,
			a1 * degPerRad,
			a_end * degPerRad,
			g.radius
		)
	end
end



function m.tikz_shape_closed_line(a,b)
	-- todo : add "close" flag to decide if we close diameters ? 
	core._assert(a:isNot(b), "points must be distinct")
	if not a:isUnit() or not b:isUnit() then
		a, b = core.endpoints(a,b)
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
	options = options or m.GEODESIC_STYLE

	a, b = core._coerce_assert_in_closed_disk(a,b)
	core._assert(not a:isNear(b), "drawLine : points must be distinct")
	
	local end_a, end_b = core.endpoints(a,b)
	local shape = m.tikz_shape_segment(end_a,end_b)
	m.tikzPrintf("\\draw[%s] %s;", options, shape)
end


function m.drawLinesFromTable(pairs, options)
	options = options or m.GEODESIC_STYLE
	for _, pair in ipairs(pairs) do
		m.drawLine(pair[1], pair[2], options)
	end
end

function m.drawPerpendicularThrough(P,A,B,options)
	-- perpendicular through P to geodesic (A,B)
	options = options or m.GEODESIC_STYLE
	P, A, B = core._coerce_assert_in_closed_disk(P, A, B)
	core._assert(A:isNot(B), "A and B must be distinct")
	local H = core.projection(A,B)(P)
	core._assert(P:isNot(H), "point must not be on line")
	-- todo : fix this : should be ok.
	m.drawLine(P,H,options)
end



function m.drawPerpendicularBisector(A, B, options)
	options = options or m.GEODESIC_STYLE
	A, B = core._coerce_assert_in_closed_disk(A, B)

	core._assert(A:isNot(B), "drawPerpendicularBisector: A and B must be distinct")

	local e1, e2 = core.endpoints_perpendicular_bisector(A, B)
	m.drawLine(e1, e2, options)
end

function m.drawAngleBisector(A, O, B, options)
	options = options or m.GEODESIC_STYLE
	A, O, B = core._coerce_assert_in_closed_disk(A, O, B)

	core._assert(complex.distinct(O,A) and complex.distinct(O,B),
		"angle_bisector: O must be distinct from A and B")

	local e1, e2 = core.endpoints_angle_bisector(A, O, B)
	m.drawLine(e1, e2, options)
end

--- Draw a hyperbolic ray from two points: start at p1, through p2
function m.drawRayFromPoints(p1, p2, options)
	options = options or m.GEODESIC_STYLE
	local _, e2 = core.endpoints(p1, p2) -- e2 is the "ahead" endpoint
	m.drawSegment(p1, e2, options)
end

m.drawRay = m.drawRayFromPoints

--- Draw a hyperbolic ray from a start point p along a tangent vector v
function m.drawRayFromVector(p, v, options)
	options = options or m.GEODESIC_STYLE
	p = core._coerce_assert_in_disk(p)
	-- TODO : allow point at infinity (check vector direction) FIX/TEST
	local q = core.expMap(p, v) -- move along v in hyperbolic space
	local _, e2 = core.endpoints(p, q)
	m.drawSegment(p, e2, options)
end

function m.drawLineFromVector(p, v, options)
	options = options or m.GEODESIC_STYLE
	-- TODO : allow point at infinity
	local q = core.expMap(p, v) -- move along v in hyperbolic space
	m.drawLine(p, q, options)
end

function m.drawTangentAt(center, point, options)
	-- draw tangent line of circle of center 'center' passing through 'point'
	options = options or m.GEODESIC_STYLE
	center, point = core._coerce_assert_in_disk(center, point)
	local Q = core.rotation(point, PI / 2)(center)
	m.drawLine(point, Q, options)
end

-- function m.drawTangentFrom(center, radius, point)
	-- TODO !
--	return
-- end

-- ========== VECTORS =============


function m.tikz_shape_euclidean_segment(a,b)
	return string.format(
			"(%f,%f) -- (%f,%f)",a.re, a.im, b.re, b.im)
end

function m.drawTangentVector(p, v, options)
	options = options or ""
	local norm_v = complex.abs(v)
	core._assert(norm_v > core.EPS, "drawTangentVector : vector must not be zero")
	local u = v / norm_v
	local factor = (1 - complex.abs2(p))
	local euclid_vec = tanh(factor * norm_v / 2) * u
    local shape = m.tikz_shape_euclidean_segment(p, p+euclid_vec)
	m.tikzPrintf("\\draw[->,%s] %s;",options,shape)
end

-- ========== FOR CONVENIENCE (draw multiple objets/segments etc

function m.drawLines(...)
	local points, options = parse_points_with_options(...)
	core._assert(#points % 2 == 0, "drawLines expects  an even number of points, got " .. #points)

	for i = 1, #points, 2 do
		m.drawLine(points[i], points[i + 1], options)
	end
end

function m.drawSegments(...)
	local points, options = parse_points_with_options(...)

	core._assert(#points % 2 == 0, "drawSegments expects  an even number of points, got " .. #points)

	for i = 1, #points, 2 do
		m.drawSegment(points[i], points[i + 1], options)
	end
end

function m.markSegments(...)
	-- parameters : points and optional options string
	local points, options = parse_points_with_options(...)
	for i = 1, #points, 2 do
		m.markSegment(points[i], points[i + 1], options)
	end
end

function m.drawTriangle(...)
	local points, options = parse_points_with_options(...)

	core._assert(#points == 3, "drawTriangle expects exactly 3 points, got " .. #points)

	local a, b, c = points[1], points[2], points[3]
	m.drawSegment(a, b, options)
	m.drawSegment(b, c, options)
	m.drawSegment(c, a, options)
end

-- Draw a polyline from a table of points (open chain)
function m.drawPolylineFromTable(points, options)
	options = options or m.GEODESIC_STYLE
	core._assert(#points >= 2, "drawPolylineFromTable expects at least 2 points, got " .. #points)

	for i = 1, #points - 1 do
		m.drawSegment(points[i], points[i + 1], options)
	end
end

function m.drawPolyline(...)
	local points, options = parse_points_with_options(...)
	core._assert(#points >= 2, "drawPolyline expects at least 2 points, got " .. #points)
	m.drawPolylineFromTable(points, options)
end


function m.drawPolygonFromTable(points, options)
	options = options or m.GEODESIC_STYLE
	core._assert(#points >= 2, "drawPolygonFromTable expects at least 2 points, got " .. #points)

	for i = 1, #points do
		local z = points[i]
		local w = points[i % #points + 1] -- wrap around to first point
		m.drawSegment(z, w, options)
	end
end

function m.drawPolygon(...)
	local points, options = parse_points_with_options(...)

	-- a 2-gon is a polygon
	core._assert(#points >= 2, "drawPolygon expects at least 2 points, got " .. #points)
	m.drawPolygonFromTable(points, options)
end

function m.drawRegularPolygon(center, point, nbSides, options)
	options = options or m.GEODESIC_STYLE
	core._assert(nbSides>1, "drawRegularPolygon : expects >=2 sides, got " .. nbSides)
	core._assert_in_disk(center)
	core._assert_in_disk(point)
	core._assert(complex.distinct(center, point), "drawRegularPolygon : center and point must be distinct")
	local rot = core.rotation(center, 2*PI/nbSides)
	local vertices = {}
	for k=1,nbSides do
		point = rot(point)
		table.insert(vertices, point)
	end
	m.drawPolygonFromTable(vertices, options)
end

-- ========== DRAW CIRCLES, SEMICIRCLES, ARCS ==========

function m.drawCircleRadius(z0, r, options)
	options = options or m.CIRCLE_STYLE
	z0 = core._coerce_assert_in_disk(z0)
	local c, R = core._circle_to_euclidean(z0, r)

	m.tikzPrintf("\\draw[%s] (%f,%f) circle (%f);", options, c.re, c.im, R)
end

m.drawCircle = m.drawCircleRadius

function m.drawCircleThrough(center, point, options)
	options = options or m.CIRCLE_STYLE
	center, point = core._coerce_assert_in_disk(center, point)
	local r = core.distance(center, point)
	m.drawCircle(center, r, options)
end

function m.drawIncircle(A, B, C, options)
	options = options or m.CIRCLE_STYLE
	A, B, C = core._coerce_assert_in_disk(A, B, C)
	local I = core.triangleIncenter(A, B, C)
	local a = core.projection(B, C)(I)
	m.drawCircleThrough(I, a, options)
end

function m.drawCircumcircle(A, B, C, options)
	options = options or m.CIRCLE_STYLE
	A, B, C = core._coerce_assert_in_disk(A, B, C)
	local O = core.triangleCircumcenter(A, B, C)
	if O ~= nil then
		m.drawCircleThrough(O,A, options)
	else
		m._warning("drawCircumcircle : circumcenter does not exist")
	end
end



function m.drawArc(O, A, B, options)
	options = options or m.CIRCLE_STYLE
	O, A, B = core._coerce_assert_in_disk(O, A, B)

	-- Check points are on same hyperbolic circle
	local rA = core.distance(O, A)
	local rB = core.distance(O, B)
	core._assert(abs(rA - rB) < core.EPS, "drawArc: points A and B are not on the same hyperbolic circle")

	local c, R = core._circle_to_euclidean(O, rA)

	-- Compute angles of A and B on the Euclidean circle
	local function angleOnCircle(p)
		return deg(atan2(p.im - c.im, p.re - c.re)) % 360
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
	options = options or m.CIRCLE_STYLE
	local endpoint = (core.symmetry(center))(startpoint)
	m.drawArc(center, startpoint, endpoint, options)
end





-- ========== HOROCYCLES AND HYPERCYCLES

function m.drawHorocycle(idealPoint, point, options)
	options = options or m.HOROCYCLE_STYLE

	core._assert(complex.isClose(complex.abs(idealPoint), 1), "drawHorocycle: ideal point must be on unit circle")
	core._assert(core._in_disk(point), "drawHorocycle: second point must be in disk")
	-- rotate :
	local w = point / idealPoint
	local x, y = w.re, w.im
	-- compute center and radius
	local a = (x ^ 2 + y ^ 2 - 1) / (2 * (x - 1))
	local r = abs(a - 1)
	local center = complex.new(a, 0)
	-- rotate back
	center = center * idealPoint

	m.tikzPrintf("\\draw[%s] (%f,%f) circle (%f);", options, center.re, center.im, r)
end


function m.drawHypercycleThrough(P, A, B, options)
	options = options or m.HYPERCYCLE_STYLE
	P, A, B = complex.coerce(P, A, B)
	if not A:isUnit() or not B:isUnit() then
		A, B = core.endpoints(A, B)
	end
	if abs(complex.det(P-A, P-B)) < core.EPS then
		m.tikzPrintf("\\draw[%s] (%f,%f) -- (%f,%f);", options, A.re, A.im, B.re, B.im)
		return
	end
	local O = euclidean_circumcenter(P, A, B)
	local radius = complex.abs(O-A)
	m.tikzPrintf("\\draw[%s] (%f,%f) circle (%f);", options, O.re, O.im, radius)
end



-- ========== DRAW ANGLES, RIGHT ANGLES

function m.drawAngle(A, O, B, options, distFactor)
	distFactor = distFactor or m.DRAW_ANGLE_DIST
	options = options or m.ANGLE_STYLE
	core._assert_in_disk(A)
	core._assert_in_disk(O)
	core._assert_in_disk(B)

	local dOA = core.distance(O,A)
	local dOB = core.distance(O,B)
	local minDist = min(dOA,dOB)
	local radius= minDist*distFactor
	local AA = core.interpolate(O,A,radius / dOA)
	local BB = core.interpolate(O,B,radius/ dOB)
	m.drawArc(O,AA,BB, options)
end

function m.drawRightAngle(A, O, B, options, distFactor)
	-- assumes angle(AOB) = +90 deg !
	distFactor = distFactor or m.DRAW_ANGLE_DIST
	options = options or m.ANGLE_STYLE
	core._assert_in_disk(A)
	core._assert_in_disk(O)
	core._assert_in_disk(B)
	local dOA = core.distance(O,A)
	local dOB = core.distance(O,B)
	local minDist = min(dOA, dOB)
	local radius = minDist*distFactor
	local AA = core.interpolate(O,A,radius / dOA)
	local BB = core.interpolate(O,B,radius / dOB)

	local v = core.tangentVector(AA,A)*complex.I
	local w = core.tangentVector(BB,B)*(-complex.I)
	local VV = core.expMap(AA,v)
	local WW = core.expMap(BB,w)
	local P = core.interLL(AA,VV, BB, WW)
	-- fast&lazy : euclidean polyline instead of geodesic:
	m.tikzPrintf("\\draw[%s] (%f,%f) -- (%f,%f) -- (%f,%f);",
		options,
		AA.re, AA.im,
		P.re, P.im,
		BB.re, BB.im
	)
end

-- ========== LABEL OBJETS ==================


function m.labelPoint(z, label, options)
	options = options or m.LABEL_STYLE
	-- accept nil point (circumcenter can be nil)
	if z == nil then
		m._warning("labelPoint : point is nil, aborting")
		return
	end
	m.tikzPrintf("\\node[%s] at (%f,%f) {%s};", options, z.re, z.im, label)
end

function m.labelPoints(...)
	-- always above left ! 
	local args = { ... }
	local n = #args
	local options = m.LABEL_STYLE -- default : "above left"

	if n >= 3 and type(args[n]) == "string" and (n % 2 == 1) then
		options = args[n]
		n = n - 1
	end

	core._assert(n % 2 == 0, "labelPoints expects pairs: (point, label)")

	for i = 1, n, 2 do
		m.labelPoint(args[i], args[i + 1], options)
	end
end

function m.labelSegment(A, B, label, options)
	options = options or m.LABEL_STYLE
	local midpoint = core.midpoint(A, B)
	m.labelPoint(midpoint, label,options)
end


-- ====================== MODULE END

return m

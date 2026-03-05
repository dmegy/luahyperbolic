local M = {}

local complex = require("complex")

M.core = require("luahyperbolic-core")
M.tikz = require("luahyperbolic-tikz")
M.tilings = require("luahyperbolic-tilings")

local function merge(dst, src)
    for k,v in pairs(src) do
        dst[k] = v
    end
end

merge(M, core)
merge(M, tikz)
merge(M, tilings)

return M
-- builds luahyperbolic.sty from Lua source files
-- usage: lua build.lua

--------------------------------------------------
-- utilities
--------------------------------------------------

local function read(path)
  local f = assert(io.open(path, "r"))
  local s = f:read("*a")
  f:close()
  return s
end

local function write(path, content)
  local f = assert(io.open(path, "w"))
  f:write(content)
  f:close()
end

local function strip_requires(code)
  return code:gsub("[^\n]*require%s*%b()%s*\n", "")
end

local function replace_return(code, varname)
  return code:gsub("return%s+m%s*$", varname .. " = m")
end

local function wrap_module(code)
  return "do\n" .. code .. "\nend\n"
end

local function process_module(path, name)
  local code = read(path)
  code = strip_requires(code)
  code = replace_return(code, name)
  code = wrap_module(code)
  return code
end

--------------------------------------------------
-- process modules
--------------------------------------------------

local complex_code = process_module(
  "lua/complex.lua",
  "complex"
)

local core_code = process_module(
  "lua/luahyperbolic-core.lua",
  "core"
)

local tikz_code = process_module(
  "lua/luahyperbolic-tikz.lua",
  "tikz"
)

local tilings_code = process_module(
  "lua/luahyperbolic-tilings.lua",
  "tilings"
)

--------------------------------------------------
-- API construction
--------------------------------------------------

local api_code = [[

-- public API
hyper = {}

-- structured access
hyper.core = core
hyper.tikz = tikz
hyper.tilings = tilings

local function merge(dst, src)
  for k,v in pairs(src) do
    dst[k] = v
  end
end

-- flattened API
merge(hyper, core)
merge(hyper, tikz)
merge(hyper, tilings)

]]

--------------------------------------------------
-- concatenate Lua code
--------------------------------------------------

local timestamp = os.date("%Y/%m/%d %H:%M:%S")

local all_code = table.concat({

"-- AUTO-GENERATED FILE",
"-- DO NOT EDIT",
"-- DATE: " .. timestamp,
"",

"-- internal modules",
"local core",
"local tikz",
"local tilings",
"",

complex_code,
core_code,
tikz_code,
tilings_code,

api_code

}, "\n")

--------------------------------------------------
-- insert into template and write template
--------------------------------------------------

local template = read("lua/luahyperbolic.template.sty")

template = template:gsub("===TIMESTAMPPLACEHOLDER===", timestamp)

local final_sty = template:gsub("%-%- ===LUACODEPLACEHOLDER===", function()
  return all_code
end)

write("luahyperbolic.sty", final_sty)

print("luahyperbolic.sty written successfully")
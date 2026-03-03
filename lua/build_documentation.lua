local file_to_document = "complex.lua"
local output_tex_file = file_to_document:gsub("%.lua$", "-documentation.tex")

local function escape_latex(str)
    str = str or ""
    str = str:gsub("([&%%$#_{}~^\\\\])", "\\%1")
    return str
end

-- lecture du fichier
local lines = {}
for line in io.lines(file_to_document) do table.insert(lines, line) end

local docs = {}
local current = nil

local function save_current(name, kind)
    if current and name then
        current.name = name
        current.kind = kind
        table.insert(docs, current)
        current = nil
    end
end

for _, line in ipairs(lines) do
    -- cherche les commentaires avec --- ou -- pouvant contenir @param, @return, @error
    local comment = line:match("^%s*%-%-+%s*(.*)")
    if comment then
        if not current then
            current = {description = {}, params = {}, returns = {}, errors = {}}
        end

        local tag, rest = comment:match("^@(%w+)%s*(.*)")
        if tag == "param" then
            local name, typ, desc = rest:match("(%S+)%s*(%S*)%s*(.*)")
            table.insert(current.params, {name=name or "", type=typ or "", desc=desc or ""})
        elseif tag == "return" then
            local typ, desc = rest:match("(%S*)%s*(.*)")
            table.insert(current.returns, {type=typ or "", desc=desc or ""})
        elseif tag == "error" then
            table.insert(current.errors, rest or "")
        else
            table.insert(current.description, comment)
        end
    else
        if current then
            local name, kind
            name = line:match("^%s*function%s+m%.([%w_]+)%s*%(")
            if name then kind="function" end
            if not name then
                name = line:match("^%s*function%s+m:([%w_]+)%s*%(")
                if name then kind="function" end
            end
            if not name then
                name = line:match("^%s*m%.([%w_]+)%s*=")
                if name then kind="constant" end
            end
            if name then save_current(name, kind) end
        end
    end
end

-- Génération LaTeX
local tex_lines = {}
table.insert(tex_lines, "\\documentclass{article}")
table.insert(tex_lines, "\\usepackage[margin=1in]{geometry}")
table.insert(tex_lines, "\\usepackage[T1]{fontenc}")
table.insert(tex_lines, "\\usepackage{hyperref}")
table.insert(tex_lines, "\\usepackage{longtable}")
table.insert(tex_lines, "\\usepackage{amsmath}")
table.insert(tex_lines, "\\begin{document}")
table.insert(tex_lines, "\\section*{Documentation for module: " .. escape_latex(file_to_document) .. "}")

for _, f in ipairs(docs) do
    local title = f.kind=="constant" and "Constant: " or "Function: "
    table.insert(tex_lines, "\\subsection*{"..escape_latex(title..f.name).."}")

    if #f.description>0 then
        table.insert(tex_lines, escape_latex(table.concat(f.description, " ")))
    end

    if #f.params>0 then
        table.insert(tex_lines, "\\textbf{Parameters:}")
        table.insert(tex_lines, "\\begin{itemize}")
        for _, p in ipairs(f.params) do
            table.insert(tex_lines, string.format("\\item \\texttt{%s} (%s) : %s",
                escape_latex(p.name), escape_latex(p.type), escape_latex(p.desc)))
        end
        table.insert(tex_lines, "\\end{itemize}")
    end

    if #f.returns>0 then
        table.insert(tex_lines, "\\textbf{Returns:}")
        table.insert(tex_lines, "\\begin{itemize}")
        for _, r in ipairs(f.returns) do
            table.insert(tex_lines, string.format("\\item (%s) : %s",
                escape_latex(r.type), escape_latex(r.desc)))
        end
        table.insert(tex_lines, "\\end{itemize}")
    end

    if #f.errors>0 then
        table.insert(tex_lines, "\\textbf{Errors:}")
        table.insert(tex_lines, "\\begin{itemize}")
        for _, e in ipairs(f.errors) do
            table.insert(tex_lines, "\\item "..escape_latex(e))
        end
        table.insert(tex_lines, "\\end{itemize}")
    end

    table.insert(tex_lines, "\\hrulefill\n")
end

table.insert(tex_lines, "\\end{document}")

local out=io.open(output_tex_file,"w")
out:write(table.concat(tex_lines,"\n"))
out:close()

print("Documentation written to: "..output_tex_file)
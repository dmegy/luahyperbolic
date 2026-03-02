# Lua Hyperbolic Geometry

**luahyperbolic** is a LaTeX package and a Lua library for performing operations in hyperbolic geometry, intended for use with LuaLaTeX (LuaTeX). The package provides complex number manipulation and hyperbolic geometric functions.

![triangle_tiling_5_4](examples/triangle-tiling-2-3-7.png)

## Installation

### Manual Installation (for now)

If you wish to install the package manually, follow these steps:

- Pu the file `luahyperbolic.sty` in your working directory
- Include the package in your document by running:

  ```latex
  \usepackage{luahyperbolic}
  ```

### Example Usage

A MWE is (see `minimal_example.tex`in `examples/`) :

```latex
\documentclass[margin=.2cm,multi,tikz]{standalone}
\usepackage{luahyperbolic} %loads luacode package
\begin{document}
\begin{luacode*}
hyper.tikzBegin("scale=2.5")
local P = complex(0.5,-0.2)
local A = complex.exp_i(math.pi/10)
for k=1,5 do hyper.drawLine(P, A^k, "teal") end
hyper.labelPoint(P, "$P$", "left=.2cm")
hyper.drawLine(complex.J,-complex.I,"very thick, dashed, red")
hyper.tikzEnd()
\end{luacode*}
\end{document}
```

Compiling that file with `lualatex` produces the following :
![minimal example](examples/minimal_example.png)

See the [package manual (pdf)](doc/documentation-luahyperbolic.pdf) for numerous examples.

More examples in [examples/](examples/)

## License

This package is released under the **Public Domain (CC0 1.0 Universal License)**. You may use, modify, and distribute it freely, without restriction.

For more information on the license, see the `LICENSE` file or visit [CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/).

## Todo

### In `luahyperbolic-core` :

- function distance_between_geodesics(z1, z2, w1, w2)
- function closest_points_between_geodesics(z1, z2, w1, w2)
- triangle intouch points, extouchpoints
- triangle orthocenter

### In `luahyperbolic-tikz` :

- function `markSegment` ?
- function `markAngle(A, O, B, options)`
- function `labelSegment(A, B, label)`
- function `labelAngle(A, O, B, label)`
- more tikz shapes
- draw external angle bisector ?

## Contact

Don't contact me

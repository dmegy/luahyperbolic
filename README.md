# Lua Hyperbolic Geometry

**luahyperbolic** is a LaTeX package and a Lua library for performing operations and drawing pictures in hyperbolic geometry, intended for use with LuaLaTeX. The package provides complex number manipulation and hyperbolic geometric functions.

![triangle_tiling_5_4](triangle-tiling-2-4-5.png)

## Installation

### Manual Installation (for now)

If you wish to install the package manually, follow these steps:

- Put the file `luahyperbolic.sty` in your working directory
- Include the package in your document by adding:

  ```latex
  \usepackage{luahyperbolic}
  ```

### Example Usage

A minimal working example is (see `minimal_example.tex`in `examples/`) :

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
hyper.tikzEnd("myfile.tikz")
\end{luacode*}
\end{document}
```

Compiling that file with `lualatex` produces the following output:

![minimal example](minimal-example.png)

It also saves the TikZ picture to `myfile.tikz`, for later use. (Optional)

See the [package documentation (pdf)](documentation-luahyperbolic.pdf) for numerous examples.

More examples in [examples/](examples/)

## License

This package is released under the **Public Domain (CC0 1.0 Universal License)**. You may use, modify, and distribute it freely, without restriction.

For more information on the license, see the `LICENSE` file or visit [CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/).

## Todo

### In `luahyperbolic-core` :

- function distance_between_geodesics(z1, z2, w1, w2)
- function closest_points_between_geodesics(z1, z2, w1, w2)
- triangle intouch points, extouchpoints
- hide functions metric_factor, circle_to_euclidean
- get rif of cosh, sinh, tanh
- IMPORTANT write function that computes triangle with given angles. Necessary for (p,q,r) tilings.
- change name fundamentalIdealTriangle if only one angle is zero
- power of a point, radical axis
- hyper.getType(phi) for automorphism
- hyper.getFixedPoints(phi) for automorphism
- symmetrySending (A to B)
- reflectionSending (A to B)
- intouch points, extouch points, excenters

### In `luahyperbolic-tikz` :

- more constants : distances for angle drawing/labelling etc,
- function `drawExcircle` and variants
- more triangle geometry ? Gergonne, Nagel etc ?
- function `markAngle(A, O, B, options)`
- function `labelSegment(A, B, label)`
- function `labelAngle(A, O, B, label)`
- more tikz shapes if necessary
- draw external angle bisector ?
- replace old `complex.isClose(z,w)` etc with `z:isNear(w)` etc.
- fillTriangle, fillPolygon etc ?
- drawExcircle

### In `luahyperbolic-tilings`

- faster tiling generation
- draw tiling step by step, triangle by triangle

### In documentation

links to math articles on wikipedia for definitions ?

### More examples

- ex circles

## Contact

Do you really need to contact me ? Please don't contact me.

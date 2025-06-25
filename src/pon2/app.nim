## This module implements applications for [Puyo Puyo](https://puyo.sega.jp/) and
## [Nazo Puyo](https://vc.sega.jp/3ds/nazopuyo/).
##
## Submodule Documentations:
## - [color](./app/color.html)
## - [generate](./app/generate.html)
## - [ide](./app/ide.html)
## - [key](./app/key.html)
## - [marathon](./app/marathon.html)
## - [nazopuyowrap](./app/nazopuyowrap.html)
## - [permute](./app/permute.html)
## - [simulator](./app/simulator.html)
## - [solve](./app/solve.html)
##
## Compile Options:
## | Option               | Description                | Default  |
## | -------------------- | -------------------------- | -------- |
## | `-d:pon2.path=<str>` | Path of the web simulator. | `/pon2/` |
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import
  ./app/[color, generate, ide, key, marathon, nazopuyowrap, permute, simulator, solve]

export color, generate, ide, key, marathon, nazopuyowrap, permute, simulator, solve

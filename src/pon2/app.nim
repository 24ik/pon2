## This module implements applications for [Puyo Puyo](https://puyo.sega.jp/) and
## [Nazo Puyo](https://vc.sega.jp/3ds/nazopuyo/).
##
## Submodule Documentations:
## - [generate](./app/generate.html)
## - [key](./app/key.html)
## - [marathon](./app/marathon.html)
## - [nazopuyowrap](./app/nazopuyowrap.html)
## - [permute](./app/permute.html)
## - [simulator](./app/simulator.html)
## - [solve](./app/solve.html)
## - [studio](./app/studio.html)
##
## Compile Options:
## | Option               | Description             | Default                |
## | -------------------- | ----------------------- | ---------------------- |
## | `-d:pon2.path=<str>` | Path of the web studio. | `/pon2/stable/studio/` |
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ./[core]
import ./app/[generate, key, marathon, nazopuyowrap, permute, simulator, solve, studio]

export core, generate, key, marathon, nazopuyowrap, permute, simulator, solve, studio

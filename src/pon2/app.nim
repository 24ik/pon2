## This module implements applications dedicated to
## [Puyo Puyo](https://puyo.sega.jp/) and [Nazo Puyo](https://vc.sega.jp/3ds/nazopuyo/).
##
## Submodule Documentations:
## - [generate](./app/generate.html)
## - [grimoire](./app/grimoire.html)
## - [key](./app/key.html)
## - [marathon](./app/marathon.html)
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
import ./app/[generate, grimoire, key, marathon, permute, simulator, solve, studio]

export core, generate, grimoire, key, marathon, permute, simulator, solve, studio

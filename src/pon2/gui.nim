## This module implements GUI application for [Puyo Puyo](https://puyo.sega.jp/) and
## [Nazo Puyo](https://vc.sega.jp/3ds/nazopuyo/).
##
## Submodule Documentations:
## - [helper](./gui/helper.html)
## - [marathon](./gui/marathon.html)
## - [simulator](./gui/simulator.html)
## - [studio](./gui/studio.html)
##
## Compile Options:
## | Option                 | Description       | Default     |
## | ---------------------- | ----------------- | ----------- |
## | `-d:pon2.assets=<str>` | Assets directory. | `../assets` |
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ./[app]
import ./gui/[helper, marathon, simulator, studio]

export app
export helper, marathon, simulator, studio

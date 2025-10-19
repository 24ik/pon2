## This module implements GUI application for [Puyo Puyo](https://puyo.sega.jp/) and
## [Nazo Puyo](https://vc.sega.jp/3ds/nazopuyo/).
##
## Submodule Documentations:
## - [color](./gui/color.html)
## - [ide](./gui/ide.html)
## - [simulator](./gui/simulator.html)
##
## Compile Options:
## | Option                 | Description       | Default    |
## | ---------------------- | ----------------- | ---------- |
## | `-d:pon2.assets=<str>` | Assets directory. | `./assets` |
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ./gui/[color, ide, simulator]

export color, ide, simulator

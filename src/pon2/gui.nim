## This module implements GUIs dedicated to [Puyo Puyo](https://puyo.sega.jp/) and
## [Nazo Puyo](https://vc.sega.jp/3ds/nazopuyo/).
##
## Submodule Documentations:
## - [grimoire](./gui/grimoire.html)
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
import ./gui/[grimoire, helper, marathon, simulator, studio]

export app, grimoire, helper, marathon, simulator, studio

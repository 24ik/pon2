## This module implements common types and constants.
##
## Compile Options:
## | Option                      | Description          | Default |
## | --------------------------- | -------------------- | ------- |
## | `-d:pon2.waterheight=<int>` | Height of the water. | `8`     |
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[typetraits]

type
  Row* {.pure.} = enum ## Field's row. The top is 0 and the bottom is 12.
    Row0
    Row1
    Row2
    Row3
    Row4
    Row5
    Row6
    Row7
    Row8
    Row9
    Row10
    Row11
    Row12

  Col* {.pure.} = enum ## Field's column. The left is 0 and the right is 5.
    Col0
    Col1
    Col2
    Col3
    Col4
    Col5

const
  Height* = Row.enumLen
  Width* = Col.enumLen
  WaterHeight* {.define: "pon2.waterheight".} = 8
  AirHeight* = Height - WaterHeight

static:
  doAssert WaterHeight >= 2
  doAssert AirHeight >= 3

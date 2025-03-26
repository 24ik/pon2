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
  Row* = enum ## Field's row. The top is 0 and the bottom is 12.
    Row0 = "13th row"
    Row1 = "12th row"
    Row2 = "11th row"
    Row3 = "10th row"
    Row4 = "9th row"
    Row5 = "8th row"
    Row6 = "7th row"
    Row7 = "6th row"
    Row8 = "5th row"
    Row9 = "4th row"
    Row10 = "3rd row"
    Row11 = "2nd row"
    Row12 = "1st row"

  Col* = enum ## Field's column. The left is 0 and the right is 5.
    Col0 = "1st col"
    Col1 = "2nd col"
    Col2 = "3rd col"
    Col3 = "4th col"
    Col4 = "5th col"
    Col5 = "6th col"

const
  Height* = Row.enumLen
  Width* = Col.enumLen
  WaterHeight* {.define: "pon2.waterheight".} = 8
  AirHeight* = Height - WaterHeight

static:
  doAssert WaterHeight >= 2
  doAssert AirHeight >= 3

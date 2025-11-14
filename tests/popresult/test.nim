{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, unittest]
import ../../src/pon2/core/[cell, common, popresult]
import ../../src/pon2/private/[assign, strutils2]
import ../../src/pon2/private/core/[binfield]

proc toBinField(str: string): BinField =
  ## Returns the binary field converted from the string representation.
  let strs = str.split "\n"

  var arr {.noinit.}: array[Row, array[Col, bool]]
  for row in Row:
    for col in Col:
      arr[row][col].assign strs[row.ord][col.ord] == 'x'

  return arr.toBinField

# ------------------------------------------------
# Constructor
# ------------------------------------------------

block: # init
  let zero = BinField.init
  check PopResult.init(zero, zero, zero, zero, zero, zero, zero, zero, zero) ==
    PopResult.init

# ------------------------------------------------
# Property
# ------------------------------------------------

block: # isPopped
  let zero = BinField.init

  block:
    var red = BinField.init
    red[Row6, Col3] = true

    check PopResult.init(red, zero, zero, zero, zero, zero, zero, zero, red).isPopped

  block:
    check not PopResult.init(zero, zero, zero, zero, zero, zero, zero, zero, zero).isPopped

# ------------------------------------------------
# Count
# ------------------------------------------------

block: # cellCnt, puyoCnt, colorPuyoCnt, garbagesCnt
  var
    red = BinField.init
    yellow = BinField.init
    hard = BinField.init
    hardToGarbage = BinField.init
    garbage = BinField.init
  red[Row1, Col3] = true
  red[Row5, Col2] = true
  yellow[Row0, Col0] = true
  hard[Row8, Col1] = true
  hard[Row9, Col1] = true
  hardToGarbage[Row10, Col3] = true
  garbage[Row2, Col3] = true

  let
    zero = BinField.init
    popRes = PopResult.init(
      red, zero, zero, yellow, zero, hard, hardToGarbage, garbage, red + yellow
    )

  check popRes.cellCnt(Red) == 2
  check popRes.cellCnt(Green) == 0
  check popRes.puyoCnt == 6
  check popRes.colorPuyoCnt == 3
  check popRes.garbagesCnt == 3
  check popRes.hardToGarbageCnt == 1

# ------------------------------------------------
# Connection
# ------------------------------------------------

block: # connCnts
  let
    red =
      """
......
xxx...
...x..
x.....
x.....
.....x
....xx
....x.
.xx...
......
......
......
......""".toBinField
    green =
      """
......
......
...x..
...x..
...x.x
...x.x
...xxx
....x.
.xxxx.
.x....
.x..x.
.xxxx.
......""".toBinField

    zero = BinField.init
    popRes = PopResult.init(red, green, zero, zero, zero, zero, zero, zero, zero)

  check popRes.connCnts == [@[], @[], @[], @[3, 1, 2, 4, 2], @[21], @[], @[], @[]]

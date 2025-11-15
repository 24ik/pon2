{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, unittest]
import ../../src/pon2/core/[cell, common, popresult]
import ../../src/pon2/private/[assign, strutils]
import ../../src/pon2/private/core/[binaryfield]

proc toBinaryField(str: string): BinaryField =
  ## Returns the binary field converted from the string representation.
  let strs = str.split "\n"

  var arr {.noinit.}: array[Row, array[Col, bool]]
  for row in Row:
    for col in Col:
      arr[row][col].assign strs[row.ord][col.ord] == 'x'

  return arr.toBinaryField

# ------------------------------------------------
# Constructor
# ------------------------------------------------

block: # init
  let zero = BinaryField.init
  check PopResult.init(zero, zero, zero, zero, zero, zero, zero, zero, zero) ==
    PopResult.init

# ------------------------------------------------
# Property
# ------------------------------------------------

block: # isPopped
  let zero = BinaryField.init

  block:
    var red = BinaryField.init
    red[Row6, Col3] = true

    check PopResult.init(red, zero, zero, zero, zero, zero, zero, zero, red).isPopped

  block:
    check not PopResult.init(zero, zero, zero, zero, zero, zero, zero, zero, zero).isPopped

# ------------------------------------------------
# Count
# ------------------------------------------------

block: # cellCount, puyoCount, colorPuyoCount, garbagesCount
  var
    red = BinaryField.init
    yellow = BinaryField.init
    hard = BinaryField.init
    hardToGarbage = BinaryField.init
    garbage = BinaryField.init
  red[Row1, Col3] = true
  red[Row5, Col2] = true
  yellow[Row0, Col0] = true
  hard[Row8, Col1] = true
  hard[Row9, Col1] = true
  hardToGarbage[Row10, Col3] = true
  garbage[Row2, Col3] = true

  let
    zero = BinaryField.init
    popRes = PopResult.init(
      red, zero, zero, yellow, zero, hard, hardToGarbage, garbage, red + yellow
    )

  check popRes.cellCount(Red) == 2
  check popRes.cellCount(Green) == 0
  check popRes.puyoCount == 6
  check popRes.colorPuyoCount == 3
  check popRes.garbagesCount == 3
  check popRes.hardToGarbageCount == 1

# ------------------------------------------------
# Connection
# ------------------------------------------------

block: # connectionCounts
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
......""".toBinaryField
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
......""".toBinaryField

    zero = BinaryField.init
    popRes = PopResult.init(red, green, zero, zero, zero, zero, zero, zero, zero)

  check popRes.connectionCounts ==
    [@[], @[], @[], @[3, 1, 2, 4, 2], @[21], @[], @[], @[]]

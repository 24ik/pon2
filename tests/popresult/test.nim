{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/core/[cell, common, popresult]
import ../../src/pon2/private/[assign, strutils]
import ../../src/pon2/private/core/[binaryfield]

proc toBinaryField(str: string): BinaryField =
  ## Returns the binary field converted from the string representation.
  let strs = str.split "\n"

  var boolArray {.noinit.}: array[Row, array[Col, bool]]
  for row in Row:
    for col in Col:
      boolArray[row][col].assign strs[row.ord][col.ord] == 'x'

  return boolArray.toBinaryField

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

block: # cellCount, puyoCount, colorPuyoCount, nuisancePuyoCount
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
    popResult = PopResult.init(
      red, zero, zero, yellow, zero, hard, hardToGarbage, garbage, red + yellow
    )

  check popResult.cellCount(Red) == 2
  check popResult.cellCount(Green) == 0
  check popResult.puyoCount == 6
  check popResult.colorPuyoCount == 3
  check popResult.nuisancePuyoCount == 3
  check popResult.hardToGarbageCount == 1

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
    popResult = PopResult.init(red, green, zero, zero, zero, zero, zero, zero, zero)

  check popResult.connectionCounts ==
    [@[], @[], @[], @[3, 1, 2, 4, 2], @[21], @[], @[], @[]]

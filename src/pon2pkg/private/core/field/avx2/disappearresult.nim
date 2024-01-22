## This module implements disappearing results with AVX2.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[bitops, sequtils]
import ./[binary]
import ../[binary]
import ../../../[unionfind]
import ../../../../corepkg/[cell, misc]

type DisappearResult* = object
  ## Disappearing result.
  red*: BinaryField
  greenBlue*: BinaryField
  yellowPurple*: BinaryField
  garbage*: BinaryField
  color*: BinaryField

using
  disRes: DisappearResult

# ------------------------------------------------
# Property
# ------------------------------------------------

func notDisappeared*(disRes): bool {.inline.} = disRes.color.isZero
  ## Returns `true` if no puyos disappeared.

# ------------------------------------------------
# Count - Color
# ------------------------------------------------

func colorCount*(disRes): int {.inline.} =
  ## Returns the number of color puyos that disappeared.
  disRes.red.popcnt + disRes.greenBlue.popcnt + disRes.yellowPurple.popcnt

# ------------------------------------------------
# Count - Garbage
# ------------------------------------------------

func garbageCount*(disRes): int {.inline.} = disRes.garbage.popcnt
  ## Returns the number of garbage puyos that disappeared.

# ------------------------------------------------
# Count - Puyo
# ------------------------------------------------

func puyoCount*(disRes; puyo: Puyo): int {.inline.} =
  ## Returns the number of `puyo` that disappeared.
  case puyo
  of Hard: 0
  of Garbage: disRes.garbage.popcnt
  of Red: disRes.red.popcnt
  of Green: disRes.greenBlue.popcnt 0
  of Blue: disRes.greenBlue.popcnt 1
  of Yellow: disRes.yellowPurple.popcnt 0
  of Purple: disRes.yellowPurple.popcnt 1

func puyoCount*(disRes): int {.inline.} =
  ## Returns the number of puyos that disappeared.
  disRes.colorCount + disRes.garbageCount

# ------------------------------------------------
# Connection
# ------------------------------------------------

func initDefaultComponents: array[
    Height + 2, array[Width + 2, tuple[color: 0..2; idx: Natural]]] {.inline.} =
  ## Constructor of `DefaultComponents`.
  result[0][0] = (0, 0) # dummy to remove warning
  for i in 0..<Height.succ 2:
    for j in 0..<Width.succ 2:
      result[i][j].color = 0
      result[i][j].idx = 0

const DefaultComponents = initDefaultComponents()

func connectionCounts(field: BinaryField): array[2, seq[int]] {.inline.} =
  ## Returns the number of cells for each connected component.
  ## `result[0]` for the first color, and `result[1]` for the second color.
  ## The order of the returned sequence is undefined.
  ## This function ignores ghost puyos.
  let arr = cast[array[16, uint16]](field)

  var
    components = DefaultComponents
    uf = initUnionFind Height * Width
    nextComponentIdx = Natural 1

  for col in Column.low..Column.high:
    # NOTE: YMM[e15, ..., e0] == array[e0, ..., e15]
    let
      colIdx = col.ord.succ
      colVal1 = arr[14 - col]
      colVal2 = arr[6 - col]

    for row in Row.low..Row.high:
      let
        rowIdx = row.ord.succ
        rowDigit = 13 - row
        color = bitor(
          colVal1.testBit(rowDigit).int, colVal2.testBit(rowDigit).int shl 1)
      if color == 0:
        continue

      components[rowIdx][colIdx].color = color

      let
        up = components[rowIdx.pred][colIdx]
        left = components[rowIdx][colIdx.pred]
      if up.color == color:
        if left.color == color:
          components[rowIdx][colIdx].idx = min(up.idx, left.idx)
          uf.merge up.idx, left.idx
        else:
          components[rowIdx][colIdx].idx = up.idx
      else:
        if left.color == color:
          components[rowIdx][colIdx].idx = left.idx
        else:
          components[rowIdx][colIdx].idx = nextComponentIdx
          nextComponentIdx.inc

  result[0] = 0.repeat nextComponentIdx
  result[1] = 0.repeat nextComponentIdx
  for row in Row.low..Row.high:
    for col in Column.low..Column.high:
      let (color, idx) = components[row.ord.succ][col.ord.succ]
      if color == 0:
        continue

      result[color.pred][uf.getRoot idx].inc

  result[0].keepItIf it > 0
  result[1].keepItIf it > 0

func connectionCounts*(disRes): array[ColorPuyo, seq[int]] {.inline.} =
  ## Returns the number of color puyos in each connected component.
  let
    greenBlue = disRes.greenBlue.connectionCounts
    yellowPurple = disRes.yellowPurple.connectionCounts

  result[Red] = disRes.red.connectionCounts[1]
  result[Green] = greenBlue[0]
  result[Blue] = greenBlue[1]
  result[Yellow] = yellowPurple[0]
  result[Purple] = yellowPurple[1]

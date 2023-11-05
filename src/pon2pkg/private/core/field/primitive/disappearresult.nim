## This module implements disappearing results with primitive field.
##

{.experimental: "strictDefs".}

import std/[sequtils]
import ../../[unionfind]
import ../../../../corepkg/[cell, misc]

when defined(cpu32):
  import ./bit32/[binary]
else:
  import ./bit64/[binary]

type DisappearResult* = object
  ## Disappearing result.
  red*: BinaryField
  green*: BinaryField
  blue*: BinaryField
  yellow*: BinaryField
  purple*: BinaryField
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
  disRes.red.popcnt + disRes.green.popcnt + disRes.blue.popcnt +
    disRes.yellow.popcnt + disRes.purple.popcnt
    
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
  of Green: disRes.green.popcnt
  of Blue: disRes.blue.popcnt
  of Yellow: disRes.yellow.popcnt
  of Purple: disRes.purple.popcnt

func puyoCount*(disRes): int {.inline.} =
  ## Returns the number of puyos that disappeared.
  disRes.colorCount + disRes.garbageCount

# ------------------------------------------------
# Connection
# ------------------------------------------------

func initDefaultComponents: array[Height + 2, array[Width + 2, Natural]] {.inline.} =
  ## Constructor of `DefaultComponents`.
  result[0][0] = 0 # dummy to remove warning
  for i in 0..<Height.succ 2:
    for j in 0..<Width.succ 2:
      result[i][j] = 0

const DefaultComponents = initDefaultComponents()

func connectionCounts(field: BinaryField): seq[int] {.inline.} =
  ## Returns the number of cells for each connected component.
  ## The order of the returned sequence is undefined.
  ## This function ignores ghost puyos.
  var
    components = DefaultComponents
    uf = initUnionFind Height * Width
    nextComponentIdx = Natural 1

  for col in Column.low..Column.high:
    for row in Row.low..Row.high:
      if not field[row, col]:
        continue

      let
        rowIdx = row.ord.succ
        colIdx = col.ord.succ
        up = components[rowIdx.pred][colIdx]
        left = components[rowIdx][colIdx.pred]
      if up != 0:
        if left != 0:
          components[rowIdx][colIdx] = min(up, left)
          uf.merge up, left
        else:
          components[rowIdx][colIdx] = up
      else:
        if left != 0:
          components[rowIdx][colIdx] = left
        else:
          components[rowIdx][colIdx] = nextComponentIdx
          nextComponentIdx.inc

  result = 0.repeat nextComponentIdx
  for row in Row.low..Row.high:
    for col in Column.low..Column.high:
      let idx = components[row.ord.succ][col.ord.succ]
      if idx == 0:
        continue

      result[uf.getRoot idx].inc

  result.keepItIf it > 0

func connectionCounts*(disRes): array[ColorPuyo, seq[int]] {.inline.} =
  ## Returns the number of puyos in each connected component.
  result[Red] = disRes.red.connectionCounts
  result[Green] = disRes.green.connectionCounts
  result[Blue] = disRes.blue.connectionCounts
  result[Yellow] = disRes.yellow.connectionCounts
  result[Purple] = disRes.purple.connectionCounts

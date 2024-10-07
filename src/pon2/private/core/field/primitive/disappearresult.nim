## This module implements disappearing results with primitive field.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils]
import ../../../[unionfind]
import ../../../../core/[cell, fieldtype]

when defined(cpu32):
  import ./bit32/[binary]
else:
  import ./bit64/[binary]

type DisappearResult* = object ## Disappearing result.
  red*: BinaryField
  green*: BinaryField
  blue*: BinaryField
  yellow*: BinaryField
  purple*: BinaryField
  garbage*: BinaryField
  color*: BinaryField

# ------------------------------------------------
# Property
# ------------------------------------------------

func notDisappeared*(self: DisappearResult): bool {.inline.} =
  ## Returns `true` if no puyos disappeared.
  self.color.isZero

# ------------------------------------------------
# Count
# ------------------------------------------------

func colorCount*(self: DisappearResult): int {.inline.} =
  ## Returns the number of color puyos that disappeared.
  self.red.popcnt + self.green.popcnt + self.blue.popcnt + self.yellow.popcnt +
    self.purple.popcnt

func garbageCount*(self: DisappearResult): int {.inline.} =
  ## Returns the number of garbage puyos that disappeared.
  self.garbage.popcnt

func puyoCount*(self: DisappearResult, puyo: Puyo): int {.inline.} =
  ## Returns the number of `puyo` that disappeared.
  case puyo
  of Hard: 0
  of Garbage: self.garbage.popcnt
  of Red: self.red.popcnt
  of Green: self.green.popcnt
  of Blue: self.blue.popcnt
  of Yellow: self.yellow.popcnt
  of Purple: self.purple.popcnt

func puyoCount*(self: DisappearResult): int {.inline.} =
  ## Returns the number of puyos that disappeared.
  self.colorCount + self.garbageCount

# ------------------------------------------------
# Connection
# ------------------------------------------------

func initDefaultComponents(): array[Height + 2, array[Width + 2, Natural]] {.inline.} =
  ## Returns `DefaultComponents`.
  result[0][0] = 0 # HACK: dummy to suppress warning
  for i in 0 ..< Height.succ 2:
    for j in 0 ..< Width.succ 2:
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

  for col in Column.low .. Column.high:
    for row in Row.low .. Row.high:
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
  for row in Row.low .. Row.high:
    for col in Column.low .. Column.high:
      let idx = components[row.ord.succ][col.ord.succ]
      if idx == 0:
        continue

      result[uf.getRoot idx].inc

  result.keepItIf it > 0

func connectionCounts*(self: DisappearResult): array[ColorPuyo, seq[int]] {.inline.} =
  ## Returns the number of puyos in each connected component.
  result[Red] = self.red.connectionCounts
  result[Green] = self.green.connectionCounts
  result[Blue] = self.blue.connectionCounts
  result[Yellow] = self.yellow.connectionCounts
  result[Purple] = self.purple.connectionCounts

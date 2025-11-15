## This module implements pop results.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils]
import ./[cell, common]
import ../private/[arrayutils, assign, core, staticfor, unionfind]

export cell

type PopResult* = object ## Pop Results.
  red: BinaryField
  green: BinaryField
  blue: BinaryField
  yellow: BinaryField
  purple: BinaryField
  hard: BinaryField
  hardToGarbage: BinaryField
  garbage: BinaryField
  color: BinaryField

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(
    T: type PopResult,
    red, green, blue, yellow, purple, hard, hardToGarbage, garbage, color: BinaryField,
): T {.inline, noinit.} =
  T(
    red: red,
    green: green,
    blue: blue,
    yellow: yellow,
    purple: purple,
    hard: hard,
    hardToGarbage: hardToGarbage,
    garbage: garbage,
    color: color,
  )

func init*(T: type PopResult): T {.inline, noinit.} =
  let zero = BinaryField.init
  T.init(zero, zero, zero, zero, zero, zero, zero, zero, zero)

# ------------------------------------------------
# Property
# ------------------------------------------------

func isPopped*(self: PopResult): bool {.inline, noinit.} =
  ## Returns `true` if any puyo popped.
  self.color != BinaryField.init

# ------------------------------------------------
# Count
# ------------------------------------------------

func cellCount*(self: PopResult, cell: Cell): int {.inline, noinit.} =
  ## Returns the number of `cell` that popped.
  case cell
  of None: 0
  of Hard: self.hard.popcnt
  of Garbage: self.garbage.popcnt
  of Red: self.red.popcnt
  of Green: self.green.popcnt
  of Blue: self.blue.popcnt
  of Yellow: self.yellow.popcnt
  of Purple: self.purple.popcnt

func puyoCount*(self: PopResult): int {.inline, noinit.} =
  ## Returns the number of puyos that popped.
  self.color.popcnt + self.hard.popcnt + self.garbage.popcnt

func colorPuyoCount*(self: PopResult): int {.inline, noinit.} =
  ## Returns the number of color puyos that popped.
  self.color.popcnt

func garbagesCount*(self: PopResult): int {.inline, noinit.} =
  ## Returns the number of hard and garbage puyos that popped.
  self.hard.popcnt + self.garbage.popcnt

func hardToGarbageCount*(self: PopResult): int {.inline, noinit.} =
  ## Returns the number of hard puyos that becomes garbage puyos.
  self.hardToGarbage.popcnt

# ------------------------------------------------
# Connection
# ------------------------------------------------

func connectionCounts(self: BinaryField): seq[int] {.inline, noinit.} =
  ## Returns an array of a sequence that represents the numbers of connections.
  const DefaultCcIndex = 0

  let arr = self.toArray

  var
    ccIndexArray =
      static((Height.succ 2).initArrayWith (Width.succ 2).initArrayWith DefaultCcIndex)
    uf = static(UnionFind.init Height * Width)
    nextCcIndex = DefaultCcIndex.succ

  staticFor(row, Row):
    staticFor(col, Col):
      if arr[row][col]:
        let
          rowOrd = row.ord
          arrRowIndex = rowOrd.succ
          colOrd = col.ord
          arrColIndex = colOrd.succ

          ccIndexU = ccIndexArray[rowOrd][arrColIndex]
          ccIndexL = ccIndexArray[arrRowIndex][colOrd]

        if ccIndexU == DefaultCcIndex:
          if ccIndexL == DefaultCcIndex:
            ccIndexArray[arrRowIndex][arrColIndex].assign nextCcIndex
            nextCcIndex.inc
          else:
            ccIndexArray[arrRowIndex][arrColIndex].assign ccIndexL
        else:
          ccIndexArray[arrRowIndex][arrColIndex].assign ccIndexU

          if ccIndexL != DefaultCcIndex:
            uf.merge ccIndexU, ccIndexL

  var connections = 0.repeat nextCcIndex
  staticFor(row, Row):
    staticFor(col, Col):
      let ccIndex = ccIndexArray[row.ord.succ][col.ord.succ]
      if ccIndex != DefaultCcIndex:
        connections[uf.root ccIndex].inc

  connections.filterIt it > 0

func connectionCounts*(self: PopResult): array[Cell, seq[int]] {.inline, noinit.} =
  ## Returns an array of a sequence that represents the numbers of connections.
  [
    @[],
    @[],
    @[],
    self.red.connectionCounts,
    self.green.connectionCounts,
    self.blue.connectionCounts,
    self.yellow.connectionCounts,
    self.purple.connectionCounts,
  ]

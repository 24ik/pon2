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
  ## If the cell is `None`, returns 0.
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

func nuisancePuyoCount*(self: PopResult): int {.inline, noinit.} =
  ## Returns the number of nuisance puyos that popped.
  self.hard.popcnt + self.garbage.popcnt

func hardToGarbageCount*(self: PopResult): int {.inline, noinit.} =
  ## Returns the number of hard puyos that becomes garbage puyos.
  self.hardToGarbage.popcnt

# ------------------------------------------------
# Connection
# ------------------------------------------------

func connectionCounts(self: BinaryField): seq[int] {.inline, noinit.} =
  ## Returns an array of a sequence that represents the numbers of connections.
  const DefaultConnectIndex = 0

  let boolArray = self.toArray

  var
    connectIndexArray =
      static((Height + 2).initArrayWith (Width + 2).initArrayWith DefaultConnectIndex)
    unionFind = static(UnionFind.init Height * Width)
    nextConnectIndex = DefaultConnectIndex + 1

  staticFor(row, Row):
    staticFor(col, Col):
      if boolArray[row][col]:
        let
          rowOrd = row.ord
          arrayRowIndex = rowOrd + 1
          colOrd = col.ord
          arrayColIndex = colOrd + 1

          connectIndexU = connectIndexArray[rowOrd][arrayColIndex]
          connectIndexL = connectIndexArray[arrayRowIndex][colOrd]

        if connectIndexU == DefaultConnectIndex:
          if connectIndexL == DefaultConnectIndex:
            connectIndexArray[arrayRowIndex][arrayColIndex].assign nextConnectIndex
            nextConnectIndex += 1
          else:
            connectIndexArray[arrayRowIndex][arrayColIndex].assign connectIndexL
        else:
          connectIndexArray[arrayRowIndex][arrayColIndex].assign connectIndexU

          if connectIndexL != DefaultConnectIndex:
            unionFind.merge connectIndexU, connectIndexL

  var connections = 0.repeat nextConnectIndex
  staticFor(row, Row):
    staticFor(col, Col):
      let connectIndex = connectIndexArray[row.ord + 1][col.ord + 1]
      if connectIndex != DefaultConnectIndex:
        connections[unionFind.root connectIndex] += 1

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

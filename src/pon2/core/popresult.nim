## This module implements pop results.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils]
import ./[cell, common]
import ../private/[arrayutils, assign3, core, staticfor2, unionfind]

export cell

type PopResult* = object ## Pop Results.
  red: BinField
  green: BinField
  blue: BinField
  yellow: BinField
  purple: BinField
  hard: BinField
  hardToGarbage: BinField
  garbage: BinField
  color: BinField

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(
    T: type PopResult,
    red, green, blue, yellow, purple, hard, hardToGarbage, garbage, color: BinField,
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
  let zero = BinField.init
  T.init(zero, zero, zero, zero, zero, zero, zero, zero, zero)

# ------------------------------------------------
# Property
# ------------------------------------------------

func isPopped*(self: PopResult): bool {.inline, noinit.} =
  ## Returns `true` if any puyo popped.
  self.color != BinField.init

# ------------------------------------------------
# Count
# ------------------------------------------------

func cellCnt*(self: PopResult, cell: Cell): int {.inline, noinit.} =
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

func puyoCnt*(self: PopResult): int {.inline, noinit.} =
  ## Returns the number of puyos that popped.
  self.color.popcnt + self.hard.popcnt + self.garbage.popcnt

func colorPuyoCnt*(self: PopResult): int {.inline, noinit.} =
  ## Returns the number of color puyos that popped.
  self.color.popcnt

func garbagesCnt*(self: PopResult): int {.inline, noinit.} =
  ## Returns the number of hard and garbage puyos that popped.
  self.hard.popcnt + self.garbage.popcnt

func hardToGarbageCnt*(self: PopResult): int {.inline, noinit.} =
  ## Returns the number of hard puyos that becomes garbage puyos.
  self.hardToGarbage.popcnt

# ------------------------------------------------
# Connection
# ------------------------------------------------

func connCnts(self: BinField): seq[int] {.inline, noinit.} =
  ## Returns an array of a sequence that represents the numbers of connections.
  const DefaultCcIdx = 0

  let arr = self.toArr

  var
    ccIdxArr =
      static((Height.succ 2).initArrayWith (Width.succ 2).initArrayWith DefaultCcIdx)
    uf = static(UnionFind.init Height * Width)
    nextCcIdx = DefaultCcIdx.succ

  staticFor(row, Row):
    staticFor(col, Col):
      if arr[row][col]:
        let
          rowOrd = row.ord
          arrRowIdx = rowOrd.succ
          colOrd = col.ord
          arrColIdx = colOrd.succ

          ccIdxU = ccIdxArr[rowOrd][arrColIdx]
          ccIdxL = ccIdxArr[arrRowIdx][colOrd]

        if ccIdxU == DefaultCcIdx:
          if ccIdxL == DefaultCcIdx:
            ccIdxArr[arrRowIdx][arrColIdx].assign nextCcIdx
            nextCcIdx.inc
          else:
            ccIdxArr[arrRowIdx][arrColIdx].assign ccIdxL
        else:
          ccIdxArr[arrRowIdx][arrColIdx].assign ccIdxU

          if ccIdxL != DefaultCcIdx:
            uf.merge ccIdxU, ccIdxL

  var conns = 0.repeat nextCcIdx
  staticFor(row, Row):
    staticFor(col, Col):
      let ccIdx = ccIdxArr[row.ord.succ][col.ord.succ]
      if ccIdx != DefaultCcIdx:
        conns[uf.root ccIdx].inc

  conns.filterIt it > 0

func connCnts*(self: PopResult): array[Cell, seq[int]] {.inline, noinit.} =
  ## Returns an array of a sequence that represents the numbers of connections.
  [
    @[],
    @[],
    @[],
    self.red.connCnts,
    self.green.connCnts,
    self.blue.connCnts,
    self.yellow.connCnts,
    self.purple.connCnts,
  ]

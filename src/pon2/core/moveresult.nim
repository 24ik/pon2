## This module implements move results.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, strformat, sugar]
import ./[cell, common, notice]
import ../[utils]
import ../private/[arrayutils, math, staticfor]

export cell, notice, utils

type MoveResult* = object ## Move result.
  chainCount*: int
  popCounts*: array[Cell, int]
  hardToGarbageCount*: int
  detailPopCounts*: seq[array[Cell, int]]
  detailHardToGarbageCount*: seq[int]
  fullPopCountsOpt*: Opt[seq[array[Cell, seq[int]]]]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(
    T: type MoveResult,
    chainCount: int,
    popCounts: array[Cell, int],
    hardToGarbageCount: int,
    detailPopCounts: seq[array[Cell, int]],
    detailHardToGarbageCount: seq[int],
): T {.inline, noinit.} =
  T(
    chainCount: chainCount,
    popCounts: popCounts,
    hardToGarbageCount: hardToGarbageCount,
    detailPopCounts: detailPopCounts,
    detailHardToGarbageCount: detailHardToGarbageCount,
    fullPopCountsOpt: Opt[seq[array[Cell, seq[int]]]].err,
  )

func init*(
    T: type MoveResult,
    chainCount: int,
    popCounts: array[Cell, int],
    hardToGarbageCount: int,
    detailPopCounts: seq[array[Cell, int]],
    detailHardToGarbageCount: seq[int],
    fullPopCounts: seq[array[Cell, seq[int]]],
): T {.inline, noinit.} =
  T(
    chainCount: chainCount,
    popCounts: popCounts,
    hardToGarbageCount: hardToGarbageCount,
    detailPopCounts: detailPopCounts,
    detailHardToGarbageCount: detailHardToGarbageCount,
    fullPopCountsOpt: Opt[seq[array[Cell, seq[int]]]].ok fullPopCounts,
  )

func init*(T: type MoveResult, includeFullPopCounts = true): T {.inline, noinit.} =
  if includeFullPopCounts:
    T.init(0, static(Cell.initArrayWith 0), 0, @[], @[], @[])
  else:
    T.init(0, static(Cell.initArrayWith 0), 0, @[], @[])

# ------------------------------------------------
# Count
# ------------------------------------------------

func sumColor(arr: array[Cell, int]): int {.inline, noinit.} =
  ## Returns the total number of color puyos.
  (arr[Red] + arr[Green] + arr[Blue]) + (arr[Yellow] + arr[Purple])

func cellCount*(self: MoveResult, cell: Cell): int {.inline, noinit.} =
  ## Returns the number of `cell` that popped.
  self.popCounts[cell]

func puyoCount*(self: MoveResult): int {.inline, noinit.} =
  ## Returns the number of cells that popped.
  self.popCounts.sum

func colorPuyoCount*(self: MoveResult): int {.inline, noinit.} =
  ## Returns the number of color puyos that popped.
  self.popCounts.sumColor

func garbagesCount*(self: MoveResult): int {.inline, noinit.} =
  ## Returns the number of hard and garbage puyos that popped.
  self.popCounts[Hard] + self.popCounts[Garbage]

func cellCounts*(self: MoveResult, cell: Cell): seq[int] {.inline, noinit.} =
  ## Returns a sequence of the number of `cell` that popped in each chain.
  self.detailPopCounts.mapIt it[cell]

func puyoCounts*(self: MoveResult): seq[int] {.inline, noinit.} =
  ## Returns a sequence of the number of puyos that popped in each chain.
  self.detailPopCounts.mapIt it.sum

func colorPuyoCounts*(self: MoveResult): seq[int] {.inline, noinit.} =
  ## Returns a sequence of the number of color puyos that popped in each chain.
  self.detailPopCounts.mapIt it.sumColor

func garbagesCounts*(self: MoveResult): seq[int] {.inline, noinit.} =
  ## Returns a sequence of the number of hard and garbage puyos that popped in
  ## each chain.
  self.detailPopCounts.mapIt it[Hard] + it[Garbage]

# ------------------------------------------------
# Color
# ------------------------------------------------

func colors(arr: array[Cell, int]): set[Cell] {.inline, noinit.} =
  ## Returns the set of colors that popped.
  var cells = set[Cell]({})
  for cell in Red .. Purple:
    if arr[cell] > 0:
      cells.incl cell

  cells

func colors*(self: MoveResult): set[Cell] {.inline, noinit.} =
  ## Returns the set of colors that popped.
  self.popCounts.colors

func colorsSeq*(self: MoveResult): seq[set[Cell]] {.inline, noinit.} =
  ## Returns a sequence of the set of colors that popped in each chain.
  self.detailPopCounts.mapIt it.colors

# ------------------------------------------------
# Place
# ------------------------------------------------

func placeCounts*(
    self: MoveResult, cell: Cell
): Pon2Result[seq[int]] {.inline, noinit.} =
  ## Returns a sequence of the number of places where `cell` popped in each chain.
  if self.fullPopCountsOpt.isOk:
    ok self.fullPopCountsOpt.unsafeValue.mapIt it[cell].len
  else:
    err "`placeCounts` not supported: {self}".fmt

func placeCounts*(self: MoveResult): Pon2Result[seq[int]] {.inline, noinit.} =
  ## Returns a sequence of the number of places where color puyos popped in each chain.
  if self.fullPopCountsOpt.isOk:
    ok self.fullPopCountsOpt.unsafeValue.mapIt (
      it[Red].len + it[Green].len + it[Blue].len
    ) + (it[Yellow].len + it[Purple].len)
  else:
    err "`placeCounts` not supported: {self}".fmt

# ------------------------------------------------
# Connect
# ------------------------------------------------

func connectionCounts*(
    self: MoveResult, cell: Cell
): Pon2Result[seq[int]] {.inline, noinit.} =
  ## Returns a sequence of the number of connections of `cell` that popped.
  if self.fullPopCountsOpt.isOk:
    ok concat self.fullPopCountsOpt.unsafeValue.mapIt it[cell]
  else:
    err "`connectionCounts` not supported: {self}".fmt

func connectionCounts*(self: MoveResult): Pon2Result[seq[int]] {.inline, noinit.} =
  ## Returns a sequence of the number of connections of color puyos that popped.
  if self.fullPopCountsOpt.isOk:
    ok concat self.fullPopCountsOpt.unsafeValue.mapIt it[Red .. Purple].concat
  else:
    err "`connectionCounts` not supported: {self}".fmt

# ------------------------------------------------
# Score
# ------------------------------------------------

const
  ConnectionBonuses = collect:
    for connection in 0 .. Height.pred * Width:
      if connection <= 4:
        0
      elif connection in 5 .. 10:
        connection - 3
      else:
        10
  ChainBonuses = collect:
    for chain in 0 .. Height * Width div 4:
      if chain <= 1:
        0
      elif chain in 2 .. 5:
        8 * 2 ^ (chain - 2)
      else:
        64 + 32 * (chain - 5)
  ColorBonuses = collect:
    for color in 0 .. 5:
      if color <= 1:
        0
      else:
        3 * 2 ^ (color - 2)

func connectionBonus(counts: seq[int]): int {.inline, noinit.} =
  ## Returns the connect bonus.
  sum counts.mapIt ConnectionBonuses[it]

func score*(self: MoveResult): Pon2Result[int] {.inline, noinit.} =
  ## Returns the score.
  if self.fullPopCountsOpt.isErr:
    return err "`score` not supported: {self}".fmt

  var totalScore = 0
  for chainIndex, countsArray in self.fullPopCountsOpt.unsafeValue:
    var
      connectionBonus = 0
      totalPuyoCount = 0
      colorCount = 0

    staticFor(cell, Red .. Purple):
      connectionBonus.inc countsArray[cell].connectionBonus

      let puyoCount = self.detailPopCounts[chainIndex][cell]
      totalPuyoCount.inc puyoCount

      if puyoCount > 0:
        colorCount.inc

    let
      hardCount = self.detailPopCounts[chainIndex][Hard]
      hardToGarbageCount = self.detailHardToGarbageCount[chainIndex]
      colorBonus = ColorBonuses[colorCount]

    totalScore.inc ((totalPuyoCount + hardToGarbageCount) * 10 + hardCount * 80) *
      max(ChainBonuses[chainIndex.succ] + connectionBonus + colorBonus, 1)

  ok totalScore

# ------------------------------------------------
# Notice Garbage
# ------------------------------------------------

func noticeCounts*(
    self: MoveResult, garbageRate: int, useComet = false
): Pon2Result[array[Notice, int]] {.inline, noinit.} =
  ## Returns the number of notice garbages.
  Pon2Result[array[Notice, int]].ok (
    ?self.score.context "`noticeCounts` not supported: {self}".fmt
  ).noticeCounts(garbageRate, useComet)

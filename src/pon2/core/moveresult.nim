## This module implements move results.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, sugar]
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
    fullPopCountsOpt: Opt[seq[array[Cell, seq[int]]]],
): T {.inline, noinit.} =
  T(
    chainCount: chainCount,
    popCounts: popCounts,
    hardToGarbageCount: hardToGarbageCount,
    detailPopCounts: detailPopCounts,
    detailHardToGarbageCount: detailHardToGarbageCount,
    fullPopCountsOpt: fullPopCountsOpt,
  )

func init*(
    T: type MoveResult,
    chainCount: int,
    popCounts: array[Cell, int],
    hardToGarbageCount: int,
    detailPopCounts: seq[array[Cell, int]],
    detailHardToGarbageCount: seq[int],
): T {.inline, noinit.} =
  T.init(
    chainCount,
    popCounts,
    hardToGarbageCount,
    detailPopCounts,
    detailHardToGarbageCount,
    Opt[seq[array[Cell, seq[int]]]].err,
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
  T.init(
    chainCount,
    popCounts,
    hardToGarbageCount,
    detailPopCounts,
    detailHardToGarbageCount,
    Opt[seq[array[Cell, seq[int]]]].ok fullPopCounts,
  )

func init*(T: type MoveResult, inclFullPopCounts = true): T {.inline, noinit.} =
  if inclFullPopCounts:
    T.init(0, Cell.initArrayWith 0, 0, @[], @[], @[])
  else:
    T.init(0, Cell.initArrayWith 0, 0, @[], @[])

# ------------------------------------------------
# Count
# ------------------------------------------------

func cellCount*(self: MoveResult, cell: Cell): int {.inline, noinit.} =
  ## Returns the number of `cell` that popped.
  self.popCounts[cell]

func puyoCount*(self: MoveResult): int {.inline, noinit.} =
  ## Returns the number of cells that popped.
  self.popCounts.sum

func coloredPuyoCount*(self: MoveResult): int {.inline, noinit.} =
  ## Returns the number of colored puyos that popped.
  ColoredPuyos.sumIt self.popCounts[it]

func nuisancePuyoCount*(self: MoveResult): int {.inline, noinit.} =
  ## Returns the number of nuisance puyos that popped.
  self.popCounts[Hard] + self.popCounts[Garbage]

func cellCounts*(self: MoveResult, cell: Cell): seq[int] {.inline, noinit.} =
  ## Returns a sequence of the number of `cell` that popped in each chain.
  self.detailPopCounts.mapIt it[cell]

func puyoCounts*(self: MoveResult): seq[int] {.inline, noinit.} =
  ## Returns a sequence of the number of puyos that popped in each chain.
  self.detailPopCounts.mapIt it.sum

func coloredPuyoCounts*(self: MoveResult): seq[int] {.inline, noinit.} =
  ## Returns a sequence of the number of colored puyos that popped in each chain.
  self.detailPopCounts.map (counts: array[Cell, int]) => ColoredPuyos.sumIt counts[it]

func nuisancePuyoCounts*(self: MoveResult): seq[int] {.inline, noinit.} =
  ## Returns a sequence of the number of nuisance puyos that popped in each chain.
  self.detailPopCounts.mapIt it[Hard] + it[Garbage]

# ------------------------------------------------
# Color
# ------------------------------------------------

func colors(counts: array[Cell, int]): set[Cell] {.inline, noinit.} =
  ## Returns the set of colors that popped.
  var cells: set[Cell] = {}
  staticFor(cell, ColoredPuyos):
    if counts[cell] > 0:
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
    err "`placeCounts` not supported: " & $self

func placeCounts*(self: MoveResult): Pon2Result[seq[int]] {.inline, noinit.} =
  ## Returns a sequence of the number of places where color puyos popped in each chain.
  if self.fullPopCountsOpt.isOk:
    ok self.fullPopCountsOpt.unsafeValue.map (counts: array[Cell, seq[int]]) =>
      (ColoredPuyos.sumIt counts[it].len)
  else:
    err "`placeCounts` not supported: " & $self

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
    err "`connectionCounts` not supported: " & $self

func connectionCounts*(self: MoveResult): Pon2Result[seq[int]] {.inline, noinit.} =
  ## Returns a sequence of the number of connections of color puyos that popped.
  if self.fullPopCountsOpt.isOk:
    ok concat self.fullPopCountsOpt.unsafeValue.mapIt it[Red .. Purple].concat
  else:
    err "`connectionCounts` not supported: " & $self

# ------------------------------------------------
# Score
# ------------------------------------------------

const
  ConnectionBonuses = collect:
    for connection in 0 .. (Height - 1) * Width:
      case connection
      of 0 .. 4:
        0
      of 5 .. 10:
        connection - 3
      else:
        10
  ChainBonuses = collect:
    for chain in 0 .. Height * Width div 4:
      case chain
      of 0 .. 1:
        0
      of 2 .. 5:
        8 * 2 ^ (chain - 2)
      else:
        64 + 32 * (chain - 5)
  ColorBonuses = collect:
    for color in 0 .. 5:
      case color
      of 0 .. 1:
        0
      else:
        3 * 2 ^ (color - 2)

func connectionBonus(counts: seq[int]): int {.inline, noinit.} =
  ## Returns the connect bonus.
  counts.sumIt ConnectionBonuses[it]

func score*(self: MoveResult): Pon2Result[int] {.inline, noinit.} =
  ## Returns the score.
  if self.fullPopCountsOpt.isErr:
    return err "`score` not supported: " & $self

  var totalScore = 0
  for chainIndex, countsArray in self.fullPopCountsOpt.unsafeValue:
    var
      connectionBonus = 0
      totalPuyoCount = 0
      colorCount = 0

    staticFor(cell, ColoredPuyos):
      connectionBonus += countsArray[cell].connectionBonus

      let puyoCount = self.detailPopCounts[chainIndex][cell]
      totalPuyoCount += puyoCount

      if puyoCount > 0:
        colorCount += 1

    let
      hardCount = self.detailPopCounts[chainIndex][Hard]
      hardToGarbageCount = self.detailHardToGarbageCount[chainIndex]
      colorBonus = ColorBonuses[colorCount]

    totalScore +=
      ((totalPuyoCount + hardToGarbageCount) * 10 + hardCount * 80) *
      max(ChainBonuses[chainIndex + 1] + connectionBonus + colorBonus, 1)

  ok totalScore

# ------------------------------------------------
# Notice Garbage
# ------------------------------------------------

func noticeCounts*(
    self: MoveResult, garbageRate: int, useComet = false
): Pon2Result[array[Notice, int]] {.inline, noinit.} =
  ## Returns the number of notice garbages.
  Pon2Result[array[Notice, int]].ok (
    ?self.score.context "`noticeCounts` not supported: " & $self
  ).noticeCounts(garbageRate, useComet)

## This module implements moving results.
##

{.experimental: "strictDefs".}

import std/math except sum
import std/[sequtils, setutils, sugar]
import ./[cell, misc]

type
  NotSupportDefect* = object of Defect

  MoveResult* = object of RootObj
    chainCount*: Natural

  RoughMoveResult* = object of MoveResult
    totalDisappearCounts*: array[Puyo, Natural]

  DetailMoveResult* = object of RoughMoveResult
    disappearCounts*: seq[array[Puyo, Natural]]

  FullMoveResult* = object of DetailMoveResult
    ## Moving result.
    ## - `chainCount`: Number of chains.
    ## - `totalDisappearCounts`: Number of puyos that disappeared.
    ## - `disappearCounts`: Number of puyos that disappeared in each chain.
    ## - `detailDisappearCounts`: Number of color puyos in each connected \
    ## component that disappeared in each chain.
    detailDisappearCounts*: seq[array[ColorPuyo, seq[Natural]]]

using
  moveRes: MoveResult
  roughRes: RoughMoveResult
  detailRes: DetailMoveResult
  fullRes: FullMoveResult

# ------------------------------------------------
# Count - Cell
# ------------------------------------------------

func cellCount*(moveRes; cell: Cell): int {.inline.} =
  ## Returns the number of `cell` that disappeared.
  result = 0
  raise newException(NotSupportDefect, "Not support: `MoveResult.cellCount")

func cellCount*(moveRes): int {.inline.} =
  ## Returns the number of cells that disappeared.
  result = 0
  raise newException(NotSupportDefect, "Not support: `MoveResult.cellCount")

func cellCount*(roughRes; cell: Cell): int {.inline.} =
  ## Returns the number of `cell` that disappeared.
  if cell == None: 0 else: roughRes.totalDisappearCounts[cell]

func cellCount*(roughRes): int {.inline.} =
  ## Returns the number of cells that disappeared.
  roughRes.totalDisappearCounts.sum

# ------------------------------------------------
# Count - Puyo
# ------------------------------------------------

func puyoCount*(moveRes): int {.inline.} = moveRes.cellCount
  ## Returns the number of puyos that disappeared.

func puyoCount*(roughRes): int {.inline.} = roughRes.cellCount
  ## Returns the number of puyos that disappeared.

# ------------------------------------------------
# Count - Color
# ------------------------------------------------

func colorCount*(moveRes): int {.inline.} =
  ## Returns the number of color puyos that disappeared.
  result = 0
  raise newException(NotSupportDefect, "Not support: `MoveResult.colorCount")

func colorCount*(roughRes): int {.inline.} =
  ## Returns the number of color puyos that disappeared.
  roughRes.totalDisappearCounts[ColorPuyo.low..ColorPuyo.high].sum

# ------------------------------------------------
# Count - Garbage
# ------------------------------------------------

func garbageCount*(moveRes): int {.inline.} =
  ## Returns the number of garbage puyos that disappeared.
  result = 0
  raise newException(NotSupportDefect, "Not support: `MoveResult.garbageCount")

func garbageCount*(roughRes): int {.inline.} =
  ## Returns the number of garbage puyos that disappeared.
  roughRes.totalDisappearCounts[Hard] + roughRes.totalDisappearCounts[Garbage]

# ------------------------------------------------
# Counts - Cell
# ------------------------------------------------

func cellCounts*(moveRes; cell: Cell): seq[int] {.inline.} =
  ## Returns the number of `cell` that disappeared in each chain.
  result = newSeq[int] 0
  raise newException(NotSupportDefect, "Not support: `MoveResult.cellCounts")

func cellCounts*(moveRes): seq[int] {.inline.} =
  ## Returns the number of cells that disappeared in each chain.
  result = newSeq[int] 0
  raise newException(NotSupportDefect, "Not support: `MoveResult.cellCounts")

func cellCounts*(detailRes; cell: Cell): seq[int] {.inline.} =
  ## Returns the number of `cell` that disappeared in each chain.
  if cell == None: newSeq[int](0)
  else: detailRes.disappearCounts.mapIt it[cell].int

func cellCounts*(detailRes): seq[int] {.inline.} =
  ## Returns the number of cells that disappeared in each chain.
  detailRes.disappearCounts.mapIt it.sum.int

# ------------------------------------------------
# Counts - Puyo
# ------------------------------------------------

func puyoCounts*(moveRes): seq[int] {.inline.} = moveRes.cellCounts
  ## Returns the number of puyos that disappeared in each chain.

func puyoCounts*(detailRes): seq[int] {.inline.} = detailRes.cellCounts
  ## Returns the number of puyos that disappeared in each chain.

# ------------------------------------------------
# Counts - Color
# ------------------------------------------------

func colorCounts*(moveRes): seq[int] {.inline.} =
  ## Returns the number of color puyos that disappeared in each chain.
  result = newSeq[int] 0
  raise newException(NotSupportDefect, "Not support: `MoveResult.colorCounts")

func colorCounts*(detailRes): seq[int] {.inline.} =
  ## Returns the number of color puyos that disappeared in each chain.
  detailRes.disappearCounts.mapIt it[ColorPuyo.low..ColorPuyo.high].sum.int

# ------------------------------------------------
# Counts - Garbage
# ------------------------------------------------

func garbageCounts*(moveRes): seq[int] {.inline.} =
  ## Returns the number of garbage puyos that disappeared in each chain.
  result = newSeq[int] 0
  raise newException(NotSupportDefect, "Not support: `MoveResult.garbageCounts")

func garbageCounts*(detailRes): seq[int] {.inline.} =
  ## Returns the number of garbage puyos that disappeared in each chain.
  detailRes.disappearCounts.mapIt it[Hard] + it[Garbage]

# ------------------------------------------------
# Score
# ------------------------------------------------

const
  ConnectBonuses = collect:
    for connect in 0 .. Height.pred * Width:
      if connect <= 4:
        0
      elif connect in 5..10:
        connect - 3
      else:
        10
  ChainBonuses = collect:
    for chain in 0 .. Height * Width div 4:
      if chain <= 1:
        0
      elif chain in 2..5:
        8 * 2 ^ (chain - 2)
      else:
        64 + 32 * (chain - 5)
  ColorBonuses = collect:
    for color in 0..ColorPuyo.fullSet.card:
      if color <= 1:
        0
      else:
        3 * 2 ^ (color - 2)

func connectBonus(puyoCounts: seq[Natural]): int {.inline.} =
  ## Returns the connect bonus.
  result = 0

  for count in puyoCounts:
    result.inc ConnectBonuses[count]

func score*(moveRes): int {.inline.} =
  result = 0
  raise newException(NotSupportDefect, "Not support: MoveResult.score")

func score*(fullRes): int {.inline.} =
  ## Returns the score.
  result = 0

  for chainIdx, countsArray in fullRes.detailDisappearCounts:
    let
      disappearCounts =
        fullRes.disappearCounts[chainIdx][ColorPuyo.low..ColorPuyo.high]

      chainBonus = ChainBonuses[chainIdx.succ]
      connectBonus =
        sum countsArray[ColorPuyo.low..ColorPuyo.high].mapIt it.connectBonus
      colorBonus = ColorBonuses[disappearCounts.countIt it > 0]

    result.inc 10 * disappearCounts.sum *
      max(chainBonus + connectBonus + colorBonus, 1)

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/core/[cell, moveresult, notice, rule]
import ../../src/pon2/private/[arrayutils, results2]

let
  chainCount = 3
  popCounts: array[Cell, int] = [0, 1, 12, 12, 4, 13, 0, 15]
  hardToGarbageCount = 3
  detailHardToGarbageCount = @[1, 2, 0]

  detailArray1: array[Cell, int] = [0, 1, 0, 4, 0, 5, 0, 9]
  detailArray2: array[Cell, int] = [0, 0, 0, 4, 4, 0, 0, 0]
  detailArray3: array[Cell, int] = [0, 0, 12, 4, 0, 8, 0, 6]
  detailPopCounts = @[detailArray1, detailArray2, detailArray3]

  fullArray1: array[Cell, seq[int]] = [@[], @[1], @[], @[4], @[], @[5], @[], @[4, 5]]
  fullArray2: array[Cell, seq[int]] = [@[], @[], @[], @[4], @[4], @[], @[], @[]]
  fullArray3: array[Cell, seq[int]] = [@[], @[], @[4, 4, 4], @[4], @[], @[5], @[], @[6]]
  fullPopCounts = @[fullArray1, fullArray2, fullArray3]

  moveResult1 = MoveResult.init(
    chainCount, popCounts, hardToGarbageCount, detailPopCounts, detailHardToGarbageCount
  )
  moveResult2 = MoveResult.init(
    chainCount, popCounts, hardToGarbageCount, detailPopCounts,
    detailHardToGarbageCount, fullPopCounts,
  )

# ------------------------------------------------
# Constructor
# ------------------------------------------------

block: # init
  check moveResult1 ==
    MoveResult(
      chainCount: chainCount,
      popCounts: popCounts,
      hardToGarbageCount: hardToGarbageCount,
      detailPopCounts: detailPopCounts,
      detailHardToGarbageCount: detailHardToGarbageCount,
      fullPopCountsOpt: Opt[seq[array[Cell, seq[int]]]].err,
    )
  check moveResult2 ==
    MoveResult(
      chainCount: chainCount,
      popCounts: popCounts,
      hardToGarbageCount: hardToGarbageCount,
      detailPopCounts: detailPopCounts,
      detailHardToGarbageCount: detailHardToGarbageCount,
      fullPopCountsOpt: Opt[seq[array[Cell, seq[int]]]].ok fullPopCounts,
    )

  check MoveResult.init(false) == MoveResult.init(0, Cell.initArrayWith 0, 0, @[], @[])
  check MoveResult.init(true) ==
    MoveResult.init(0, Cell.initArrayWith 0, 0, @[], @[], @[])
  check MoveResult.init == MoveResult.init true

# ------------------------------------------------
# Count
# ------------------------------------------------

block:
  # cellCount, puyoCount, colorPuyoCount, garbagesCount,
  # cellCounts, puyoCounts, colorPuyoCounts, garbagesCounts
  let
    countP = 15
    countY = 0
  check moveResult1.cellCount(Purple) == countP
  check moveResult2.cellCount(Purple) == countP
  check moveResult1.cellCount(Yellow) == countY
  check moveResult2.cellCount(Yellow) == countY

  let countPuyo = 57
  check moveResult1.puyoCount == countPuyo
  check moveResult2.puyoCount == countPuyo

  let countColor = 44
  check moveResult1.colorPuyoCount == countColor
  check moveResult2.colorPuyoCount == countColor

  let countGarbages = 13
  check moveResult1.garbagesCount == countGarbages
  check moveResult2.garbagesCount == countGarbages

  let
    countsB = @[5, 0, 8]
    countsY = @[0, 0, 0]
  check moveResult1.cellCounts(Blue) == countsB
  check moveResult2.cellCounts(Blue) == countsB
  check moveResult1.cellCounts(Yellow) == countsY
  check moveResult2.cellCounts(Yellow) == countsY

  let countsPuyo = @[19, 8, 30]
  check moveResult1.puyoCounts == countsPuyo
  check moveResult2.puyoCounts == countsPuyo

  let countsColor = @[18, 8, 18]
  check moveResult1.colorPuyoCounts == countsColor
  check moveResult2.colorPuyoCounts == countsColor

  let countsGarbages = @[1, 0, 12]
  check moveResult1.garbagesCounts == countsGarbages
  check moveResult2.garbagesCounts == countsGarbages

# ------------------------------------------------
# Color
# ------------------------------------------------

block: # colors, colorsSeq
  let colors2 = {Red, Green, Blue, Purple}
  check moveResult1.colors == colors2
  check moveResult2.colors == colors2

  let colorsSeq2 = @[{Red, Blue, Purple}, {Red, Green}, {Red, Blue, Purple}]
  check moveResult1.colorsSeq == colorsSeq2
  check moveResult2.colorsSeq == colorsSeq2

# ------------------------------------------------
# Place
# ------------------------------------------------

block: # placeCounts
  check moveResult1.placeCounts(Purple).isErr
  check moveResult2.placeCounts(Purple) == Pon2Result[seq[int]].ok @[2, 0, 1]
  check moveResult1.placeCounts(Yellow).isErr
  check moveResult2.placeCounts(Yellow) == Pon2Result[seq[int]].ok @[0, 0, 0]

  check moveResult1.placeCounts.isErr
  check moveResult2.placeCounts == Pon2Result[seq[int]].ok @[4, 2, 3]

# ------------------------------------------------
# Connect
# ------------------------------------------------

block: # connectionCounts
  check moveResult1.connectionCounts(Purple).isErr
  check moveResult2.connectionCounts(Purple) == Pon2Result[seq[int]].ok @[4, 5, 6]
  check moveResult1.connectionCounts(Yellow).isErr
  check moveResult2.connectionCounts(Yellow) == Pon2Result[seq[int]].ok @[]

  check moveResult1.connectionCounts.isErr
  check moveResult2.connectionCounts ==
    Pon2Result[seq[int]].ok @[4, 5, 4, 5, 4, 4, 4, 5, 6]

# ------------------------------------------------
# Score
# ------------------------------------------------

let scoreAnswer = 8660

block: # score
  check moveResult1.score.isErr
  check moveResult2.score == Pon2Result[int].ok scoreAnswer

# ------------------------------------------------
# Notice Garbage
# ------------------------------------------------

block: # noticeCounts
  for rule in Rule:
    check moveResult1.noticeCounts(rule).isErr
    check moveResult2.noticeCounts(rule) ==
      Pon2Result[array[Notice, int]].ok scoreAnswer.noticeCounts rule

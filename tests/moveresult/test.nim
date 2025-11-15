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

  detailArr1: array[Cell, int] = [0, 1, 0, 4, 0, 5, 0, 9]
  detailArr2: array[Cell, int] = [0, 0, 0, 4, 4, 0, 0, 0]
  detailArr3: array[Cell, int] = [0, 0, 12, 4, 0, 8, 0, 6]
  detailPopCounts = @[detailArr1, detailArr2, detailArr3]

  fullArr1: array[Cell, seq[int]] = [@[], @[1], @[], @[4], @[], @[5], @[], @[4, 5]]
  fullArr2: array[Cell, seq[int]] = [@[], @[], @[], @[4], @[4], @[], @[], @[]]
  fullArr3: array[Cell, seq[int]] = [@[], @[], @[4, 4, 4], @[4], @[], @[5], @[], @[6]]
  fullPopCounts = @[fullArr1, fullArr2, fullArr3]

  moveRes1 = MoveResult.init(
    chainCount, popCounts, hardToGarbageCount, detailPopCounts, detailHardToGarbageCount
  )
  moveRes2 = MoveResult.init(
    chainCount, popCounts, hardToGarbageCount, detailPopCounts,
    detailHardToGarbageCount, fullPopCounts,
  )

# ------------------------------------------------
# Constructor
# ------------------------------------------------

block: # init
  check moveRes1 ==
    MoveResult(
      chainCount: chainCount,
      popCounts: popCounts,
      hardToGarbageCount: hardToGarbageCount,
      detailPopCounts: detailPopCounts,
      detailHardToGarbageCount: detailHardToGarbageCount,
      fullPopCounts: Opt[seq[array[Cell, seq[int]]]].err,
    )
  check moveRes2 ==
    MoveResult(
      chainCount: chainCount,
      popCounts: popCounts,
      hardToGarbageCount: hardToGarbageCount,
      detailPopCounts: detailPopCounts,
      detailHardToGarbageCount: detailHardToGarbageCount,
      fullPopCounts: Opt[seq[array[Cell, seq[int]]]].ok fullPopCounts,
    )

  check MoveResult.init == MoveResult.init(0, Cell.initArrayWith 0, 0, @[], @[])
  check MoveResult.init(true) ==
    MoveResult.init(0, Cell.initArrayWith 0, 0, @[], @[], @[])

# ------------------------------------------------
# Count
# ------------------------------------------------

block:
  # cellCount, puyoCount, colorPuyoCount, garbagesCount,
  # cellCounts, puyoCounts, colorPuyoCounts, garbagesCounts
  let
    countP = 15
    countY = 0
  check moveRes1.cellCount(Purple) == countP
  check moveRes2.cellCount(Purple) == countP
  check moveRes1.cellCount(Yellow) == countY
  check moveRes2.cellCount(Yellow) == countY

  let countPuyo = 57
  check moveRes1.puyoCount == countPuyo
  check moveRes2.puyoCount == countPuyo

  let countColor = 44
  check moveRes1.colorPuyoCount == countColor
  check moveRes2.colorPuyoCount == countColor

  let countGarbages = 13
  check moveRes1.garbagesCount == countGarbages
  check moveRes2.garbagesCount == countGarbages

  let
    countsB = @[5, 0, 8]
    countsY = @[0, 0, 0]
  check moveRes1.cellCounts(Blue) == countsB
  check moveRes2.cellCounts(Blue) == countsB
  check moveRes1.cellCounts(Yellow) == countsY
  check moveRes2.cellCounts(Yellow) == countsY

  let countsPuyo = @[19, 8, 30]
  check moveRes1.puyoCounts == countsPuyo
  check moveRes2.puyoCounts == countsPuyo

  let countsColor = @[18, 8, 18]
  check moveRes1.colorPuyoCounts == countsColor
  check moveRes2.colorPuyoCounts == countsColor

  let countsGarbages = @[1, 0, 12]
  check moveRes1.garbagesCounts == countsGarbages
  check moveRes2.garbagesCounts == countsGarbages

# ------------------------------------------------
# Color
# ------------------------------------------------

block: # colors, colorsSeq
  let colors2 = {Red, Green, Blue, Purple}
  check moveRes1.colors == colors2
  check moveRes2.colors == colors2

  let colorsSeq2 = @[{Red, Blue, Purple}, {Red, Green}, {Red, Blue, Purple}]
  check moveRes1.colorsSeq == colorsSeq2
  check moveRes2.colorsSeq == colorsSeq2

# ------------------------------------------------
# Place
# ------------------------------------------------

block: # placeCounts
  check moveRes1.placeCounts(Purple).isErr
  check moveRes2.placeCounts(Purple) == StrErrorResult[seq[int]].ok @[2, 0, 1]
  check moveRes1.placeCounts(Yellow).isErr
  check moveRes2.placeCounts(Yellow) == StrErrorResult[seq[int]].ok @[0, 0, 0]

  check moveRes1.placeCounts.isErr
  check moveRes2.placeCounts == StrErrorResult[seq[int]].ok @[4, 2, 3]

# ------------------------------------------------
# Connect
# ------------------------------------------------

block: # connectionCounts
  check moveRes1.connectionCounts(Purple).isErr
  check moveRes2.connectionCounts(Purple) == StrErrorResult[seq[int]].ok @[4, 5, 6]
  check moveRes1.connectionCounts(Yellow).isErr
  check moveRes2.connectionCounts(Yellow) == StrErrorResult[seq[int]].ok @[]

  check moveRes1.connectionCounts.isErr
  check moveRes2.connectionCounts ==
    StrErrorResult[seq[int]].ok @[4, 5, 4, 5, 4, 4, 4, 5, 6]

# ------------------------------------------------
# Score
# ------------------------------------------------

let scoreAns = 8660

block: # score
  check moveRes1.score.isErr
  check moveRes2.score == StrErrorResult[int].ok scoreAns

# ------------------------------------------------
# Notice Garbage
# ------------------------------------------------

block: # noticeCounts
  check moveRes1.noticeCounts(Tsu).isErr
  check moveRes2.noticeCounts(Tsu) ==
    StrErrorResult[array[Notice, int]].ok scoreAns.noticeCounts Tsu

  check moveRes1.noticeCounts(Water).isErr
  check moveRes2.noticeCounts(Water) ==
    StrErrorResult[array[Notice, int]].ok scoreAns.noticeCounts Water

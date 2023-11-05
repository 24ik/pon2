## This module implements moving results.
##

{.experimental: "strictDefs".}

import std/math except sum
import std/[sequtils, setutils, sugar]
import ./[cell, misc]
import ../private/[misc]

type
  NotSupportDefect* = object of Defect

  MoveResult* = object of RootObj
    ## Moving result.
    ## No available methods.
    chainCount: int

  RoughMoveResult* = object of MoveResult
    ## Moving result.
    ## Available methods:
    totalDisappearCounts: array[Puyo, int]

  DetailMoveResult* = object of RoughMoveResult
    disappearCounts: seq[array[Puyo, int]]

  FullMoveResult* = object of DetailMoveResult
    ## Moving result.
    detailDisappearCounts: seq[array[ColorPuyo, seq[int]]]

using
  moveRes: MoveResult
  roughRes: RoughMoveResult
  detailRes: DetailMoveResult
  fullRes: FullMoveResult

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func initMoveResult*(chainCount: int): MoveResult {.inline.} =
  ## Constructor of `MoveResult`.
  result.chainCount = chainCount

func initRoughMoveResult*(
    chainCount: int, totalDisappearCounts: array[Puyo, int]): RoughMoveResult
    {.inline.} =
  ## Constructor of `RoughMoveResult`.
  result.chainCount = chainCount
  result.totalDisappearCounts = totalDisappearCounts

func initDetailMoveResult*(
    chainCount: int, totalDisappearCounts: array[Puyo, int],
    disappearCounts: seq[array[Puyo, int]]): DetailMoveResult {.inline.} =
  ## Constructor of `DetailMoveResult`.
  result.chainCount = chainCount
  result.totalDisappearCounts = totalDisappearCounts
  result.disappearCounts = disappearCounts

func initFullMoveResult*(
    chainCount: int, totalDisappearCounts: array[Puyo, int],
    disappearCounts: seq[array[Puyo, int]],
    detailDisappearCounts: seq[array[ColorPuyo, seq[int]]]): FullMoveResult
    {.inline.} =
  ## Constructor of `FullMoveResult`.
  result.chainCount = chainCount
  result.totalDisappearCounts = totalDisappearCounts
  result.disappearCounts = disappearCounts
  result.detailDisappearCounts = detailDisappearCounts

# ------------------------------------------------
# Property
# ------------------------------------------------

func chainCount*(moveRes): int {.inline.} = moveRes.chainCount
  ## Returns the number of chains.

# ------------------------------------------------
# Count - Puyo
# ------------------------------------------------

func puyoCount*(moveRes; puyo: Puyo): int {.inline.} =
  ## Returns the number of `puyo` that disappeared.
  result = 0
  raise newException(NotSupportDefect, "Not support: `MoveResult.puyoCount")

func puyoCount*(moveRes): int {.inline.} =
  ## Returns the number of puyos that disappeared.
  result = 0
  raise newException(NotSupportDefect, "Not support: `MoveResult.puyoCount")

func puyoCount*(roughRes; puyo: Puyo): int {.inline.} =
  ## Returns the number of `puyo` that disappeared.
  roughRes.totalDisappearCounts[puyo]

func puyoCount*(roughRes): int {.inline.} =
  ## Returns the number of puyos that disappeared.
  roughRes.totalDisappearCounts.sum

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
# Counts - Puyo
# ------------------------------------------------

func puyoCounts*(moveRes; puyo: Puyo): seq[int] {.inline.} =
  ## Returns the number of `puyo` that disappeared in each chain.
  result = newSeq[int] 0
  raise newException(NotSupportDefect, "Not support: `MoveResult.puyoCounts")

func puyoCounts*(moveRes): seq[int] {.inline.} =
  ## Returns the number of puyos that disappeared in each chain.
  result = newSeq[int] 0
  raise newException(NotSupportDefect, "Not support: `MoveResult.puyoCounts")

func puyoCounts*(detailRes; puyo: Puyo): seq[int] {.inline.} =
  ## Returns the number of `puyo` that disappeared in each chain.
  detailRes.disappearCounts.mapIt it[puyo]

func puyoCounts*(detailRes): seq[int] {.inline.} =
  ## Returns the number of puyos that disappeared in each chain.
  detailRes.disappearCounts.mapIt it.sum

# ------------------------------------------------
# Counts - Color
# ------------------------------------------------

func colorCounts*(moveRes): seq[int] {.inline.} =
  ## Returns the number of color puyos that disappeared in each chain.
  result = newSeq[int] 0
  raise newException(NotSupportDefect, "Not support: `MoveResult.colorCounts")

func colorCounts*(detailRes): seq[int] {.inline.} =
  ## Returns the number of color puyos that disappeared in each chain.
  detailRes.disappearCounts.mapIt it[ColorPuyo.low..ColorPuyo.high].sum

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
# Colors
# ------------------------------------------------

func colors*(moveRes): set[ColorPuyo] {.inline.} =
  ## Returns the set of color puyos that disappeared.
  result = {}
  raise newException(NotSupportDefect, "Not support: `MoveResult.colors")

func colors*(roughRes): set[ColorPuyo] {.inline.} =
  ## Returns the set of color puyos that disappeared.
  result = {}
  for color in ColorPuyo:
    if roughRes.totalDisappearCounts[color] > 0:
      result.incl color

func colorsSeq*(moveRes): seq[set[ColorPuyo]] {.inline.} =
  ## Returns the sequence of the set of color puyos that disappeared.
  result = @[]
  raise newException(NotSupportDefect, "Not support: `MoveResult.colorsSeq")

func colorsSeq*(detailRes): seq[set[ColorPuyo]] {.inline.} =
  ## Returns the sequence of the set of color puyos that disappeared.
  collect:
    for arr in detailRes.disappearCounts:
      var colors = set[ColorPuyo]({})

      for color in ColorPuyo:
        if arr[color] > 0:
          colors.incl color

      colors

# ------------------------------------------------
# Place
# ------------------------------------------------

func colorPlaces*(moveRes; color: ColorPuyo): seq[int] {.inline.} =
  ## Returns the number of places where `color` disappeared in each chain.
  result = newSeq[int] 0
  raise newException(NotSupportDefect, "Not support: `MoveResult.colorPlaces")

func colorPlaces*(moveRes): seq[int] {.inline.} =
  ## Returns the number of places where color puyos disappeared in each chain.
  result = newSeq[int] 0
  raise newException(NotSupportDefect, "Not support: `MoveResult.colorPlaces")

func colorPlaces*(fullRes; color: ColorPuyo): seq[int] {.inline.} =
  ## Returns the number of places where `color` disappeared in each chain.
  fullRes.detailDisappearCounts.mapIt it[color].len

func colorPlaces*(fullRes): seq[int] {.inline.} =
  ## Returns the number of places where color puyos disappeared in each chain.
  collect:
    for countsArr in fullRes.detailDisappearCounts:
      sum (ColorPuyo.low..ColorPuyo.high).mapIt countsArr[it].len

# ------------------------------------------------
# Connect
# ------------------------------------------------

func colorConnects*(moveRes; color: ColorPuyo): seq[int] {.inline.} =
  ## Returns the number of connections of `color` that disappeared.
  result = newSeq[int] 0
  raise newException(NotSupportDefect, "Not support: `MoveResult.colorConnects")

func colorConnects*(moveRes): seq[int] {.inline.} =
  ## Returns the number of connections of color puyos that disappeared.
  result = newSeq[int] 0
  raise newException(NotSupportDefect, "Not support: `MoveResult.colorConnects")

func colorConnects*(fullRes; color: ColorPuyo): seq[int] {.inline.} =
  ## Returns the number of connections of `color` that disappeared.
  concat fullRes.detailDisappearCounts.mapIt it[color]

func colorConnects*(fullRes): seq[int] {.inline.} =
  ## Returns the number of connections of color puyos that disappeared.
  concat fullRes.detailDisappearCounts.mapIt it[ColorPuyo.low..ColorPuyo.high].concat

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

func connectBonus(puyoCounts: seq[int]): int {.inline.} =
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

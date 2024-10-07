## This module implements moving results.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[math, options, sequtils, setutils, sugar]
import ./[cell, fieldtype, notice, rule]
import ../private/[misc]

type MoveResult* = object ## Moving result.
  chainCount*: Natural
  disappearCounts*: array[Puyo, int]
  detailDisappearCounts*: Option[seq[array[Puyo, int]]]
  fullDisappearCounts*: Option[seq[array[ColorPuyo, seq[int]]]]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func initMoveResult*(
    chainCount: Natural, disappearCounts: array[Puyo, int]
): MoveResult {.inline.} =
  ## Returns a new move result.
  MoveResult(
    chainCount: chainCount,
    disappearCounts: disappearCounts,
    detailDisappearCounts: none seq[array[Puyo, int]],
    fullDisappearCounts: none seq[array[ColorPuyo, seq[int]]],
  )

func initMoveResult*(
    chainCount: Natural,
    disappearCounts: array[Puyo, int],
    detailDisappearCounts: seq[array[Puyo, int]],
): MoveResult {.inline.} =
  ## Returns a new move result.
  MoveResult(
    chainCount: chainCount,
    disappearCounts: disappearCounts,
    detailDisappearCounts: some detailDisappearCounts,
    fullDisappearCounts: none seq[array[ColorPuyo, seq[int]]],
  )

func initMoveResult*(
    chainCount: Natural,
    disappearCounts: array[Puyo, int],
    detailDisappearCounts: seq[array[Puyo, int]],
    fullDisappearCounts: seq[array[ColorPuyo, seq[int]]],
): MoveResult {.inline.} =
  ## Returns a new move result.
  MoveResult(
    chainCount: chainCount,
    disappearCounts: disappearCounts,
    detailDisappearCounts: some detailDisappearCounts,
    fullDisappearCounts: some fullDisappearCounts,
  )

# ------------------------------------------------
# Count
# ------------------------------------------------

func puyoCount*(self: MoveResult, puyo: Puyo): int {.inline.} =
  ## Returns the number of `puyo` that disappeared.
  self.disappearCounts[puyo]

func puyoCount*(self: MoveResult): int {.inline.} =
  ## Returns the number of puyos that disappeared.
  self.disappearCounts.sum2

func colorCount*(self: MoveResult): int {.inline.} =
  ## Returns the number of color puyos that disappeared.
  self.disappearCounts[ColorPuyo.low .. ColorPuyo.high].sum2

func garbageCount*(self: MoveResult): int {.inline.} =
  ## Returns the number of garbage puyos that disappeared.
  self.disappearCounts[Hard] + self.disappearCounts[Garbage]

# ------------------------------------------------
# Counts
# ------------------------------------------------

func puyoCounts*(self: MoveResult, puyo: Puyo): seq[int] {.inline.} =
  ## Returns the number of `puyo` that disappeared in each chain.
  ## `UnpackDefect` is raised if not supported.
  self.detailDisappearCounts.get.mapIt it[puyo]

func puyoCounts*(self: MoveResult): seq[int] {.inline.} =
  ## Returns the number of puyos that disappeared in each chain.
  ## `UnpackDefect` is raised if not supported.
  self.detailDisappearCounts.get.mapIt it.sum2

func colorCounts*(self: MoveResult): seq[int] {.inline.} =
  ## Returns the number of color puyos that disappeared in each chain.
  ## `UnpackDefect` is raised if not supported.
  self.detailDisappearCounts.get.mapIt it[ColorPuyo.low .. ColorPuyo.high].sum2

func garbageCounts*(self: MoveResult): seq[int] {.inline.} =
  ## Returns the number of garbage puyos that disappeared in each chain.
  ## `UnpackDefect` is raised if not supported.
  self.detailDisappearCounts.get.mapIt it[Hard] + it[Garbage]

# ------------------------------------------------
# Colors
# ------------------------------------------------

func colors*(self: MoveResult): set[ColorPuyo] {.inline.} =
  ## Returns the set of color puyos that disappeared.
  result = {}

  for color in ColorPuyo:
    if self.disappearCounts[color] > 0:
      result.incl color

func colorsSeq*(self: MoveResult): seq[set[ColorPuyo]] {.inline.} =
  ## Returns the sequence of the set of color puyos that disappeared.
  ## `UnpackDefect` is raised if not supported.
  collect:
    for arr in self.detailDisappearCounts.get:
      var colors = set[ColorPuyo]({})

      for color in ColorPuyo:
        if arr[color] > 0:
          colors.incl color

      colors

# ------------------------------------------------
# Place
# ------------------------------------------------

func colorPlaces*(self: MoveResult, color: ColorPuyo): seq[int] {.inline.} =
  ## Returns the number of places where `color` disappeared in each chain.
  ## `UnpackDefect` is raised if not supported.
  self.fullDisappearCounts.get.mapIt it[color].len

func colorPlaces*(self: MoveResult): seq[int] {.inline.} =
  ## Returns the number of places where color puyos disappeared in each chain.
  ## `UnpackDefect` is raised if not supported.
  collect:
    for countsArr in self.fullDisappearCounts.get:
      sum2 (ColorPuyo.low .. ColorPuyo.high).mapIt countsArr[it].len

# ------------------------------------------------
# Connect
# ------------------------------------------------

func colorConnects*(self: MoveResult, color: ColorPuyo): seq[int] {.inline.} =
  ## Returns the number of connections of `color` that disappeared.
  ## `UnpackDefect` is raised if not supported.
  concat self.fullDisappearCounts.get.mapIt it[color]

func colorConnects*(self: MoveResult): seq[int] {.inline.} =
  ## Returns the number of connections of color puyos that disappeared.
  ## `UnpackDefect` is raised if not supported.
  concat self.fullDisappearCounts.get.mapIt it[ColorPuyo.low .. ColorPuyo.high].concat

# ------------------------------------------------
# Score
# ------------------------------------------------

const
  ConnectBonuses = collect:
    for connect in 0 .. Height.pred * Width:
      if connect <= 4:
        0
      elif connect in 5 .. 10:
        connect - 3
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
    for color in 0 .. ColorPuyo.fullSet.card:
      if color <= 1:
        0
      else:
        3 * 2 ^ (color - 2)

func connectBonus(puyoCounts: seq[int]): int {.inline.} =
  ## Returns the connect bonus.
  result = 0

  for count in puyoCounts:
    result.inc ConnectBonuses[count]

func score*(self: MoveResult): int {.inline.} =
  ## Returns the score.
  ## `UnpackDefect` is raised if not supported.
  result = 0

  for chainIdx, countsArray in self.fullDisappearCounts.get:
    var
      connectBonus = 0
      puyoCount = 0
      colorCount = 0
    for color in ColorPuyo.low .. ColorPuyo.high:
      let counts = countsArray[color]
      connectBonus.inc counts.connectBonus

      let count = counts.sum2
      puyoCount.inc count

      if count > 0:
        colorCount.inc

    let colorBonus = ColorBonuses[colorCount]
    result.inc 10 * puyoCount *
      max(ChainBonuses[chainIdx.succ] + connectBonus + colorBonus, 1)

# ------------------------------------------------
# Notice Garbage
# ------------------------------------------------

func noticeGarbageCounts*(
    self: MoveResult, rule: Rule
): array[NoticeGarbage, int] {.inline.} =
  ## Returns the number of notice garbages.
  ## Note that this function calls `score()`.
  self.score.noticeGarbageCounts rule

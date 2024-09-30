## This module implements moving results.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[math, sequtils, setutils, sugar]
import ./[cell, fieldtype, notice, rule]
import ../private/[misc]

type
  MoveTrackingLevel* = enum
    ## Tracking level.
    ## The number of chains and puyos that disappeared are tracked in all level.
    ## Additionally, the followings are tracked:
    ## - Level0: None
    ## - Level1: Puyos that disappeared in each chain
    ## - Level2: Puyos that disappeared in each connected component in each chain
    Level0
    Level1
    Level2

  MoveResult* = object ## Moving result.
    chainCount*: Natural
    disappearCounts*: array[Puyo, int]

    case trackingLevel*: MoveTrackingLevel
    of Level0: discard
    of Level1: detailDisappearCounts*: seq[array[Puyo, int]]
    of Level2: fullDisappearCounts*: seq[array[ColorPuyo, seq[int]]]

using
  self: MoveResult
  mSelf: var MoveResult

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func initMoveResult*(
    chainCount: Natural, disappearCounts: array[Puyo, int]
): MoveResult {.inline.} =
  ## Returns a new move result.
  MoveResult(
    chainCount: chainCount, disappearCounts: disappearCounts, trackingLevel: Level0
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
    trackingLevel: Level1,
    detailDisappearCounts: detailDisappearCounts,
  )

func initMoveResult*(
    chainCount: Natural,
    disappearCounts: array[Puyo, int],
    fullDisappearCounts: seq[array[ColorPuyo, seq[int]]],
): MoveResult {.inline.} =
  ## Returns a new move result.
  MoveResult(
    chainCount: chainCount,
    disappearCounts: disappearCounts,
    trackingLevel: Level2,
    fullDisappearCounts: fullDisappearCounts,
  )

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `==`*(self; moveRes: MoveResult): bool {.inline.} =
  if self.chainCount != moveRes.chainCount or
      self.disappearCounts != moveRes.disappearCounts or
      self.trackingLevel != moveRes.trackingLevel:
    return false

  result =
    case self.trackingLevel
    of Level0:
      true
    of Level1:
      self.detailDisappearCounts == moveRes.detailDisappearCounts
    of Level2:
      self.fullDisappearCounts == moveRes.fullDisappearCounts

# ------------------------------------------------
# Count
# ------------------------------------------------

func puyoCount*(self; puyo: Puyo): int {.inline.} =
  ## Returns the number of `puyo` that disappeared.
  self.disappearCounts[puyo]

func puyoCount*(self): int {.inline.} =
  ## Returns the number of puyos that disappeared.
  self.disappearCounts.sum2

func colorCount*(self): int {.inline.} =
  ## Returns the number of color puyos that disappeared.
  self.disappearCounts[ColorPuyo.low .. ColorPuyo.high].sum2

func garbageCount*(self): int {.inline.} =
  ## Returns the number of garbage puyos that disappeared.
  self.disappearCounts[Hard] + self.disappearCounts[Garbage]

# ------------------------------------------------
# Counts
# ------------------------------------------------

func puyoCounts*(self; puyo: Puyo): seq[int] {.inline.} =
  ## Returns the number of `puyo` that disappeared in each chain.
  ## `FieldDefect` is raised if not supported.
  self.detailDisappearCounts.mapIt it[puyo]

func puyoCounts*(self): seq[int] {.inline.} =
  ## Returns the number of puyos that disappeared in each chain.
  ## `FieldDefect` is raised if not supported.
  self.detailDisappearCounts.mapIt it.sum2

func colorCounts*(self): seq[int] {.inline.} =
  ## Returns the number of color puyos that disappeared in each chain.
  ## `FieldDefect` is raised if not supported.
  self.detailDisappearCounts.mapIt it[ColorPuyo.low .. ColorPuyo.high].sum2

func garbageCounts*(self): seq[int] {.inline.} =
  ## Returns the number of garbage puyos that disappeared in each chain.
  ## `FieldDefect` is raised if not supported.
  self.detailDisappearCounts.mapIt it[Hard] + it[Garbage]

# ------------------------------------------------
# Colors
# ------------------------------------------------

func colors*(self): set[ColorPuyo] {.inline.} =
  ## Returns the set of color puyos that disappeared.
  result = {}
  for color in ColorPuyo:
    if self.disappearCounts[color] > 0:
      result.incl color

func colorsSeq*(self): seq[set[ColorPuyo]] {.inline.} =
  ## Returns the sequence of the set of color puyos that disappeared.
  ## `FieldDefect` is raised if not supported.
  collect:
    for arr in self.detailDisappearCounts:
      var colors = set[ColorPuyo]({})

      for color in ColorPuyo:
        if arr[color] > 0:
          colors.incl color

      colors

# ------------------------------------------------
# Place
# ------------------------------------------------

func colorPlaces*(self; color: ColorPuyo): seq[int] {.inline.} =
  ## Returns the number of places where `color` disappeared in each chain.
  ## `FieldDefect` is raised if not supported.
  self.fullDisappearCounts.mapIt it[color].len

func colorPlaces*(self): seq[int] {.inline.} =
  ## Returns the number of places where color puyos disappeared in each chain.
  ## `FieldDefect` is raised if not supported.
  collect:
    for countsArr in self.fullDisappearCounts:
      sum2 (ColorPuyo.low .. ColorPuyo.high).mapIt countsArr[it].len

# ------------------------------------------------
# Connect
# ------------------------------------------------

func colorConnects*(self; color: ColorPuyo): seq[int] {.inline.} =
  ## Returns the number of connections of `color` that disappeared.
  ## `FieldDefect` is raised if not supported.
  concat self.fullDisappearCounts.mapIt it[color]

func colorConnects*(self): seq[int] {.inline.} =
  ## Returns the number of connections of color puyos that disappeared.
  ## `FieldDefect` is raised if not supported.
  concat self.fullDisappearCounts.mapIt it[ColorPuyo.low .. ColorPuyo.high].concat

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

func score*(self): int {.inline.} =
  ## Returns the score.
  ## `FieldDefect` is raised if not supported.
  result = 0

  for chainIdx, countsArray in self.fullDisappearCounts:
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

func noticeGarbageCounts*(self; rule: Rule): array[NoticeGarbage, int] {.inline.} =
  ## Returns the number of notice garbages.
  ## Note that this function calls `score()`.
  self.score.noticeGarbageCounts rule

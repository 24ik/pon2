## This module implements moving results.
##
## Compile Options:
## | Option                            | Description                 | Default  |
## | --------------------------------- | --------------------------- | -------- |
## | `-d:pon2.garbagerate.tsu=<int>`   | Garbage rate in Tsu rule.   | `70`     |
## | `-d:pon2.garbagerate.water=<int>` | Garbage rate in Water rule. | `90`     |
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[math, options, sequtils, setutils, sugar]
import ./[cell, fieldtype, rule]
import ../private/[misc]

type
  MoveResult* = object ## Moving result.
    chainCount*: int
    totalDisappearCounts*: Option[array[Puyo, int]]
    disappearCounts*: Option[seq[array[Puyo, int]]]
    detailDisappearCounts*: Option[seq[array[ColorPuyo, seq[int]]]]

  NoticeGarbage* {.pure.} = enum
    ## Notice garbage puyo.
    Small
    Big
    Rock
    Star
    Moon
    Crown
    Comet

const
  TsuGarbageRate {.define: "pon2.garbagerate.tsu".} = 70
  WaterGarbageRate {.define: "pon2.garbagerate.water".} = 90
  GarbageRates*: array[Rule, Positive] = [TsuGarbageRate.Positive, WaterGarbageRate]

using
  self: MoveResult
  mSelf: var MoveResult

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func initMoveResult*(chainCount: int): MoveResult {.inline.} =
  ## Returns a new move result.
  result.chainCount = chainCount
  {.push warning[ProveInit]: off.}
  result.totalDisappearCounts = none array[Puyo, int]
  result.disappearCounts = none seq[array[Puyo, int]]
  result.detailDisappearCounts = none seq[array[ColorPuyo, seq[int]]]
  {.pop.}

func initMoveResult*(
    chainCount: int, totalDisappearCounts: array[Puyo, int]
): MoveResult {.inline.} =
  ## Returns a new move result.
  result.chainCount = chainCount
  result.totalDisappearCounts = some totalDisappearCounts
  {.push warning[ProveInit]: off.}
  result.disappearCounts = none seq[array[Puyo, int]]
  result.detailDisappearCounts = none seq[array[ColorPuyo, seq[int]]]
  {.pop.}

func initMoveResult*(
    chainCount: int,
    totalDisappearCounts: array[Puyo, int],
    disappearCounts: seq[array[Puyo, int]],
): MoveResult {.inline.} =
  ## Returns a new move result.
  result.chainCount = chainCount
  result.totalDisappearCounts = some totalDisappearCounts
  result.disappearCounts = some disappearCounts
  {.push warning[ProveInit]: off.}
  result.detailDisappearCounts = none seq[array[ColorPuyo, seq[int]]]
  {.pop.}

func initMoveResult*(
    chainCount: int,
    totalDisappearCounts: array[Puyo, int],
    disappearCounts: seq[array[Puyo, int]],
    detailDisappearCounts: seq[array[ColorPuyo, seq[int]]],
): MoveResult {.inline.} =
  ## Returns a new move result.
  result.chainCount = chainCount
  result.totalDisappearCounts = some totalDisappearCounts
  result.disappearCounts = some disappearCounts
  result.detailDisappearCounts = some detailDisappearCounts

# ------------------------------------------------
# Count
# ------------------------------------------------

func puyoCount*(self; puyo: Puyo): int {.inline.} =
  ## Returns the number of `puyo` that disappeared.
  ## `UnpackDefect` will be raised if not supported.
  self.totalDisappearCounts.get[puyo]

func puyoCount*(self): int {.inline.} =
  ## Returns the number of puyos that disappeared.
  ## `UnpackDefect` will be raised if not supported.
  self.totalDisappearCounts.get.sum2

func colorCount*(self): int {.inline.} =
  ## Returns the number of color puyos that disappeared.
  ## `UnpackDefect` will be raised if not supported.
  self.totalDisappearCounts.get[ColorPuyo.low .. ColorPuyo.high].sum2

func garbageCount*(self): int {.inline.} =
  ## Returns the number of garbage puyos that disappeared.
  ## `UnpackDefect` will be raised if not supported.
  self.totalDisappearCounts.get[Hard] + self.totalDisappearCounts.get[Garbage]

# ------------------------------------------------
# Counts
# ------------------------------------------------

func puyoCounts*(self; puyo: Puyo): seq[int] {.inline.} =
  ## Returns the number of `puyo` that disappeared in each chain.
  ## `UnpackDefect` will be raised if not supported.
  self.disappearCounts.get.mapIt it[puyo]

func puyoCounts*(self): seq[int] {.inline.} =
  ## Returns the number of puyos that disappeared in each chain.
  ## `UnpackDefect` will be raised if not supported.
  self.disappearCounts.get.mapIt it.sum2

func colorCounts*(self): seq[int] {.inline.} =
  ## Returns the number of color puyos that disappeared in each chain.
  ## `UnpackDefect` will be raised if not supported.
  self.disappearCounts.get.mapIt it[ColorPuyo.low .. ColorPuyo.high].sum2

func garbageCounts*(self): seq[int] {.inline.} =
  ## Returns the number of garbage puyos that disappeared in each chain.
  ## `UnpackDefect` will be raised if not supported.
  self.disappearCounts.get.mapIt it[Hard] + it[Garbage]

# ------------------------------------------------
# Colors
# ------------------------------------------------

func colors*(self): set[ColorPuyo] {.inline.} =
  ## Returns the set of color puyos that disappeared.
  ## `UnpackDefect` will be raised if not supported.
  result = {}
  for color in ColorPuyo:
    if self.totalDisappearCounts.get[color] > 0:
      result.incl color

func colorsSeq*(self): seq[set[ColorPuyo]] {.inline.} =
  ## Returns the sequence of the set of color puyos that disappeared.
  ## `UnpackDefect` will be raised if not supported.
  collect:
    for arr in self.disappearCounts.get:
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
  ## `UnpackDefect` will be raised if not supported.
  self.detailDisappearCounts.get.mapIt it[color].len

func colorPlaces*(self): seq[int] {.inline.} =
  ## Returns the number of places where color puyos disappeared in each chain.
  ## `UnpackDefect` will be raised if not supported.
  collect:
    for countsArr in self.detailDisappearCounts.get:
      sum2 (ColorPuyo.low .. ColorPuyo.high).mapIt countsArr[it].len

# ------------------------------------------------
# Connect
# ------------------------------------------------

func colorConnects*(self; color: ColorPuyo): seq[int] {.inline.} =
  ## Returns the number of connections of `color` that disappeared.
  ## `UnpackDefect` will be raised if not supported.
  concat self.detailDisappearCounts.get.mapIt it[color]

func colorConnects*(self): seq[int] {.inline.} =
  ## Returns the number of connections of color puyos that disappeared.
  ## `UnpackDefect` will be raised if not supported.
  concat self.detailDisappearCounts.get.mapIt it[ColorPuyo.low .. ColorPuyo.high].concat

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
  ## `UnpackDefect` will be raised if not supported.
  result = 0

  for chainIdx, countsArray in self.detailDisappearCounts.get:
    let
      disappearCounts =
        self.disappearCounts.get[chainIdx][ColorPuyo.low .. ColorPuyo.high]

      chainBonus = ChainBonuses[chainIdx.succ]
      connectBonus =
        sum2 countsArray[ColorPuyo.low .. ColorPuyo.high].mapIt it.connectBonus
      colorBonus = ColorBonuses[disappearCounts.countIt it > 0]

    result.inc 10 * disappearCounts.sum2 * max(
      chainBonus + connectBonus + colorBonus, 1
    )

# ------------------------------------------------
# Notice Garbage
# ------------------------------------------------

const NoticeUnits: array[NoticeGarbage, Natural] = [1, 6, 30, 180, 360, 720, 1440]

func noticeGarbageCounts*(
    score: Natural, rule: Rule
): array[NoticeGarbage, int] {.inline.} =
  ## Returns the number of notice garbages.
  result[Small] = 0 # HACK: dummy to suppress warning

  var score2 = score div GarbageRates[rule]
  for notice in countdown(NoticeGarbage.high, NoticeGarbage.low):
    let unit = NoticeUnits[notice]
    result[notice] = score2 div unit
    score2.dec result[notice] * unit

func noticeGarbageCounts*(self; rule: Rule): array[NoticeGarbage, int] {.inline.} =
  ## Returns the number of notice garbages.
  ## Note that this function calls `score()`.
  self.score.noticeGarbageCounts rule

## This module implements move results.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, strformat, sugar]
import ./[cell, common, notice, rule]
import ../private/[arrayops2, math2, results2, staticfor2]

export results2

type MoveResult* = object ## Move result.
  chainCnt*: int
  popCnts*: array[Cell, int]
  hardToGarbageCnt*: int
  detailPopCnts*: seq[array[Cell, int]]
  detailHardToGarbageCnt*: seq[int]
  fullPopCnts*: Opt[seq[array[Cell, seq[int]]]]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(
    T: type MoveResult,
    chainCnt: int,
    popCnts: array[Cell, int],
    hardToGarbageCnt: int,
    detailPopCnts: seq[array[Cell, int]],
    detailHardToGarbageCnt: seq[int],
): T {.inline, noinit.} =
  T(
    chainCnt: chainCnt,
    popCnts: popCnts,
    hardToGarbageCnt: hardToGarbageCnt,
    detailPopCnts: detailPopCnts,
    detailHardToGarbageCnt: detailHardToGarbageCnt,
    fullPopCnts: Opt[seq[array[Cell, seq[int]]]].err,
  )

func init*(
    T: type MoveResult,
    chainCnt: int,
    popCnts: array[Cell, int],
    hardToGarbageCnt: int,
    detailPopCnts: seq[array[Cell, int]],
    detailHardToGarbageCnt: seq[int],
    fullPopCnts: seq[array[Cell, seq[int]]],
): T {.inline, noinit.} =
  T(
    chainCnt: chainCnt,
    popCnts: popCnts,
    hardToGarbageCnt: hardToGarbageCnt,
    detailPopCnts: detailPopCnts,
    detailHardToGarbageCnt: detailHardToGarbageCnt,
    fullPopCnts: Opt[seq[array[Cell, seq[int]]]].ok fullPopCnts,
  )

func init*(
    T: type MoveResult, includeFullPopCnts: static bool = false
): T {.inline, noinit.} =
  when includeFullPopCnts:
    T.init(0, static(initArrWith[Cell, int](0)), 0, @[], @[], @[])
  else:
    T.init(0, static(initArrWith[Cell, int](0)), 0, @[], @[])

# ------------------------------------------------
# Count
# ------------------------------------------------

func sumColor(arr: array[Cell, int]): int {.inline, noinit.} =
  ## Returns the total number of color puyos.
  (arr[Red] + arr[Green] + arr[Blue]) + (arr[Yellow] + arr[Purple])

func cellCnt*(self: MoveResult, cell: Cell): int {.inline, noinit.} =
  ## Returns the number of `cell` that popped.
  self.popCnts[cell]

func puyoCnt*(self: MoveResult): int {.inline, noinit.} =
  ## Returns the number of cells that popped.
  self.popCnts.sum2

func colorPuyoCnt*(self: MoveResult): int {.inline, noinit.} =
  ## Returns the number of color puyos that popped.
  self.popCnts.sumColor

func garbagesCnt*(self: MoveResult): int {.inline, noinit.} =
  ## Returns the number of hard and garbage puyos that popped.
  self.popCnts[Hard] + self.popCnts[Garbage]

func cellCnts*(self: MoveResult, cell: Cell): seq[int] {.inline, noinit.} =
  ## Returns a sequence of the number of `cell` that popped in each chain.
  self.detailPopCnts.mapIt it[cell]

func puyoCnts*(self: MoveResult): seq[int] {.inline, noinit.} =
  ## Returns a sequence of the number of puyos that popped in each chain.
  self.detailPopCnts.mapIt it.sum2

func colorPuyoCnts*(self: MoveResult): seq[int] {.inline, noinit.} =
  ## Returns a sequence of the number of color puyos that popped in each chain.
  self.detailPopCnts.mapIt it.sumColor

func garbagesCnts*(self: MoveResult): seq[int] {.inline, noinit.} =
  ## Returns a sequence of the number of hard and garbage puyos that popped in
  ## each chain.
  self.detailPopCnts.mapIt it[Hard] + it[Garbage]

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
  self.popCnts.colors

func colorsSeq*(self: MoveResult): seq[set[Cell]] {.inline, noinit.} =
  ## Returns a sequence of the set of colors that popped in each chain.
  self.detailPopCnts.mapIt it.colors

# ------------------------------------------------
# Place
# ------------------------------------------------

func placeCnts*(self: MoveResult, cell: Cell): Res[seq[int]] {.inline, noinit.} =
  ## Returns a sequence of the number of places where `cell` popped in each chain.
  if self.fullPopCnts.isOk:
    ok self.fullPopCnts.unsafeValue.mapIt it[cell].len
  else:
    err "`placeCnts` not supported: {self}".fmt

func placeCnts*(self: MoveResult): Res[seq[int]] {.inline, noinit.} =
  ## Returns a sequence of the number of places where color puyos popped in each chain.
  if self.fullPopCnts.isOk:
    ok self.fullPopCnts.unsafeValue.mapIt (it[Red].len + it[Green].len + it[Blue].len) +
      (it[Yellow].len + it[Purple].len)
  else:
    err "`placeCnts` not supported: {self}".fmt

# ------------------------------------------------
# Connect
# ------------------------------------------------

func connCnts*(self: MoveResult, cell: Cell): Res[seq[int]] {.inline, noinit.} =
  ## Returns a sequence of the number of connections of `cell` that popped.
  if self.fullPopCnts.isOk:
    ok concat self.fullPopCnts.unsafeValue.mapIt it[cell]
  else:
    err "`conns` not supported: {self}".fmt

func connCnts*(self: MoveResult): Res[seq[int]] {.inline, noinit.} =
  ## Returns a sequence of the number of connections of color puyos that popped.
  if self.fullPopCnts.isOk:
    ok concat self.fullPopCnts.unsafeValue.mapIt it[Red .. Purple].concat
  else:
    err "`conns` not supported: {self}".fmt

# ------------------------------------------------
# Score
# ------------------------------------------------

const
  ConnBonuses = collect:
    for conn in 0 .. Height.pred * Width:
      if conn <= 4:
        0
      elif conn in 5 .. 10:
        conn - 3
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

func connBonus(cnts: seq[int]): int {.inline, noinit.} =
  ## Returns the connect bonus.
  sum2 cnts.mapIt ConnBonuses[it]

func score*(self: MoveResult): Res[int] {.inline, noinit.} =
  ## Returns the score.
  if self.fullPopCnts.isErr:
    return err "`score` not supported: {self}".fmt

  var totalScore = 0
  for chainIdx, cntsArr in self.fullPopCnts.unsafeValue:
    var
      connBonus = 0
      totalPuyoCnt = 0
      colorCnt = 0

    staticFor(cell, Red .. Purple):
      connBonus.inc cntsArr[cell].connBonus

      let puyoCnt = self.detailPopCnts[chainIdx][cell]
      totalPuyoCnt.inc puyoCnt

      if puyoCnt > 0:
        colorCnt.inc

    let
      hardCnt = self.detailPopCnts[chainIdx][Hard]
      hardToGarbageCnt = self.detailHardToGarbageCnt[chainIdx]
      colorBonus = ColorBonuses[colorCnt]

    totalScore.inc ((totalPuyoCnt + hardToGarbageCnt) * 10 + hardCnt * 80) *
      max(ChainBonuses[chainIdx.succ] + connBonus + colorBonus, 1)

  ok totalScore

# ------------------------------------------------
# Notice Garbage
# ------------------------------------------------

func noticeGarbageCnts*(
    self: MoveResult, rule: Rule, useComet = false
): Res[array[NoticeGarbage, int]] {.inline, noinit.} =
  ## Returns the number of notice garbages.
  (?self.score.context "`noticeGarbageCnts` not supported: {self}".fmt).noticeGarbageCnts(
    rule, useComet
  )

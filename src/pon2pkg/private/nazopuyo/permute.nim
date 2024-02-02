## This module implements procedures used in permutation.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques, sequtils, sugar]
import ../../corepkg/[cell, field, pair]
import ../../nazopuyopkg/[nazopuyo]

func allPairsSeq(
    originalPairs: Pairs, fixMoves: openArray[Positive], allowDouble: bool,
    allowLastDouble: bool, colorCounts: array[ColorPuyo, Natural],
    idx: Natural, moveCount: Positive): seq[Pairs] {.inline.} =
  ## Returns all possible pairs in ascending order that can be obtained by
  ## permuting puyos contained in the `originalPairs`.
  # NOTE: Swapped pair sometimes gives a different solution, but this function
  # does not consider it.
  if idx == moveCount:
    return @[initDeque[Pair](moveCount)]

  result = @[]
  let nowLast = idx == moveCount.pred

  for axis in ColorPuyo:
    if colorCounts[axis] == 0:
      continue

    var newColorCountsMid = colorCounts
    newColorCountsMid[axis].dec

    for child in axis..ColorPuyo.high:
      if axis == child and (
          not allowDouble or (nowLast and not allowLastDouble)):
        continue
      if newColorCountsMid[child] == 0:
        continue

      var newColorCounts = newColorCountsMid
      newColorCounts[child].dec

      let
        nowPairTmp = initPair(axis, child)
        nowPair: Pair
      if idx.succ in fixMoves:
        if originalPairs[idx] notin {nowPairTmp, nowPairTmp.swapped}:
          continue

        nowPair = originalPairs[idx]
      else:
        nowPair = nowPairTmp

      result &= originalPairs.allPairsSeq(
        fixMoves, allowDouble, allowLastDouble, newColorCounts, idx.succ,
        moveCount).mapIt it.dup addFirst(nowPair)

func allPairsSeq*[F: TsuField or WaterField](
    nazo: NazoPuyo[F], fixMoves: openArray[Positive], allowDouble: bool,
    allowLastDouble: bool): seq[Pairs] {.inline.} =
  ## Returns all possible pairs in ascending order that can be obtained by
  ## permuting puyos contained in the pairs.
  # NOTE: Swapped pair sometimes gives a different solution, but this function
  # does not consider it.
  var colorCounts: array[ColorPuyo, Natural] = [0, 0, 0, 0, 0]
  for color in ColorPuyo:
    colorCounts[color] = nazo.environment.pairs.puyoCount color

  result = nazo.environment.pairs.allPairsSeq(
    fixMoves.deduplicate, allowDouble, allowLastDouble, colorCounts, 0,
    nazo.moveCount)

## This module implements helper procedures used in permutation.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, sugar]
import ../../core/[cell, field, nazopuyo, pair, pairposition]

func allPairsPositionsSeq(
    originalPairsPositions: PairsPositions,
    fixMoves: openArray[Positive],
    allowDouble: bool,
    allowLastDouble: bool,
    colorCounts: array[ColorPuyo, Natural],
    idx: Natural,
    moveCount: Positive,
): seq[PairsPositions] {.inline.} =
  ## Returns all possible pairs (and positions) in ascending order that can be
  ## obtained by permuting puyos contained in the `originalPairsPositions`.
  # NOTE: Swapped pair sometimes gives a different solution, but this function
  # does not consider it.
  if idx == moveCount:
    return @[]

  result = @[]
  let nowLast = idx == moveCount.pred

  for axis in ColorPuyo:
    if colorCounts[axis] == 0:
      continue

    var newColorCountsMid = colorCounts
    newColorCountsMid[axis].dec

    for child in axis .. ColorPuyo.high:
      if axis == child and (not allowDouble or (nowLast and not allowLastDouble)):
        continue
      if newColorCountsMid[child] == 0:
        continue

      var newColorCounts = newColorCountsMid
      newColorCounts[child].dec

      let
        nowPairTmp = initPair(axis, child)
        nowPair: Pair
      if idx.succ in fixMoves:
        if originalPairsPositions[idx].pair notin {nowPairTmp, nowPairTmp.swapped}:
          continue

        nowPair = originalPairsPositions[idx].pair
      else:
        nowPair = nowPairTmp

      result &=
        originalPairsPositions.allPairsPositionsSeq(
          fixMoves, allowDouble, allowLastDouble, newColorCounts, idx.succ, moveCount
        ).mapIt it.dup insert(nowPair, 0)

func allPairsPositionsSeq*[F: TsuField or WaterField](
    nazo: NazoPuyo[F],
    fixMoves: openArray[Positive],
    allowDouble: bool,
    allowLastDouble: bool,
): seq[Pairs] {.inline.} =
  ## Returns all possible pairs (and positions) in ascending order that can be
  ## obtained by permuting puyos contained in the pairs.
  # NOTE: Swapped pair sometimes gives a different solution, but this function
  # does not consider it.
  var colorCounts: array[ColorPuyo, Natural] = [0, 0, 0, 0, 0]
  for color in ColorPuyo:
    colorCounts[color] = nazo.puyoPuyo.pairs.puyoCount color

  result = nazo.puyoPuyo.pairsPositions.allPairsPositionsSeq(
    fixMoves.deduplicate, allowDouble, allowLastDouble, colorCounts, 0, nazo.moveCount
  )

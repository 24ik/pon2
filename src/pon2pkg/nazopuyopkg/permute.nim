## This module implements permuters.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques, sequtils, sugar]
import ../corepkg/[cell, field, pair, position]
import ../nazopuyopkg/[nazopuyo, solve]

when not defined(js):
  import std/[cpuinfo]
  import suru

# ------------------------------------------------
# Permute
# ------------------------------------------------

const SuruBarUpdateMs = 100

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

iterator permute*[F: TsuField or WaterField](
    nazo: NazoPuyo[F], fixMoves: seq[Positive], allowDouble: bool,
    allowLastDouble: bool,
    parallelCount: Positive = (
      when defined(js): 1 else: max(countProcessors(), 1)),
    showProgress = false): tuple[pairs: Pairs, answer: Positions] {.inline.} =
  ## Yields pairs and answer of the nazo puyo that is obtained by permuting
  ## pairs and has a unique solution.
  ## `parallelCount` and `showProgress` will be ignored on JS backend.
  var colorCounts: array[ColorPuyo, Natural] = [0, 0, 0, 0, 0]
  for color in ColorPuyo:
    colorCounts[color] = nazo.environment.pairs.puyoCount color
  let pairsSeq = nazo.environment.pairs.allPairsSeq(
    fixMoves.deduplicate true, allowDouble, allowLastDouble, colorCounts, 0,
    nazo.moveCount)

  when not defined(js):
    var bar: SuruBar
    if showProgress:
      bar = initSuruBar()
      bar[0].total = pairsSeq.len
      bar.setup

  for pairs in pairsSeq:
    var nazo2 = nazo
    nazo2.environment.pairs = pairs

    let answers = nazo2.solve(parallelCount, earlyStopping = true)

    when not defined(js):
      bar.inc
      bar.update SuruBarUpdateMs * 1000 * 1000

    if answers.len == 1:
      yield (pairs, answers[0])

  when not defined(js):
    if showProgress:
      bar.finish

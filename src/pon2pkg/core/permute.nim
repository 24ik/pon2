## This module implements the permuter.
##

import deques
import math
import sequtils
import sugar

import nazopuyo_core
import puyo_core

import ./solve

when not defined(js):
  import cpuinfo

  import suru

# ------------------------------------------------
# Permute
# ------------------------------------------------

const SuruBarUpdateMs = 100

iterator allPairsSeq(
  originalPairs: Pairs,
  fixMoves: seq[Positive],
  allowDouble: bool,
  allowLastDouble: bool,
  skipSwap: bool
): seq[Pairs] {.inline.} =
  ## Yields all possible pairs in ascending order that can be obtained by permuting puyoes contained in the
  ## `originalPairs`.
  # calculate the number of puyoes
  let moveCount = originalPairs.len
  var colorCounts: array[ColorPuyo, Natural]
  for color in ColorPuyo.low .. ColorPuyo.high:
    colorCounts[color] = originalPairs.count color

  # HACK: we use a stack instead of recursion since a recursive iterator is not allowed by Nim
  var stack: Deque[tuple[colorCounts: array[ColorPuyo, Natural], pairsSeq: seq[Pairs]]]
  stack.addLast (colorCounts, @[initDeque[Pair](moveCount)])

  while stack.len > 0:
    let
      (nowColorCounts, nowPairsSeq) = stack.popLast
      nowPairsLen = nowPairsSeq[0].len

    if nowPairsLen == moveCount:
      yield nowPairsSeq
      continue

    # HACK: reversed loop make the result ascending order
    for axisColor in countdown(ColorPuyo.high, ColorPuyo.low):
      if nowColorCounts[axisColor] < 1:
        continue

      for childColor in countdown(ColorPuyo.high, axisColor):
        var newPairs: seq[Pair]
        if axisColor == childColor:
          if not allowDouble:
            continue
          if not allowLastDouble and nowPairsLen == moveCount.pred:
            continue
          if nowColorCounts[axisColor] < 2:
            continue

          let newPair = [axisColor, childColor].toPair
          if nowPairsLen.succ in fixMoves and originalPairs[nowPairsLen] != newPair:
            continue

          newPairs = @[newPair]
        else:
          if nowColorCounts[childColor] < 1:
            continue

          let
            pair1 = [axisColor, childColor].toPair
            pair2 = pair1.swapped
          if nowPairsLen.succ in fixMoves:
            if originalPairs[nowPairsLen] notin {pair1, pair2}:
              continue

            newPairs = @[originalPairs[nowPairsLen]]
          else:
            newPairs = if skipSwap: @[pair1] else: @[pair1, pair2]

        var newColorCounts = nowColorCounts
        newColorCounts[axisColor].dec
        newColorCounts[childColor].dec

        let newPairsSeq = collect:
          for nowPairs in nowPairsSeq:
            for newPair in newPairs:
              var newPairs = nowPairs
              newPairs.addLast newPair
              newPairs

        stack.addLast (newColorCounts, newPairsSeq)

iterator permute*(
  nazo: NazoPuyo,
  fixMoves: seq[Positive],
  allowDouble: bool,
  allowLastDouble: bool,
  skipSwap: bool,
  parallelCount = (when defined(js): 1 else: max(countProcessors(), 1)),
  showProgress = false,
): tuple[pairs: Pairs, answer: Positions] {.inline.} =
  ## Yields the pairs and the answer of the nazo puyo that is obtained by permuting puyoes contained in the pairs,
  ## and has a unique solution.
  ## `parallelCount` and `showProgress` will be ignored on JS backend.
  let pairsSeqSeq =
    nazo.environment.pairs.allPairsSeq(fixMoves.deduplicate true, allowDouble, allowLastDouble, skipSwap).toSeq

  when not defined(js):
    var bar: SuruBar
    if showProgress:
      bar = initSuruBar()
      bar[0].total = sum pairsSeqSeq.mapIt it.len
      bar.setup

  for pairsSeq in pairsSeqSeq:
    for pairs in pairsSeq:
      var nazo2 = nazo
      nazo2.environment.pairs = pairs

      let answers = nazo2.inspectSolve(parallelCount, showProgress, true).answers

      when not defined(js):
        bar.inc
        bar.update SuruBarUpdateMs * 1000 * 1000

      if answers.len == 1:
        yield (pairs, answers[0])
        break # TODO: swapped pair sometimes gives a different solution

  # `bar.finish` affects stdout, so we need to branch here
  when not defined(js):
    if showProgress:
      bar.finish

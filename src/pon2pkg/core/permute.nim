## This module implements the permuter.
##

import deques
import math
import options
import sequtils
import sugar

import nazopuyo_core
import puyo_core

import ./solve

# ------------------------------------------------
# Permute
# ------------------------------------------------

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
  let moveNum = originalPairs.len
  var colorNums: array[ColorPuyo, Natural]
  for color in ColorPuyo.low .. ColorPuyo.high:
    colorNums[color] = originalPairs.colorNum color

  # HACK: we use a stack instead of recursion since a recursive iterator is not allowed by Nim
  var stack: Deque[tuple[colorNums: array[ColorPuyo, Natural], pairsSeq: seq[Pairs]]]
  stack.addLast (colorNums: colorNums, pairsSeq: @[initDeque[Pair](moveNum)])

  while stack.len > 0:
    let
      (nowColorNums, nowPairsSeq) = stack.popLast
      nowPairsLen = nowPairsSeq[0].len

    if nowPairsLen == moveNum:
      yield nowPairsSeq
      continue

    # HACK: reversed loop make the result ascending order.
    for axisColor in countdown(ColorPuyo.high, ColorPuyo.low):
      if nowColorNums[axisColor] < 1:
        continue

      for childColor in countdown(ColorPuyo.high, axisColor):
        var newPairs: seq[Pair]
        if axisColor == childColor:
          if not allowDouble:
            continue
          if not allowLastDouble and nowPairsLen == moveNum.pred:
            continue
          if nowColorNums[axisColor] < 2:
            continue

          let newPair = [axisColor, childColor].toPair
          if nowPairsLen.succ in fixMoves and originalPairs[nowPairsLen] != newPair:
            continue

          newPairs = @[newPair]
        else:
          if nowColorNums[childColor] < 1:
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

        var newColorNums = nowColorNums
        newColorNums[axisColor].dec
        newColorNums[childColor].dec

        let newPairsSeq = collect:
          for nowPairs in nowPairsSeq:
            for newPair in newPairs:
              var newPairs = nowPairs
              newPairs.addLast newPair
              newPairs

        stack.addLast (colorNums: newColorNums, pairsSeq: newPairsSeq)

iterator permute*(
  nazo: Nazo,
  fixMoves: seq[Positive],
  allowDouble: bool,
  allowLastDouble: bool,
  skipSwap: bool,
): tuple[pairs: Pairs, solution: Solution]{.inline.} =
  ## Yields the pairs and solution of the `nazo` that is obtained by permuting puyoes contained in the pairs,
  ## and has a unique solution.
  for pairsSeq in nazo.env.pairs.allPairsSeq(fixMoves.deduplicate true, allowDouble, allowLastDouble, skipSwap):
    for pairs in pairsSeq:
      var nazo2 = nazo
      nazo2.env.pairs = pairs

      let sol = nazo2.inspectSolve(true).solutions
      if sol.len == 1:
        yield (pairs: pairs, solution: sol[0])
        break # TODO: swapped pair sometimes gives a different solution

iterator permute*(
  url: string,
  fixMoves: seq[Positive],
  allowDouble: bool,
  allowLastDouble: bool,
  skipSwap: bool,
  domain = ISHIKAWAPUYO,
): Option[tuple[problem: string, solution: string]] {.inline.} =
  ## Yields the pairs and solution of the nazo puyo represented by the `url`
  ## that is obtained by permuting puyoes contained in the pairs, and has a unique solution.
  ## If the `url` is invalid, yields `none` once.
  let nazo = url.toNazo true
  if nazo.isSome:
    for (pairs, solution) in nazo.get.permute(fixMoves, allowDouble, allowLastDouble, skipSwap):
      var nazo2 = nazo.get
      nazo2.env.pairs = pairs
      yield some (problem: nazo2.toUrl(domain = domain), solution: nazo2.toUrl(solution.some, domain))
  else:
    yield none tuple[problem: string, solution: string]

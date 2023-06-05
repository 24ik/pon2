## This module implements a permuter.
##

import deques
import math
import options
import sets
import sugar

import nazopuyo_core
import puyo_core

import ./solve

iterator possiblePairsSeq(
  originalPairs: Pairs,
  fixMoves: HashSet[Positive],
  allowDouble: bool,
  allowLastDouble: bool,
  skipSwap: bool
): seq[Pairs] {.inline.} =
  ## Yields all pairs that are equal if we identify all swapped pairs.
  let moveNum = originalPairs.len
  var colorNums: array[ColorPuyo, Natural]
  for color in ColorPuyo.low .. ColorPuyo.high:
    colorNums[color] = originalPairs.colorNum color

  # HACK: we use a stack instead of recursion since a recursive iterator is not allowed
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
  fixMoves: HashSet[Positive],
  allowDouble: bool,
  allowLastDouble: bool,
  skipSwap: bool,
): tuple[pairs: Pairs, solution: Solution]{.inline.} =
  ## Yields pairs and a solution such that nazo puyoes with the pairs have a unique solution.
  for pairsSeq in nazo.env.pairs.possiblePairsSeq(fixMoves, allowDouble, allowLastDouble, skipSwap):
    for pairs in pairsSeq:
      var nazo2 = nazo
      nazo2.env.pairs = pairs

      let sol = nazo2.inspectSolve(true).solutions
      if sol.len == 1:
        yield (pairs: pairs, solution: sol[0])
        break # TODO: sometimes swapped pair gives a different solution

iterator permute*(
  url: string,
  fixMoves: HashSet[Positive],
  allowDouble: bool,
  allowLastDouble: bool,
  skipSwap: bool,
  domain = ISHIKAWAPUYO,
): Option[tuple[problem: string, solution: string]] {.inline.} =
  ## Yields a nazo puyo with a unique solution obtained by changing only the pairs.
  let nazo = url.toNazo true
  if nazo.isSome:
    for (pairs, solution) in nazo.get.permute(fixMoves, allowDouble, allowLastDouble, skipSwap):
      var nazo2 = nazo.get
      nazo2.env.pairs = pairs
      yield some (problem: nazo2.toUrl(domain = domain), solution: nazo2.toUrl(solution.some, domain))
  else:
    yield none tuple[problem: string, solution: string]

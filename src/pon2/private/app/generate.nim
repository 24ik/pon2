## This module implements helper procedures used by generators.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[algorithm, random, sequtils, sugar]
import ../[assign3, math2, results2]

export results2

func round(rng: var Rand, x: float): int {.inline.} =
  ## Probabilistic round function.
  ## For example, `rng.round(2.7)` becomes `2` with a 30% probability and
  ## `3` with a 70% probability.
  let floorX = x.int
  floorX + (rng.rand(1.0) < x - floorX.float).int

func split*(
    rng: var Rand, total, chunkCnt: int, allowZeroChunk: bool
): Res[seq[int]] {.inline.} =
  ## Splits the number `total` into `chunkCnt` chunks.
  if total < 0:
    return err "`total` cannot be negative"

  if chunkCnt < 1:
    return err "`chunkCnt` should be greater than 0"

  if chunkCnt == 1:
    if total == 0 and not allowZeroChunk:
      return err "`total` cannot be positive if `allowZeroChunk` if false"

    return ok @[total]

  # separation indices
  var sepIndices = newSeqOfCap[int](chunkCnt.succ)
  sepIndices.add 0

  if allowZeroChunk:
    for _ in 0 ..< chunkCnt.pred:
      sepIndices.add rng.rand total
  else:
    if total < chunkCnt:
      return err "`total` should be greater than or equal to `chunkCnt` if `allowZeroChunk` is false"

    var indices = (1 ..< total).toSeq
    rng.shuffle indices
    sepIndices &= indices[0 ..< chunkCnt.pred]
  sepIndices.sort
  sepIndices.add total

  let res = collect:
    for i in 0 ..< chunkCnt:
      sepIndices[i.succ] - sepIndices[i]
  ok res

func split*(
    rng: var Rand, total: int, weights: openArray[int]
): Res[seq[int]] {.inline.} =
  ## Splits the number `total` into chunks following the probability `weights`.
  ## If `weights` are all zero, splits randomly.
  ## Note that an infinite loop can occur.
  if total < 0:
    return err "`total` cannot be negative"

  if weights.len == 0:
    return err "`weights` should have at least one element"

  if weights.len == 1:
    return ok @[total]

  if weights.anyIt it < 0:
    return err "`weights` cannot have negative element"

  let weightSum = weights.sum2
  if weightSum == 0:
    return rng.split(total, weights.len, allowZeroChunk = true)

  var res = newSeq[int](weights.len) # NOTE: somehow `newSeqUninit` does not work
  while true:
    var last = total

    for i in 0 ..< weights.len.pred:
      var rounded = rng.round total * weights[i] / weightSum
      res[i].assign rounded
      last.dec rounded

    if last == 0 or (last > 0 and weights[^1] > 0):
      res[^1].assign last
      break

  ok res

func split*(
    rng: var Rand, total: int, positives: openArray[bool]
): Res[seq[int]] {.inline.} =
  ## Splits the number `total` into chunks randomly.
  ## Elements of the result where `positives` are `true` are set to positive, and
  ## the others are set to zero.
  ## If `positives` are all `false`, splits randomly.
  if total < 0:
    return err "`total` cannot be negative"

  if positives.len == 0:
    return err "`positive` should have at least one element"

  if positives.allIt(not it):
    return rng.split(total, positives.len, allowZeroChunk = true)

  if positives.len == 1:
    return ok @[total]

  let cnts =
    ?rng.split(total, positives.countIt it, allowZeroChunk = false).context "Cannot split"
  var
    res = newSeqOfCap[int](positives.len)
    cntsIdx = 0
  for pos in positives:
    if pos:
      res.add cnts[cntsIdx]
      cntsIdx.inc
    else:
      res.add 0

  ok res

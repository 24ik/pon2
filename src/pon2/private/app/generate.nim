## This module implements helper procedures used in generation.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[algorithm, options, random, sequtils, sugar]
import ../[misc]

type GenerateError* = object of CatchableError ## Exception in generation.

# ------------------------------------------------
# Split
# ------------------------------------------------

func round(rng: var Rand, x: SomeNumber or Natural): int {.inline.} =
  ## Probabilistic round function.
  ## For example, `rng.round(2.7)` becomes `2` with a 30% probability and
  ## `3` with a 70% probability.
  let floorX = x.int
  result = floorX + (rng.rand(1.0) < x.float - floorX.float).int

func split*(
    rng: var Rand, total: Natural, chunkCount: Positive, allowZeroChunk: bool
): seq[int] {.inline.} =
  ## Splits the number `total` into `chunkCount` chunks.
  ## If splitting fails, `GenerateError` is raised.
  runnableExamples:
    import std/[math, random, sequtils]

    var rng = 123.initRand
    let numbers = rng.split(10, 3, false)
    assert numbers.sum == 10
    assert numbers.len == 3
    assert numbers.allIt it > 0

  if chunkCount == 1:
    if total == 0 and not allowZeroChunk:
      raise newException(
        GenerateError, "`total` should be positive if `allowZeroChunk` is false."
      )
    else:
      return @[total.int]

  if total == 1 and not allowZeroChunk:
    if chunkCount == 1:
      return @[total.int]
    else:
      raise newException(
        GenerateError,
        "`total` should be equal or greater than `chunkCount` if" &
          "`allowZeroChunk` is false.",
      )

  # separation index
  let sepIndicesWithoutLast: seq[int]
  if allowZeroChunk:
    sepIndicesWithoutLast = collect:
      for _ in 0 ..< chunkCount.pred:
        rng.rand total
  else:
    if total < chunkCount:
      raise newException(
        GenerateError,
        "`total` should be equal or greater than `chunkCount` if" &
          "`allowZeroChunk` is false.",
      )

    var indices = (1 .. total.pred).toSeq
    rng.shuffle indices
    sepIndicesWithoutLast = indices[0 ..< chunkCount.pred]
  let sepIndices = @[0] & sepIndicesWithoutLast.sorted & @[total.int]

  result = collect:
    for i in 0 ..< chunkCount:
      sepIndices[i.succ] - sepIndices[i]

func split*(
    rng: var Rand, total: Natural, ratios: openArray[Option[Natural]]
): seq[int] {.inline.} =
  ## Splits the number `total` into chunks following the probabilistic
  ## distribution represented by `ratios`.
  ## `ratios` can contain `none` to specify a random positive ratio, and
  ## cannot contain anything but `none` and `some(0)` when doing so.
  ## If all elements in `ratios` are all `some(0)`, splits randomly.
  ## If splitting fails, `GenerateError` is raised.
  runnableExamples:
    import std/[options, random]

    var rng = 123.initRand
    let numbers = rng.split(10, [some Natural 2, some Natural 3])
    assert numbers == @[4, 6]

  if ratios.len == 0:
    raise newException(GenerateError, "`ratios` should have at least one element.")

  if ratios.len == 1:
    return @[total.int]

  if ratios.allIt it.isSome:
    let ratios2 = ratios.mapIt it.get

    let sumRatio = ratios2.sum2
    if sumRatio == 0:
      return rng.split(total, ratios.len, true)

    while true:
      result = newSeqOfCap(ratios.len)
      var last = total

      for mean in ratios2[0 ..^ 2].mapIt total * it / sumRatio:
        let count = rng.round mean
        result.add count
        last.dec count

      if (ratios2[^1] == 0 and last == 0) or (ratios2[^1] > 0 and last > 0):
        result.add last
        return

  if ratios.anyIt it.isSome and it.get != 0:
    raise newException(
      GenerateError,
      "If `ratios` contains `none`, it can contain only `none` and `some(0).",
    )

  result = newSeqOfCap(ratios.len)
  let counts = rng.split(total, ratios.countIt it.isNone, false)
  var idx = 0
  for ratio in ratios:
    if ratio.isSome:
      assert ratio.get == 0
      result.add 0
    else:
      result.add counts[idx]
      idx.inc

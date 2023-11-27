## This module implements generators.
##

{.experimental: "strictDefs".}

import std/[algorithm, options, random, sequtils, sugar]
import ../corepkg/[cell, environment, field, misc, pair, position]
import ../nazopuyopkg/[nazopuyo, solve]
import ../private/[misc]

when not defined(js):
  import std/[cpuinfo]

type
  GenerateError* = object of CatchableError
    ## Exception in generation.

  GenerateRequirementColor* {.pure.} = enum
    ## Requirement color for generation.
    All
    SingleColor
    Garbage
    Color

  GenerateRequirement* = object
    ## Requirement for generation.
    kind*: RequirementKind
    color*: Option[GenerateRequirementColor]
    number*: Option[RequirementNumber]

const
  MaxTrialCountSplit = 10000
  MaxTrialCountGenerate = 100000

# ------------------------------------------------
# Misc
# ------------------------------------------------

func round(rng: var Rand, x: SomeNumber or Natural): int {.inline.} =
  ## Probabilistic round function.
  ## For example, `rng.round(2.7)` becomes `2` with a 30% probability and
  ## `3` with a 70% probability.
  let floorX = x.int
  result = floorX + (rng.rand(1.0) < x.float - floorX.float).int

func split(rng: var Rand, total: Natural, chunkCount: Positive,
           allowZeroChunk: bool): seq[int] {.inline.} =
  ## Splits the number `total` into `chunkCount` chunks.
  ## If splitting fails, `GenerateError` will be raised.
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
        GenerateError,
        "`total` should be positive if `allowZeroChunk` is false.")
    else:
      return @[total.int]

  if total == 1 and not allowZeroChunk:
    if chunkCount == 1:
      return @[total.int]
    else:
      raise newException(
        GenerateError,
        "`total` should be equal or greater than `chunkCount` if" &
        "`allowZeroChunk` is false.")

  # separation index
  let sepIdxesWithoutLast: seq[int]
  if allowZeroChunk:
    sepIdxesWithoutLast = collect:
      for _ in 0..<chunkCount.pred:
        rng.rand total
  else:
    if total < chunkCount:
      raise newException(
        GenerateError,
        "`total` should be equal or greater than `chunkCount` if" &
        "`allowZeroChunk` is false.")

    var idxes = (1..total.pred).toSeq
    rng.shuffle idxes
    sepIdxesWithoutLast = idxes[0..<chunkCount.pred]
  let sepIdxes = @[0] & sepIdxesWithoutLast.sorted & @[total.int]

  result = collect:
    for i in 0..<chunkCount:
      sepIdxes[i.succ] - sepIdxes[i]

func split(rng: var Rand, total: Natural, ratios: openArray[Option[Natural]]):
    seq[int] {.inline.} =
  ## Splits the number `total` into chunks following the probabilistic
  ## distribution represented by `ratios`.
  ## `ratios` can contain `none` to specify a random positive ratio, and
  ## cannot contain anything but `none` and `some(0)` when doing so.
  ## If all elements in `ratios` are all `some(0)`, splits randomly.
  ## If splitting fails, `GenerateError` will be raised.
  runnableExamples:
    import std/[random]

    var rng = 123.initRand
    let numbers = rng.split(10, [some Natural 2, some Natural 3])
    assert numbers == @[4, 6]

  if ratios.len == 0:
    raise newException(
      GenerateError, "`ratios` should have at least one element.")

  if ratios.allIt it.isSome:
    let ratios2 = ratios.mapIt it.get

    let sumRatio = ratios2.sum
    if sumRatio == 0:
      return rng.split(total, ratios.len, true)

    for _ in 0..<MaxTrialCountSplit:
      result = newSeqOfCap[int] ratios.len
      var last = total

      for mean in ratios2.mapIt total * it / sumRatio:
        let count = rng.round mean
        result.add count
        last.dec count

      if (ratios2[^1] == 0 and last == 0) or (ratios2[^1] > 0 and last > 0):
        result.add last
        return
      else:
        continue

    raise newException(GenerateError, "Reached max trial: `split`.")

  if ratios.anyIt it.isSome and it.get != 0:
    raise newException(
      GenerateError,
      "If `ratios` contains `none`, it can contain only `none` and `some(0).")

  result = newSeqOfCap[int] ratios.len
  let counts = rng.split(total, ratios.countIt it.isNone, false)
  var idx = 0
  for ratio in ratios:
    if ratio.isSome:
      assert ratio.get == 0
      result.add 0
    else:
      result.add counts[idx]
      idx.inc

iterator zip[T, U, V](s1: openArray[T], s2: openArray[U], s3: openArray[V]):
    (T, U, V) {.inline.} =
  ## Yields a combination of elements.
  ## Longer arrays will be truncated.
  let minLen = [s1.len, s2.len, s3.len].min
  for i in 0..<minLen:
    yield (s1[i], s2[i], s3[i])

func sample[T](rng: var Rand, arr: openArray[T], count: Natural): seq[T]
           {.inline.} =
  ## Selects and returns `count` elements in the array without duplicates.
  var arr2 = arr.toSeq
  rng.shuffle arr2
  result = arr2[0..<count]

# ------------------------------------------------
# Environment
# ------------------------------------------------

func generateEnvironment[F: TsuField or WaterField](
    rng: var Rand, moveCount: Positive, useColors: seq[ColorPuyo],
    heights: array[Column, Option[Natural]],
    puyoCounts: tuple[color: Natural, garbage: Natural]): Environment[F]
    {.inline.} =
  ## Returns a random environment.
  ## If generation fails, `GenerateError` will be raised.
  let
    fieldCount = puyoCounts.color + puyoCounts.garbage - 2 * moveCount
    chainCount = puyoCounts.color div 4
    extraCount = puyoCounts.color mod 4

    chains = rng.split(chainCount, useColors.len, false)
    extras = rng.split(extraCount, useColors.len, true)

  # shuffle for pairs
  var puyos = newSeqOfCap[Puyo] puyoCounts.color + puyoCounts.garbage
  for color, chain, surplus in zip(useColors, chains, extras):
    puyos &= color.Puyo.repeat chain * 4 + surplus
  rng.shuffle puyos

  # make pairs array
  let pairsArr = collect:
    for i in 0..<moveCount:
      [puyos[2 * i].ColorPuyo, puyos[2 * i + 1].ColorPuyo]

  # shuffle for field
  var fieldPuyos =
    puyos[2 * moveCount .. ^1] & Cell.Garbage.Puyo.repeat puyoCounts.garbage
  rng.shuffle fieldPuyos

  # calc heights
  let colCounts = rng.split(fieldCount, heights)
  if colCounts.anyIt it > (when F is TsuField: Height else: WaterHeight):
    raise newException(GenerateError, "some height[s] exceeds the limit.")

  # make field array
  var
    fieldArr: array[Row, array[Column, Cell]]
    puyoIdx = 0
  fieldArr[Row.low][Column.low] = Cell.low # HACK: dummy to remove warning
  for col in Column.low..Column.high:
    for i in 0..<colCounts[col]:
      let row =
        when F is TsuField: Row.high.pred i
        else: WaterRow.low.succ i
      fieldArr[row][col] = fieldPuyos[puyoIdx]
      puyoIdx.inc

  result = parseEnvironment[F](fieldArr, pairsArr)

# ------------------------------------------------
# Requirement
# ------------------------------------------------

const ColorToReqColor: array[ColorPuyo, RequirementColor] = [
  RequirementColor.Red, RequirementColor.Green, RequirementColor.Blue,
  RequirementColor.Yellow, RequirementColor.Purple]

{.push warning[UnsafeSetLen]: off.}
{.push warning[UnsafeDefault]: off.}
func generateRequirement(
    rng: var Rand, req: GenerateRequirement,
    useColors: seq[ColorPuyo]): Requirement {.inline.} =
  ## Returns a random requirement.
  ## If generation fails, `GenerateError` will be raised.
  result.kind = req.kind

  # color
  result.color = none RequirementColor
  if req.kind in ColorKinds:
    if req.color.isNone:
      raise newException(GenerateError, "Color is not set.")

    result.color = case req.color.get
    of GenerateRequirementColor.All:
      some RequirementColor.All
    of GenerateRequirementColor.SingleColor:
      some ColorToReqColor[rng.sample useColors]
    of GenerateRequirementColor.Garbage:
      some RequirementColor.Garbage
    of GenerateRequirementColor.Color:
      some RequirementColor.Color

  # number
  result.number = none RequirementNumber
  if req.kind in NumberKinds:
    if req.number.isNone:
      raise newException(GenerateError, "Number is not set.")

    result.number = req.number
{.pop.}
{.pop.}

# ------------------------------------------------
# Generate
# ------------------------------------------------

func hasDouble(pairs: Pairs): bool {.inline.} = pairs.anyIt it.isDouble
  ## Returns `true` if any pair in the pairs is double.
  # HACK: Cutting this function out is needed due to Nim's bug

proc generate[F: TsuField or WaterField](
    seed: Option[SomeSignedInt], req: GenerateRequirement, moveCount: Positive,
    colorCount: range[1..5], heights: array[Column, Option[Natural]],
    puyoCounts: tuple[color: Natural, garbage: Natural],
    connect3Counts: tuple[total: Option[Natural], vertical: Option[Natural],
                          horizontal: Option[Natural], lShape: Option[Natural]],
    allowDouble: bool, allowLastDouble: bool, parallelCount: Positive):
    tuple[question: NazoPuyo[F], answer: Positions] {.inline.} =
  ## Returns a randomly generated nazo puyo that has a unique solution.
  ## If generation fails, `GenerateError` will be raised.
  ## `parallelCount` will be ignored on JS backend.
  result.question = initNazoPuyo[F]() # HACK: dummy to remove warning

  # validate the arguments
  # TODO: validate more strictly
  if puyoCounts.color + puyoCounts.garbage - 2 * moveCount notin 0 .. (
      when F is TsuField: Height else: WaterHeight) * Width:
    raise newException(GenerateError, "The number of puyos exceeds limit.")
  if puyoCounts.color div 4 < colorCount:
    raise newException(GenerateError, "The number of colors is too big.")

  var rng = if seed.isSome: seed.get.int64.initRand else: initRand()

  {.push warning[UnsafeSetLen]: off.}
  let
    useColors = rng.sample((ColorPuyo.low..ColorPuyo.high).toSeq, colorCount)
    req = rng.generateRequirement(req, useColors)
  {.pop.}
  if not req.isSupported:
    raise newException(GenerateError, "Unsupported requirement.")

  {.push warning[UnsafeSetLen]: off.}
  {.push warning[UnsafeDefault]: off.}
  for _ in 0..<MaxTrialCountGenerate:
    try:
      result.question.environment = rng.generateEnvironment[:F](
        moveCount, useColors, heights, puyoCounts)
    except GenerateError:
      continue

    # check features
    if result.question.environment.field.isDead:
      continue
    if result.question.environment.field.willDisappear:
      continue
    if not allowDouble and result.question.environment.pairs.hasDouble:
      continue
    if not allowLastDouble and
        result.question.environment.pairs.peekLast.isDouble:
      continue
    if connect3Counts.total.isSome and
        result.question.environment.field.connect3.colorCount !=
        connect3Counts.total.get * 3:
      continue
    if connect3Counts.vertical.isSome and
        result.question.environment.field.connect3V.colorCount !=
        connect3Counts.vertical.get * 3:
      continue
    if connect3Counts.horizontal.isSome and
        result.question.environment.field.connect3H.colorCount !=
        connect3Counts.horizontal.get * 3:
      continue
    if connect3Counts.lShape.isSome and
        result.question.environment.field.connect3L.colorCount !=
        connect3Counts.lShape.get * 3:
      continue

    result.question.requirement = req
    let answers = result.question.solve(parallelCount, earlyStopping = true)
    if answers.len == 1 and answers[0].len == result.question.moveCount:
      result.answer = answers[0]
      return
  {.pop.}
  {.pop.}

  raise newException(GenerateError, "Reached max trial: `generate`.")

proc generate*[F: TsuField or WaterField](
    seed: SomeSignedInt, req: GenerateRequirement, moveCount: Positive,
    colorCount: range[1..5], heights: array[Column, Option[Natural]],
    puyoCounts: tuple[color: Natural, garbage: Natural],
    connect3Counts: tuple[total: Option[Natural], vertical: Option[Natural],
                          horizontal: Option[Natural], lShape: Option[Natural]],
    allowDouble: bool,
    allowLastDouble: bool,
    parallelCount: Positive = (
      when defined(js): 1 else: max(countProcessors(), 1))):
    tuple[question: NazoPuyo[F], answer: Positions] {.inline.} =
  ## Returns a randomly generated nazo puyo that has a unique solution.
  ## If generation fails, `GenerateError` will be raised.
  ## `parallelCount` will be ignored on JS backend.
  generate[F](some seed, req, moveCount, colorCount, heights, puyoCounts,
              connect3Counts, allowDouble, allowLastDouble, parallelCount)

proc generate*[F: TsuField or WaterField](
    req: GenerateRequirement, moveCount: Positive, colorCount: range[1..5],
    heights: array[Column, Option[Natural]],
    puyoCounts: tuple[color: Natural, garbage: Natural],
    connect3Counts: tuple[total: Option[Natural], vertical: Option[Natural],
                          horizontal: Option[Natural], lShape: Option[Natural]],
    allowDouble: bool,
    allowLastDouble: bool,
    parallelCount: Positive = (
      when defined(js): 1 else: max(countProcessors(), 1))):
    tuple[question: NazoPuyo[F], answer: Positions] {.inline.} =
  ## Returns a randomly generated nazo puyo that has a unique solution.
  ## If generation fails, `GenerateError` will be raised.
  ## `parallelCount` will be ignored on JS backend.
  {.push warning[ProveInit]: off.}
  result = generate[F](
    none int, req, moveCount, colorCount, heights, puyoCounts, connect3Counts,
    allowDouble, allowLastDouble, parallelCount)
  {.pop.}

proc generates*(
    seed: SomeSignedInt, rule: Rule, req: GenerateRequirement,
    moveCount: Positive, colorCount: range[1..5],
    heights: array[Column, Option[Natural]],
    puyoCounts: tuple[color: Natural, garbage: Natural],
    connect3Counts: tuple[total: Option[Natural], vertical: Option[Natural],
                          horizontal: Option[Natural], lShape: Option[Natural]],
    allowDouble: bool,
    allowLastDouble: bool,
    parallelCount: Positive = (
      when defined(js): 1 else: max(countProcessors(), 1))):
    tuple[question: NazoPuyos, answer: Positions] {.inline.} =
  ## Returns a randomly generated nazo puyo that has a unique solution.
  ## If generation fails, `GenerateError` will be raised.
  ## `parallelCount` will be ignored on JS backend.
  result.question.rule = rule

  case rule
  of Tsu:
    (result.question.tsu, result.answer) = generate[TsuField](
      seed, req, moveCount, colorCount, heights, puyoCounts, connect3Counts,
      allowDouble, allowLastDouble, parallelCount)
    result.question.water = initWaterNazoPuyo()
  of Water:
    result.question.tsu = initTsuNazoPuyo()
    (result.question.water, result.answer) = generate[WaterField](
      seed, req, moveCount, colorCount, heights, puyoCounts, connect3Counts,
      allowDouble, allowLastDouble, parallelCount)

proc generates*(
    rule: Rule, req: GenerateRequirement, moveCount: Positive,
    colorCount: range[1..5], heights: array[Column, Option[Natural]],
    puyoCounts: tuple[color: Natural, garbage: Natural],
    connect3Counts: tuple[total: Option[Natural], vertical: Option[Natural],
                          horizontal: Option[Natural], lShape: Option[Natural]],
    allowDouble: bool,
    allowLastDouble: bool,
    parallelCount: Positive = (
      when defined(js): 1 else: max(countProcessors(), 1))):
    tuple[question: NazoPuyos, answer: Positions] {.inline.} =
  ## Returns a randomly generated nazo puyo that has a unique solution.
  ## If generation fails, `GenerateError` will be raised.
  ## `parallelCount` will be ignored on JS backend.
  result.question.rule = rule

  case rule
  of Tsu:
    (result.question.tsu, result.answer) = generate[TsuField](
      req, moveCount, colorCount, heights, puyoCounts, connect3Counts,
      allowDouble, allowLastDouble, parallelCount)
    result.question.water = initWaterNazoPuyo()
  of Water:
    result.question.tsu = initTsuNazoPuyo()
    (result.question.water, result.answer) = generate[WaterField](
      req, moveCount, colorCount, heights, puyoCounts, connect3Counts,
      allowDouble, allowLastDouble, parallelCount)

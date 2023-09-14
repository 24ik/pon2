## This module implements the generator.
##

import algorithm
import deques
import math
import options
import random
import sequtils
import sugar

import nazopuyo_core
import puyo_core

import ./solve

type
  AbstractRequirementColor* {.pure.} = enum
    ## Requirement color with all single color puyoes identical.
    ALL
    SINGLE_COLOR
    GARBAGE
    COLOR

  AbstractRequirement* = tuple
    ## Requirement with all single color puyoes identical.
    kind: RequirementKind
    color: Option[AbstractRequirementColor]
    number: Option[RequirementNumber]

# ------------------------------------------------
# Environment
# ------------------------------------------------

func round(rng: var Rand, x: SomeNumber): int {.inline.} =
  ## Probabilistic round function.
  ## For example, `rng.round(2.7)` becomes `2` with a 30% probability and `3` with a 70% probability.
  let floorX = x.int
  return floorX + (rng.rand(1.0) < x.float - floorX.float).int

func split(rng: var Rand, total: Natural, chunkNum: Positive, allowZeroChunk: bool): Option[seq[Natural]] {.inline.} =
  ## Splits the number `total` into `chunkNum` chunks.
  ## If the splitting fails, returns `none`.
  runnableExamples:
    import math
    import random
    import sequtils

    var rng = 42.initRand
    let numbers = rng.split(10, 3, false).get
    assert numbers.sum == 10
    assert numbers.len == 3
    assert numbers.allIt it > 0

  if chunkNum == 1:
    if total == 0 and not allowZeroChunk:
      return
    else:
      return some @[total]

  if total == 1 and not allowZeroChunk:
    if chunkNum == 1:
      return some @[total]
    else:
      return

  # separate index
  var sepIdxesWithoutLast: seq[int]
  if allowZeroChunk:
    sepIdxesWithoutLast = collect:
      for _ in 0 ..< chunkNum.pred:
        rng.rand total
  else:
    if total < chunkNum:
      return

    var idxes = (1 .. total.pred).toSeq
    rng.shuffle idxes
    sepIdxesWithoutLast = idxes[0 ..< chunkNum.pred]
  let sepIdxes = @[0] & sepIdxesWithoutLast.sorted & @[total.int]

  let res = collect:
    for i in 0 ..< chunkNum:
      Natural sepIdxes[i.succ] - sepIdxes[i]
  return some res

func split(rng: var Rand, total: Natural, ratios: openArray[Option[Natural]]): Option[seq[Natural]] {.inline.} =
  ## Splits the number `total` into chunks following the probabilistic distribution represented by `ratios`.
  ## `none` in the `ratios` means a random.
  ## If all elements in `ratios` are all `some(0)`, splits randomly.
  ## If the splitting fails, returns `none`.
  runnableExamples:
    import random

    var rng = 42.initRand
    let numbers = rng.split(10, [2.Natural, 3])
    assert numbers == some @[4.Natural, 6.Natural]

  if ratios.len == 0:
    return

  if ratios.allIt it.isSome:
    # FIXME: better implementation (currently no guarantee of loop termination)
    while true:
      let ratioSum = sum ratios.mapIt it.get
      if ratioSum == 0:
        return rng.split(total, ratios.len, true)

      var
        res = newSeqOfCap[Natural] ratios.len
        last = total

      for mean in ratios.mapIt total * it.get / ratioSum:
        let num = rng.round mean

        res.add num
        last.dec num

      if (ratios[^1].get == 0 and last == 0) or (ratios[^1].get > 0 and last > 0):
        res.add last
        return some res
  elif ratios.allIt(it.isNone or it.get == 0):
    let nums = rng.split(total, ratios.countIt it.isNone, false)
    if nums.isNone:
      return

    var
      res = newSeqOfCap[Natural] ratios.len
      idx = 0
    for ratio in ratios:
      if ratio.isNone:
        res.add nums.get[idx]
        idx.inc
      else:
        res.add 0

    return some res

iterator zip[T, U, V](s1: openArray[T], s2: openArray[U], s3: openArray[V]): (T, U, V) {.inline.} =
  ## Yields a combination of elements.
  ## Longer arrays will be truncated.
  let minLen = [s1.len, s2.len, s3.len].min
  for i in 0 ..< minLen:
    yield (s1[i], s2[i], s3[i])

func generateEnvironment(
  rng: var Rand,
  rule: Rule,
  moveCount: Positive,
  useColors: seq[ColorPuyo],
  heights: array[Column, Option[Natural]],
  puyoCounts: tuple[color: Natural, garbage: Natural],
): Option[Environment] {.inline.} =
  ## Returns a random environment.
  ## If the generation fails, returns `none`.
  let
    fieldCount = puyoCounts.color + puyoCounts.garbage - 2 * moveCount
    chainCount = puyoCounts.color div 4
    surplusCount = puyoCounts.color mod 4

    chains = rng.split(chainCount, useColors.len, false).get 
    surpluses = rng.split(surplusCount, useColors.len, true).get

  # pairs
  var puyoes = newSeqOfCap[Puyo] puyoCounts.color + puyoCounts.garbage
  for color, chain, surplus in zip(useColors, chains, surpluses):
    puyoes &= color.Puyo.repeat chain * 4 + surplus
  rng.shuffle puyoes
  let pairsArray = collect:
    for i in 0 ..< moveCount:
      [puyoes[2 * i].ColorPuyo, puyoes[2 * i + 1].ColorPuyo]

  # field
  puyoes = puyoes[2 * moveCount .. ^1]
  puyoes &= Cell.GARBAGE.Puyo.repeat puyoCounts.garbage
  rng.shuffle puyoes
  let colCounts = rng.split(fieldCount, heights)
  if colCounts.isNone or colCounts.get.anyIt it > Height:
    return
  var
    fieldArray: array[Row, array[Column, Cell]]
    idx = 0
  for col in Column.low .. Column.high:
    for i in 0 ..< colCounts.get[col]:
      let row = case rule
      of TSU: Row.high.pred i
      of WATER: WaterRow.low.Row.succ i
      fieldArray[row][col] = puyoes[idx]
      idx.inc

  return some toEnvironment(fieldArray, pairsArray, rule)

# ------------------------------------------------
# Requirement
# ------------------------------------------------

const ColorToRequirementColor: array[ColorPuyo, RequirementColor] = [
  RequirementColor.RED,
  RequirementColor.GREEN,
  RequirementColor.BLUE,
  RequirementColor.YELLOW,
  RequirementColor.PURPLE]

func generateRequirement(
  rng: var Rand,
  req: AbstractRequirement,
  useColors: seq[ColorPuyo],
): Option[Requirement] {.inline.} =
  ## Returns a random requirement.
  ## If the generation fails, returns `none`.
  # color
  var reqColor = none RequirementColor
  if req.kind in ColorKinds:
    if req.color.isNone:
      return

    case req.color.get
    of AbstractRequirementColor.ALL:
      reqColor = some RequirementColor.ALL
    of AbstractRequirementColor.SINGLE_COLOR:
      reqColor = some ColorToRequirementColor[rng.sample useColors]
    of AbstractRequirementColor.GARBAGE:
      reqColor = some RequirementColor.GARBAGE
    of AbstractRequirementColor.COLOR:
      reqColor = some RequirementColor.COLOR

  # number
  var reqNumber = none RequirementNumber
  if req.kind in NumberKinds:
    if req.number.isNone:
      return

    reqNumber = req.number

  return some Requirement (kind: req.kind, color: reqColor, number: reqNumber)

# ------------------------------------------------
# Entry Point
# ------------------------------------------------

func sample[T](rng: var Rand, `array`: openArray[T], num: Natural): seq[T] {.inline.} =
  ## Selects and returns `num` elements in the `array` without duplicates.
  var array2 = `array`.toSeq
  rng.shuffle array2
  return array2[0 ..< num]

func hasDouble(pairs: Pairs): bool {.inline.} =
  ## Returns `true` if any pair in the `pairs` is double.
  # HACK: It should not be necessary to cut it out as a function, but perhaps due to a Nim's bug
  # the program does not work if we check `hasDouble` directly in the `generate` function.
  pairs.anyIt it.isDouble

proc generate*(
  seed: SomeSignedInt,
  rule: Rule,
  moveCount: Positive,
  abstractReq: AbstractRequirement,
  colorCount: range[1 .. 5],
  heights: array[Column, Option[Natural]],
  puyoCounts: tuple[color: Natural, garbage: Natural],
  connect3Counts: tuple[
    total: Option[Natural], vertical: Option[Natural], horizontal: Option[Natural], lShape: Option[Natural]],
  allowDouble: bool,
  allowLastDouble: bool,
): Option[tuple[question: NazoPuyo, answer: Positions]] {.inline.} =
  ## Returns a randomly generated nazo puyo that has a unique answer.
  ## If the generation fails, returns `none`.
  # validate the arguments
  # TODO: validate more strictly
  let height = case rule
  of TSU: Height
  of WATER: WaterHeight
  if puyoCounts.color + puyoCounts.garbage - 2 * moveCount notin 0 .. height * Width:
    return
  if puyoCounts.color div 4 < colorCount:
    return
  if abstractReq.kind in {
    DISAPPEAR_PLACE, DISAPPEAR_PLACE_MORE, DISAPPEAR_CONNECT, DISAPPEAR_CONNECT_MORE
  } and abstractReq.color.get == AbstractRequirementColor.GARBAGE:
    return

  var rng = seed.int64.initRand

  let
    useColors = rng.sample(ColorPuyo.toSeq, colorCount)
    req = rng.generateRequirement(abstractReq, useColors)
  if req.isNone:
    return

  # FIXME: better implementation (currently no guarantee of loop termination)
  while true:
    let env = rng.generateEnvironment(rule, moveCount, useColors, heights, puyoCounts)
    if env.isNone:
      continue

    # check features
    if env.get.field.isDead:
      continue
    if env.get.field.willDisappear:
      continue
    if not allowDouble and env.get.pairs.hasDouble:
      continue
    if not allowLastDouble and env.get.pairs.peekLast.isDouble:
      continue
    if connect3Counts.total.isSome and env.get.field.connect3.countColor != connect3Counts.total.get * 3:
      continue
    if connect3Counts.vertical.isSome and env.get.field.connect3V.countColor != connect3Counts.vertical.get * 3:
      continue
    if connect3Counts.horizontal.isSome and env.get.field.connect3H.countColor != connect3Counts.horizontal.get * 3:
      continue
    if connect3Counts.lShape.isSome and env.get.field.connect3L.countColor != connect3Counts.lShape.get * 3:
      continue

    let nazo = (environment: env.get, requirement: req.get)
    let answers = nazo.inspectSolve(true).answers
    if answers.len != 1:
      continue
    if answers[0].len != nazo.moveCount:
      continue

    return some (nazo, answers[0])

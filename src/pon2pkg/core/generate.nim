## This module implements the generator.
##

import algorithm
import deques
import math
import options
import random
import sequtils
import std/setutils
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
    num: Option[RequirementNumber]

# ------------------------------------------------
# Env
# ------------------------------------------------

func round(rng: var Rand, x: SomeNumber): int {.inline.} =
  ## Probabilistic round function.
  ## For example, `rng.round(2.7)` becomes `2` with a 30% probability and `3` with a 70% probability.
  let floorX = x.int
  return floorX + (rng.rand(1.0) < x.float - floorX.float).int

func split(rng: var Rand, total: Natural, chunkNum: Positive, allowZeroChunk: bool): Option[seq[Natural]] {.inline.} =
  ## Splits the `total` number into `chunkNum` chunks.
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
  ## Splits the `total` number into chunks following the distribution represented by the `ratios`.
  ## `none` in the `ratios` means a random.
  ## If `ratios` are all `some(0)`, splits randomly.
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
  let minLen = [s1.len, s2.len, s3.len].min
  for i in 0 ..< minLen:
    yield (s1[i], s2[i], s3[i])

func generateEnv(
  rng: var Rand,
  moveNum: Positive,
  useColors: seq[ColorPuyo],
  heights: array[Col, Option[Natural]],
  puyoNums: tuple[color: Natural, garbage: Natural],
): Option[Env] {.inline.} =
  ## Returns a random environment.
  ## If the generation fails, returns `none`.
  let
    fieldNum = puyoNums.color + puyoNums.garbage - 2 * moveNum
    chainNum = puyoNums.color div 4
    surplusNum = puyoNums.color mod 4

    chains = rng.split(chainNum, useColors.len, false).get 
    surpluses = rng.split(surplusNum, useColors.len, true).get

  # pairs
  var puyoes = newSeqOfCap[Puyo] puyoNums.color + puyoNums.garbage
  for color, chain, surplus in zip(useColors, chains, surpluses):
    puyoes &= color.Puyo.repeat (chain * 4 + surplus)
  rng.shuffle puyoes
  let pairsArray = collect:
    for i in 0 ..< moveNum:
      [puyoes[2 * i].ColorPuyo, puyoes[2 * i + 1].ColorPuyo]

  # field
  puyoes = puyoes[2 * moveNum .. ^1]
  puyoes &= Cell.GARBAGE.Puyo.repeat puyoNums.garbage
  rng.shuffle puyoes
  let colNums = rng.split(fieldNum, heights)
  if colNums.isNone or colNums.get.anyIt it > Height:
    return
  var
    fieldArray: array[Row, array[Col, Cell]]
    idx = 0
  for i in 0 ..< Width:
    for j in 0 ..< colNums.get[i]:
      fieldArray[Row.high.pred j][Col.low.succ i] = puyoes[idx]
      idx.inc

  return some toEnv(fieldArray, pairsArray, some ColorPuyo.fullSet)

# ------------------------------------------------
# Requirement
# ------------------------------------------------

func generateRequirement(
  rng: var Rand,
  req: AbstractRequirement,
  useColors: seq[ColorPuyo],
  puyoNums: tuple[color: Natural, garbage: Natural],
): Option[Requirement] {.inline.} =
  ## Returns a random requirement.
  ## If the generation fails, returns `none`.
  const ColorToRequirementColor: array[ColorPuyo, RequirementColor] = [
    RequirementColor.RED,
    RequirementColor.GREEN,
    RequirementColor.BLUE,
    RequirementColor.YELLOW,
    RequirementColor.PURPLE]

  # color
  var reqColor = none RequirementColor
  if req.kind in RequirementKindsWithColor:
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

  # num
  var reqNum = none RequirementNumber
  if req.kind in RequirementKindsWithNum:
    if req.num.isNone:
      return

    reqNum = req.num

  return some (kind: req.kind, color: reqColor, num: reqNum).Requirement

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
  moveNum: Positive,
  req: AbstractRequirement,
  colorNum: range[1 .. 5],
  heights: array[Col, Option[Natural]],
  puyoNums: tuple[color: Natural, garbage: Natural],
  connect3Nums: tuple[
    total: Option[Natural], vertical: Option[Natural], horizontal: Option[Natural], lShape: Option[Natural]],
  allowDouble: bool,
  allowLastDouble: bool,
): Option[tuple[problem: Nazo, solution: Solution]] {.inline.} =
  ## Returns a nazo puyo that have a unique solution.
  ## If the generation fails, returns `none`.
  # validate the arguments
  # TODO: validate more strictly
  if puyoNums.color + puyoNums.garbage - 2 * moveNum notin 0 .. Height * Width - 2:
    return
  if puyoNums.color div 4 < colorNum:
    return
  if req.kind in {
    DISAPPEAR_PLACE, DISAPPEAR_PLACE_MORE, DISAPPEAR_CONNECT, DISAPPEAR_CONNECT_MORE
  } and req.color.get == AbstractRequirementColor.GARBAGE:
    return

  var rng = seed.int64.initRand

  let
    useColors = rng.sample(ColorPuyo.toSeq, colorNum)
    req = rng.generateRequirement(req, useColors, puyoNums)
  if req.isNone:
    return

  # FIXME: better implementation (currently no guarantee of loop termination)
  while true:
    let env = rng.generateEnv(moveNum, useColors, heights, puyoNums)
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
    if connect3Nums.total.isSome and env.get.field.connect3.puyoNum != connect3Nums.total.get * 3:
      continue
    if connect3Nums.vertical.isSome and env.get.field.connect3V.puyoNum != connect3Nums.vertical.get * 3:
      continue
    if connect3Nums.horizontal.isSome and env.get.field.connect3H.puyoNum != connect3Nums.horizontal.get * 3:
      continue
    if connect3Nums.lShape.isSome and env.get.field.connect3L.puyoNum != connect3Nums.lShape.get * 3:
      continue

    let nazo = (env: env.get, req: req.get).Nazo
    let sol = nazo.inspectSolve(true).solutions
    if sol.len != 1:
      continue
    if sol[0].len != nazo.moveNum:
      continue

    return some (problem: nazo, solution: sol[0])

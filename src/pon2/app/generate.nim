## This module implements Nazo Puyo generators.
##
# TODO: make object type of generate arguments

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[algorithm, options, random, sequtils, sugar]
import ./[nazopuyo, solve]
import
  ../core/[
    cell, field, fieldtype, nazopuyo, pair, pairposition, position, puyopuyo,
    requirement, rule,
  ]
import ../private/[misc]

type
  GenerateError* = object of CatchableError ## Exception in generation.

  GenerateRequirementColor* {.pure.} = enum
    ## Requirement color for generation.
    All
    SingleColor
    Garbage
    Color

  GenerateRequirement* = object ## Requirement for generation.
    kind: RequirementKind
    color: Option[GenerateRequirementColor]
    number: Option[RequirementNumber]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func initGenerateRequirement*(
    kind: RequirementKind, color: GenerateRequirementColor, number: RequirementNumber
): GenerateRequirement {.inline.} =
  ## Returns a requirement.
  GenerateRequirement(kind: kind, color: some color, number: some number)

func initGenerateRequirement*(
    kind: RequirementKind, color: GenerateRequirementColor
): GenerateRequirement {.inline.} =
  ## Returns a requirement.
  GenerateRequirement(kind: kind, color: some color, number: none RequirementNumber)

func initGenerateRequirement*(
    kind: RequirementKind, number: RequirementNumber
): GenerateRequirement {.inline.} =
  GenerateRequirement(
    kind: kind, color: none GenerateRequirementColor, number: some number
  )

# ------------------------------------------------
# Property
# ------------------------------------------------

const
  DefaultColor = GenerateRequirementColor.All
  DefaultNumber = 0.RequirementNumber

func kind*(self: GenerateRequirement): RequirementKind {.inline.} =
  ## Returns the kind of the requirement.
  self.kind

func color*(self: GenerateRequirement): GenerateRequirementColor {.inline.} =
  ## Returns the color of the requirement.
  ## If the requirement does not have a color, `UnpackDefect` is raised.
  self.color.get

func number*(self: GenerateRequirement): RequirementNumber {.inline.} =
  ## Returns the number of the requirement.
  ## If the requirement does not have a number, `UnpackDefect` is raised.
  self.number.get

func `kind=`*(self: var GenerateRequirement, kind: RequirementKind) {.inline.} =
  ## Sets the kind of the requirement.
  if self.kind == kind:
    return
  self.kind = kind

  if kind in ColorKinds:
    if self.color.isNone:
      self.color = some DefaultColor
  else:
    if self.color.isSome:
      self.color = none GenerateRequirementColor

  if kind in NumberKinds:
    if self.number.isNone:
      self.number = some DefaultNumber
  else:
    if self.number.isSome:
      self.number = none RequirementNumber

func `color=`*(
    self: var GenerateRequirement, color: GenerateRequirementColor
) {.inline.} =
  ## Sets the color of the requirement.
  ## If the requirement does not have a color, `UnpackDefect` is raised.
  if self.kind in NoColorKinds:
    raise newException(UnpackDefect, "The requirement does not have a color.")

  self.color = some color

func `number=`*(self: var GenerateRequirement, number: RequirementNumber) {.inline.} =
  ## Sets the number of the requirement.
  ## If the requirement does not have a color, `UnpackDefect` is raised.
  if self.kind in NoNumberKinds:
    raise newException(UnpackDefect, "The requirement does not have a number.")

  self.number = some number

# ------------------------------------------------
# Misc
# ------------------------------------------------

func round(rng: var Rand, x: SomeNumber or Natural): int {.inline.} =
  ## Probabilistic round function.
  ## For example, `rng.round(2.7)` becomes `2` with a 30% probability and
  ## `3` with a 70% probability.
  let floorX = x.int
  result = floorX + (rng.rand(1.0) < x.float - floorX.float).int

func split(
    rng: var Rand, total: Natural, chunkCount: Positive, allowZeroChunk: bool
): seq[int] {.inline.} =
  ## Splits the number `total` into `chunkCount` chunks.
  ## If splitting fails, `GenerateError` is raised.
  runnableExamples:
    import std/[math, random, sequtils]

    var rng = 123.initRand
    let numbers = rng.split(10, 3, false)
    assert numbers.sum2 == 10
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

func split(
    rng: var Rand, total: Natural, ratios: openArray[Option[Natural]]
): seq[int] {.inline.} =
  ## Splits the number `total` into chunks following the probabilistic
  ## distribution represented by `ratios`.
  ## `ratios` can contain `none` to specify a random positive ratio, and
  ## cannot contain anything but `none` and `some(0)` when doing so.
  ## If all elements in `ratios` are all `some(0)`, splits randomly.
  ## If splitting fails, `GenerateError` is raised.
  runnableExamples:
    import std/[random]

    var rng = 123.initRand
    let numbers = rng.split(10, [some Natural 2, some Natural 3])
    assert numbers == @[4, 6]

  if ratios.len == 0:
    raise newException(GenerateError, "`ratios` should have at least one element.")

  if ratios.allIt it.isSome:
    let ratios2 = ratios.mapIt it.get

    let sumRatio = ratios2.sum2
    if sumRatio == 0:
      return rng.split(total, ratios.len, true)

    while true:
      result = newSeqOfCap(ratios.len)
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

# ------------------------------------------------
# Puyo Puyo
# ------------------------------------------------

func generatePuyoPuyo[F: TsuField or WaterField](
    rng: var Rand,
    moveCount: Positive,
    useColors: seq[ColorPuyo],
    heights: array[Column, Option[Natural]],
    puyoCounts: tuple[color: Natural, garbage: Natural],
): PuyoPuyo[F] {.inline.} =
  ## Returns a random Puyo Puyo game.
  ## If generation fails, `GenerateError` is raised.
  let
    fieldCount = puyoCounts.color + puyoCounts.garbage - 2 * moveCount
    chainCount = puyoCounts.color div 4
    extraCount = puyoCounts.color mod 4

    chains = rng.split(chainCount, useColors.len, false)
    extras = rng.split(extraCount, useColors.len, true)

  # shuffle for pairs&positions
  var puyos = newSeqOfCap[Puyo](puyoCounts.color + puyoCounts.garbage)
  for color, chain, surplus in zip(useColors, chains, extras):
    {.push warning[UnsafeDefault]: off.}
    {.push warning[UnsafeSetLen]: off.}
    {.push warning[ProveInit]: off.}
    puyos &= color.Puyo.repeat chain * 4 + surplus
    {.pop.}
    {.pop.}
    {.pop.}
  rng.shuffle puyos

  # make pairs&positions
  let pairsPositions = collect:
    for i in 0 ..< moveCount:
      PairPosition(
        pair: initPair(puyos[2 * i], puyos[2 * i + 1]), position: Position.None
      )

  # shuffle for field
  {.push warning[ProveInit]: off.}
  var fieldPuyos =
    puyos[2 * moveCount .. ^1] & Cell.Garbage.Puyo.repeat puyoCounts.garbage
  {.pop.}
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
  for col in Column.low .. Column.high:
    for i in 0 ..< colCounts[col]:
      let row =
        when F is TsuField:
          Row.high.pred i
        else:
          WaterRow.low.succ i
      fieldArr[row][col] = fieldPuyos[puyoIdx]
      puyoIdx.inc

  result = initPuyoPuyo[F]()
  result.field = parseField[F](fieldArr)
  result.pairsPositions = pairsPositions

# ------------------------------------------------
# Requirement
# ------------------------------------------------

const ColorToReqColor: array[ColorPuyo, RequirementColor] = [
  RequirementColor.Red, RequirementColor.Green, RequirementColor.Blue,
  RequirementColor.Yellow, RequirementColor.Purple,
]

func generateRequirement(
    rng: var Rand, req: GenerateRequirement, useColors: seq[ColorPuyo]
): Requirement {.inline.} =
  ## Returns a random requirement.
  ## If generation fails, `GenerateError` is raised.
  if req.kind in NoColorKinds:
    result = initRequirement(req.kind, req.number.get)
  elif req.kind in NoNumberKinds:
    result = initRequirement(req.kind, RequirementColor.low)
  else:
    result = initRequirement(req.kind, RequirementColor.low, req.number.get)

  # color
  if req.kind in ColorKinds:
    {.push warning[ProveInit]: off.}
    {.push warning[UnsafeSetLen]: off.}
    {.push warning[UnsafeDefault]: off.}
    result.color =
      case req.color.get
      of GenerateRequirementColor.All:
        RequirementColor.All
      of GenerateRequirementColor.SingleColor:
        ColorToReqColor[rng.sample useColors]
      of GenerateRequirementColor.Garbage:
        RequirementColor.Garbage
      of GenerateRequirementColor.Color:
        RequirementColor.Color
    {.pop.}
    {.pop.}
    {.pop.}

# ------------------------------------------------
# Generate - Generics
# ------------------------------------------------

proc generate*[F: TsuField or WaterField](
    seed: SomeSignedInt,
    req: GenerateRequirement,
    moveCount: Positive,
    colorCount: range[1 .. 5],
    heights: array[Column, Option[Natural]],
    puyoCounts: tuple[color: Option[Natural], garbage: Natural],
    connect2Counts:
      tuple[
        total: Option[Natural], vertical: Option[Natural], horizontal: Option[Natural]
      ],
    connect3Counts:
      tuple[
        total: Option[Natural],
        vertical: Option[Natural],
        horizontal: Option[Natural],
        lShape: Option[Natural],
      ],
    allowDouble: bool,
    allowLastDouble: bool,
): NazoPuyo[F] {.inline.} =
  ## Returns a randomly generated nazo puyo that has a unique solution.
  ## If generation fails, `GenerateError` is raised.
  ## If `puyoCounts.color` is `none`, it is inferred from the requirement if
  ## the kind is chain-like; otherwise `GenerateError` is raised.
  ## `parallelCount` is ignored on JS backend.
  result = initNazoPuyo[F]() # HACK: dummy to suppress warning

  # infer color count if not specified
  var puyoCounts2 = (color: 0.Natural, garbage: puyoCounts.garbage)
  if puyoCounts.color.isSome:
    puyoCounts2.color = puyoCounts.color.get
  else:
    if req.kind in {Chain, ChainMore, ChainClear, ChainMoreClear}:
      puyoCounts2.color = req.number.get * 4
    else:
      raise newException(GenerateError, "The number of color puyoes is not specified.")

  # validate the arguments
  # TODO: validate more strictly
  if puyoCounts2.color + puyoCounts.garbage - 2 * moveCount notin
      0 .. (when F is TsuField: Height else: WaterHeight) * Width:
    raise newException(GenerateError, "The number of puyos exceeds limit.")
  if puyoCounts2.color div 4 < colorCount:
    raise newException(GenerateError, "The number of colors is too big.")

  var rng = seed.int64.initRand

  # requirement
  {.push warning[UnsafeSetLen]: off.}
  {.push warning[ProveInit]: off.}
  let useColors = rng.sample((ColorPuyo.low .. ColorPuyo.high).toSeq, colorCount)
  {.pop.}
  {.pop.}
  result.requirement = rng.generateRequirement(req, useColors)
  if not result.requirement.isSupported:
    raise newException(GenerateError, "Unsupported requirement.")

  # puyo puyo
  while true:
    try:
      result.puyoPuyo =
        generatePuyoPuyo[F](rng, moveCount, useColors, heights, puyoCounts2)
    except GenerateError:
      continue

    # check features
    if result.puyoPuyo.field.isDead:
      continue
    if result.puyoPuyo.field.willDisappear:
      continue
    if not allowDouble and result.puyoPuyo.pairsPositions.anyIt it.pair.isDouble:
      continue
    if not allowLastDouble and result.puyoPuyo.pairsPositions[^1].pair.isDouble:
      continue
    if connect2Counts.total.isSome and
        result.puyoPuyo.field.connect2.colorCount != connect2Counts.total.get * 2:
      continue
    if connect2Counts.vertical.isSome and
        result.puyoPuyo.field.connect2V.colorCount != connect2Counts.vertical.get * 2:
      continue
    if connect2Counts.horizontal.isSome and
        result.puyoPuyo.field.connect2H.colorCount != connect2Counts.horizontal.get * 2:
      continue
    if connect3Counts.total.isSome and
        result.puyoPuyo.field.connect3.colorCount != connect3Counts.total.get * 3:
      continue
    if connect3Counts.vertical.isSome and
        result.puyoPuyo.field.connect3V.colorCount != connect3Counts.vertical.get * 3:
      continue
    if connect3Counts.horizontal.isSome and
        result.puyoPuyo.field.connect3H.colorCount != connect3Counts.horizontal.get * 3:
      continue
    if connect3Counts.lShape.isSome and
        result.puyoPuyo.field.connect3L.colorCount != connect3Counts.lShape.get * 3:
      continue

    let answers = result.solve(earlyStopping = true)
    if answers.len == 1 and answers[0][^1].position != Position.None:
      result.puyoPuyo.pairsPositions = answers[0]
      return

proc generate*[F: TsuField or WaterField](
    req: GenerateRequirement,
    moveCount: Positive,
    colorCount: range[1 .. 5],
    heights: array[Column, Option[Natural]],
    puyoCounts: tuple[color: Option[Natural], garbage: Natural],
    connect2Counts:
      tuple[
        total: Option[Natural], vertical: Option[Natural], horizontal: Option[Natural]
      ],
    connect3Counts:
      tuple[
        total: Option[Natural],
        vertical: Option[Natural],
        horizontal: Option[Natural],
        lShape: Option[Natural],
      ],
    allowDouble: bool,
    allowLastDouble: bool,
): NazoPuyo[F] {.inline.} =
  ## Returns a randomly generated nazo puyo that has a unique solution.
  ## If generation fails, `GenerateError` will be raised.
  ## `parallelCount` will be ignored on JS backend.
  var rng = initRand()
  result = generate[F](
    rng.rand int,
    req,
    moveCount,
    colorCount,
    heights,
    puyoCounts,
    connect2Counts,
    connect3Counts,
    allowDouble,
    allowLastDouble,
  )

# ------------------------------------------------
# Generate - Wrap
# ------------------------------------------------

proc generate*(
    seed: SomeSignedInt,
    rule: Rule,
    req: GenerateRequirement,
    moveCount: Positive,
    colorCount: range[1 .. 5],
    heights: array[Column, Option[Natural]],
    puyoCounts: tuple[color: Option[Natural], garbage: Natural],
    connect2Counts:
      tuple[
        total: Option[Natural], vertical: Option[Natural], horizontal: Option[Natural]
      ],
    connect3Counts:
      tuple[
        total: Option[Natural],
        vertical: Option[Natural],
        horizontal: Option[Natural],
        lShape: Option[Natural],
      ],
    allowDouble: bool,
    allowLastDouble: bool,
): NazoPuyoWrap {.inline.} =
  ## Returns a randomly generated nazo puyo that has a unique solution.
  ## If generation fails, `GenerateError` is raised.
  ## `parallelCount` is ignored on JS backend.
  case rule
  of Tsu:
    generate[TsuField](
      seed, req, moveCount, colorCount, heights, puyoCounts, connect2Counts,
      connect3Counts, allowDouble, allowLastDouble,
    ).initNazoPuyoWrap
  of Water:
    generate[WaterField](
      seed, req, moveCount, colorCount, heights, puyoCounts, connect2Counts,
      connect3Counts, allowDouble, allowLastDouble,
    ).initNazoPuyoWrap

proc generate*(
    rule: Rule,
    req: GenerateRequirement,
    moveCount: Positive,
    colorCount: range[1 .. 5],
    heights: array[Column, Option[Natural]],
    puyoCounts: tuple[color: Option[Natural], garbage: Natural],
    connect2Counts:
      tuple[
        total: Option[Natural], vertical: Option[Natural], horizontal: Option[Natural]
      ],
    connect3Counts:
      tuple[
        total: Option[Natural],
        vertical: Option[Natural],
        horizontal: Option[Natural],
        lShape: Option[Natural],
      ],
    allowDouble: bool,
    allowLastDouble: bool,
): NazoPuyoWrap {.inline.} =
  ## Returns a randomly generated nazo puyo that has a unique solution.
  ## If generation fails, `GenerateError` will be raised.
  ## `parallelCount` will be ignored on JS backend.
  case rule
  of Tsu:
    generate[TsuField](
      req, moveCount, colorCount, heights, puyoCounts, connect2Counts, connect3Counts,
      allowDouble, allowLastDouble,
    ).initNazoPuyoWrap
  of Water:
    generate[WaterField](
      req, moveCount, colorCount, heights, puyoCounts, connect2Counts, connect3Counts,
      allowDouble, allowLastDouble,
    ).initNazoPuyoWrap

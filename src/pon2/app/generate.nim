## This module implements Nazo Puyo generators.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[algorithm, deques, options, random, sequtils]
import ./[nazopuyo, solve]
import
  ../core/[
    cell, field, fieldtype, nazopuyo, pair, pairposition, position, puyopuyo,
    requirement, rule,
  ]
import ../private/[misc]
import ../private/app/[generate as generateLib]

export generateLib.GenerateError

type
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

  GenerateOption* = object ## Option for generation.
    requirement*: GenerateRequirement
    moveCount*: Positive
    colorCount*: range[1 .. 5]
    heights*: array[Column, Option[Natural]]
    puyoCounts*: tuple[color: Option[Natural], garbage: Natural]
      ## `color` can be `none` only if the kind is chain-like.
    connect2Counts*:
      tuple[
        total: Option[Natural], vertical: Option[Natural], horizontal: Option[Natural]
      ]
    connect3Counts*:
      tuple[
        total: Option[Natural],
        vertical: Option[Natural],
        horizontal: Option[Natural],
        lShape: Option[Natural],
      ]
    allowDouble*: bool
    allowLastDouble*: bool

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
# Puyo Puyo
# ------------------------------------------------

func generatePuyoPuyo[F: TsuField or WaterField](
    option: GenerateOption, useColors: seq[ColorPuyo], rng: var Rand
): PuyoPuyo[F] {.inline.} =
  ## Returns a random Puyo Puyo game.
  ## If generation fails, `GenerateError` is raised.
  let
    fieldCount =
      option.puyoCounts.color.get + option.puyoCounts.garbage - 2 * option.moveCount
    chainCount = option.puyoCounts.color.get div 4
    extraCount = option.puyoCounts.color.get mod 4

    chains = rng.split(chainCount, useColors.len, false)
    extras = rng.split(extraCount, useColors.len, true)

  # shuffle for pairs&positions
  var puyos = newSeqOfCap[Puyo](option.puyoCounts.color.get + option.puyoCounts.garbage)
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
  var pairsPositions = initDeque[PairPosition](option.moveCount)
  for i in 0 ..< option.moveCount:
    pairsPositions.addLast PairPosition(
      pair: initPair(puyos[2 * i], puyos[2 * i + 1]), position: Position.None
    )

  # shuffle for field
  {.push warning[ProveInit]: off.}
  var fieldPuyos =
    puyos[2 * option.moveCount .. ^1] &
    Cell.Garbage.Puyo.repeat option.puyoCounts.garbage
  {.pop.}
  rng.shuffle fieldPuyos

  # calc heights
  let colCounts = rng.split(fieldCount, option.heights)
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
    option: GenerateOption, useColors: seq[ColorPuyo], rng: var Rand
): Requirement {.inline.} =
  ## Returns a random requirement.
  ## If generation fails, `GenerateError` is raised.
  if option.requirement.kind in NoColorKinds:
    result = initRequirement(option.requirement.kind, option.requirement.number.get)
  elif option.requirement.kind in NoNumberKinds:
    result = initRequirement(option.requirement.kind, RequirementColor.low)
  else:
    result = initRequirement(
      option.requirement.kind, RequirementColor.low, option.requirement.number.get
    )

  # color
  if option.requirement.kind in ColorKinds:
    {.push warning[ProveInit]: off.}
    {.push warning[UnsafeSetLen]: off.}
    {.push warning[UnsafeDefault]: off.}
    result.color =
      case option.requirement.color.get
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
    option: GenerateOption,
    seed: SomeSignedInt,
    parallelCount: Positive = processorCount(),
): NazoPuyo[F] {.inline.} =
  ## Returns a randomly generated nazo puyo that has a unique solution.
  ## If generation fails, `GenerateError` is raised.
  ## `parallelCount` is ignored on JS backend.
  result = initNazoPuyo[F]() # HACK: dummy to suppress warning

  var option2 = option

  # infer color count if not specified
  if option.puyoCounts.color.isNone:
    if option.requirement.kind in {Chain, ChainMore, ChainClear, ChainMoreClear}:
      option2.puyoCounts.color = some Natural option.requirement.number.get * 4
    else:
      raise newException(GenerateError, "The number of color puyoes is not specified.")

  # validate the arguments
  # TODO: validate more strictly
  if option2.puyoCounts.color.get + option2.puyoCounts.garbage - 2 * option2.moveCount notin
      0 .. (when F is TsuField: Height else: WaterHeight) * Width:
    raise newException(GenerateError, "The number of puyos exceeds limit.")
  if option2.puyoCounts.color.get div 4 < option2.colorCount:
    raise newException(GenerateError, "The number of colors is too big.")

  var rng = seed.int64.initRand

  # requirement
  {.push warning[UnsafeSetLen]: off.}
  {.push warning[ProveInit]: off.}
  let useColors =
    rng.sample((ColorPuyo.low .. ColorPuyo.high).toSeq, option2.colorCount)
  {.pop.}
  {.pop.}
  result.requirement = option2.generateRequirement(useColors, rng)
  if not result.requirement.isSupported:
    raise newException(GenerateError, "Unsupported requirement.")

  # puyo puyo
  while true:
    try:
      result.puyoPuyo = generatePuyoPuyo[F](option2, useColors, rng)
    except GenerateError:
      continue

    # check features
    if result.puyoPuyo.field.isDead:
      continue
    if result.puyoPuyo.field.willDisappear:
      continue
    if not option2.allowDouble and result.puyoPuyo.pairsPositions.anyIt it.pair.isDouble:
      continue
    if not option2.allowLastDouble and result.puyoPuyo.pairsPositions[^1].pair.isDouble:
      continue
    if option2.connect2Counts.total.isSome and
        result.puyoPuyo.field.connect2.colorCount != option2.connect2Counts.total.get * 2:
      continue
    if option2.connect2Counts.vertical.isSome and
        result.puyoPuyo.field.connect2V.colorCount !=
        option2.connect2Counts.vertical.get * 2:
      continue
    if option2.connect2Counts.horizontal.isSome and
        result.puyoPuyo.field.connect2H.colorCount !=
        option2.connect2Counts.horizontal.get * 2:
      continue
    if option2.connect3Counts.total.isSome and
        result.puyoPuyo.field.connect3.colorCount != option2.connect3Counts.total.get * 3:
      continue
    if option2.connect3Counts.vertical.isSome and
        result.puyoPuyo.field.connect3V.colorCount !=
        option2.connect3Counts.vertical.get * 3:
      continue
    if option2.connect3Counts.horizontal.isSome and
        result.puyoPuyo.field.connect3H.colorCount !=
        option2.connect3Counts.horizontal.get * 3:
      continue
    if option2.connect3Counts.lShape.isSome and
        result.puyoPuyo.field.connect3L.colorCount !=
        option2.connect3Counts.lShape.get * 3:
      continue

    let answers = result.solve(parallelCount = parallelCount, earlyStopping = true)
    if answers.len == 1 and answers[0].len == result.moveCount:
      result.puyoPuyo.pairsPositions.positions = answers[0]
      return

proc generate*[F: TsuField or WaterField](
    option: GenerateOption, parallelCount: Positive = processorCount()
): NazoPuyo[F] {.inline.} =
  ## Returns a randomly generated nazo puyo that has a unique solution.
  ## If generation fails, `GenerateError` will be raised.
  ## `parallelCount` will be ignored on JS backend.
  var rng = initRand()
  generate[F](rng.rand int, parallelCount)

# ------------------------------------------------
# Generate - Wrap
# ------------------------------------------------

proc generate*(
    option: GenerateOption,
    rule: Rule,
    seed: SomeSignedInt,
    parallelCount: Positive = processorCount(),
): NazoPuyoWrap {.inline.} =
  ## Returns a randomly generated nazo puyo that has a unique solution.
  ## If generation fails, `GenerateError` is raised.
  ## `parallelCount` is ignored on JS backend.
  case rule
  of Tsu:
    generate[TsuField](option, seed, parallelCount).initNazoPuyoWrap
  of Water:
    generate[WaterField](option, seed, parallelCount).initNazoPuyoWrap

proc generate*(
    option: GenerateOption, rule: Rule, parallelCount: Positive = processorCount()
): NazoPuyoWrap {.inline.} =
  ## Returns a randomly generated nazo puyo that has a unique solution.
  ## If generation fails, `GenerateError` will be raised.
  ## `parallelCount` will be ignored on JS backend.
  var rng = initRand()
  option.generate(rule, rng.rand int, parallelCount)

## This module implements Nazo Puyo generators.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[random, sequtils, sets, sugar]
import ./[solve]
import ../[core]
import ../private/[algorithm, arrayutils, assign, deques, math, setutils, staticfor]

export core

type GenerateSettings* = object ## Settings of Nazo Puyo generation.
  rule: Rule
  goal: Goal
  moveCount: int
  colorCount: int
  heights: array[Col, int]
  puyoCounts: tuple[colored: int, garbage: int, hard: int]
  connection2Counts:
    tuple[totalOpt: Opt[int], verticalOpt: Opt[int], horizontalOpt: Opt[int]]
  connection3Counts:
    tuple[
      totalOpt: Opt[int],
      verticalOpt: Opt[int],
      horizontalOpt: Opt[int],
      lShapeOpt: Opt[int],
    ]
  indices:
    tuple[
      allowDouble: seq[int],
      garbage: seq[int],
      hard: seq[int],
      rotate: seq[int],
      crossRotate: seq[int],
    ]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(
    T: type GenerateSettings,
    rule: Rule,
    goal: Goal,
    moveCount, colorCount: int,
    heights: array[Col, int],
    puyoCounts: tuple[colored: int, garbage: int, hard: int],
    connection2Counts:
      tuple[totalOpt: Opt[int], verticalOpt: Opt[int], horizontalOpt: Opt[int]],
    connection3Counts:
      tuple[
        totalOpt: Opt[int],
        verticalOpt: Opt[int],
        horizontalOpt: Opt[int],
        lShapeOpt: Opt[int],
      ],
    indices:
      tuple[
        allowDouble: seq[int],
        garbage: seq[int],
        hard: seq[int],
        rotate: seq[int],
        crossRotate: seq[int],
      ],
): T =
  GenerateSettings(
    rule: rule,
    goal: goal,
    moveCount: moveCount,
    colorCount: colorCount,
    heights: heights,
    puyoCounts: puyoCounts,
    connection2Counts: connection2Counts,
    connection3Counts: connection3Counts,
    indices: indices,
  )

# ------------------------------------------------
# Split
# ------------------------------------------------

func split(
    rng: var Rand, total, chunkCount: int, allowZeroChunk: bool
): Pon2Result[seq[int]] =
  ## Returns the split values.
  if total < 0:
    return err "`total` should be non-negative"
  if chunkCount < 1:
    return err "`chunkCount` should be positive"

  if chunkCount == 1:
    if total == 0 and not allowZeroChunk:
      return err "`total` should be positive if `allowZeroChunk` is false"

    return ok @[total]

  # separation indices
  var sepIndices = newSeqOfCap[int](chunkCount + 1)
  sepIndices.add 0

  if allowZeroChunk:
    for _ in 0 ..< chunkCount - 1:
      sepIndices.add rng.rand total
  else:
    if total < chunkCount:
      return err "`total` should be greater than or equal to `chunkCount` if `allowZeroChunk` is false"

    var indices = (1 ..< total).toSeq
    rng.shuffle indices
    sepIndices &= indices[0 ..< chunkCount - 1]
  sepIndices.sort
  sepIndices.add total

  let chunks = collect:
    for i in 0 ..< chunkCount:
      sepIndices[i + 1] - sepIndices[i]
  ok chunks

func split(rng: var Rand, total: int, weights: openArray[int]): Pon2Result[seq[int]] =
  ## Returns the split values.
  ## All `weights` should have the same sign (zero is allowed).
  ## Positive weights represent probabilities, negative ones represent random positive
  ## values, and the zero weight represents the zero.
  ## If all the `weights` are zero, splits randomly.
  if total < 0:
    return err "`total` should be zero or positive"
  if weights.len == 0:
    return err "`weights` should have at least one element"

  if total == 0:
    return ok 0.repeat weights.len
  if weights.len == 1:
    return ok @[total]

  if weights.allIt it == 0:
    return rng.split(total, weights.len, allowZeroChunk = true)

  if weights.allIt it >= 0:
    let
      weightSum = weights.sum
      offset = rng.rand 1.0
    var
      chunks = newSeqOfCap[int](weights.len)
      nowWeightSum = 0
      prev = 0

    for weight in weights:
      nowWeightSum += weight

      let now = (total * nowWeightSum / weightSum + offset).int
      chunks.add now - prev

      prev.assign now

    return ok chunks

  if weights.allIt it <= 0:
    let counts =
      ?rng.split(total, weights.countIt it < 0, allowZeroChunk = false).context "Splitting by weights failed"

    var
      chunks = newSeqOfCap[int](weights.len)
      countsIndex = 0
    for weight in weights:
      if weight == 0:
        chunks.add 0
      else:
        chunks.add counts[countsIndex]
        countsIndex += 1

    return ok chunks

  err "all `weights` should have the same sign (zero is allowed)"

# ------------------------------------------------
# Puyo Puyo
# ------------------------------------------------

func generateNuisanceCounts(rng: var Rand, total: int): array[Col, int] =
  ## Returns a random nuisance counts.
  let (baseCount, extraCount) = total.divmod Width
  var counts = Col.initArrayWith baseCount

  for colOrd, extra in rng.split(extraCount, Width, allowZeroChunk = true).unsafeValue:
    counts[colOrd.Col] += extra

  counts

func generatePuyoPuyo(
    rng: var Rand, settings: GenerateSettings, useCells: set[Cell]
): Pon2Result[PuyoPuyo] =
  ## Returns a random Puyo Puyo.
  ## This function may not return because of an infinite loop.
  let
    garbageIndices = settings.indices.garbage.toHashSet
    hardIndices = settings.indices.hard.toHashSet
    rotateIndices = settings.indices.rotate.toHashSet
    crossRotateIndices = settings.indices.crossRotate.toHashSet
    pairPlaceIndices =
      (0 ..< settings.moveCount).toSeq.toHashSet -
      sum(garbageIndices, hardIndices, rotateIndices, crossRotateIndices)
    pairPlaceIndicesSeq = pairPlaceIndices.toSeq.sorted

  for indices in [garbageIndices, hardIndices, rotateIndices, crossRotateIndices]:
    if indices.anyIt it notin 0 ..< settings.moveCount:
      return err "out of range index detected"
  if (garbageIndices * hardIndices * rotateIndices * crossRotateIndices).card > 0:
    return err "all indices should be disjoint (except `allowDouble`)"
  if settings.puyoCounts.garbage < garbageIndices.card:
    return err "garbage puyo count is too small"
  if settings.puyoCounts.hard < hardIndices.card:
    return err "hard puyo count is too small"
  if pairPlaceIndices.card == 0:
    return err "at least one step should be `PairPlace`"
  if settings.puyoCounts.colored > Height * Width - 1 + 2 * pairPlaceIndices.card:
    return err "colored puyo count is too big"

  # steps
  var
    cells = newSeq[Cell]()
    steps = Steps.init settings.moveCount
    pairPlaceSteps = newSeq[Step](pairPlaceIndices.card)
    fieldGarbageCount = 0
    fieldHardCount = 0
    stepsGarbageCount = 0
    stepsHardCount = 0
  while true:
    # calc count
    stepsGarbageCount.assign (
      if garbageIndices.card == 0: 0
      else: rng.rand garbageIndices.card .. settings.puyoCounts.garbage
    )
    stepsHardCount.assign (
      if hardIndices.card == 0: 0
      else: rng.rand hardIndices.card .. settings.puyoCounts.hard
    )
    fieldGarbageCount.assign settings.puyoCounts.garbage - stepsGarbageCount
    fieldHardCount.assign settings.puyoCounts.hard - stepsHardCount

    # prepare cells
    let
      (chainCount, extraCount) = settings.puyoCounts.colored.divmod 4
      chainCounts =
        ?rng.split(chainCount, useCells.card, allowZeroChunk = false).context "colored puyo count is too small"
      extraCounts =
        rng.split(extraCount, useCells.card, allowZeroChunk = true).unsafeValue
    cells.assign newSeqOfCap[Cell](
      settings.puyoCounts.colored + fieldGarbageCount + fieldHardCount
    )
    var cellIndex = 0
    for cell in useCells:
      cells &= cell.repeat chainCounts[cellIndex] * 4 + extraCounts[cellIndex]
      cellIndex += 1
    rng.shuffle cells

    # pair-placement
    # NOTE: use the cells from behind since cut them off later
    pairPlaceSteps.setLen 0
    for i in 0 ..< pairPlaceIndices.card:
      let pair = Pair.init(cells[^(2 * i + 2)], cells[^(2 * i + 1)])
      if pairPlaceIndicesSeq[i] notin settings.indices.allowDouble and pair.isDouble:
        break

      pairPlaceSteps.add Step.init pair
    if pairPlaceSteps.len < pairPlaceIndices.card:
      continue

    break

  # nuisance
  let
    garbageSteps =
      if garbageIndices.card == 0:
        newSeq[Step]()
      else:
        collect:
          for count in rng.split(
            stepsGarbageCount, garbageIndices.card, allowZeroChunk = false
          ).unsafeValue:
            Step.init(rng.generateNuisanceCounts count, hard = false)
    hardSteps =
      if hardIndices.card == 0:
        newSeq[Step]()
      else:
        collect:
          for count in rng.split(
            stepsHardCount, hardIndices.card, allowZeroChunk = false
          ).unsafeValue:
            Step.init(rng.generateNuisanceCounts count, hard = true)

  # add steps
  var
    pairPlaceIndex = 0
    garbageIndex = 0
    hardIndex = 0
  for stepIndex in 0 ..< settings.moveCount:
    if stepIndex in pairPlaceIndices:
      steps.addLast pairPlaceSteps[pairPlaceIndex]
      pairPlaceIndex += 1
    elif stepIndex in garbageIndices:
      steps.addLast garbageSteps[garbageIndex]
      garbageIndex += 1
    elif stepIndex in hardIndices:
      steps.addLast hardSteps[hardIndex]
      hardIndex += 1
    elif stepIndex in rotateIndices:
      steps.addLast Step.init(cross = false)
    else: # CrossRotate
      steps.addLast Step.init(cross = true)

  # prepare cells for field
  cells.setLen cells.len - pairPlaceIndices.card * 2
  cells &= Garbage.repeat fieldGarbageCount
  cells &= Hard.repeat fieldHardCount
  rng.shuffle cells

  # field heights
  var fieldCellCounts = newSeq[int]()
  while true:
    fieldCellCounts.assign ?rng.split(cells.len, settings.heights).context "invalid heights"

    let heightMax = if settings.rule == Rule.Water: WaterHeight else: Height
    if fieldCellCounts.allIt it in 0 .. heightMax:
      break

  # field
  var
    cellArray = Row.initArrayWith Col.initArrayWith Cell.None
    cellIndex = 0
  staticFor(col, Col):
    for i in 0 ..< fieldCellCounts[col.ord]:
      cellArray[
        if settings.rule == Rule.Water:
          WaterTopRow.succ i
        else:
          Row.high.pred i
      ][col].assign cells[cellIndex]
      cellIndex += 1
  let field = cellArray.toField settings.rule

  ok PuyoPuyo.init(field, steps)

# ------------------------------------------------
# Generate
# ------------------------------------------------

proc generate*(rng: var Rand, settings: GenerateSettings): Pon2Result[NazoPuyo] =
  ## Returns a random Nazo Puyo that has a unique solution.
  # check settings
  if not settings.goal.isSupported:
    return err "goal is not supported"
  if settings.moveCount < 1:
    return err "moveCount should be positive"
  if settings.rule != Spinner and settings.indices.rotate.len > 0:
    return err "`Rotate` is allowed only in the Spinner rule"
  if settings.rule != CrossSpinner and settings.indices.crossRotate.len > 0:
    return err "`CrossRotate` is allowed only in the CrossSpinner rule"

  # cells
  var useCells = set[Cell]({})
  if settings.goal.mainOpt.isOk:
    let main = settings.goal.mainOpt.unsafeValue
    if main.color in GoalColor.Red .. GoalColor.Purple:
      useCells.incl main.color.ord.Cell
  if settings.goal.clearColorOpt.isOk:
    let clearColor = settings.goal.clearColorOpt.unsafeValue
    if clearColor in GoalColor.Red .. GoalColor.Purple:
      useCells.incl clearColor.ord.Cell
  if settings.colorCount notin useCells.card .. ColoredPuyos.card:
    return err "colorCount is out of range"
  if settings.colorCount > useCells.card:
    var extraCells = ColoredPuyos - useCells
    useCells.incl extraCells.toSeq.dup(shuffle(rng, _))[
      0 ..< settings.colorCount - useCells.card
    ].toSet

  var nazoPuyo = NazoPuyo.init(PuyoPuyo.init, settings.goal)

  while true:
    nazoPuyo.puyoPuyo.assign ?rng.generatePuyoPuyo(settings, useCells).context "Puyo Puyo generation failed"

    # check field
    if nazoPuyo.puyoPuyo.field.isDead:
      continue
    if nazoPuyo.puyoPuyo.field.canPop:
      continue

    # check connection2
    if settings.connection2Counts.totalOpt.isOk and
        nazoPuyo.puyoPuyo.field.connection2.coloredPuyoCount !=
        settings.connection2Counts.totalOpt.unsafeValue * 2:
      continue
    if settings.connection2Counts.verticalOpt.isOk and
        nazoPuyo.puyoPuyo.field.connection2Vertical.coloredPuyoCount !=
        settings.connection2Counts.verticalOpt.unsafeValue * 2:
      continue
    if settings.connection2Counts.horizontalOpt.isOk and
        nazoPuyo.puyoPuyo.field.connection2Horizontal.coloredPuyoCount !=
        settings.connection2Counts.horizontalOpt.unsafeValue * 2:
      continue

    # check connection3
    if settings.connection3Counts.totalOpt.isOk and
        nazoPuyo.puyoPuyo.field.connection3.coloredPuyoCount !=
        settings.connection3Counts.totalOpt.unsafeValue * 3:
      continue
    if settings.connection3Counts.verticalOpt.isOk and
        nazoPuyo.puyoPuyo.field.connection3Vertical.coloredPuyoCount !=
        settings.connection3Counts.verticalOpt.unsafeValue * 3:
      continue
    if settings.connection3Counts.horizontalOpt.isOk and
        nazoPuyo.puyoPuyo.field.connection3Horizontal.coloredPuyoCount !=
        settings.connection3Counts.horizontalOpt.unsafeValue * 3:
      continue
    if settings.connection3Counts.lShapeOpt.isOk and
        nazoPuyo.puyoPuyo.field.connection3LShape.coloredPuyoCount !=
        settings.connection3Counts.lShapeOpt.unsafeValue * 3:
      continue

    # check solutions
    let solutions = nazoPuyo.solve(calcAllSolutions = false)
    if solutions.len == 1 and solutions[0].len == settings.moveCount:
      for stepIndex, step in nazoPuyo.puyoPuyo.steps.mpairs:
        if step.kind == PairPlace:
          step.placement.assign solutions[0][stepIndex]

      break

  ok nazoPuyo

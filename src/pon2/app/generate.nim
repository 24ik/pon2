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
  heights: tuple[weights: Opt[array[Col, int]], positives: Opt[array[Col, bool]]]
  puyoCounts: tuple[colors: int, garbage: int, hard: int]
  connection2Counts: tuple[total: Opt[int], vertical: Opt[int], horizontal: Opt[int]]
  connection3Counts:
    tuple[total: Opt[int], vertical: Opt[int], horizontal: Opt[int], lShape: Opt[int]]
  dropGarbagesIndices: seq[int]
  dropHardsIndices: seq[int]
  rotateIndices: seq[int]
  crossRotateIndices: seq[int]
  allowDoubleNotLast: bool
  allowDoubleLast: bool

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(
    T: type GenerateSettings,
    rule: Rule,
    goal: Goal,
    moveCount, colorCount: int,
    heights: tuple[weights: Opt[array[Col, int]], positives: Opt[array[Col, bool]]],
    puyoCounts: tuple[colors: int, garbage: int, hard: int],
    connection2Counts: tuple[total: Opt[int], vertical: Opt[int], horizontal: Opt[int]],
    connection3Counts:
      tuple[total: Opt[int], vertical: Opt[int], horizontal: Opt[int], lShape: Opt[int]],
    dropGarbagesIndices, dropHardsIndices, rotateIndices, crossRotateIndices: seq[int],
    allowDoubleNotLast, allowDoubleLast: bool,
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
    dropGarbagesIndices: dropGarbagesIndices,
    dropHardsIndices: dropHardsIndices,
    rotateIndices: rotateIndices,
    crossRotateIndices: crossRotateIndices,
    allowDoubleNotLast: allowDoubleNotLast,
    allowDoubleLast: allowDoubleLast,
  )

# ------------------------------------------------
# Split
# ------------------------------------------------

func round(rng: var Rand, x: float): int =
  ## Probabilistic round function.
  ## For example, `rng.round(2.7)` becomes `2` with a 30% probability and
  ## `3` with a 70% probability.
  let floorX = x.int
  floorX + (rng.rand(1.0) < x - floorX.float).int

func split(
    rng: var Rand, total, chunkCount: int, allowZeroChunk: bool
): Pon2Result[seq[int]] =
  ## Splits the number `total` into `chunkCount` chunks.
  if total < 0:
    return err "`total` cannot be negative"

  if chunkCount < 1:
    return err "`chunkCount` should be greater than 0"

  if chunkCount == 1:
    if total == 0 and not allowZeroChunk:
      return err "`total` cannot be positive if `allowZeroChunk` if false"

    return ok @[total]

  # separation indices
  var sepIndices = newSeqOfCap[int](chunkCount.succ)
  sepIndices.add 0

  if allowZeroChunk:
    for _ in 0 ..< chunkCount.pred:
      sepIndices.add rng.rand total
  else:
    if total < chunkCount:
      return err "`total` should be greater than or equal to `chunkCount` if `allowZeroChunk` is false"

    var indices = (1 ..< total).toSeq
    rng.shuffle indices
    sepIndices &= indices[0 ..< chunkCount.pred]
  sepIndices.sort
  sepIndices.add total

  let chunks = collect:
    for i in 0 ..< chunkCount:
      sepIndices[i.succ] - sepIndices[i]
  ok chunks

func split(rng: var Rand, total: int, weights: openArray[int]): Pon2Result[seq[int]] =
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

  let weightSum = weights.sum
  if weightSum == 0:
    return rng.split(total, weights.len, allowZeroChunk = true)

  var chunks = newSeq[int](weights.len) # NOTE: somehow `newSeqUninit` does not work
  while true:
    var last = total

    for i in 0 ..< weights.len.pred:
      var rounded = rng.round total * weights[i] / weightSum
      chunks[i].assign rounded
      last.dec rounded

    if last == 0 or (last > 0 and weights[^1] > 0):
      chunks[^1].assign last
      break

  ok chunks

func split(
    rng: var Rand, total: int, positives: openArray[bool]
): Pon2Result[seq[int]] =
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

  let counts =
    ?rng.split(total, positives.countIt it, allowZeroChunk = false).context "Cannot split"
  var
    chunks = newSeqOfCap[int](positives.len)
    countsIndex = 0
  for positive in positives:
    if positive:
      chunks.add counts[countsIndex]
      countsIndex.inc
    else:
      chunks.add 0

  ok chunks

# ------------------------------------------------
# Checker
# ------------------------------------------------

const
  DummyCell = Cell.low
  GoalColorToCell: array[GoalColor, Cell] = [
    DummyCell, Cell.Red, Cell.Green, Cell.Blue, Cell.Yellow, Cell.Purple, DummyCell,
    DummyCell,
  ]

func isValid(self: GenerateSettings): Pon2Result[void] =
  ## Returns `true` if the settings are valid.
  ## Note that this function is "weak" checker; a generation may be failed
  ## (entering infinite loop) even though this function returns `true`.
  if not self.goal.isSupported:
    return err "none-goal is not supported"

  if self.moveCount < 1:
    return err "`moveCount` should be positive"

  var colors = set[Cell]({})
  if self.goal.mainOpt.isOk:
    let main = self.goal.mainOpt.unsafeValue
    if main.color in GoalColor.Red .. GoalColor.Purple:
      colors.incl GoalColorToCell[main.color]
  if self.goal.clearColorOpt.isOk:
    let clearColor = self.goal.clearColorOpt.unsafeValue
    if clearColor in GoalColor.Red .. GoalColor.Purple:
      colors.incl GoalColorToCell[clearColor]
  if self.colorCount notin max(colors.card, 1) .. 5:
    return err "`colorCount` should be in 1..5 (some goals require 2..5)"

  if self.heights.weights.isOk == self.heights.positives.isOk:
    return err "Either `heights.weights` or `heights.positives` should have a value"

  if self.heights.weights.isOk and self.heights.weights.unsafeValue.anyIt it < 0:
    return err "All elements in `heights.weights` should be non-negative"

  if self.puyoCounts.colors < 0:
    return err "`puyoCounts.colors` should be non-negative"

  if self.puyoCounts.garbage < 0:
    return err "`puyoCounts.garbage` should be non-negative"

  if self.puyoCounts.hard < 0:
    return err "`puyoCounts.hard` should be non-negative"

  if Height * Width - 1 + 2 * self.moveCount < self.puyoCounts.colors:
    return err "`puyoCounts.colors` is too small"

  if self.connection2Counts.total.isOk:
    if self.connection2Counts.total.unsafeValue < 0:
      return err "`connection2Counts.total` should be non-negative"

    var connection2VH = 0
    if self.connection2Counts.vertical.isOk:
      connection2VH.inc self.connection2Counts.vertical.unsafeValue
    if self.connection2Counts.horizontal.isOk:
      connection2VH.inc self.connection2Counts.horizontal.unsafeValue
    if connection2VH > self.connection2Counts.total.unsafeValue:
      return err "`connection2Counts.total` is too small"

  if self.connection3Counts.total.isOk:
    if self.connection3Counts.total.unsafeValue < 0:
      return err "`connection3Counts.total` should be non-negative"

    var connection3VHL = 0
    if self.connection3Counts.vertical.isOk:
      connection3VHL.inc self.connection3Counts.vertical.unsafeValue
    if self.connection3Counts.horizontal.isOk:
      connection3VHL.inc self.connection3Counts.horizontal.unsafeValue
    if self.connection3Counts.lShape.isOk:
      connection3VHL.inc self.connection3Counts.lShape.unsafeValue
    if connection3VHL > self.connection3Counts.total.unsafeValue:
      return err "`connection3Counts.total` is too small"

  if self.rule != Spinner and self.rotateIndices.len > 0:
    return err "Rotate is allowed only in the Spinner rule."
  if self.rule != CrossSpinner and self.crossRotateIndices.len > 0:
    return err "Cross-rotate is allowed only in the CrossSpinner rule."

  let
    dropGarbagesIndexSet = self.dropGarbagesIndices.toHashSet
    dropHardsIndexSet = self.dropHardsIndices.toHashSet
    rotateIndexSet = self.rotateIndices.toHashSet
    crossRotateIndexSet = self.crossRotateIndices.toHashSet
    notPairPlacementIndexSet =
      dropGarbagesIndexSet + dropHardsIndexSet + rotateIndexSet + crossRotateIndexSet

  if dropGarbagesIndexSet.card > self.puyoCounts.garbage:
    return err "`dropGarbagesIndices` is too large"

  if dropHardsIndexSet.card > self.puyoCounts.hard:
    return err "`dropHardsIndices` is too large"

  if notPairPlacementIndexSet.anyIt it notin 0 ..< self.moveCount:
    return err "`indices` are out of range"

  if notPairPlacementIndexSet.card !=
      dropGarbagesIndexSet.card + dropHardsIndexSet.card + rotateIndexSet.card +
      crossRotateIndexSet.card:
    return err "all `indices` should be disjoint"

  if notPairPlacementIndexSet.card >= self.moveCount:
    return err "at least one pair-step is required"

  Pon2Result[void].ok

# ------------------------------------------------
# Puyo Puyo
# ------------------------------------------------

func generateGarbagesCounts(rng: var Rand, total: int): array[Col, int] =
  ## Returns random garbage counts.
  let (baseCount, diffCount) = total.divmod Width
  var counts = Col.initArrayWith baseCount

  for colOrd, diff in rng.split(diffCount, Width, allowZeroChunk = true).unsafeValue:
    counts[Col.low.succ colOrd].inc diff

  counts

func generatePuyoPuyo(
    rng: var Rand, settings: GenerateSettings, useCells: seq[Cell]
): Pon2Result[PuyoPuyo] =
  ## Returns a random Puyo Puyo.
  ## Note that an infinite loop can occur.
  ## This function requires the settings passes `isValid`.
  let
    dropGarbagesIndexSet = settings.dropGarbagesIndices.toHashSet
    dropHardsIndexSet = settings.dropHardsIndices.toHashSet
    rotateIndexSet = settings.rotateIndices.toHashSet
    crossRotateIndexSet = settings.crossRotateIndices.toHashSet

    pairPlacementStepCount =
      settings.moveCount - (
        dropGarbagesIndexSet + dropHardsIndexSet + rotateIndexSet + crossRotateIndexSet
      ).card

  var
    cells = newSeq[Cell]()
    steps = initDeque[Step](settings.moveCount)
    garbageCountInField = 0
    hardCountInField = 0
  while true:
    let
      garbageCountInSteps =
        if dropGarbagesIndexSet.card == 0:
          0
        else:
          rng.rand dropGarbagesIndexSet.card .. settings.puyoCounts.garbage
      hardCountInSteps =
        if dropHardsIndexSet.card == 0:
          0
        else:
          rng.rand dropHardsIndexSet.card .. settings.puyoCounts.hard

    garbageCountInField = settings.puyoCounts.garbage - garbageCountInSteps
    hardCountInField = settings.puyoCounts.hard - hardCountInSteps

    # initialize cells
    let
      (chainCountMax, extraCount) = settings.puyoCounts.colors.divmod 4
      chainCounts =
        ?rng.split(chainCountMax, useCells.len, allowZeroChunk = false).context "Puyo Puyo generation failed"
      extraCounts =
        ?rng.split(extraCount, useCells.len, allowZeroChunk = true).context "Puyo Puyo generation failed"
    cells.assign newSeqOfCap[Cell](
      settings.puyoCounts.colors + garbageCountInField + hardCountInField
    )
    for i, cell in useCells:
      cells &= cell.repeat chainCounts[i] * 4 + extraCounts[i]
    rng.shuffle cells

    # steps (pair-placement)
    let pairPlacementSteps = collect:
      for i in 1 .. pairPlacementStepCount:
        Step.init Pair.init(cells[^(2 * i - 1)], cells[^(2 * i)])

    # check steps (pair-placement)
    if not settings.allowDoubleNotLast:
      for i in 0 ..< pairPlacementSteps.len.pred:
        if pairPlacementSteps[i].pair.isDouble:
          continue
    if not settings.allowDoubleLast:
      if pairPlacementSteps[^1].pair.isDouble:
        continue

    # steps (garbages)
    let
      garbagesSteps =
        if dropGarbagesIndexSet.card == 0:
          newSeq[Step]()
        else:
          let garbageCountsInSteps =
            ?rng.split(
              garbageCountInSteps, dropGarbagesIndexSet.card, allowZeroChunk = false
            ).context "Steps generation failed"
          collect:
            for total in garbageCountsInSteps:
              Step.init(rng.generateGarbagesCounts(total), dropHard = false)
      hardsSteps =
        if dropHardsIndexSet.card == 0:
          newSeq[Step]()
        else:
          let hardCountsInSteps =
            ?rng.split(hardCountInSteps, dropHardsIndexSet.card, allowZeroChunk = false).context "Steps generation failed"
          collect:
            for total in hardCountsInSteps:
              Step.init(rng.generateGarbagesCounts(total), dropHard = true)

    # steps
    var
      garbagesStepsIndex = 0
      hardsStepsIndex = 0
      pairPlacementStepsIndex = 0
    for stepIndex in 0 ..< settings.moveCount:
      if stepIndex in dropGarbagesIndexSet:
        steps.addLast garbagesSteps[garbagesStepsIndex]
        garbagesStepsIndex.inc
      elif stepIndex in dropHardsIndexSet:
        steps.addLast hardsSteps[hardsStepsIndex]
        hardsStepsIndex.inc
      elif stepIndex in rotateIndexSet:
        steps.addLast Step.init(cross = false)
      elif stepIndex in crossRotateIndexSet:
        steps.addLast Step.init(cross = true)
      else:
        steps.addLast pairPlacementSteps[pairPlacementStepsIndex]
        pairPlacementStepsIndex.inc

    # fix cells
    cells.setLen cells.len.pred pairPlacementStepCount * 2
    cells &= Garbage.repeat garbageCountInField
    cells &= Hard.repeat hardCountInField
    rng.shuffle cells

    break

  # field heights
  var cellCountsInField = newSeq[int]()
  while true:
    cellCountsInField.assign(
      if settings.heights.weights.isOk:
        ?rng.split(cells.len, settings.heights.weights.unsafeValue).context "Field generation failed"
      else:
        ?rng.split(cells.len, settings.heights.positives.unsafeValue).context "Field generation failed"
    )
    if cellCountsInField.allIt(
      it in 0 .. (if settings.rule == Rule.Water: WaterHeight else: Height)
    ):
      break

  # field
  var
    cellArray = Row.initArrayWith Col.initArrayWith Cell.None
    cellIndex = 0
  staticFor(col, Col):
    for i in 0 ..< cellCountsInField[col.ord]:
      let row =
        if settings.rule == Rule.Water:
          Row.low.succ(AirHeight).succ i
        else:
          Row.high.pred i
      cellArray[row][col].assign cells[cellIndex]
      cellIndex.inc
  let field = cellArray.toField settings.rule

  ok PuyoPuyo.init(field, steps)

# ------------------------------------------------
# Generate
# ------------------------------------------------

proc generate*(rng: var Rand, settings: GenerateSettings): Pon2Result[NazoPuyo] =
  ## Returns a random Nazo Puyo that has a unique solution.
  ?settings.isValid.context "Generation failed"

  # cells
  var useCellsSet = set[Cell]({})
  if settings.goal.mainOpt.isOk:
    let main = settings.goal.mainOpt.unsafeValue
    if main.color in GoalColor.Red .. GoalColor.Purple:
      useCellsSet.incl GoalColorToCell[main.color]
  if settings.goal.clearColorOpt.isOk:
    let clearColor = settings.goal.clearColorOpt.unsafeValue
    if clearColor in GoalColor.Red .. GoalColor.Purple:
      useCellsSet.incl GoalColorToCell[clearColor]
  useCellsSet.incl (Cell.Red .. Cell.Purple).toSeq.dup(shuffle(rng, _))[
    0 ..< settings.colorCount - useCellsSet.card
  ].toSet
  let useCells = useCellsSet.toSeq

  while true:
    let puyoPuyoResult = rng.generatePuyoPuyo(settings, useCells)
    if puyoPuyoResult.isErr:
      continue
    let puyoPuyo = puyoPuyoResult.unsafeValue

    if puyoPuyo.field.isDead:
      continue
    if puyoPuyo.field.canPop:
      continue

    if settings.connection2Counts.total.isOk and
        puyoPuyo.field.connection2.colorPuyoCount !=
        settings.connection2Counts.total.unsafeValue * 2:
      continue
    if settings.connection2Counts.vertical.isOk and
        puyoPuyo.field.connection2Vertical.colorPuyoCount !=
        settings.connection2Counts.vertical.unsafeValue * 2:
      continue
    if settings.connection2Counts.horizontal.isOk and
        puyoPuyo.field.connection2Horizontal.colorPuyoCount !=
        settings.connection2Counts.horizontal.unsafeValue * 2:
      continue

    if settings.connection3Counts.total.isOk and
        puyoPuyo.field.connection3.colorPuyoCount !=
        settings.connection3Counts.total.unsafeValue * 3:
      continue
    if settings.connection3Counts.vertical.isOk and
        puyoPuyo.field.connection3Vertical.colorPuyoCount !=
        settings.connection3Counts.vertical.unsafeValue * 3:
      continue
    if settings.connection3Counts.horizontal.isOk and
        puyoPuyo.field.connection3Horizontal.colorPuyoCount !=
        settings.connection3Counts.horizontal.unsafeValue * 3:
      continue
    if settings.connection3Counts.lShape.isOk and
        puyoPuyo.field.connection3LShape.colorPuyoCount !=
        settings.connection3Counts.lShape.unsafeValue * 3:
      continue

    var nazoPuyo = NazoPuyo.init(puyoPuyo, settings.goal)
    let answers = nazoPuyo.solve(calcAllAnswers = false)
    if answers.len == 1 and answers[0].len == settings.moveCount:
      for stepIndex, optPlacement in answers[0]:
        if nazoPuyo.puyoPuyo.steps[stepIndex].kind == PairPlacement:
          nazoPuyo.puyoPuyo.steps[stepIndex].optPlacement.assign optPlacement

      return ok nazoPuyo

  return err "Not reached here"

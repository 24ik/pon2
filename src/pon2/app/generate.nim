## This module implements Nazo Puyo generators.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[algorithm, random, sequtils, sugar]
import ./[nazopuyowrap, solve]
import ../[core]
import ../private/[arrayops2, assign3, deques2, math2, results2, staticfor2]

export results2

type
  GenerateGoalColor* {.pure.} = enum
    ## Nazo Puyo goal color for generation.
    All
    SingleColor
    Garbages
    Colors

  GenerateGoal* = object ## Nazo Puyo goal for generation.
    kind: GoalKind
    color: GenerateGoalColor
    val: GoalVal

  GenerateSettings* = object ## Settings of Nazo Puyo generation.
    goal: GenerateGoal
    moveCnt: int
    colorCnt: int
    heights: tuple[weights: Opt[array[Col, int]], positives: Opt[array[Col, bool]]]
    puyoCnts: tuple[colors: int, garbage: int, hard: int]
    conn2Cnts: tuple[total: Opt[int], vertical: Opt[int], horizontal: Opt[int]]
    conn3Cnts:
      tuple[total: Opt[int], vertical: Opt[int], horizontal: Opt[int], lShape: Opt[int]]
    allowDblNotLast: bool
    allowDblLast: bool
    allowGarbagesStep: bool
    allowHardStep: bool

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(
    T: type GenerateGoal, kind: GoalKind, color: GenerateGoalColor, val: GoalVal
): T {.inline.} =
  T(kind: kind, color: color, val: val)

func init*(
    T: type GenerateSettings,
    goal: GenerateGoal,
    moveCnt, colorCnt: int,
    heights: tuple[weights: Opt[array[Col, int]], positives: Opt[array[Col, bool]]],
    puyoCnts: tuple[colors: int, garbage: int, hard: int],
    conn2Cnts: tuple[total: Opt[int], vertical: Opt[int], horizontal: Opt[int]],
    conn3Cnts:
      tuple[total: Opt[int], vertical: Opt[int], horizontal: Opt[int], lShape: Opt[int]],
    allowDblNotLast, allowDblLast, allowGarbagesStep, allowHardStep: bool,
): T {.inline.} =
  GenerateSettings(
    goal: goal,
    moveCnt: moveCnt,
    colorCnt: colorCnt,
    heights: heights,
    puyoCnts: puyoCnts,
    conn2Cnts: conn2Cnts,
    conn3Cnts: conn3Cnts,
    allowDblNotLast: allowDblNotLast,
    allowDblLast: allowDblLast,
    allowGarbagesStep: allowGarbagesStep,
    allowHardStep: allowHardStep,
  )

# ------------------------------------------------
# Split
# ------------------------------------------------

func round(rng: var Rand, x: float): int {.inline.} =
  ## Probabilistic round function.
  ## For example, `rng.round(2.7)` becomes `2` with a 30% probability and
  ## `3` with a 70% probability.
  let floorX = x.int
  floorX + (rng.rand(1.0) < x - floorX.float).int

func split(
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

func split(
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

func split(
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

# ------------------------------------------------
# Checker
# ------------------------------------------------

func isValid(self: GenerateSettings): Res[void] {.inline.} =
  ## Returns `true` if the settings are valid.
  ## Note that this function is "weak" checker; a generation may be failed
  ## (entering infinite loop) even though this function returns `true`.
  if self.moveCnt < 1:
    return err "`moveCnt` should be positive"

  if self.colorCnt notin 1 .. 5:
    return err "`colorCnt` should be in 1..5"

  if self.heights.weights.isOk == self.heights.positives.isOk:
    return err "Either `heights.weights` or `heights.positives` should have a value"

  if self.heights.weights.isOk and self.heights.weights.unsafeValue.anyIt it < 0:
    return err "All elements in `heights.weights` should be non-negative"

  if self.puyoCnts.colors < 0:
    return err "`puyoCnts.colors` should be non-negative"

  if self.puyoCnts.garbage < 0:
    return err "`puyoCnts.garbage` should be non-negative"

  if self.puyoCnts.hard < 0:
    return err "`puyoCnts.hard` should be non-negative"

  if Height * Width - 1 + 2 * self.moveCnt < self.puyoCnts.colors:
    return err "`puyoCnts.colors` is too small"

  if self.conn2Cnts.total.isOk:
    if self.conn2Cnts.total.unsafeValue < 0:
      return err "`conn2Cnts.total` should be non-negative"

    var conn2VH = 0
    if self.conn2Cnts.vertical.isOk:
      conn2VH.inc self.conn2Cnts.vertical.unsafeValue
    if self.conn2Cnts.horizontal.isOk:
      conn2VH.inc self.conn2Cnts.horizontal.unsafeValue
    if conn2VH > self.conn2Cnts.total.unsafeValue:
      return err "`conn2Cnts.total` is too small"

  if self.conn3Cnts.total.isOk:
    if self.conn3Cnts.total.unsafeValue < 0:
      return err "`conn3Cnts.total` should be non-negative"

    var conn3VHL = 0
    if self.conn3Cnts.vertical.isOk:
      conn3VHL.inc self.conn3Cnts.vertical.unsafeValue
    if self.conn3Cnts.horizontal.isOk:
      conn3VHL.inc self.conn3Cnts.horizontal.unsafeValue
    if self.conn3Cnts.lShape.isOk:
      conn3VHL.inc self.conn3Cnts.lShape.unsafeValue
    if conn3VHL > self.conn3Cnts.total.unsafeValue:
      return err "`conn3Cnts.total` is too small"

  Res[void].ok

# ------------------------------------------------
# Puyo Puyo
# ------------------------------------------------

func generateGarbagesCnts(rng: var Rand, total: int): array[Col, int] {.inline.} =
  ## Returns random garbage counts.
  let (baseCnt, diffCnt) = total.divmod Width
  var cnts = initArrWith[Col, int](baseCnt)

  for colOrd, diff in rng.split(diffCnt, Width, allowZeroChunk = true).unsafeValue:
    cnts[Col.low.succ colOrd].inc diff

  cnts

func generatePuyoPuyo[F: TsuField or WaterField](
    rng: var Rand, settings: GenerateSettings, useCells: seq[Cell]
): Res[PuyoPuyo[F]] {.inline.} =
  ## Returns a random Puyo Puyo.
  ## Note that an infinite loop can occur.
  # steps (garbages)
  let
    garbagesCellCnt = settings.puyoCnts.garbage + settings.puyoCnts.hard

    garbagesStepCntMax =
      if settings.allowGarbagesStep:
        min(settings.moveCnt.pred div 2, garbagesCellCnt)
      else:
        0

  # steps (garbages)
  var
    garbageCnt {.noinit.}, hardCnt {.noinit.}: int
    cells = newSeq[Cell]()
    steps = Steps.init
  while true:
    let
      garbagesStepCnt = rng.rand garbagesStepCntMax
      garbagesCellCntInSteps = rng.rand garbagesStepCnt .. garbagesCellCnt
    var garbagesSteps = newSeqOfCap[Step](garbagesStepCnt)

    garbageCnt.assign settings.puyoCnts.garbage
    hardCnt.assign settings.puyoCnts.hard

    if garbagesStepCnt > 0:
      let
        garbagesCellCntsInSteps =
          ?rng.split(garbagesCellCntInSteps, garbagesStepCnt, allowZeroChunk = false).context "Steps generation failed"
        garbagesCntsInSteps = collect:
          for total in garbagesCellCntsInSteps:
            rng.generateGarbagesCnts total

      var failed = false
      for garbagesStepIdx in 0 ..< garbagesStepCnt:
        let
          cnt = garbagesCellCntsInSteps[garbagesStepIdx]
          cnts = garbagesCntsInSteps[garbagesStepIdx]

        var dropHards = newSeqOfCap[bool](2)
        if cnt <= garbageCnt:
          dropHards.add false
        if settings.allowHardStep and cnt <= hardCnt:
          dropHards.add true
        if dropHards.len == 0:
          failed = true
          break

        let dropHard = rng.sample dropHards
        garbagesSteps.add Step.init(cnts, dropHard)

        if dropHard:
          hardCnt.dec cnt
        else:
          garbageCnt.dec cnt
      if failed:
        continue

    if settings.puyoCnts.colors + garbageCnt + hardCnt >
        Height * Width - 1 + (settings.moveCnt - garbagesStepCnt) * 2:
      continue

    # color cells
    let
      (chainCntMax, extraCnt) = settings.puyoCnts.colors.divmod 4
      chainCnts =
        ?rng.split(chainCntMax, useCells.len, allowZeroChunk = false).context "Generation failed"
      extraCnts =
        ?rng.split(extraCnt, useCells.len, allowZeroChunk = true).context "Generation failed"
    cells.assign newSeqOfCap[Cell](settings.puyoCnts.colors + garbageCnt + hardCnt)
    for i, cell in useCells:
      cells &= cell.repeat chainCnts[i] * 4 + extraCnts[i]
    rng.shuffle cells

    # steps (pair-placement)
    let
      pairPlcmtStepCnt = settings.moveCnt - garbagesStepCnt
      cellIdxStartInSteps = cells.len - pairPlcmtStepCnt * 2
      pairPlcmtSteps = collect:
        for i in 0 ..< pairPlcmtStepCnt:
          let idx = cellIdxStartInSteps + 2 * i
          Step.init Pair.init(cells[idx], cells[idx.succ])

    let dblStepCntMax =
      if settings.allowDblNotLast:
        pairPlcmtStepCnt - (not settings.allowDblLast).int
      else:
        settings.allowDblLast.int
    if pairPlcmtSteps.countIt(it.pair.isDbl) > dblStepCntMax:
      continue

    # steps
    var stepsSeq = garbagesSteps & pairPlcmtSteps
    rng.shuffle stepsSeq
    while stepsSeq[^1].kind != PairPlacement or
        (not settings.allowDblLast and stepsSeq[^1].pair.isDbl):
      rng.shuffle stepsSeq
    steps.assign stepsSeq.toDeque2

    # cells
    cells.setLen cellIdxStartInSteps
    cells &= Garbage.repeat garbageCnt
    cells &= Hard.repeat hardCnt
    rng.shuffle cells

    break

  # field heights
  let cellCntInField = cells.len
  var cellCntsInField = newSeq[int]()
  while true:
    cellCntsInField.assign(
      if settings.heights.weights.isOk:
        ?rng.split(cellCntInField, settings.heights.weights.unsafeValue).context "Field generation failed"
      else:
        ?rng.split(cellCntInField, settings.heights.positives.unsafeValue).context "Field generation failed"
    )
    if cellCntsInField.allIt(it in 0 .. (when F is TsuField: Height else: WaterHeight)):
      break

  # field
  var
    fieldArr = initArrWith[Row, array[Col, Cell]](initArrWith[Col, Cell](None))
    cellIdx = 0
  staticFor(col, Col):
    for i in 0 ..< cellCntsInField[col.ord]:
      let row =
        when F is TsuField:
          Row.high.pred i
        else:
          Row.low.succ(AirHeight).succ i
      fieldArr[row][col].assign cells[cellIdx]
      cellIdx.inc
  let field = when F is TsuField: fieldArr.toTsuField else: fieldArr.toWaterField

  ok PuyoPuyo[F].init(field, steps)

# ------------------------------------------------
# Goal
# ------------------------------------------------

const
  DummyGoalColor = GoalColor.All
  CellToGoalColor: array[Cell, GoalColor] = [
    DummyGoalColor, DummyGoalColor, DummyGoalColor, GoalColor.Red, GoalColor.Green,
    GoalColor.Blue, GoalColor.Yellow, GoalColor.Purple,
  ]

func generateGoal(
    rng: var Rand, settings: GenerateSettings, useCells: seq[Cell]
): Goal {.inline.} =
  ## Returns a random goal.
  var goal = Goal.init
  goal.kind.assign settings.goal.kind

  if goal.kind in ColorKinds:
    goal.optColor.ok (
      case settings.goal.color
      of GenerateGoalColor.All:
        GoalColor.All
      of SingleColor:
        CellToGoalColor[rng.sample useCells]
      of GenerateGoalColor.Garbages:
        GoalColor.Garbages
      of GenerateGoalColor.Colors:
        GoalColor.Colors
    )

  if goal.kind in ValKinds:
    goal.optVal.ok settings.goal.val

  goal.normalized

# ------------------------------------------------
# Generate
# ------------------------------------------------

proc generate[F: TsuField or WaterField](
    rng: var Rand, settings: GenerateSettings
): Res[NazoPuyo[F]] {.inline.} =
  ## Returns a random Nazo Puyo that has a unique solution.
  ?settings.isValid.context "Generation failed"

  let
    useCells =
      (Cell.Red .. Cell.Purple).toSeq.dup(shuffle(rng, _))[0 ..< settings.colorCnt]
    goal = rng.generateGoal(settings, useCells)
  if not goal.isSupported:
    return err "Unsupported goal"

  while true:
    let puyoPuyoRes = generatePuyoPuyo[F](rng, settings, useCells)
    if puyoPuyoRes.isErr:
      continue

    let puyoPuyo = puyoPuyoRes.unsafeValue

    if puyoPuyo.field.isDead:
      continue
    if puyoPuyo.field.canPop:
      continue

    if settings.conn2Cnts.total.isOk and
        puyoPuyo.field.conn2.colorPuyoCnt != settings.conn2Cnts.total.unsafeValue * 2:
      continue
    if settings.conn2Cnts.vertical.isOk and
        puyoPuyo.field.conn2Vertical.colorPuyoCnt !=
        settings.conn2Cnts.vertical.unsafeValue * 2:
      continue
    if settings.conn2Cnts.horizontal.isOk and
        puyoPuyo.field.conn2Horizontal.colorPuyoCnt !=
        settings.conn2Cnts.horizontal.unsafeValue * 2:
      continue

    if settings.conn3Cnts.total.isOk and
        puyoPuyo.field.conn3.colorPuyoCnt != settings.conn3Cnts.total.unsafeValue * 3:
      continue
    if settings.conn3Cnts.vertical.isOk and
        puyoPuyo.field.conn3Vertical.colorPuyoCnt !=
        settings.conn3Cnts.vertical.unsafeValue * 3:
      continue
    if settings.conn3Cnts.horizontal.isOk and
        puyoPuyo.field.conn3Horizontal.colorPuyoCnt !=
        settings.conn3Cnts.horizontal.unsafeValue * 3:
      continue
    if settings.conn3Cnts.lShape.isOk and
        puyoPuyo.field.conn3LShape.colorPuyoCnt !=
        settings.conn3Cnts.lShape.unsafeValue * 3:
      continue

    var nazo = NazoPuyo[F].init(puyoPuyo, goal)
    let answers = nazo.solve(calcAllAnswers = false)
    if answers.len == 1 and answers[0].len == settings.moveCnt:
      for stepIdx, optPlcmt in answers[0]:
        if nazo.puyoPuyo.steps[stepIdx].kind == PairPlacement:
          nazo.puyoPuyo.steps[stepIdx].optPlacement.assign optPlcmt

      return ok nazo

  return err "Not reached here"

proc generate*(
    rng: var Rand, settings: GenerateSettings, rule: Rule
): Res[NazoPuyoWrap] {.inline.} =
  ## Returns a random Nazo Puyo that has a unique solution.
  case rule
  of Tsu:
    ok NazoPuyoWrap.init ?generate[TsuField](rng, settings)
  of Water:
    ok NazoPuyoWrap.init ?generate[WaterField](rng, settings)

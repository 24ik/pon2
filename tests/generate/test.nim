{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[random, sequtils, sugar, unittest]
import ../../src/pon2/[core]
import ../../src/pon2/app/[generate, nazopuyowrap, solve]

# ------------------------------------------------
# Generate
# ------------------------------------------------

proc checkGenerate(
    genGoalKind: GoalKind,
    genGoalColor: GenerateGoalColor,
    genGoalVal: GoalVal,
    moveCount: int,
    colorCount: int,
    heights: tuple[weights: Opt[array[Col, int]], positives: Opt[array[Col, bool]]],
    puyoCounts: tuple[colors: int, garbage: int, hard: int],
    connection2Counts: tuple[total: Opt[int], vertical: Opt[int], horizontal: Opt[int]],
    connection3Counts:
      tuple[total: Opt[int], vertical: Opt[int], horizontal: Opt[int], lShape: Opt[int]],
    dropGarbagesIndices: seq[int],
    dropHardsIndices: seq[int],
    rotateIndices: seq[int],
    crossRotateIndices: seq[int],
    allowDoubleNotLast: bool,
    allowDoubleLast: bool,
    rule: Rule,
    seed: int,
) {.raises: [Exception].} =
  var rng = seed.initRand
  let
    genGoal = GenerateGoal.init(genGoalKind, genGoalColor, genGoalVal)
    settings = GenerateSettings.init(
      genGoal, moveCount, colorCount, heights, puyoCounts, connection2Counts,
      connection3Counts, dropGarbagesIndices, dropHardsIndices, rotateIndices,
      crossRotateIndices, allowDoubleNotLast, allowDoubleLast,
    )
    wrapRes = rng.generate(settings, rule)

  check wrapRes.isOk
  let wrap = wrapRes.unsafeValue

  check wrap.optGoal.isOk
  let goal = wrap.optGoal.unsafeValue

  check goal.isNormalForm
  check goal.kind == genGoalKind
  if goal.kind in ColorKinds:
    case genGoalColor
    of GenerateGoalColor.All:
      check goal.optColor.unsafeValue == GoalColor.All
    of SingleColor:
      check goal.optColor.unsafeValue in GoalColor.Red .. GoalColor.Purple
    of GenerateGoalColor.Garbages:
      check goal.optColor.unsafeValue == GoalColor.Garbages
    of GenerateGoalColor.Colors:
      check goal.optColor.unsafeValue == GoalColor.Colors
  if goal.kind in ValKinds:
    check goal.optVal.unsafeValue == genGoalVal

  wrap.unwrapNazoPuyo:
    let nazo = itNazo

    check nazo.puyoPuyo.steps.len == moveCount

    check (Cell.Red .. Cell.Purple).toSeq.filter(
      (cell) => nazo.puyoPuyo.cellCount(cell) > 0
    ).len == colorCount

    check nazo.puyoPuyo.field.isSettled
    check not nazo.puyoPuyo.field.canPop

    let baseRow =
      case rule
      of Tsu: Row.high
      of Water: AirHeight.Row
    if heights.weights.isOk:
      if heights.weights.unsafeValue != [0, 0, 0, 0, 0, 0]:
        for col in Col:
          if heights.weights.unsafeValue[col] == 0:
            check nazo.puyoPuyo.field[baseRow, col] == None
    else:
      for col in Col:
        check heights.positives.unsafeValue[col] ==
          (nazo.puyoPuyo.field[baseRow, col] != None)

    check puyoCounts.colors == nazo.puyoPuyo.colorPuyoCount
    check puyoCounts.garbage == nazo.puyoPuyo.cellCount Garbage
    check puyoCounts.hard == nazo.puyoPuyo.cellCount Hard

    if connection2Counts.total.isOk:
      check connection2Counts.total.unsafeValue ==
        nazo.puyoPuyo.field.connection2.colorPuyoCount div 2
    if connection2Counts.vertical.isOk:
      check connection2Counts.vertical.unsafeValue ==
        nazo.puyoPuyo.field.connection2Vertical.colorPuyoCount div 2
    if connection2Counts.horizontal.isOk:
      check connection2Counts.horizontal.unsafeValue ==
        nazo.puyoPuyo.field.connection2Vertical.colorPuyoCount div 2

    if connection3Counts.total.isOk:
      check connection3Counts.total.unsafeValue ==
        nazo.puyoPuyo.field.connection3.colorPuyoCount div 3
    if connection3Counts.vertical.isOk:
      check connection3Counts.vertical.unsafeValue ==
        nazo.puyoPuyo.field.connection3Vertical.colorPuyoCount div 3
    if connection3Counts.horizontal.isOk:
      check connection3Counts.horizontal.unsafeValue ==
        nazo.puyoPuyo.field.connection3Vertical.colorPuyoCount div 3
    if connection3Counts.lShape.isOk:
      check connection3Counts.lShape.unsafeValue ==
        nazo.puyoPuyo.field.connection3LShape.colorPuyoCount div 3

    if not allowDoubleNotLast:
      check (0 ..< moveCount.pred).toSeq.all (index) =>
        nazo.puyoPuyo.steps[index].kind != PairPlacement or
        not nazo.puyoPuyo.steps[index].pair.isDouble

    if not allowDoubleLast:
      check nazo.puyoPuyo.steps[^1].kind != PairPlacement or
        not nazo.puyoPuyo.steps[^1].pair.isDouble

    for stepIndex in dropGarbagesIndices:
      check nazo.puyoPuyo.steps[stepIndex].kind == StepKind.Garbages and
        not nazo.puyoPuyo.steps[stepIndex].dropHard

    for stepIndex in dropHardsIndices:
      check nazo.puyoPuyo.steps[stepIndex].kind == StepKind.Garbages and
        nazo.puyoPuyo.steps[stepIndex].dropHard

    for stepIndex in rotateIndices:
      check nazo.puyoPuyo.steps[stepIndex].kind == StepKind.Rotate and
        not nazo.puyoPuyo.steps[stepIndex].cross

    for stepIndex in crossRotateIndices:
      check nazo.puyoPuyo.steps[stepIndex].kind == StepKind.Rotate and
        nazo.puyoPuyo.steps[stepIndex].cross

    let ans = nazo.solve
    check ans.len == 1
    check ans[0].len == moveCount
    for stepIndex, step in nazo.puyoPuyo.steps:
      case step.kind
      of PairPlacement:
        check step.optPlacement == ans[0][stepIndex]
      else:
        check ans[0][stepIndex].isErr

block: # generate
  checkGenerate(
    Chain,
    GenerateGoalColor.low,
    5,
    2,
    3,
    (
      weights: Opt[array[Col, int]].err,
      positives: Opt[array[Col, bool]].ok [false, true, true, true, false, false],
    ),
    (colors: 20, garbage: 5, hard: 1),
    (total: Opt[int].err, vertical: Opt[int].ok 0, horizontal: Opt[int].err),
    (
      total: Opt[int].ok 2,
      vertical: Opt[int].err,
      horizontal: Opt[int].err,
      lShape: Opt[int].ok 1,
    ),
    @[0],
    newSeq[int](),
    newSeq[int](),
    newSeq[int](),
    false,
    false,
    Water,
    123,
  )
  checkGenerate(
    Clear,
    GenerateGoalColor.All,
    0,
    2,
    2,
    (
      weights: Opt[array[Col, int]].ok [0, 0, 1, 2, 3, 0],
      positives: Opt[array[Col, bool]].err,
    ),
    (colors: 12, garbage: 3, hard: 0),
    (total: Opt[int].ok 2, vertical: Opt[int].err, horizontal: Opt[int].err),
    (
      total: Opt[int].ok 1,
      vertical: Opt[int].err,
      horizontal: Opt[int].err,
      lShape: Opt[int].err,
    ),
    newSeq[int](),
    newSeq[int](),
    @[0],
    newSeq[int](),
    false,
    false,
    Tsu,
    456,
  )

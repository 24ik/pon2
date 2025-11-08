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
    moveCnt: int,
    colorCnt: int,
    heights: tuple[weights: Opt[array[Col, int]], positives: Opt[array[Col, bool]]],
    puyoCnts: tuple[colors: int, garbage: int, hard: int],
    conn2Cnts: tuple[total: Opt[int], vertical: Opt[int], horizontal: Opt[int]],
    conn3Cnts:
      tuple[total: Opt[int], vertical: Opt[int], horizontal: Opt[int], lShape: Opt[int]],
    dropGarbagesIndices: seq[int],
    dropHardsIndices: seq[int],
    rotateIndices: seq[int],
    crossRotateIndices: seq[int],
    allowDblNotLast: bool,
    allowDblLast: bool,
    rule: Rule,
    seed: int,
) {.raises: [Exception].} =
  var rng = seed.initRand
  let
    genGoal = GenerateGoal.init(genGoalKind, genGoalColor, genGoalVal)
    settings = GenerateSettings.init(
      genGoal, moveCnt, colorCnt, heights, puyoCnts, conn2Cnts, conn3Cnts,
      dropGarbagesIndices, dropHardsIndices, rotateIndices, crossRotateIndices,
      allowDblNotLast, allowDblLast,
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

    check nazo.puyoPuyo.steps.len == moveCnt

    check (Cell.Red .. Cell.Purple).toSeq.filter(
      (cell) => nazo.puyoPuyo.cellCnt(cell) > 0
    ).len == colorCnt

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

    check puyoCnts.colors == nazo.puyoPuyo.colorPuyoCnt
    check puyoCnts.garbage == nazo.puyoPuyo.cellCnt Garbage
    check puyoCnts.hard == nazo.puyoPuyo.cellCnt Hard

    if conn2Cnts.total.isOk:
      check conn2Cnts.total.unsafeValue == nazo.puyoPuyo.field.conn2.colorPuyoCnt div 2
    if conn2Cnts.vertical.isOk:
      check conn2Cnts.vertical.unsafeValue ==
        nazo.puyoPuyo.field.conn2Vertical.colorPuyoCnt div 2
    if conn2Cnts.horizontal.isOk:
      check conn2Cnts.horizontal.unsafeValue ==
        nazo.puyoPuyo.field.conn2Vertical.colorPuyoCnt div 2

    if conn3Cnts.total.isOk:
      check conn3Cnts.total.unsafeValue == nazo.puyoPuyo.field.conn3.colorPuyoCnt div 3
    if conn3Cnts.vertical.isOk:
      check conn3Cnts.vertical.unsafeValue ==
        nazo.puyoPuyo.field.conn3Vertical.colorPuyoCnt div 3
    if conn3Cnts.horizontal.isOk:
      check conn3Cnts.horizontal.unsafeValue ==
        nazo.puyoPuyo.field.conn3Vertical.colorPuyoCnt div 3
    if conn3Cnts.lShape.isOk:
      check conn3Cnts.lShape.unsafeValue ==
        nazo.puyoPuyo.field.conn3LShape.colorPuyoCnt div 3

    if not allowDblNotLast:
      check (0 ..< moveCnt.pred).toSeq.all (idx) =>
        nazo.puyoPuyo.steps[idx].kind != PairPlacement or
        not nazo.puyoPuyo.steps[idx].pair.isDbl

    if not allowDblLast:
      check nazo.puyoPuyo.steps[^1].kind != PairPlacement or
        not nazo.puyoPuyo.steps[^1].pair.isDbl

    for stepIdx in dropGarbagesIndices:
      check nazo.puyoPuyo.steps[stepIdx].kind == StepKind.Garbages and
        not nazo.puyoPuyo.steps[stepIdx].dropHard

    for stepIdx in dropHardsIndices:
      check nazo.puyoPuyo.steps[stepIdx].kind == StepKind.Garbages and
        nazo.puyoPuyo.steps[stepIdx].dropHard

    for stepIdx in rotateIndices:
      check nazo.puyoPuyo.steps[stepIdx].kind == StepKind.Rotate and
        not nazo.puyoPuyo.steps[stepIdx].cross

    for stepIdx in crossRotateIndices:
      check nazo.puyoPuyo.steps[stepIdx].kind == StepKind.Rotate and
        nazo.puyoPuyo.steps[stepIdx].cross

    let ans = nazo.solve
    check ans.len == 1
    check ans[0].len == moveCnt
    for stepIdx, step in nazo.puyoPuyo.steps:
      case step.kind
      of PairPlacement:
        check step.optPlacement == ans[0][stepIdx]
      else:
        check ans[0][stepIdx].isErr

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

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[random, sequtils, sugar, unittest]
import ../../src/pon2/[core]
import ../../src/pon2/app/[generate, nazopuyowrap]
import ../../src/pon2/private/[math2]
import ../../src/pon2/private/app/[generate]

# ------------------------------------------------
# private
# ------------------------------------------------

block: # split
  var rng = 123.initRand

  block: # split by chunkCnt
    block: # allow zero chunk
      block:
        let
          total = 10
          chunkCnt = 5
          res = rng.split(total, chunkCnt, allowZeroChunk = true)

        check res.isOk
        check res.unsafeValue.sum2 == total
        check res.unsafeValue.len == chunkCnt
        check res.unsafeValue.allIt it >= 0

      block: # corner case
        let
          total = 10
          chunkCnt = 5

        check rng.split(total, 0, allowZeroChunk = true).isErr
        check rng.split(total, 1, allowZeroChunk = true) == Res[seq[int]].ok @[total]
        check rng.split(-1, chunkCnt, allowZeroChunk = true).isErr
        check rng.split(0, chunkCnt, allowZeroChunk = true) ==
          Res[seq[int]].ok 0.repeat chunkCnt

    block: # not allow zero chunk
      block:
        let
          total = 10
          chunkCnt = 5
          res = rng.split(total, chunkCnt, allowZeroChunk = false)

        check res.isOk
        check res.unsafeValue.sum2 == total
        check res.unsafeValue.len == chunkCnt
        check res.unsafeValue.allIt it > 0

      block: # corner case
        let
          total = 10
          chunkCnt = 5

        check rng.split(total, 0, allowZeroChunk = false).isErr
        check rng.split(total, 1, allowZeroChunk = false) == Res[seq[int]].ok @[total]
        check rng.split(-1, chunkCnt, allowZeroChunk = false).isErr
        check rng.split(0, chunkCnt, allowZeroChunk = false).isErr

  block: # split by weights
    block:
      let
        total = 5
        weights = [0, 1, 2]
        res = rng.split(total, weights)

      check res.isOk
      check res.unsafeValue.sum2 == total
      check res.unsafeValue.len == weights.len
      check res.unsafeValue.allIt it >= 0

    block: # all zero
      let
        total = 5
        weights = [0, 0, 0]
        res = rng.split(total, weights)

      check res.isOk
      check res.unsafeValue.sum2 == total
      check res.unsafeValue.len == weights.len
      check res.unsafeValue.allIt it >= 0

    block: # corner case
      let
        total = 5
        weights = [0, 1, 2]

      check rng.split(total, newSeq[int]()).isErr
      check rng.split(total, [0]) == Res[seq[int]].ok @[total]
      check rng.split(-1, weights).isErr
      check rng.split(0, weights) == Res[seq[int]].ok 0.repeat weights.len

  block: # split by positives
    block:
      let
        total = 5
        positives = [true, false, true]
        res = rng.split(total, positives)

      check res.isOk
      check res.unsafeValue.sum2 == total
      check res.unsafeValue.len == positives.len
      for i, pos in positives:
        if pos:
          check res.unsafeValue[i] > 0
        else:
          check res.unsafeValue[i] == 0

    block: # all false
      let
        total = 5
        positives = [false, false, false]
        res = rng.split(total, positives)

      check res.isOk
      check res.unsafeValue.sum2 == total
      check res.unsafeValue.len == positives.len
      check res.unsafeValue.allIt it >= 0

    block: # corner case
      let
        total = 5
        positives = [true, false, true]

      check rng.split(total, newSeq[bool]()).isErr
      check rng.split(total, [true]) == Res[seq[int]].ok @[total]
      check rng.split(-1, positives).isErr
      check rng.split(0, positives).isErr

# ------------------------------------------------
# Generate
# ------------------------------------------------

block: # generate
  var rng = 123.initRand
  let
    genGoalKind = Chain
    genGoalColor = GenerateGoalColor.low
    genGoalVal = 5
    genGoal = GenerateGoal.init(genGoalKind, genGoalColor, genGoalVal)

    moveCnt = 2
    colorCnt = 3
    heights = (
      weights: Opt[array[Col, int]].err,
      positives: Opt[array[Col, bool]].ok [false, true, true, true, false, false],
    )
    puyoCnts = (colors: genGoalVal * 4, garbage: 5, hard: 1)
    conn2Cnts = (total: Opt[int].err, vertical: Opt[int].ok 0, horizontal: Opt[int].err)
    conn3Cnts = (
      total: Opt[int].ok 2,
      vertical: Opt[int].err,
      horizontal: Opt[int].err,
      lShape: Opt[int].ok 1,
    )
    allowDblNotLast = true
    allowDblLast = false
    allowGarbagesStep = false
    allowHardStep = false

    settings = GenerateSettings.init(
      genGoal, moveCnt, colorCnt, heights, puyoCnts, conn2Cnts, conn3Cnts,
      allowDblNotLast, allowDblLast, allowGarbagesStep, allowHardStep,
    )

    rule = Tsu
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

  wrap.runIt:
    let nazo = itNazo

    check nazo.puyoPuyo.steps.len == moveCnt

    check (Cell.Red .. Cell.Purple).toSeq.filter(
      (cell) => nazo.puyoPuyo.cellCnt(cell) > 0
    ).len == colorCnt

    check nazo.puyoPuyo.field.isSettled
    check not nazo.puyoPuyo.field.canPop

    if heights.positives.isOk:
      for col in Col:
        check heights.positives.unsafeValue[col] ==
          (nazo.puyoPuyo.field[Row.high, col] != None)

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

    if not allowGarbagesStep:
      check nazo.puyoPuyo.steps.toSeq.all (step) => step.kind != StepKind.Garbages

    if not allowHardStep:
      check nazo.puyoPuyo.steps.toSeq.all (step) =>
        step.kind != StepKind.Garbages or not step.dropHard

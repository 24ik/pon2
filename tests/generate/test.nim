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
    goal: Goal,
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
    settings = GenerateSettings.init(
      goal, moveCount, colorCount, heights, puyoCounts, connection2Counts,
      connection3Counts, dropGarbagesIndices, dropHardsIndices, rotateIndices,
      crossRotateIndices, allowDoubleNotLast, allowDoubleLast,
    )
    wrapResult = rng.generate(settings, rule)

  check wrapResult.isOk

  unwrap wrapResult.unsafeValue:
    check it.goal == goal

    check it.puyoPuyo.steps.len == moveCount

    check (Cell.Red .. Cell.Purple).toSeq.filter(
      (cell) => it.puyoPuyo.cellCount(cell) > 0
    ).len == colorCount

    check it.puyoPuyo.field.isSettled
    check not it.puyoPuyo.field.canPop

    let baseRow =
      case rule
      of Tsu: Row.high
      of Water: AirHeight.Row
    if heights.weights.isOk:
      if heights.weights.unsafeValue != [0, 0, 0, 0, 0, 0]:
        for col in Col:
          if heights.weights.unsafeValue[col] == 0:
            check it.puyoPuyo.field[baseRow, col] == None
    else:
      for col in Col:
        check heights.positives.unsafeValue[col] ==
          (it.puyoPuyo.field[baseRow, col] != None)

    check puyoCounts.colors == it.puyoPuyo.colorPuyoCount
    check puyoCounts.garbage == it.puyoPuyo.cellCount Garbage
    check puyoCounts.hard == it.puyoPuyo.cellCount Hard

    if connection2Counts.total.isOk:
      check connection2Counts.total.unsafeValue ==
        it.puyoPuyo.field.connection2.colorPuyoCount div 2
    if connection2Counts.vertical.isOk:
      check connection2Counts.vertical.unsafeValue ==
        it.puyoPuyo.field.connection2Vertical.colorPuyoCount div 2
    if connection2Counts.horizontal.isOk:
      check connection2Counts.horizontal.unsafeValue ==
        it.puyoPuyo.field.connection2Vertical.colorPuyoCount div 2

    if connection3Counts.total.isOk:
      check connection3Counts.total.unsafeValue ==
        it.puyoPuyo.field.connection3.colorPuyoCount div 3
    if connection3Counts.vertical.isOk:
      check connection3Counts.vertical.unsafeValue ==
        it.puyoPuyo.field.connection3Vertical.colorPuyoCount div 3
    if connection3Counts.horizontal.isOk:
      check connection3Counts.horizontal.unsafeValue ==
        it.puyoPuyo.field.connection3Vertical.colorPuyoCount div 3
    if connection3Counts.lShape.isOk:
      check connection3Counts.lShape.unsafeValue ==
        it.puyoPuyo.field.connection3LShape.colorPuyoCount div 3

    if not allowDoubleNotLast:
      check (0 ..< moveCount.pred).toSeq.all (index) =>
        it.puyoPuyo.steps[index].kind != PairPlacement or
        not it.puyoPuyo.steps[index].pair.isDouble

    if not allowDoubleLast:
      check it.puyoPuyo.steps[^1].kind != PairPlacement or
        not it.puyoPuyo.steps[^1].pair.isDouble

    for stepIndex in dropGarbagesIndices:
      check it.puyoPuyo.steps[stepIndex].kind == StepKind.Garbages and
        not it.puyoPuyo.steps[stepIndex].dropHard

    for stepIndex in dropHardsIndices:
      check it.puyoPuyo.steps[stepIndex].kind == StepKind.Garbages and
        it.puyoPuyo.steps[stepIndex].dropHard

    for stepIndex in rotateIndices:
      check it.puyoPuyo.steps[stepIndex].kind == StepKind.Rotate and
        not it.puyoPuyo.steps[stepIndex].cross

    for stepIndex in crossRotateIndices:
      check it.puyoPuyo.steps[stepIndex].kind == StepKind.Rotate and
        it.puyoPuyo.steps[stepIndex].cross

    let answer = it.solve
    check answer.len == 1
    check answer[0].len == moveCount
    for stepIndex, step in it.puyoPuyo.steps:
      case step.kind
      of PairPlacement:
        check step.optPlacement == answer[0][stepIndex]
      else:
        check answer[0][stepIndex].isErr

block: # generate
  checkGenerate(
    Goal.init(Chain, 5, Exact),
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
    Goal.init(Count, GoalColor.Red, 4, AtLeast, GoalColor.Garbages),
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

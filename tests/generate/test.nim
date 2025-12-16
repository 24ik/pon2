{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[random, sequtils, sugar, unittest]
import ../../src/pon2/[core]
import ../../src/pon2/app/[generate, solve]

# ------------------------------------------------
# Generate
# ------------------------------------------------

proc checkGenerate(
    rule: Rule,
    goal: Goal,
    moveCount: int,
    colorCount: int,
    heights:
      tuple[weightsOpt: Opt[array[Col, int]], positivesOpt: Opt[array[Col, bool]]],
    puyoCounts: tuple[colors: int, garbage: int, hard: int],
    connection2Counts:
      tuple[totalOpt: Opt[int], verticalOpt: Opt[int], horizontalOpt: Opt[int]],
    connection3Counts:
      tuple[
        totalOpt: Opt[int],
        verticalOpt: Opt[int],
        horizontalOpt: Opt[int],
        lShapeOpt: Opt[int],
      ],
    dropGarbagesIndices: seq[int],
    dropHardsIndices: seq[int],
    rotateIndices: seq[int],
    crossRotateIndices: seq[int],
    allowDoubleIndices: seq[int],
    seed: int,
) {.raises: [Exception].} =
  var rng = seed.initRand
  let
    settings = GenerateSettings.init(
      rule, goal, moveCount, colorCount, heights, puyoCounts, connection2Counts,
      connection3Counts, dropGarbagesIndices, dropHardsIndices, rotateIndices,
      crossRotateIndices, allowDoubleIndices,
    )
    nazoPuyoResult = rng.generate settings

  check nazoPuyoResult.isOk
  let nazoPuyo = nazoPuyoResult.unsafeValue

  check nazoPuyo.goal == goal

  check nazoPuyo.puyoPuyo.steps.len == moveCount

  check (Cell.Red .. Cell.Purple).toSeq.filter(
    (cell) => nazoPuyo.puyoPuyo.cellCount(cell) > 0
  ).len == colorCount

  check nazoPuyo.puyoPuyo.field.isSettled
  check not nazoPuyo.puyoPuyo.field.canPop

  let baseRow =
    case rule
    of Tsu, Spinner, CrossSpinner: Row.high
    of Water: AirHeight.Row
  if heights.weightsOpt.isOk:
    if heights.weightsOpt.unsafeValue != [0, 0, 0, 0, 0, 0]:
      for col in Col:
        if heights.weightsOpt.unsafeValue[col] == 0:
          check nazoPuyo.puyoPuyo.field[baseRow, col] == None
  else:
    for col in Col:
      check heights.positivesOpt.unsafeValue[col] ==
        (nazoPuyo.puyoPuyo.field[baseRow, col] != None)

  check puyoCounts.colors == nazoPuyo.puyoPuyo.coloredPuyoCount
  check puyoCounts.garbage == nazoPuyo.puyoPuyo.cellCount Garbage
  check puyoCounts.hard == nazoPuyo.puyoPuyo.cellCount Hard

  if connection2Counts.totalOpt.isOk:
    check connection2Counts.totalOpt.unsafeValue ==
      nazoPuyo.puyoPuyo.field.connection2.coloredPuyoCount div 2
  if connection2Counts.verticalOpt.isOk:
    check connection2Counts.verticalOpt.unsafeValue ==
      nazoPuyo.puyoPuyo.field.connection2Vertical.coloredPuyoCount div 2
  if connection2Counts.horizontalOpt.isOk:
    check connection2Counts.horizontalOpt.unsafeValue ==
      nazoPuyo.puyoPuyo.field.connection2Horizontal.coloredPuyoCount div 2

  if connection3Counts.totalOpt.isOk:
    check connection3Counts.totalOpt.unsafeValue ==
      nazoPuyo.puyoPuyo.field.connection3.coloredPuyoCount div 3
  if connection3Counts.verticalOpt.isOk:
    check connection3Counts.verticalOpt.unsafeValue ==
      nazoPuyo.puyoPuyo.field.connection3Vertical.coloredPuyoCount div 3
  if connection3Counts.horizontalOpt.isOk:
    check connection3Counts.horizontalOpt.unsafeValue ==
      nazoPuyo.puyoPuyo.field.connection3Horizontal.coloredPuyoCount div 3
  if connection3Counts.lShapeOpt.isOk:
    check connection3Counts.lShapeOpt.unsafeValue ==
      nazoPuyo.puyoPuyo.field.connection3LShape.coloredPuyoCount div 3

  for stepIndex in allowDoubleIndices:
    check not (
      nazoPuyo.puyoPuyo.steps[stepIndex].kind == PairPlace and
      nazoPuyo.puyoPuyo.steps[stepIndex].pair.isDouble
    )

  for stepIndex in dropGarbagesIndices:
    check nazoPuyo.puyoPuyo.steps[stepIndex].kind == NuisanceDrop and
      not nazoPuyo.puyoPuyo.steps[stepIndex].hard

  for stepIndex in dropHardsIndices:
    check nazoPuyo.puyoPuyo.steps[stepIndex].kind == NuisanceDrop and
      nazoPuyo.puyoPuyo.steps[stepIndex].hard

  for stepIndex in rotateIndices:
    check nazoPuyo.puyoPuyo.steps[stepIndex].kind == FieldRotate and
      not nazoPuyo.puyoPuyo.steps[stepIndex].cross

  for stepIndex in crossRotateIndices:
    check nazoPuyo.puyoPuyo.steps[stepIndex].kind == FieldRotate and
      nazoPuyo.puyoPuyo.steps[stepIndex].cross

  let answer = nazoPuyo.solve
  check answer.len == 1
  check answer[0].len == moveCount
  for stepIndex, step in nazoPuyo.puyoPuyo.steps:
    case step.kind
    of PairPlace:
      check answer[0][stepIndex] == step.placement
    else:
      check answer[0][stepIndex] == Placement.None

block: # generate
  checkGenerate(
    Rule.Tsu,
    Goal.init(Chain, 5, Exact),
    2,
    3,
    (
      weightsOpt: Opt[array[Col, int]].err,
      positivesOpt: Opt[array[Col, bool]].ok [false, true, true, true, false, false],
    ),
    (colors: 20, garbage: 5, hard: 1),
    (totalOpt: Opt[int].err, verticalOpt: Opt[int].ok 0, horizontalOpt: Opt[int].err),
    (
      totalOpt: Opt[int].ok 2,
      verticalOpt: Opt[int].err,
      horizontalOpt: Opt[int].err,
      lShapeOpt: Opt[int].ok 1,
    ),
    @[0],
    newSeq[int](),
    newSeq[int](),
    newSeq[int](),
    newSeq[int](),
    123,
  )
  checkGenerate(
    Rule.Spinner,
    Goal.init All,
    2,
    2,
    (
      weightsOpt: Opt[array[Col, int]].ok [0, 0, 1, 2, 3, 0],
      positivesOpt: Opt[array[Col, bool]].err,
    ),
    (colors: 12, garbage: 3, hard: 0),
    (totalOpt: Opt[int].ok 2, verticalOpt: Opt[int].err, horizontalOpt: Opt[int].err),
    (
      totalOpt: Opt[int].ok 1,
      verticalOpt: Opt[int].err,
      horizontalOpt: Opt[int].err,
      lShapeOpt: Opt[int].err,
    ),
    newSeq[int](),
    newSeq[int](),
    @[1],
    newSeq[int](),
    @[0],
    456,
  )

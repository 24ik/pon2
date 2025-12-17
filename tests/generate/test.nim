{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[random, sequtils, unittest]
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
    seed: int,
) {.raises: [Exception].} =
  var rng = seed.initRand
  let
    settings = GenerateSettings.init(
      rule, goal, moveCount, colorCount, heights, puyoCounts, connection2Counts,
      connection3Counts, indices,
    )
    nazoPuyoResult = rng.generate settings

  check nazoPuyoResult.isOk
  let nazoPuyo = nazoPuyoResult.unsafeValue

  check nazoPuyo.goal == goal

  check nazoPuyo.puyoPuyo.steps.len == moveCount

  check ColoredPuyos.toSeq.countIt(nazoPuyo.puyoPuyo.cellCount(it) > 0) == colorCount

  check nazoPuyo.puyoPuyo.field.isSettled
  check not nazoPuyo.puyoPuyo.field.canPop

  let baseRow =
    case rule
    of Tsu, Spinner, CrossSpinner: Row.high
    of Water: WaterTopRow
  if heights.anyIt it != 0:
    for col in Col:
      check not (
        heights[col] == 0 and nazoPuyo.puyoPuyo.field[baseRow, col] != Cell.None
      )

  check nazoPuyo.puyoPuyo.coloredPuyoCount == puyoCounts.colored
  check nazoPuyo.puyoPuyo.cellCount(Garbage) == puyoCounts.garbage
  check nazoPuyo.puyoPuyo.cellCount(Hard) == puyoCounts.hard

  if connection2Counts.totalOpt.isOk:
    check nazoPuyo.puyoPuyo.field.connection2.coloredPuyoCount ==
      connection2Counts.totalOpt.unsafeValue * 2
  if connection2Counts.verticalOpt.isOk:
    check nazoPuyo.puyoPuyo.field.connection2Vertical.coloredPuyoCount ==
      connection2Counts.verticalOpt.unsafeValue * 2
  if connection2Counts.horizontalOpt.isOk:
    check nazoPuyo.puyoPuyo.field.connection2Horizontal.coloredPuyoCount ==
      connection2Counts.horizontalOpt.unsafeValue * 2

  if connection3Counts.totalOpt.isOk:
    check nazoPuyo.puyoPuyo.field.connection3.coloredPuyoCount ==
      connection3Counts.totalOpt.unsafeValue * 3
  if connection3Counts.verticalOpt.isOk:
    check nazoPuyo.puyoPuyo.field.connection3Vertical.coloredPuyoCount ==
      connection3Counts.verticalOpt.unsafeValue * 3
  if connection3Counts.horizontalOpt.isOk:
    check nazoPuyo.puyoPuyo.field.connection3Horizontal.coloredPuyoCount ==
      connection3Counts.horizontalOpt.unsafeValue * 3
  if connection3Counts.lShapeOpt.isOk:
    check nazoPuyo.puyoPuyo.field.connection3LShape.coloredPuyoCount ==
      connection3Counts.lShapeOpt.unsafeValue * 3

  for stepIndex in 0 ..< moveCount:
    if stepIndex notin indices.allowDouble:
      check not (
        nazoPuyo.puyoPuyo.steps[stepIndex].kind == PairPlace and
        nazoPuyo.puyoPuyo.steps[stepIndex].pair.isDouble
      )
  for stepIndex in indices.garbage:
    check nazoPuyo.puyoPuyo.steps[stepIndex].kind == NuisanceDrop and
      not nazoPuyo.puyoPuyo.steps[stepIndex].hard
  for stepIndex in indices.hard:
    check nazoPuyo.puyoPuyo.steps[stepIndex].kind == NuisanceDrop and
      nazoPuyo.puyoPuyo.steps[stepIndex].hard
  for stepIndex in indices.rotate:
    check nazoPuyo.puyoPuyo.steps[stepIndex].kind == FieldRotate and
      not nazoPuyo.puyoPuyo.steps[stepIndex].cross
  for stepIndex in indices.crossRotate:
    check nazoPuyo.puyoPuyo.steps[stepIndex].kind == FieldRotate and
      nazoPuyo.puyoPuyo.steps[stepIndex].cross

  let answer = nazoPuyo.solve
  check answer.len == 1
  check answer[0].len == moveCount
  for stepIndex, step in nazoPuyo.puyoPuyo.steps:
    if step.kind == PairPlace:
      check step.placement == answer[0][stepIndex]

block: # generate
  checkGenerate(
    Rule.Tsu,
    Goal.init(Chain, 4, Exact),
    2,
    3,
    [-1, -1, -1, -1, -1, 0],
    (colored: 16, garbage: 4, hard: 1),
    (totalOpt: Opt[int].err, verticalOpt: Opt[int].err, horizontalOpt: Opt[int].ok 1),
    (
      totalOpt: Opt[int].ok 2,
      verticalOpt: Opt[int].err,
      horizontalOpt: Opt[int].ok 0,
      lShapeOpt: Opt[int].err,
    ),
    (
      allowDouble: newSeq[int](),
      garbage: @[0],
      hard: newSeq[int](),
      rotate: newSeq[int](),
      crossRotate: newSeq[int](),
    ),
    123,
  )
  checkGenerate(
    Rule.Spinner,
    Goal.init All,
    2,
    2,
    [0, 0, 1, 2, 3, 0],
    (colored: 12, garbage: 3, hard: 0),
    (totalOpt: Opt[int].ok 2, verticalOpt: Opt[int].err, horizontalOpt: Opt[int].err),
    (
      totalOpt: Opt[int].ok 1,
      verticalOpt: Opt[int].err,
      horizontalOpt: Opt[int].err,
      lShapeOpt: Opt[int].err,
    ),
    (
      allowDouble: @[0],
      garbage: newSeq[int](),
      hard: newSeq[int](),
      rotate: @[1],
      crossRotate: newSeq[int](),
    ),
    456,
  )

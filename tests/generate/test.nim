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
    seed: int,
) {.raises: [Exception].} =
  var rng = seed.initRand
  let
    settings = GenerateSettings.init(
      rule, goal, moveCount, colorCount, heights, puyoCounts, connection2Counts,
      connection3Counts, dropGarbagesIndices, dropHardsIndices, rotateIndices,
      crossRotateIndices, allowDoubleNotLast, allowDoubleLast,
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
  if heights.weights.isOk:
    if heights.weights.unsafeValue != [0, 0, 0, 0, 0, 0]:
      for col in Col:
        if heights.weights.unsafeValue[col] == 0:
          check nazoPuyo.puyoPuyo.field[baseRow, col] == None
  else:
    for col in Col:
      check heights.positives.unsafeValue[col] ==
        (nazoPuyo.puyoPuyo.field[baseRow, col] != None)

  check puyoCounts.colors == nazoPuyo.puyoPuyo.coloredPuyoCount
  check puyoCounts.garbage == nazoPuyo.puyoPuyo.cellCount Garbage
  check puyoCounts.hard == nazoPuyo.puyoPuyo.cellCount Hard

  if connection2Counts.total.isOk:
    check connection2Counts.total.unsafeValue ==
      nazoPuyo.puyoPuyo.field.connection2.coloredPuyoCount div 2
  if connection2Counts.vertical.isOk:
    check connection2Counts.vertical.unsafeValue ==
      nazoPuyo.puyoPuyo.field.connection2Vertical.coloredPuyoCount div 2
  if connection2Counts.horizontal.isOk:
    check connection2Counts.horizontal.unsafeValue ==
      nazoPuyo.puyoPuyo.field.connection2Vertical.coloredPuyoCount div 2

  if connection3Counts.total.isOk:
    check connection3Counts.total.unsafeValue ==
      nazoPuyo.puyoPuyo.field.connection3.coloredPuyoCount div 3
  if connection3Counts.vertical.isOk:
    check connection3Counts.vertical.unsafeValue ==
      nazoPuyo.puyoPuyo.field.connection3Vertical.coloredPuyoCount div 3
  if connection3Counts.horizontal.isOk:
    check connection3Counts.horizontal.unsafeValue ==
      nazoPuyo.puyoPuyo.field.connection3Vertical.coloredPuyoCount div 3
  if connection3Counts.lShape.isOk:
    check connection3Counts.lShape.unsafeValue ==
      nazoPuyo.puyoPuyo.field.connection3LShape.coloredPuyoCount div 3

  if not allowDoubleNotLast:
    check (0 ..< moveCount.pred).toSeq.all (index) =>
      nazoPuyo.puyoPuyo.steps[index].kind != PairPlace or
      not nazoPuyo.puyoPuyo.steps[index].pair.isDouble

  if not allowDoubleLast:
    check nazoPuyo.puyoPuyo.steps[^1].kind != PairPlace or
      not nazoPuyo.puyoPuyo.steps[^1].pair.isDouble

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
    123,
  )
  checkGenerate(
    Rule.Spinner,
    Goal.init All,
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
    @[1],
    newSeq[int](),
    true,
    false,
    456,
  )

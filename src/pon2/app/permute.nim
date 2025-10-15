## This module implements Nazo Puyo permuters.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, sugar]
import ./[solve]
import ../[core]
import ../private/[assign3, staticfor2]

# ------------------------------------------------
# Steps
# ------------------------------------------------

func allStepsSeq(
    steps: Steps,
    stepIdx: int,
    fixIndices: openArray[int],
    allowDblNotLast, allowDblLast: bool,
    cellCnts: array[Cell, int],
): seq[Steps] {.inline.} =
  ## Returns all possible steps in ascending order that can be obtained by permuting
  ## puyos contained in the steps.
  ## Non-`PairPlacement` steps are left as they are.
  ## Note that Swapped pair may give a different answer but this function does not
  ## consider it.
  if stepIdx == steps.len:
    return @[Steps.init(steps.len)]

  let step = steps[stepIdx]
  if step.kind != PairPlacement:
    return steps.allStepsSeq(
      stepIdx.succ, fixIndices, allowDblNotLast, allowDblLast, cellCnts
    ).mapIt it.dup(addFirst(_, step))

  # NOTE: `staticFor` is preferable but we use normal `for` since
  # we want to use `continue` for easy implementation
  var stepsSeq = newSeq[Steps]()
  for pivotCell in Cell.Red .. Cell.Purple:
    if cellCnts[pivotCell] == 0:
      continue

    var newCellCntsMid = cellCnts
    newCellCntsMid[pivotCell].dec

    for rotorCell in pivotCell .. Cell.Purple:
      if newCellCntsMid[rotorCell] == 0:
        continue

      if pivotCell == rotorCell:
        if stepIdx == steps.len.pred:
          if not allowDblLast:
            continue
        else:
          if not allowDblNotLast:
            continue

      var newCellCnts = newCellCntsMid
      newCellCnts[rotorCell].dec

      let
        newPairMid = Pair.init(pivotCell, rotorCell)
        newPair: Pair
      if stepIdx in fixIndices:
        if step.pair notin {newPairMid, newPairMid.swapped}:
          continue

        newPair = step.pair
      else:
        newPair = newPairMid

      stepsSeq &=
        steps.allStepsSeq(
          stepIdx.succ, fixIndices, allowDblNotLast, allowDblLast, newCellCnts
        ).mapIt it.dup(addFirst(_, Step.init newPair))

  stepsSeq

func allStepsSeq(
    steps: Steps, fixIndices: openArray[int], allowDblNotLast, allowDblLast: bool
): seq[Steps] {.inline.} =
  ## Returns all possible steps in ascending order that can be obtained by permuting
  ## puyos contained in the steps.
  ## Non-`PairPlacement` steps are left as they are.
  ## Note that Swapped pair may give a different answer but this function does not
  ## consider it.
  var cellCnts {.noinit.}: array[Cell, int]
  staticFor(cell2, Cell.Red .. Cell.Purple):
    cellCnts[cell2].assign steps.cellCnt cell2

  steps.allStepsSeq(0, fixIndices, allowDblNotLast, allowDblLast, cellCnts)

# ------------------------------------------------
# Permute
# ------------------------------------------------

iterator permute*[F: TsuField or WaterField](
    nazo: NazoPuyo[F], fixIndices: openArray[int], allowDblNotLast, allowDblLast: bool
): NazoPuyo[F] {.inline.} =
  ## Yields Nazo Puyo that is obtained by permuting steps and has a unique answer.
  for steps in nazo.puyoPuyo.steps.allStepsSeq(
    fixIndices, allowDblNotLast, allowDblLast
  ):
    var nazo2 = nazo
    nazo2.puyoPuyo.steps.assign steps

    let answers = nazo2.solve(calcAllAnswers = false)
    if answers.len == 1:
      for stepIdx, step in nazo2.puyoPuyo.steps.mpairs:
        if step.kind == PairPlacement:
          step.optPlacement = answers[0][stepIdx]

      yield nazo2

## This module implements Nazo Puyo permuters.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, sugar]
import ./[solve]
import ../[core]
import ../private/[assign, staticfor]

export core

when defined(js) or defined(nimsuggest):
  when not defined(pon2.build.worker):
    import std/[asyncjs]

# ------------------------------------------------
# Steps
# ------------------------------------------------

func allStepsSeq(
    steps: Steps,
    stepIndex: int,
    fixIndices: openArray[int],
    allowDoubleNotLast, allowDoubleLast: bool,
    cellCounts: array[Cell, int],
): seq[Steps] =
  ## Returns all possible steps in ascending order that can be obtained by permuting
  ## puyos contained in the steps.
  ## Non-`PairPlacement` steps are left as they are.
  ## Note that Swapped pair may give a different answer but this function does not
  ## consider it.
  if stepIndex == steps.len:
    return @[Steps.init(steps.len)]

  let step = steps[stepIndex]
  if step.kind != PairPlacement:
    return steps.allStepsSeq(
      stepIndex.succ, fixIndices, allowDoubleNotLast, allowDoubleLast, cellCounts
    ).mapIt it.dup(addFirst(_, step))

  # NOTE: `staticFor` is preferable but we use normal `for` since
  # we want to use `continue` for easy implementation
  var stepsSeq = newSeq[Steps]()
  for pivotCell in Cell.Red .. Cell.Purple:
    if cellCounts[pivotCell] == 0:
      continue

    var newCellCountsBase = cellCounts
    newCellCountsBase[pivotCell].dec

    for rotorCell in pivotCell .. Cell.Purple:
      if newCellCountsBase[rotorCell] == 0:
        continue

      if pivotCell == rotorCell:
        if stepIndex == steps.len.pred:
          if not allowDoubleLast:
            continue
        else:
          if not allowDoubleNotLast:
            continue

      var newCellCounts = newCellCountsBase
      newCellCounts[rotorCell].dec

      let
        newPairBase = Pair.init(pivotCell, rotorCell)
        newPair: Pair
      if stepIndex in fixIndices:
        if step.pair notin {newPairBase, newPairBase.swapped}:
          continue

        newPair = step.pair
      else:
        newPair = newPairBase

      stepsSeq &=
        steps.allStepsSeq(
          stepIndex.succ, fixIndices, allowDoubleNotLast, allowDoubleLast, newCellCounts
        ).mapIt it.dup(addFirst(_, Step.init newPair))

  stepsSeq

func allStepsSeq(
    steps: Steps, fixIndices: openArray[int], allowDoubleNotLast, allowDoubleLast: bool
): seq[Steps] =
  ## Returns all possible steps in ascending order that can be obtained by permuting
  ## puyos contained in the steps.
  ## Non-`PairPlacement` steps are left as they are.
  ## Note that Swapped pair may give a different answer but this function does not
  ## consider it.
  var cellCounts {.noinit.}: array[Cell, int]
  staticFor(cell2, Cell.Red .. Cell.Purple):
    cellCounts[cell2].assign steps.cellCount cell2

  steps.allStepsSeq(0, fixIndices, allowDoubleNotLast, allowDoubleLast, cellCounts)

# ------------------------------------------------
# Permute
# ------------------------------------------------

proc permute*[F: TsuField or WaterField](
    nazo: NazoPuyo[F],
    fixIndices: openArray[int],
    allowDoubleNotLast, allowDoubleLast: bool,
): seq[NazoPuyo[F]] =
  ## Returns a sequence of Nazo Puyos that is obtained by permuting steps and has a
  ## unique answer.
  collect:
    for steps in nazo.puyoPuyo.steps.allStepsSeq(
      fixIndices, allowDoubleNotLast, allowDoubleLast
    ):
      var nazo2 = nazo
      nazo2.puyoPuyo.steps.assign steps

      let answers = nazo2.solve(calcAllAnswers = false)
      if answers.len == 1:
        for stepIndex, step in nazo2.puyoPuyo.steps.mpairs:
          if step.kind == PairPlacement:
            step.optPlacement.assign answers[0][stepIndex]

        nazo2

# ------------------------------------------------
# Permute - Async
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  when not defined(pon2.build.worker):
    proc asyncPermute*[F: TsuField or WaterField](
        nazo: NazoPuyo[F],
        fixIndices: openArray[int],
        allowDoubleNotLast, allowDoubleLast: bool,
        progressRef: ref tuple[now, total: int] = nil,
    ): Future[seq[NazoPuyo[F]]] {.async.} =
      ## Permutes the Nazo Puyo asynchronously with web workers.
      ## This function requires that the field is settled.
      let stepsSeq =
        nazo.puyoPuyo.steps.allStepsSeq(fixIndices, allowDoubleNotLast, allowDoubleLast)
      if not progressRef.isNil:
        if stepsSeq.len == 0:
          progressRef[] = (1, 1)
        else:
          progressRef[] = (0, stepsSeq.len)

      var nazos = newSeq[NazoPuyo[F]]()
      for steps in stepsSeq:
        var nazo2 = nazo
        nazo2.puyoPuyo.steps.assign steps

        let answers = await nazo2.asyncSolve(calcAllAnswers = false)
        if answers.len == 1:
          for stepIndex, step in nazo2.puyoPuyo.steps.mpairs:
            if step.kind == PairPlacement:
              step.optPlacement.assign answers[0][stepIndex]

          nazos.add nazo2

        if not progressRef.isNil:
          progressRef[].now.inc

      return nazos

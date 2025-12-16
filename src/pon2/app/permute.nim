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
    fixIndices: openArray[int],
    allowDoubleNotLast, allowDoubleLast: bool,
    stepIndex: int,
    cellCounts: array[Cell, int],
): seq[Steps] =
  ## Returns all possible steps in ascending order that can be obtained by permuting
  ## puyos after `stepIndex` contained in the steps.
  ## Non-`PairPlace` steps are left as they are.
  ## Note that swapped pairs may give different answers but this function does not
  ## consider it.
  ## `cellCounts` should be set for colored puyos.
  if stepIndex == steps.len:
    return @[Steps.init steps.len]

  let step = steps[stepIndex]
  if step.kind != PairPlace:
    return steps.allStepsSeq(
      fixIndices, allowDoubleNotLast, allowDoubleLast, stepIndex + 1, cellCounts
    ).mapIt it.dup(addFirst(step))

  # NOTE: we use standard for-loop instead of `staticFor` for simple implementation
  var stepsSeq = newSeq[Steps]()
  for pivotCell in Cell.Red .. Cell.Purple:
    if cellCounts[pivotCell] == 0:
      continue

    var newCellCountsBase = cellCounts
    newCellCountsBase[pivotCell] -= 1

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
      newCellCounts[rotorCell] -= 1

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
          fixIndices, allowDoubleNotLast, allowDoubleLast, stepIndex + 1, newCellCounts
        ).mapIt it.dup(addFirst(Step.init newPair))

  stepsSeq

func allStepsSeq(
    steps: Steps, fixIndices: openArray[int], allowDoubleNotLast, allowDoubleLast: bool
): seq[Steps] =
  ## Returns all possible steps in ascending order that can be obtained by permuting
  ## puyos contained in the steps.
  ## Non-`PairPlace` steps are left as they are.
  ## Note that Swapped pair may give a different answer but this function does not
  ## consider it.
  var cellCounts {.noinit.}: array[Cell, int]
  staticFor(cell2, ColoredPuyos):
    cellCounts[cell2].assign steps.cellCount cell2

  steps.allStepsSeq(fixIndices, allowDoubleNotLast, allowDoubleLast, 0, cellCounts)

# ------------------------------------------------
# Permute
# ------------------------------------------------

proc permute*(
    self: NazoPuyo,
    fixIndices: openArray[int],
    allowDoubleNotLast, allowDoubleLast: bool,
): seq[NazoPuyo] =
  ## Returns a sequence of Nazo Puyos that is obtained by permuting steps and has a
  ## unique answer.
  collect:
    for steps in self.puyoPuyo.steps.allStepsSeq(
      fixIndices, allowDoubleNotLast, allowDoubleLast
    ):
      var nazoPuyo = self
      nazoPuyo.puyoPuyo.steps.assign steps

      let answers = nazoPuyo.solve(calcAllAnswers = false)
      if answers.len == 1:
        for stepIndex, step in nazoPuyo.puyoPuyo.steps.mpairs:
          if step.kind == PairPlace:
            step.placement.assign answers[0][stepIndex]

        nazoPuyo

# ------------------------------------------------
# Permute - Async
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  when not defined(pon2.build.worker):
    proc asyncPermute*(
        self: NazoPuyo,
        fixIndices: openArray[int],
        allowDoubleNotLast, allowDoubleLast: bool,
        progressRef: ref tuple[now, total: int] = nil,
    ): Future[seq[NazoPuyo]] {.async.} =
      ## Permutes the Nazo Puyo asynchronously with web workers.
      ## This function requires that the field is settled.
      let stepsSeq =
        self.puyoPuyo.steps.allStepsSeq(fixIndices, allowDoubleNotLast, allowDoubleLast)
      if not progressRef.isNil:
        if stepsSeq.len == 0:
          progressRef[] = (1, 1)
        else:
          progressRef[] = (0, stepsSeq.len)

      var nazoPuyos = newSeq[NazoPuyo]()
      for steps in stepsSeq:
        var nazoPuyo = self
        nazoPuyo.puyoPuyo.steps.assign steps

        let answers = await nazoPuyo.asyncSolve(calcAllAnswers = false)
        if answers.len == 1:
          for stepIndex, step in nazoPuyo.puyoPuyo.steps.mpairs:
            if step.kind == PairPlace:
              step.placement.assign answers[0][stepIndex]

          nazoPuyos.add nazoPuyo

        if not progressRef.isNil:
          progressRef[].now += 1

      return nazoPuyos

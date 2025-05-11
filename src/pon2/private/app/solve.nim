## This module implements solutions search trees of Nazo Puyo solvers.
## 

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[algorithm, sequtils]
import ../../[core]
import ../../private/[assign3, core, macros2, math2, results2, staticfor2]

when not defined(js):
  import std/[os, sugar]
  import ../../private/[suru2]

  {.push warning[Deprecated]: off.}
  import std/[threadpool]
  {.pop.}

type
  SolveAnswer* = seq[OptPlacement]
    ## Nazo Puyo answer.
    ## Elements corresponding to non-`PairPlacement` are set to `NonePlacement`.

  SolveNode*[F: TsuField or WaterField] = object ## Node of solutions search tree.
    depth: int

    field: F
    moveResult: MoveResult

    popColors: set[Cell]
    popCnt: int

    fieldCnts: array[Cell, int]
    stepsCnts: array[Cell, int]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init[F: TsuField or WaterField](
    T: type SolveNode[F],
    depth: int,
    field: F,
    moveRes: MoveResult,
    popColors: set[Cell],
    popCnt: int,
    fieldCnts: array[Cell, int],
    stepsCnts: array[Cell, int],
): T {.inline.} =
  T(
    depth: depth,
    field: field,
    moveResult: moveRes,
    popColors: popColors,
    popCnt: popCnt,
    fieldCnts: fieldCnts,
    stepsCnts: stepsCnts,
  )

func init*[F: TsuField or WaterField](
    T: type SolveNode[F], puyoPuyo: PuyoPuyo[F]
): T {.inline.} =
  var fieldCnts {.noinit.}, stepsCnts {.noinit.}: array[Cell, int]
  fieldCnts[None] = 0
  stepsCnts[None] = 0
  staticFor(cell2, Hard .. Cell.Purple):
    fieldCnts[cell2].assign puyoPuyo.field.cellCnt cell2
    stepsCnts[cell2].assign puyoPuyo.steps.cellCnt cell2

  T.init(0, puyoPuyo.field, static(MoveResult.init), {}, 0, fieldCnts, stepsCnts)

# ------------------------------------------------
# Child
# ------------------------------------------------

const
  DummyCell = Cell.low
  GoalColorToCell: array[GoalColor, Cell] = [
    DummyCell, Cell.Red, Cell.Green, Cell.Blue, Cell.Yellow, Cell.Purple, DummyCell,
    DummyCell,
  ]

template childImpl[F: TsuField or WaterField](
    self: SolveNode[F],
    kind: static GoalKind,
    color: static GoalColor,
    step: Step,
    stepKind: static StepKind,
    moveBody: untyped,
): SolveNode[F] =
  ## Returns the child node with `childField` injected.
  ## This function requires that the field is settled.
  ## `stepKind` is used instead of `step.kind`.
  var childField {.inject.} = self.field

  let moveRes = moveBody

  let childPopColors = staticCase:
    case kind
    of AccColor, AccColorMore:
      self.popColors + moveRes.colors
    else:
      set[Cell]({})

  let childPopCnt = staticCase:
    case kind
    of AccCnt, AccCntMore:
      let newCnt = staticCase:
        case color
        of All:
          moveRes.puyoCnt
        of Colors:
          moveRes.colorPuyoCnt
        of GoalColor.Garbages:
          moveRes.garbagesCnt
        else:
          moveRes.cellCnt static(GoalColorToCell[color])
      self.popCnt.succ newCnt
    else:
      0

  when kind in {AccColor, AccColorMore}:
    var childFieldCnts {.noinit.}, childStepsCnts {.noinit.}: array[Cell, int]
  else:
    var childFieldCnts = self.fieldCnts
    when kind in ColorKinds and color in GoalColor.Red .. GoalColor.Purple:
      const GoalCell = GoalColorToCell[color]
      childFieldCnts[GoalCell].assign self.fieldCnts[GoalCell].pred moveRes.cellCnt GoalCell
    else:
      staticFor(cell2, Cell.Red .. Cell.Purple):
        childFieldCnts[cell2].dec moveRes.cellCnt cell2

    var childStepsCnts = self.stepsCnts
    when stepKind == PairPlacement:
      let
        pivotCell = step.pair.pivot
        rotorCell = step.pair.rotor

      childFieldCnts[pivotCell].inc
      childFieldCnts[rotorCell].inc
      childStepsCnts[pivotCell].dec
      childStepsCnts[rotorCell].dec

  when kind in {Clear, AccCnt, AccCntMore, ClearChain, ClearChainMore, Cnt, CntMore} and
      color in {All, GoalColor.Garbages}:
    let h2g = moveRes.hardToGarbageCnt
    childFieldCnts[Hard].dec moveRes.popCnts[Hard] + h2g
    childFieldCnts[Garbage].dec moveRes.popCnts[Garbage] - h2g

    when stepKind == StepKind.Garbages:
      childStepsCnts[Garbage.pred step.dropHard.int].dec step.garbagesCnt

  SolveNode[F].init(
    self.depth.succ, childField, moveRes, childPopColors, childPopCnt, childFieldCnts,
    childStepsCnts,
  )

func childPairPlcmt[F: TsuField or WaterField](
    self: SolveNode[F],
    kind: static GoalKind,
    color: static GoalColor,
    step: Step,
    plcmt: Placement,
): SolveNode[F] {.inline.} =
  ## Returns the child node with the `step` edge.
  ## This function requires that the field is settled.
  self.childImpl(kind, color, step, PairPlacement):
    childField.move(
      step.pair, plcmt, static(kind in {Place, PlaceMore, Conn, ConnMore})
    )

func childGarbages[F: TsuField or WaterField](
    self: SolveNode[F], kind: static GoalKind, color: static GoalColor, step: Step
): SolveNode[F] {.inline.} =
  ## Returns the child node with the `step` edge.
  ## This function requires that the field is settled.
  self.childImpl(kind, color, step, StepKind.Garbages):
    childField.move(
      step.cnts, step.dropHard, static(kind in {Place, PlaceMore, Conn, ConnMore})
    )

func children[F: TsuField or WaterField](
    self: SolveNode[F], kind: static GoalKind, color: static GoalColor, step: Step
): seq[tuple[node: SolveNode[F], optPlacement: OptPlacement]] {.inline.} =
  ## Returns the children of the node.
  ## This function requires that the field is settled.
  ## `optPlacement` is set to `NonePlacement` if the edge is non-`PairPlacement`.
  case step.kind
  of PairPlacement:
    let plcmts =
      if step.pair.isDbl: self.field.validDblPlacements else: self.field.validPlacements

    plcmts.mapIt (self.childPairPlcmt(kind, color, step, it), OptPlacement.ok it)
  of StepKind.Garbages:
    @[(self.childGarbages(kind, color, step), NonePlacement)]

# ------------------------------------------------
# Accept
# ------------------------------------------------

func cellCnt[F: TsuField or WaterField](
    self: SolveNode[F], cell: Cell
): int {.inline.} =
  ## Returns the number of `cell` in the node.
  self.fieldCnts[cell] + self.stepsCnts[cell]

func garbagesCnt[F: TsuField or WaterField](self: SolveNode[F]): int {.inline.} =
  ## Returns the number of hard and garbage puyos in the node.
  (self.fieldCnts[Hard] + self.fieldCnts[Garbage]) +
    (self.stepsCnts[Hard] + self.stepsCnts[Garbage])

func isAccepted[F: TsuField or WaterField](
    self: SolveNode[F], goal: Goal, kind: static GoalKind, color: static GoalColor
): bool {.inline.} =
  ## Returns `true` if the goal is satisfied.
  # check clear
  staticCase:
    case kind
    of Clear, ClearChain, ClearChainMore:
      let fieldCnt = staticCase:
        case color
        of All:
          self.fieldCnts.sum2
        of Colors:
          self.fieldCnts.sum2 Cell.Red .. Cell.Purple
        of GoalColor.Garbages:
          self.fieldCnts[Hard] + self.fieldCnts[Garbage]
        else:
          self.fieldCnts[static(GoalColorToCell[color])]

      if fieldCnt > 0:
        return false
    else:
      discard

  # check kind-specific
  staticCase:
    case kind
    of Clear:
      true
    of AccColor, AccColorMore:
      goal.isSatisfiedAccColor(self.popColors, kind)
    of AccCnt, AccCntMore:
      goal.isSatisfiedAccCnt(self.popCnt, kind)
    of Chain, ChainMore, ClearChain, ClearChainMore:
      goal.isSatisfiedChain(self.moveResult, kind)
    of Color, ColorMore:
      goal.isSatisfiedColor(self.moveResult, kind)
    of Cnt, CntMore:
      goal.isSatisfiedCnt(self.moveResult, kind, color)
    of Place, PlaceMore:
      goal.isSatisfiedPlace(self.moveResult, kind, color)
    of Conn, ConnMore:
      goal.isSatisfiedConn(self.moveResult, kind, color)

# ------------------------------------------------
# Prune
# ------------------------------------------------

func filter4Nim[T: SomeNumber](x: T): T {.inline.} =
  ## Returns `x` if `x >= 4`; otherwise 0.
  x * (x >= 4).T

func filter4[T: SomeNumber](x: T): T {.inline.} =
  ## Returns `x` if `x >= 4`; otherwise 0.
  # NOTE: asm uses `result`, so "expression return" is unavailable
  when nimvm:
    result = x.filter4Nim
  else:
    when defined(gcc) or defined(clang):
      {.push warning[Uninit]: off.}
      var zero {.noinit.}: int
      asm """
xor %2, %2
cmp $4, %1
cmovl %2, %0
: "=&r"(`result`)
: "0"(`x`), "r"(`zero`)"""
      {.pop.}
    else:
      result = x.filter4Nim

func canPrune[F: TsuField or WaterField](
    self: SolveNode[F],
    goal: Goal,
    kind: static GoalKind,
    color: static GoalColor,
    isZeroDepth: static bool,
): bool {.inline.} =
  ## Returns `true` if the node is unsolvable.
  # clear
  staticCase:
    case kind
    of Clear, ClearChain, ClearChainMore:
      let canPrune = staticCase:
        case color
        of All:
          var
            unpoppableColorExist = false
            poppableColorNotExist = true

          staticFor(cell2, Cell.Red .. Cell.Purple):
            let
              fieldCnt = self.fieldCnts[cell2]
              cnt = fieldCnt + self.stepsCnts[cell2]
              cntLt4 = cnt < 4

            poppableColorNotExist.assign poppableColorNotExist and cntLt4
            unpoppableColorExist.assign unpoppableColorExist or (
              fieldCnt > 0 and cntLt4
            )

          unpoppableColorExist or (
            poppableColorNotExist and
            (self.fieldCnts[Hard] + self.fieldCnts[Garbage] > 0)
          )
        of GoalColor.Garbages:
          var poppableColorNotExist = true

          staticFor(cell2, Cell.Red .. Cell.Purple):
            poppableColorNotExist.assign poppableColorNotExist and
              self.cellCnt(cell2) < 4

          poppableColorNotExist and (self.fieldCnts[Hard] + self.fieldCnts[Garbage] > 0)
        of Colors:
          var unpoppableColorExist = false

          staticFor(cell2, Cell.Red .. Cell.Purple):
            let
              fieldCnt = self.fieldCnts[cell2]
              cnt = fieldCnt + self.stepsCnts[cell2]

            unpoppableColorExist.assign unpoppableColorExist or
              (fieldCnt > 0 and cnt < 4)

          unpoppableColorExist
        else:
          const GoalCell = GoalColorToCell[color]
          let fieldCnt = self.fieldCnts[GoalCell]

          fieldCnt > 0 and fieldCnt + self.stepsCnts[GoalCell] < 4

      if canPrune:
        return true
    else:
      discard

  # kind-specific
  staticCase:
    case kind
    of Clear:
      false
    of AccColor, AccColorMore:
      when isZeroDepth:
        let possibleVal = sum2It[Cell, int](Cell.Red .. Cell.Purple):
          (self.cellCnt(it) >= 4).int
        possibleVal < goal.optVal.expect
      else:
        false
    of AccCnt, AccCntMore, Cnt, CntMore, Conn, ConnMore:
      let nowPossibleCnt = staticCase:
        case color
        of All, Colors, GoalColor.Garbages:
          let colorPossibleCnt = sum2It[Cell, int](Cell.Red .. Cell.Purple):
            self.cellCnt(it).filter4
          staticCase:
            case color
            of All:
              colorPossibleCnt + (colorPossibleCnt > 0).int * self.garbagesCnt
            of Colors:
              colorPossibleCnt
            of GoalColor.Garbages:
              (colorPossibleCnt > 0).int * self.garbagesCnt
            else:
              0 # dummy
        else:
          self.cellCnt(static(GoalColorToCell[color])).filter4

      let possibleCnt = staticCase:
        case kind
        of AccCnt, AccCntMore:
          self.popCnt + nowPossibleCnt
        of Cnt, CntMore, Conn, ConnMore:
          nowPossibleCnt
        else:
          0 # dummy

      possibleCnt < goal.optVal.expect
    of Chain, ChainMore, ClearChain, ClearChainMore:
      let possibleChain = sum2It[Cell, int](Cell.Red .. Cell.Purple):
        self.cellCnt(it) div 4
      possibleChain < goal.optVal.expect
    of Color, ColorMore:
      let possibleColorCnt = sum2It[Cell, int](Cell.Red .. Cell.Purple):
        (self.cellCnt(it) >= 4).int
      possibleColorCnt < goal.optVal.expect
    of Place, PlaceMore:
      let possiblePlace = staticCase:
        case color
        of All, Colors:
          sum2It[Cell, int](Cell.Red .. Cell.Purple):
            self.cellCnt(it) div 4
        of GoalColor.Garbages:
          0 # dummy
        else:
          self.cellCnt(static(GoalColorToCell[color])) div 4

      possiblePlace < goal.optVal.expect

# ------------------------------------------------
# Solve
# ------------------------------------------------

func solveSingleThread[F: TsuField or WaterField](
    self: SolveNode[F],
    answers: var seq[SolveAnswer],
    moveCnt: int,
    calcAllAnswers: static bool,
    goal: Goal,
    kind: static GoalKind,
    color: static GoalColor,
    steps: Steps,
    isZeroDepth: static bool,
) {.inline.} =
  ## Solves the nazo puyo with a single thread.
  ## This function requires that the field is settled and `answers` is empty.
  ## `answers` is set in reverse order.
  when isZeroDepth:
    if self.canPrune(goal, kind, color, true):
      return

  let
    step = steps[self.depth]
    childDepth = self.depth.succ
    childIsLeaf = childDepth == moveCnt
    children = self.children(kind, color, step)

  var childAnswersSeq = newSeqOfCap[seq[SolveAnswer]](children.len)
  for _ in 1 .. children.len:
    childAnswersSeq.add newSeqOfCap[SolveAnswer](22)

  for childIdx, (child, optPlcmt) in children.pairs:
    if child.isAccepted(goal, kind, color):
      var ans = newSeqOfCap[OptPlacement](childDepth)
      ans.add optPlcmt

      answers.add ans

      when not calcAllAnswers:
        if answers.len > 1:
          return

      continue

    if childIsLeaf or child.canPrune(goal, kind, color, false):
      continue

    child.solveSingleThread childAnswersSeq[childIdx],
      moveCnt, calcAllAnswers, goal, kind, color, steps, false

    for ans in childAnswersSeq[childIdx].mitems:
      ans.add optPlcmt

    when not calcAllAnswers:
      if answers.len + childAnswersSeq[childIdx].len > 1:
        answers &= childAnswersSeq[childIdx]
        return

  answers &= childAnswersSeq.concat

when not defined(js):
  proc solveSingleThread[F: TsuField or WaterField](
      self: SolveNode[F],
      answers: ptr seq[SolveAnswer],
      moveCnt: int,
      goal: Goal,
      steps: Steps,
      calcAllAnswers: static bool,
      kind: static GoalKind,
      color: static GoalColor,
      isZeroDepth: static bool,
  ): bool {.inline.} =
    ## Solves the nazo puyo with a single thread.
    ## This function requires that the field is settled and `answers` is empty.
    ## `answers` is set in reverse order.
    ## `result` has no meanings; only used to get FlowVar.
    # NOTE: non-static arguments should be placed before static ones due to `spawn` bug.
    self.solveSingleThread answers[],
      moveCnt, calcAllAnswers, goal, kind, color, steps, isZeroDepth
    true

  proc calcSpawnNodes[F: TsuField or WaterField](
      self: SolveNode[F],
      nodes: var seq[SolveNode[F]],
      optPlcmtsSeq: var seq[seq[OptPlacement]],
      answers: var seq[SolveAnswer],
      moveCnt: int,
      calcAllAnswers: static bool,
      goal: Goal,
      kind: static GoalKind,
      color: static GoalColor,
      steps: Steps,
  ) {.inline.} =
    ## Calculates nodes to be spawned.
    ## `answers` is set in reverse order.
    # NOTE: 3 shows good performance; see https://github.com/24ik/pon2/issues/198
    # NOTE: now `SpawnDepth` max is 3 since the limitations of Nim's built-in sets,
    # that is used by node indices (22^3 < int16.high < 22^4)
    const SpawnDepth = 3

    let
      step = steps[self.depth]
      childDepth = self.depth.succ
      childIsSpawned = childDepth == SpawnDepth
      childIsLeaf = childDepth == moveCnt
      children = self.children(kind, color, step)

    var
      nodesSeq = newSeqOfCap[seq[SolveNode[F]]](children.len)
      optPlcmtsSeqSeq = newSeqOfCap[seq[seq[OptPlacement]]](children.len)
      answersSeq = newSeqOfCap[seq[SolveAnswer]](children.len)
    for _ in 1 .. children.len:
      nodesSeq.add newSeqOfCap[SolveNode[F]](22)
      optPlcmtsSeqSeq.add newSeqOfCap[seq[OptPlacement]](22)
      answersSeq.add newSeqOfCap[SolveAnswer](22)

    for childIdx, (child, optPlcmt) in children.pairs:
      if child.isAccepted(goal, kind, color):
        var ans = newSeqOfCap[OptPlacement](childDepth)
        ans.add optPlcmt

        answers.add ans

        when not calcAllAnswers:
          if answers.len > 1:
            return

        continue

      if childIsLeaf or child.canPrune(goal, kind, color, false):
        continue

      if childIsSpawned:
        nodesSeq[childIdx].add child

        var optPlcmts = newSeqOfCap[OptPlacement](childDepth)
        optPlcmts.add optPlcmt
        optPlcmtsSeqSeq[childIdx].add optPlcmts
      else:
        child.calcSpawnNodes nodesSeq[childIdx],
          optPlcmtsSeqSeq[childIdx],
          answersSeq[childIdx],
          moveCnt,
          calcAllAnswers,
          goal,
          kind,
          color,
          steps

        for optPlcmts in optPlcmtsSeqSeq[childIdx].mitems:
          optPlcmts.add optPlcmt

      for ans in answersSeq[childIdx].mitems:
        ans.add optPlcmt

      when not calcAllAnswers:
        if answers.len + answersSeq[childIdx].len > 1:
          answers &= answersSeq[childIdx]
          return

    nodes &= nodesSeq.concat
    optPlcmtsSeq &= optPlcmtsSeqSeq.concat
    answers &= answersSeq.concat

  template checkSpawnFinished(
      futures: seq[FlowVar[bool]],
      answers: var seq[SolveAnswer],
      answersSeq: var seq[seq[SolveAnswer]],
      runningNodeIndices: var set[int16],
      optPlcmtsSeq: seq[seq[OptPlacement]],
      suruBar: typed,
      calcAllAnswers: static bool,
      showProgressBar: static bool,
  ) =
    ## Check all the spawned threads and reflects results if they have finished.
    var finishNodeIndices = set[int16]({})

    for runningNodeIdx in runningNodeIndices:
      if not futures[runningNodeIdx].isReady:
        continue

      finishNodeIndices.incl runningNodeIdx

      let optPlcmts = optPlcmtsSeq[runningNodeIdx]
      for ans in answersSeq[runningNodeIdx].mitems:
        ans &= optPlcmts
        ans.reverse

      when not calcAllAnswers:
        if answers.len + answersSeq[runningNodeIdx].len > 1:
          answers &= answersSeq[runningNodeIdx]

          when showProgressBar:
            suruBar.shutdown

          return

      when showProgressBar:
        suruBar.inc
        suruBar.update2

    runningNodeIndices.excl finishNodeIndices

  proc solveMultiThread[F: TsuField or WaterField](
      self: SolveNode[F],
      answers: var seq[SolveAnswer],
      moveCnt: int,
      calcAllAnswers: static bool,
      showProgressBar: static bool,
      goal: Goal,
      kind: static GoalKind,
      color: static GoalColor,
      steps: Steps,
      isZeroDepth: static bool,
  ) {.inline.} =
    ## Solves the nazo puyo.
    ## This function requires that the field is settled and `answers` is empty.
    ## `showProgressBar` is ignored on JS backend.
    const
      SpawnWaitMs = 25
      SolveWaitMs = 50

    var
      nodes = newSeq[SolveNode[F]]()
      optPlcmtsSeq = newSeq[seq[OptPlacement]]()
    self.calcSpawnNodes nodes,
      optPlcmtsSeq, answers, moveCnt, calcAllAnswers, goal, kind, color, steps

    for ans in answers.mitems:
      ans.reverse

    when not calcAllAnswers:
      if answers.len > 1:
        return

    let nodeCnt = nodes.len

    when showProgressBar:
      var suruBar = initSuruBar()
      suruBar[0].total = nodeCnt
      suruBar.setup2
    else:
      let suruBar = false # dummy

    var
      answersSeq = collect:
        for _ in 1 .. nodes.len:
          newSeq[SolveAnswer]()
      futures = newSeqOfCap[FlowVar[bool]](nodeCnt)
      runningNodeIndices = set[int16]({})

    var nodeIdx = 0'i16
    while nodeIdx < nodeCnt:
      if preferSpawn():
        futures.add spawn nodes[nodeIdx].solveSingleThread(
          answersSeq[nodeIdx].addr,
          moveCnt,
          goal,
          steps,
          calcAllAnswers,
          kind,
          color,
          isZeroDepth,
        )

        runningNodeIndices.incl nodeIdx
        nodeIdx.inc

        continue

      futures.checkSpawnFinished answers,
        answersSeq, runningNodeIndices, optPlcmtsSeq, suruBar, calcAllAnswers,
        showProgressBar
      sleep SpawnWaitMs

    while runningNodeIndices.card > 0:
      futures.checkSpawnFinished answers,
        answersSeq, runningNodeIndices, optPlcmtsSeq, suruBar, calcAllAnswers,
        showProgressBar
      sleep SolveWaitMs

    answers &= answersSeq.concat

    when showProgressBar:
      suruBar.finish2

proc solve[F: TsuField or WaterField](
    self: SolveNode[F],
    answers: var seq[SolveAnswer],
    moveCnt: int,
    calcAllAnswers: static bool,
    showProgressBar: static bool,
    goal: Goal,
    kind: static GoalKind,
    color: static GoalColor,
    steps: Steps,
    isZeroDepth: static bool,
) {.inline.} =
  ## Solves the nazo puyo.
  ## This function requires that the field is settled and `answers` is empty.
  ## `showProgressBar` is ignored on JS backend.
  when defined(js):
    self.solveSingleThread(
      answers, moveCnt, calcAllAnswers, goal, kind, color, steps, isZeroDepth
    )

    for ans in answers.mitems:
      ans.reverse
  else:
    self.solveMultiThread(
      answers, moveCnt, calcAllAnswers, showProgressBar, goal, kind, color, steps,
      isZeroDepth,
    )

proc solve[F: TsuField or WaterField](
    self: SolveNode[F],
    answers: var seq[SolveAnswer],
    moveCnt: int,
    calcAllAnswers: static bool,
    showProgressBar: static bool,
    goal: Goal,
    kind: static GoalKind,
    steps: Steps,
    isZeroDepth: static bool,
) {.inline.} =
  ## Solves the nazo puyo.
  ## This function requires that the field is settled and `answers` is empty.
  ## `showProgressBar` is ignored on JS backend.
  case goal.optColor.expect
  of All:
    self.solve(
      answers, moveCnt, calcAllAnswers, showProgressBar, goal, kind, All, steps,
      isZeroDepth,
    )
  of GoalColor.Red:
    self.solve(
      answers, moveCnt, calcAllAnswers, showProgressBar, goal, kind, GoalColor.Red,
      steps, isZeroDepth,
    )
  of GoalColor.Green:
    self.solve(
      answers, moveCnt, calcAllAnswers, showProgressBar, goal, kind, GoalColor.Green,
      steps, isZeroDepth,
    )
  of GoalColor.Blue:
    self.solve(
      answers, moveCnt, calcAllAnswers, showProgressBar, goal, kind, GoalColor.Blue,
      steps, isZeroDepth,
    )
  of GoalColor.Yellow:
    self.solve(
      answers, moveCnt, calcAllAnswers, showProgressBar, goal, kind, GoalColor.Yellow,
      steps, isZeroDepth,
    )
  of GoalColor.Purple:
    self.solve(
      answers, moveCnt, calcAllAnswers, showProgressBar, goal, kind, GoalColor.Purple,
      steps, isZeroDepth,
    )
  of GoalColor.Garbages:
    self.solve(
      answers, moveCnt, calcAllAnswers, showProgressBar, goal, kind, GoalColor.Garbages,
      steps, isZeroDepth,
    )
  of Colors:
    self.solve(
      answers, moveCnt, calcAllAnswers, showProgressBar, goal, kind, Colors, steps,
      isZeroDepth,
    )

proc solve[F: TsuField or WaterField](
    self: SolveNode[F],
    answers: var seq[SolveAnswer],
    moveCnt: int,
    calcAllAnswers: static bool,
    showProgressBar: static bool,
    goal: Goal,
    steps: Steps,
    isZeroDepth: static bool,
) {.inline.} =
  ## Solves the nazo puyo.
  ## This function requires that the field is settled and `answers` is empty.
  ## `showProgressBar` is ignored on JS backend.
  const DummyColor = All

  case goal.kind
  of Clear:
    self.solve(
      answers, moveCnt, calcAllAnswers, showProgressBar, goal, Clear, steps, isZeroDepth
    )
  of AccColor:
    self.solve(
      answers, moveCnt, calcAllAnswers, showProgressBar, goal, AccColor, DummyColor,
      steps, isZeroDepth,
    )
  of AccColorMore:
    self.solve(
      answers, moveCnt, calcAllAnswers, showProgressBar, goal, AccColorMore, DummyColor,
      steps, isZeroDepth,
    )
  of AccCnt:
    self.solve(
      answers, moveCnt, calcAllAnswers, showProgressBar, goal, AccCnt, steps,
      isZeroDepth,
    )
  of AccCntMore:
    self.solve(
      answers, moveCnt, calcAllAnswers, showProgressBar, goal, AccCntMore, steps,
      isZeroDepth,
    )
  of Chain:
    self.solve(
      answers, moveCnt, calcAllAnswers, showProgressBar, goal, Chain, DummyColor, steps,
      isZeroDepth,
    )
  of ChainMore:
    self.solve(
      answers, moveCnt, calcAllAnswers, showProgressBar, goal, ChainMore, DummyColor,
      steps, isZeroDepth,
    )
  of ClearChain:
    self.solve(
      answers, moveCnt, calcAllAnswers, showProgressBar, goal, ClearChain, steps,
      isZeroDepth,
    )
  of ClearChainMore:
    self.solve(
      answers, moveCnt, calcAllAnswers, showProgressBar, goal, ClearChainMore, steps,
      isZeroDepth,
    )
  of Color:
    self.solve(
      answers, moveCnt, calcAllAnswers, showProgressBar, goal, Color, DummyColor, steps,
      isZeroDepth,
    )
  of ColorMore:
    self.solve(
      answers, moveCnt, calcAllAnswers, showProgressBar, goal, ColorMore, DummyColor,
      steps, isZeroDepth,
    )
  of Cnt:
    self.solve(
      answers, moveCnt, calcAllAnswers, showProgressBar, goal, Cnt, steps, isZeroDepth
    )
  of CntMore:
    self.solve(
      answers, moveCnt, calcAllAnswers, showProgressBar, goal, CntMore, steps,
      isZeroDepth,
    )
  of Place:
    self.solve(
      answers, moveCnt, calcAllAnswers, showProgressBar, goal, Place, steps, isZeroDepth
    )
  of PlaceMore:
    self.solve(
      answers, moveCnt, calcAllAnswers, showProgressBar, goal, PlaceMore, steps,
      isZeroDepth,
    )
  of Conn:
    self.solve(
      answers, moveCnt, calcAllAnswers, showProgressBar, goal, Conn, steps, isZeroDepth
    )
  of ConnMore:
    self.solve(
      answers, moveCnt, calcAllAnswers, showProgressBar, goal, ConnMore, steps,
      isZeroDepth,
    )

proc solve*[F: TsuField or WaterField](
    self: SolveNode[F],
    calcAllAnswers: static bool,
    showProgressBar: static bool,
    goal: Goal,
    steps: Steps,
): seq[SolveAnswer] {.inline.} =
  ## Solves the nazo puyo.
  ## This function requires that the field is settled.
  ## `showProgressBar` is ignored on JS backend.
  if not goal.isSupported or steps.len == 0:
    return @[]

  var answers = newSeq[SolveAnswer]()
  self.solve(answers, steps.len, calcAllAnswers, showProgressBar, goal, steps, true)

  answers

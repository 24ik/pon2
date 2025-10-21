## This module implements Nazo Puyo solvers.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[algorithm, sequtils, sugar, typetraits]
import ../[core]
import ../private/[assign3, core, macros2, math2, staticfor2, utils]

when defined(js) or defined(nimsuggest):
  import std/[dom]
  import ../private/[strutils2, webworker]

when not defined(js):
  import std/[os]

  {.push warning[Deprecated]: off.}
  import std/[threadpool]
  {.pop.}

type
  SolveAnswer* = seq[OptPlacement]
    ## Nazo Puyo answer.
    ## Elements corresponding to non-`PairPlacement` steps are set to `NonePlacement`.

  SolveNode[F: TsuField or WaterField] = object ## Node of solutions search tree.
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
    fieldCnts, stepsCnts: array[Cell, int],
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

func init[F: TsuField or WaterField](
    T: type SolveNode[F], puyoPuyo: PuyoPuyo[F]
): T {.inline.} =
  var fieldCnts {.noinit.}, stepsCnts {.noinit.}: array[Cell, int]
  fieldCnts[Cell.None] = 0
  stepsCnts[Cell.None] = 0
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

func filter4Nim[T: SomeInteger](x: T): T {.inline.} =
  ## Returns `x` if `x >= 4`; otherwise 0.
  x * (x >= 4).T

func filter4[T: SomeInteger](x: T): T {.inline.} =
  ## Returns `x` if `x >= 4`; otherwise 0.
  # NOTE: asm uses `result`, so "expression return" is unavailable
  when nimvm:
    result = x.filter4Nim
  else:
    when (defined(amd64) or defined(i386)) and (defined(gcc) or defined(clang)):
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
        possibleVal < goal.optVal.unsafeValue
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

      possibleCnt < goal.optVal.unsafeValue
    of Chain, ChainMore, ClearChain, ClearChainMore:
      let possibleChain = sum2It[Cell, int](Cell.Red .. Cell.Purple):
        self.cellCnt(it) div 4
      possibleChain < goal.optVal.unsafeValue
    of Color, ColorMore:
      let possibleColorCnt = sum2It[Cell, int](Cell.Red .. Cell.Purple):
        (self.cellCnt(it) >= 4).int
      possibleColorCnt < goal.optVal.unsafeValue
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

      possiblePlace < goal.optVal.unsafeValue

# ------------------------------------------------
# Child - Depth
# ------------------------------------------------

func childrenAtDepth[F: TsuField or WaterField](
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
  ## Calculates nodes with depth 3 (named `TargetDepth` in this function)
  ## and sets them to `nodes`.
  ## A sequence of edges to reach them is set to `optPlcmtsSeq`.
  ## Answers that have `TargetDepth` or less steps are set to `answers` in reverse
  ## order.
  ## This function requires that the field is settled and `nodes`, `optPlcmtsSeq`, and
  ## `answers` are empty.
  ## Note that this function should not be called directly; instead call a `NazoPuyo`'s
  ## method.
  # NOTE: `TargetDepth == 3` is good; see https://github.com/24ik/pon2/issues/198
  # NOTE: `TargetDepth` should be less than 4 due to the limitations of Nim's built-in
  # sets, that is used by node indices (22^3 < int16.high < 22^4)
  const
    TargetDepth = 3
    PlcmtLen = Placement.enumLen

  let
    step = steps[self.depth]
    childDepth = self.depth.succ
    childIsSpawned = childDepth == TargetDepth
    childIsLeaf = childDepth == moveCnt
    children = self.children(kind, color, step)

  var
    nodesSeq = newSeqOfCap[seq[SolveNode[F]]](children.len)
    optPlcmtsSeqSeq = newSeqOfCap[seq[seq[OptPlacement]]](children.len)
    answersSeq = newSeqOfCap[seq[SolveAnswer]](children.len)
  for _ in 1 .. children.len:
    nodesSeq.add newSeqOfCap[SolveNode[F]](PlcmtLen)
    optPlcmtsSeqSeq.add newSeqOfCap[seq[OptPlacement]](PlcmtLen)
    answersSeq.add newSeqOfCap[SolveAnswer](PlcmtLen)

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
      child.childrenAtDepth nodesSeq[childIdx],
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

func childrenAtDepth[F: TsuField or WaterField](
    self: NazoPuyo[F],
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
  ## Calculates nodes with depth 3 (named `TargetDepth` in this function)
  ## and sets them to `nodes`.
  ## A sequence of edges to reach them is set to `optPlcmtsSeq`.
  ## Answers that have `TargetDepth` or less steps are set to `answers` in reverse
  ## order.
  ## This function requires that the field is settled and `nodes`, `optPlcmtsSeq`, and
  ## `answers` are empty.
  SolveNode[F].init(self.puyoPuyo).childrenAtDepth nodes,
    optPlcmtsSeq, answers, moveCnt, calcAllAnswers, goal, kind, color, steps

# ------------------------------------------------
# Static Getter
# ------------------------------------------------

template withStaticColor(goal: Goal, body: untyped): untyped =
  ## Runs `body` with `StaticColor` exposed.
  case goal.optColor.unsafeValue
  of All:
    const StaticColor {.inject.} = All
    body
  of GoalColor.Red:
    const StaticColor {.inject.} = GoalColor.Red
    body
  of GoalColor.Green:
    const StaticColor {.inject.} = GoalColor.Green
    body
  of GoalColor.Blue:
    const StaticColor {.inject.} = GoalColor.Blue
    body
  of GoalColor.Yellow:
    const StaticColor {.inject.} = GoalColor.Yellow
    body
  of GoalColor.Purple:
    const StaticColor {.inject.} = GoalColor.Purple
    body
  of GoalColor.Garbages:
    const StaticColor {.inject.} = GoalColor.Garbages
    body
  of Colors:
    const StaticColor {.inject.} = Colors
    body

template withStaticKindColor(goal: Goal, body: untyped): untyped =
  ## Runs `body` with `StaticKind` and `StaticColor` exposed.
  case goal.kind
  of Clear:
    const StaticKind {.inject.} = Clear
    goal.withStaticColor:
      body
  of AccColor:
    const
      StaticKind {.inject.} = AccColor
      StaticColor {.inject.} = GoalColor.low
    body
  of AccColorMore:
    const
      StaticKind {.inject.} = AccColorMore
      StaticColor {.inject.} = GoalColor.low
    body
  of AccCnt:
    const StaticKind {.inject.} = AccCnt
    goal.withStaticColor:
      body
  of AccCntMore:
    const StaticKind {.inject.} = AccCntMore
    goal.withStaticColor:
      body
  of Chain:
    const
      StaticKind {.inject.} = Chain
      StaticColor {.inject.} = GoalColor.low
    body
  of ChainMore:
    const
      StaticKind {.inject.} = ChainMore
      StaticColor {.inject.} = GoalColor.low
    body
  of ClearChain:
    const StaticKind {.inject.} = ClearChain
    goal.withStaticColor:
      body
  of ClearChainMore:
    const StaticKind {.inject.} = ClearChainMore
    goal.withStaticColor:
      body
  of Color:
    const
      StaticKind {.inject.} = Color
      StaticColor {.inject.} = GoalColor.low
    body
  of ColorMore:
    const
      StaticKind {.inject.} = ColorMore
      StaticColor {.inject.} = GoalColor.low
    body
  of Cnt:
    const StaticKind {.inject.} = Cnt
    goal.withStaticColor:
      body
  of CntMore:
    const StaticKind {.inject.} = CntMore
    goal.withStaticColor:
      body
  of Place:
    const StaticKind {.inject.} = Place
    goal.withStaticColor:
      body
  of PlaceMore:
    const StaticKind {.inject.} = PlaceMore
    goal.withStaticColor:
      body
  of Conn:
    const StaticKind {.inject.} = Conn
    goal.withStaticColor:
      body
  of ConnMore:
    const StaticKind {.inject.} = ConnMore
    goal.withStaticColor:
      body

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
  ## Solves the Nazo Puyo at the node with a single thread.
  ## This function requires that the field is settled and `answers` is empty.
  ## Answers in `answers` are set in reverse order.
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
    childAnswersSeq.add newSeqOfCap[SolveAnswer](static(Placement.enumLen))

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
    ## Solves the Nazo Puyo at the node with a single thread.
    ## This function requires that the field is settled and `answers` is empty.
    ## `answers` is set in reverse order.
    ## `result` has no meanings; only used to get FlowVar.
    # NOTE: non-static arguments should be placed before static ones due to `spawn` bug.
    self.solveSingleThread answers[],
      moveCnt, calcAllAnswers, goal, kind, color, steps, isZeroDepth
    true

  func checkSpawnFinished(
      futures: seq[FlowVar[bool]],
      answers: var seq[SolveAnswer],
      answersSeq: var seq[seq[SolveAnswer]],
      runningNodeIndices: var set[int16],
      optPlcmtsSeq: seq[seq[OptPlacement]],
      calcAllAnswers: static bool,
  ) {.inline.} =
    ## Checks all the spawned threads and reflects results if they have finished.
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

          return

    runningNodeIndices.excl finishNodeIndices

  proc solveMultiThread[F: TsuField or WaterField](
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
    ## Solves the Nazo Puyo at the node with multiple threads.
    ## This function requires that the field is settled and `answers` is empty.
    const
      SpawnWaitMs = 25
      SolveWaitMs = 50

    var
      nodes = newSeq[SolveNode[F]]()
      optPlcmtsSeq = newSeq[seq[OptPlacement]]()
    self.childrenAtDepth nodes,
      optPlcmtsSeq, answers, moveCnt, calcAllAnswers, goal, kind, color, steps

    for ans in answers.mitems:
      ans.reverse

    when not calcAllAnswers:
      if answers.len > 1:
        return

    let nodeCnt = nodes.len
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
        answersSeq, runningNodeIndices, optPlcmtsSeq, calcAllAnswers
      sleep SpawnWaitMs

    while runningNodeIndices.card > 0:
      futures.checkSpawnFinished answers,
        answersSeq, runningNodeIndices, optPlcmtsSeq, calcAllAnswers
      sleep SolveWaitMs

    answers &= answersSeq.concat

proc solve*[F: TsuField or WaterField](
    nazo: NazoPuyo[F], calcAllAnswers: static bool = true
): seq[SolveAnswer] {.inline.} =
  ## Solves the Nazo Puyo.
  ## A single thread is used on JS backend; otherwise multiple threads are used.
  ## This function requires that the field is settled.
  if not nazo.goal.isSupported or nazo.puyoPuyo.steps.len == 0:
    return @[]

  let
    root = SolveNode[F].init nazo.puyoPuyo
    moveCnt = nazo.puyoPuyo.steps.len
  var answers = newSeq[SolveAnswer]()

  nazo.goal.withStaticKindColor:
    when defined(js):
      root.solveSingleThread(
        answers,
        moveCnt,
        calcAllAnswers,
        nazo.goal,
        StaticKind,
        StaticColor,
        nazo.puyoPuyo.steps,
        isZeroDepth = true,
      )

      for ans in answers.mitems:
        ans.reverse
    else:
      root.solveMultiThread(
        answers,
        moveCnt,
        calcAllAnswers,
        nazo.goal,
        StaticKind,
        StaticColor,
        nazo.puyoPuyo.steps,
        isZeroDepth = true,
      )

  answers

# ------------------------------------------------
# Solve - Async
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  const
    Sep1 = "_"
    Sep2 = "~"
    Sep3 = ":"
    Sep4 = ";"
    Sep5 = "|"
    OkStr = "ok"
    ErrStr = "err"

  func toStr(self: MoveResult): string {.inline.} =
    ## Returns the string representation of the move result.
    var strs = newSeqOfCap[string](6)

    strs.add $self.chainCnt
    strs.add self.popCnts.mapIt($it).join Sep1
    strs.add $self.hardToGarbageCnt
    strs.add self.detailPopCnts.mapIt(it.map((cnt: int) => $cnt).join Sep1).join Sep2
    strs.add self.detailHardToGarbageCnt.mapIt($it).join Sep1
    if self.fullPopCnts.isOk:
      strs.add OkStr & Sep4 &
        self.fullPopCnts.unsafeValue.mapIt(
          it.map((cnts: seq[int]) => cnts.map((cnt: int) => $cnt).join Sep1).join Sep2
        ).join Sep3
    else:
      strs.add ErrStr

    strs.join Sep5

  func toStr(self: set[Cell]): string {.inline.} =
    ## Returns the string representation of the cells.
    self.mapIt($it).join

  func toStrs[F: TsuField or WaterField](self: SolveNode[F]): seq[string] {.inline.} =
    ## Returns the string representations of the node.
    var strs = newSeqOfCap[string](7)

    strs.add $self.depth

    strs.add $self.field.toUriQuery
    strs.add self.moveReult.toStr

    strs.add self.popColors.toStr
    strs.add $self.popCnt

    strs.add $self.fieldCnts.toStr
    strs.add $self.stepsCnts.toStr

    strs

  func toSolveAnswers(res: Res[seq[string]]): seq[SolveAnswer] {.inline.} =
    ## Returns the answers converted from the run result.
    if res.isErr:
      return @[]

    var answers = newSeqOfCap[SolveAnswer](res.unsafeValue.len)
    for str in res.unsafeValue:
      if str.len mod 2 == 1:
        continue

      var ans = newSeqOfCap[OptPlacement](str.len div 2)
      for charIdx in countup(0, str.len.pred, 2):
        let optPlcmtRes = str.substr(charIdx, charIdx.succ).parseOptPlacement
        if optPlcmtRes.isOk:
          ans.add optPlcmtRes.unsafeValue

      answers.add ans

    answers

  proc solveAsync*[F: TsuField or WaterField](
      nazo: NazoPuyo[F],
      progress: ref tuple[now: int, total: int],
      workerCnt: int,
      calcAllAnswers: static bool = true,
  ): Future[seq[SolveAnswer]] {.inline, async.} =
    ## Solves the Nazo Puyo asynchronously with web workers.
    ## This function requires that the field is settled.
    const WaitIntervalMs = 100

    await sleepZeroAsync()

    let root = SolveNode[F].init nazo.puyoPuyo

    var
      nodes = newSeq[SolveNode[F]]()
      optPlcmtsSeq = newSeq[seq[OptPlacement]]()
      answers = newSeq[SolveAnswer]()

    nazo.goal.withStaticKindColor:
      root.childrenAtDepth(
        nodes, optPlcmtsSeq, answers, nazo.puyoPuyo.steps.len, calcAllAnswers,
        nazo.goal, StaticKind, StaticColor, nazo.puyoPuyo.steps,
      )

    for ans in answers.mitems:
      ans.reverse

    when not calcAllAnswers:
      if answers.len > 1:
        return answers

    let nodeCnt = nodes.len
    progress[].now.assign 0
    progress[].total.assign nodeCnt

    var
      workers = collect:
        for _ in 1 .. workerCnt:
          WebWorker.init
      answersSeq = collect:
        for _ in 1 .. nodes.len:
          newSeq[SolveAnswer]()
      runningWorkerIndices = set[int16]({})
      nodeIdx = 0'i16

    proc runWorker(workerIdx: int16) =
      if nodeIdx >= nodeCnt:
        return

      runningWorkerIndices.incl workerIdx
      let nowNodeIdx = nodeIdx
      nodeIdx.inc

      discard workers[workerIdx].run(nodes[nowNodeIdx].toStrs).then(
          (res: Res[seq[string]]) => (
            block:
              progress[].now.inc
              answersSeq[nowNodeIdx].assign res.toSolveAnswers
              runningWorkerIndices.excl workerIdx

              workerIdx.runWorker
          )
        )

    let workerIndices = 0'i16 ..< workerCnt.int16
    for workerIdx in workerIndices:
      workerIdx.runTask

    while runningWorkerIndices.card > 0:
      var finishWorkerIndices = set[int16]({})

      for workerIdx in runningWorkerIndices:
        if workers[workerIdx].isRunning:
          continue

        finishWorkerIndices.incl workerIdx

      runningWorkerIndices.excl finishWorkerIndices

      await sleepAsync WaitIntervalMs

    answers &= answersSeq.concat

    answers

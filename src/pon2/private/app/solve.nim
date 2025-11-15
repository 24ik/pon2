## This module implements helpers for Nazo Puyo solving.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, typetraits]
import ../../[core]
import ../../private/[assign, core, macros, math, staticfor]

when defined(js) or defined(nimsuggest):
  import std/[strformat, sugar]
  import ../../private/[results2, strutils]

  export core, results2

type SolveNode*[F: TsuField or WaterField] = object ## Node of solutions search tree.
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
): T {.inline, noinit.} =
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
): T {.inline, noinit.} =
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
    let stepGarbageHardCnt, isHard, isGarbage: int
    when stepKind == StepKind.Garbages:
      stepGarbageHardCnt = step.garbagesCnt
      isHard = step.dropHard.int
      isGarbage = (not step.dropHard).int
    else:
      stepGarbageHardCnt = 0
      isHard = 0
      isGarbage = 0

    childFieldCnts[Hard].dec moveRes.popCnts[Hard] + moveRes.hardToGarbageCnt -
      stepGarbageHardCnt * isHard
    childFieldCnts[Garbage].dec moveRes.popCnts[Garbage] - moveRes.hardToGarbageCnt -
      stepGarbageHardCnt * isGarbage

    when stepKind == StepKind.Garbages:
      childStepsCnts[Garbage.pred isHard].dec stepGarbageHardCnt

  when stepKind == Rotate:
    staticFor(col, Col):
      let cell = self.field[Row0, col]
      childFieldCnts[cell].dec (cell != Cell.None).int

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
): SolveNode[F] {.inline, noinit.} =
  ## Returns the child node with the `step` edge.
  ## This function requires that the field is settled.
  self.childImpl(kind, color, step, PairPlacement):
    childField.move(
      step.pair, plcmt, static(kind in {Place, PlaceMore, Conn, ConnMore})
    )

func childGarbages[F: TsuField or WaterField](
    self: SolveNode[F], kind: static GoalKind, color: static GoalColor, step: Step
): SolveNode[F] {.inline, noinit.} =
  ## Returns the child node with the `step` edge.
  ## This function requires that the field is settled.
  self.childImpl(kind, color, step, StepKind.Garbages):
    childField.move(
      step.cnts, step.dropHard, static(kind in {Place, PlaceMore, Conn, ConnMore})
    )

func childRotate[F: TsuField or WaterField](
    self: SolveNode[F], kind: static GoalKind, color: static GoalColor, step: Step
): SolveNode[F] {.inline, noinit.} =
  ## Returns the child node with the `step` edge.
  self.childImpl(kind, color, step, Rotate):
    childField.move(
      cross = step.cross, static(kind in {Place, PlaceMore, Conn, ConnMore})
    )

func children[F: TsuField or WaterField](
    self: SolveNode[F], kind: static GoalKind, color: static GoalColor, step: Step
): seq[tuple[node: SolveNode[F], optPlacement: OptPlacement]] {.inline, noinit.} =
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
  of Rotate:
    @[(self.childRotate(kind, color, step), NonePlacement)]

# ------------------------------------------------
# Accept
# ------------------------------------------------

func cellCnt[F: TsuField or WaterField](
    self: SolveNode[F], cell: Cell
): int {.inline, noinit.} =
  ## Returns the number of `cell` in the node.
  self.fieldCnts[cell] + self.stepsCnts[cell]

func garbagesCnt[F: TsuField or WaterField](
    self: SolveNode[F]
): int {.inline, noinit.} =
  ## Returns the number of hard and garbage puyos in the node.
  (self.fieldCnts[Hard] + self.fieldCnts[Garbage]) +
    (self.stepsCnts[Hard] + self.stepsCnts[Garbage])

func isAccepted[F: TsuField or WaterField](
    self: SolveNode[F], goal: Goal, kind: static GoalKind, color: static GoalColor
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  # check clear
  staticCase:
    case kind
    of Clear, ClearChain, ClearChainMore:
      let fieldCnt = staticCase:
        case color
        of All:
          self.fieldCnts.sum
        of Colors:
          self.fieldCnts.sum Cell.Red .. Cell.Purple
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

func filter4Nim[T: SomeInteger](x: T): T {.inline, noinit.} =
  ## Returns `x` if `x >= 4`; otherwise 0.
  x * (x >= 4).T

func filter4[T: SomeInteger](x: T): T {.inline, noinit.} =
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
    self: SolveNode[F], goal: Goal, kind: static GoalKind, color: static GoalColor
): bool {.inline, noinit.} =
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
      let possibleVal = sumIt[Cell, int](Cell.Red .. Cell.Purple):
        (self.cellCnt(it) >= 4).int
      possibleVal < goal.optVal.unsafeValue
    of AccCnt, AccCntMore, Cnt, CntMore, Conn, ConnMore:
      let nowPossibleCnt = staticCase:
        case color
        of All, Colors, GoalColor.Garbages:
          let colorPossibleCnt = sumIt[Cell, int](Cell.Red .. Cell.Purple):
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
      let possibleChain = sumIt[Cell, int](Cell.Red .. Cell.Purple):
        self.cellCnt(it) div 4
      possibleChain < goal.optVal.unsafeValue
    of Color, ColorMore:
      let possibleColorCnt = sumIt[Cell, int](Cell.Red .. Cell.Purple):
        (self.cellCnt(it) >= 4).int
      possibleColorCnt < goal.optVal.unsafeValue
    of Place, PlaceMore:
      let possiblePlace = staticCase:
        case color
        of All, Colors:
          sumIt[Cell, int](Cell.Red .. Cell.Purple):
            self.cellCnt(it) div 4
        of GoalColor.Garbages:
          0 # dummy
        else:
          self.cellCnt(static(GoalColorToCell[color])) div 4

      possiblePlace < goal.optVal.unsafeValue

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
# Child - Depth
# ------------------------------------------------

func childrenAtDepth[F: TsuField or WaterField](
    self: SolveNode[F],
    targetDepth: int,
    nodes: var seq[SolveNode[F]],
    optPlcmtsSeq: var seq[seq[OptPlacement]],
    answers: var seq[seq[OptPlacement]],
    moveCnt: int,
    calcAllAnswers: static bool,
    goal: Goal,
    kind: static GoalKind,
    color: static GoalColor,
    steps: Steps,
) {.inline, noinit.} =
  ## Calculates nodes with the given depth and sets them to `nodes`.
  ## A sequence of edges to reach them is set to `optPlcmtsSeq`.
  ## Answers that have `targetDepth` or less steps are set to `answers` in reverse
  ## order.
  ## This function requires that the field is settled and `nodes`, `optPlcmtsSeq`, and
  ## `answers` are empty.
  let
    step = steps[self.depth]
    childDepth = self.depth.succ
    childIsSpawned = childDepth == targetDepth
    childIsLeaf = childDepth == moveCnt
    children = self.children(kind, color, step)

  var
    nodesSeq = newSeqOfCap[seq[SolveNode[F]]](children.len)
    optPlcmtsSeqSeq = newSeqOfCap[seq[seq[OptPlacement]]](children.len)
    answersSeq = newSeqOfCap[seq[seq[OptPlacement]]](children.len)
  for _ in 1 .. children.len:
    nodesSeq.add newSeqOfCap[SolveNode[F]](static(Placement.enumLen))
    optPlcmtsSeqSeq.add newSeqOfCap[seq[OptPlacement]](static(Placement.enumLen))
    answersSeq.add newSeqOfCap[seq[OptPlacement]](static(Placement.enumLen))

  for childIdx, (child, optPlcmt) in children.pairs:
    if child.isAccepted(goal, kind, color):
      var ans = newSeqOfCap[OptPlacement](childDepth)
      ans.add optPlcmt

      answers.add ans

      when not calcAllAnswers:
        if answers.len > 1:
          return

      continue

    if childIsLeaf or child.canPrune(goal, kind, color):
      continue

    if childIsSpawned:
      nodesSeq[childIdx].add child

      var optPlcmts = newSeqOfCap[OptPlacement](childDepth)
      optPlcmts.add optPlcmt
      optPlcmtsSeqSeq[childIdx].add optPlcmts
    else:
      child.childrenAtDepth targetDepth,
        nodesSeq[childIdx],
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

func childrenAtDepth*[F: TsuField or WaterField](
    self: SolveNode[F],
    targetDepth: int,
    nodes: var seq[SolveNode[F]],
    optPlcmtsSeq: var seq[seq[OptPlacement]],
    answers: var seq[seq[OptPlacement]],
    moveCnt: int,
    calcAllAnswers: static bool,
    goal: Goal,
    steps: Steps,
) {.inline, noinit.} =
  ## Calculates nodes with the given depth and sets them to `nodes`.
  ## A sequence of edges to reach them is set to `optPlcmtsSeq`.
  ## Answers that have `TargetDepth` or less steps are set to `answers` in reverse
  ## order.
  ## This function requires that the field is settled and `nodes`, `optPlcmtsSeq`, and
  ## `answers` are empty.
  goal.withStaticKindColor:
    self.childrenAtDepth targetDepth,
      nodes, optPlcmtsSeq, answers, moveCnt, calcAllAnswers, goal, StaticKind,
      StaticColor, steps

# ------------------------------------------------
# Solve
# ------------------------------------------------

func solveSingleThread[F: TsuField or WaterField](
    self: SolveNode[F],
    answers: var seq[seq[OptPlacement]],
    moveCnt: int,
    calcAllAnswers: static bool,
    goal: Goal,
    kind: static GoalKind,
    color: static GoalColor,
    steps: Steps,
    checkPruneFirst: static bool = false,
) {.inline, noinit.} =
  ## Solves the Nazo Puyo at the node with a single thread.
  ## This function requires that the field is settled and `answers` is empty.
  ## Answers in `answers` are set in reverse order.
  when checkPruneFirst:
    if self.canPrune(goal, kind, color):
      return

  let
    step = steps[self.depth]
    childDepth = self.depth.succ
    childIsLeaf = childDepth == moveCnt
    children = self.children(kind, color, step)

  var childAnswersSeq = newSeqOfCap[seq[seq[OptPlacement]]](children.len)
  for _ in 1 .. children.len:
    childAnswersSeq.add newSeqOfCap[seq[OptPlacement]](static(Placement.enumLen))

  for childIdx, (child, optPlcmt) in children.pairs:
    if child.isAccepted(goal, kind, color):
      var ans = newSeqOfCap[OptPlacement](childDepth)
      ans.add optPlcmt

      answers.add ans

      when not calcAllAnswers:
        if answers.len > 1:
          return

      continue

    if childIsLeaf or child.canPrune(goal, kind, color):
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

func solveSingleThread*[F: TsuField or WaterField](
    self: SolveNode[F],
    answers: var seq[seq[OptPlacement]],
    moveCnt: int,
    calcAllAnswers: static bool,
    goal: Goal,
    steps: Steps,
    checkPruneFirst: static bool = false,
) {.inline, noinit.} =
  ## Solves the Nazo Puyo at the node with a single thread.
  ## This function requires that the field is settled and `answers` is empty.
  ## Answers in `answers` are set in reverse order.
  goal.withStaticKindColor:
    self.solveSingleThread answers,
      moveCnt, calcAllAnswers, goal, StaticKind, StaticColor, steps, checkPruneFirst

# ------------------------------------------------
# SolveNode <-> string
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  const
    Sep1 = ":"
    Sep2 = ";"
    Sep3 = "!"
    Sep4 = "|"
    ErrStr = "err"

  func toStr(self: MoveResult): string {.inline, noinit.} =
    ## Returns the string representation of the move result.
    var strs = newSeqOfCap[string](6)

    strs.add $self.chainCnt
    strs.add self.popCnts.mapIt($it).join Sep1
    strs.add $self.hardToGarbageCnt
    strs.add self.detailPopCnts.mapIt(it.map((cnt: int) => $cnt).join Sep1).join Sep2
    strs.add self.detailHardToGarbageCnt.mapIt($it).join Sep1
    if self.fullPopCnts.isOk:
      strs.add self.fullPopCnts.unsafeValue.mapIt(
        it.map((cnts: seq[int]) => cnts.map((cnt: int) => $cnt).join Sep1).join Sep2
      ).join Sep3
    else:
      strs.add ErrStr

    strs.join Sep4

  func toStr(self: set[Cell]): string {.inline, noinit.} =
    ## Returns the string representation of the cells.
    self.mapIt($it).join

  func toStr(self: array[Cell, int]): string {.inline, noinit.} =
    ## Returns the string representation of the array.
    self.mapIt($it).join Sep1

  func toStrs*[F: TsuField or WaterField](
      self: SolveNode[F], goal: Goal, steps: Steps
  ): seq[string] {.inline, noinit.} =
    ## Returns the string representations of the node.
    var strs = newSeqOfCap[string](10)

    strs.add $self.field.rule
    strs.add $goal.toUriQuery.unsafeValue
    strs.add $steps.toUriQuery.unsafeValue

    strs.add $self.depth

    strs.add $self.field.toUriQuery.unsafeValue
    strs.add self.moveResult.toStr

    strs.add self.popColors.toStr
    strs.add $self.popCnt

    strs.add $self.fieldCnts.toStr
    strs.add $self.stepsCnts.toStr

    strs

  func parseMoveResult(str: string): Res[MoveResult] {.inline, noinit.} =
    ## Returns the move result converted from the string representation.
    let errMsg = "Invalid move result: {str}".fmt

    let strs = str.split2 Sep4
    if strs.len != 6:
      return err errMsg & "debug1"

    let chainCnt = ?strs[0].parseInt.context errMsg

    let popCntsStrs = strs[1].split2 Sep1
    if popCntsStrs.len != static(Cell.enumLen):
      return err errMsg & "debug2"
    var popCnts {.noinit.}: array[Cell, int]
    for i, s in popCntsStrs:
      popCnts[Cell.low.succ i].assign ?s.parseInt.context errMsg

    let hardToGarbageCnt = ?strs[2].parseInt.context errMsg

    let detailPopCnts = collect:
      for detailPopCntsStrSeqSeq in strs[3].split2 Sep2:
        let detailPopCntsStrSeq = detailPopCntsStrSeqSeq.split2 Sep1
        if detailPopCntsStrSeq.len != static(Cell.enumLen):
          return err errMsg & "debug3"

        var popCnts {.noinit.}: array[Cell, int]
        for i, s in detailPopCntsStrSeq:
          popCnts[Cell.low.succ i].assign ?s.parseInt.context errMsg

        popCnts

    let detailHardToGarbageCnt = collect:
      for s in strs[4].split2 Sep1:
        ?s.parseInt.context errMsg

    if strs[5] == ErrStr:
      return ok MoveResult.init(
        chainCnt, popCnts, hardToGarbageCnt, detailPopCnts, detailHardToGarbageCnt
      )

    let fullPopCnts = collect:
      for fullPopCntsStrSeqSeq in strs[5].split2 Sep3:
        let fullPopCntsStrSeqs = fullPopCntsStrSeqSeq.split2 Sep2
        if fullPopCntsStrSeqs.len != static(Cell.enumLen):
          return err errMsg & "debug4"

        var cnts {.noinit.}: array[Cell, seq[int]]
        for cellOrd, fullPopCntsStrSeq in fullPopCntsStrSeqs:
          cnts[Cell.low.succ cellOrd].assign fullPopCntsStrSeq.split2(Sep1).mapIt ?it.parseInt.context errMsg

        cnts

    ok MoveResult.init(
      chainCnt, popCnts, hardToGarbageCnt, detailPopCnts, detailHardToGarbageCnt,
      fullPopCnts,
    )

  func parseCells(str: string): Res[set[Cell]] {.inline, noinit.} =
    ## Returns the cells converted from the string representation.
    let errMsg = "Invalid cells: {str}".fmt

    var cells: set[Cell] = {}
    for c in str:
      cells.incl ?($c).parseCell.context errMsg

    ok cells

  func parseCounts(str: string): Res[array[Cell, int]] {.inline, noinit.} =
    ## Returns the counts converted from the string representation.
    let errMsg = "Invalid counts: {str}".fmt

    let strs = str.split2 Sep1
    if strs.len != static(Cell.enumLen):
      return err errMsg

    var arr {.noinit.}: array[Cell, int]
    for i, s in strs:
      arr[Cell.low.succ i].assign ?s.parseInt.context errMsg

    ok arr

  func parseSolveInfo*(
      strs: seq[string]
  ): Res[tuple[rule: Rule, goal: Goal, steps: Steps]] {.inline, noinit.} =
    ## Returns the rule of the solve node converted from the string representations.
    let errMsg = "Invalid solve info: {strs}".fmt

    if strs.len != 10:
      return err errMsg

    ok (
      ?strs[0].parseRule.context errMsg,
      ?strs[1].parseGoal(Pon2).context errMsg,
      ?strs[2].parseSteps(Pon2).context errMsg,
    )

  func parseSolveNode*[F: TsuField or WaterField](
      strs: seq[string]
  ): Res[SolveNode[F]] {.inline, noinit.} =
    ## Returns the solve node converted from the string representations.
    let errMsg = "Invalid node: {strs}".fmt

    if strs.len != 10:
      return err errMsg

    let depth = ?strs[3].parseInt.context errMsg

    let
      field =
        when F is TsuField:
          ?strs[4].parseTsuField(Pon2).context errMsg
        else:
          ?strs[4].parseWaterField(Pon2).context errMsg
      moveResult = ?strs[5].parseMoveResult.context errMsg

    let
      popColors = ?strs[6].parseCells.context errMsg
      popCnt = ?strs[7].parseInt.context errMsg

    let
      fieldCnts = ?strs[8].parseCounts.context errMsg
      stepsCnts = ?strs[9].parseCounts.context errMsg

    ok SolveNode[F].init(
      depth, field, moveResult, popColors, popCnt, fieldCnts, stepsCnts
    )

# ------------------------------------------------
# SolveNode <-> string
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  const NonePlcmtStr = ".."

  func toStrs*(answers: seq[seq[OptPlacement]]): seq[string] {.inline, noinit.} =
    ## Returns the string representations of the answers.
    collect:
      for ans in answers:
        (
          ans.mapIt(
            if it.isOk:
              $it.unsafeValue
            else:
              NonePlcmtStr
          )
        ).join

  func parseSolveAnswers*(
      strs: seq[string]
  ): Res[seq[seq[OptPlacement]]] {.inline, noinit.} =
    ## Returns the answers converted from the run result.
    var answers = newSeqOfCap[seq[OptPlacement]](strs.len)
    for str in strs:
      let errMsg = "Invalid answers: {str}".fmt

      if str.len mod 2 == 1:
        return err errMsg

      let ans = collect:
        for charIdx in countup(0, str.len.pred, 2):
          ?str.substr(charIdx, charIdx.succ).parseOptPlacement.context errMsg
      answers.add ans

    ok answers

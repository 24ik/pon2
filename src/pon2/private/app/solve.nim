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
  popCount: int

  fieldCounts: array[Cell, int]
  stepsCounts: array[Cell, int]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init[F: TsuField or WaterField](
    T: type SolveNode[F],
    depth: int,
    field: F,
    moveResult: MoveResult,
    popColors: set[Cell],
    popCount: int,
    fieldCounts, stepsCounts: array[Cell, int],
): T {.inline, noinit.} =
  T(
    depth: depth,
    field: field,
    moveResult: moveResult,
    popColors: popColors,
    popCount: popCount,
    fieldCounts: fieldCounts,
    stepsCounts: stepsCounts,
  )

func init*[F: TsuField or WaterField](
    T: type SolveNode[F], puyoPuyo: PuyoPuyo[F]
): T {.inline, noinit.} =
  var fieldCounts {.noinit.}, stepsCounts {.noinit.}: array[Cell, int]
  fieldCounts[Cell.None].assign 0
  stepsCounts[Cell.None].assign 0
  staticFor(cell2, Hard .. Cell.Purple):
    fieldCounts[cell2].assign puyoPuyo.field.cellCount cell2
    stepsCounts[cell2].assign puyoPuyo.steps.cellCount cell2

  T.init(0, puyoPuyo.field, static(MoveResult.init), {}, 0, fieldCounts, stepsCounts)

# ------------------------------------------------
# Child
# ------------------------------------------------

const
  DummyCell = Cell.low
  GoalColorToCell: array[GoalColor, Cell] = [
    DummyCell, DummyCell, Cell.Red, Cell.Green, Cell.Blue, Cell.Yellow, Cell.Purple,
    DummyCell, DummyCell,
  ]

template childImpl[F: TsuField or WaterField](
    self: SolveNode[F],
    kind: static GoalKind,
    color: static GoalColor,
    clearColor: static GoalColor,
    step: Step,
    stepKind: static StepKind,
    moveBody: untyped,
): SolveNode[F] =
  ## Returns the child node with `childField` injected.
  ## This function requires that the field is settled.
  ## `stepKind` is used instead of `step.kind`.
  var childField {.inject.} = self.field

  let
    moveResult: MoveResult = moveBody
    childPopColors: set[Cell]
    childPopCount: int
  staticCase:
    case kind
    of AccumColor:
      childPopColors = self.popColors + moveResult.colors
      childPopCount = 0
    of AccumCount:
      let newCount = staticCase:
        case color
        of GoalColor.None, All:
          moveResult.puyoCount
        of Colors:
          moveResult.colorPuyoCount
        of GoalColor.Garbages:
          moveResult.garbagesCount
        else:
          moveResult.cellCount static(GoalColorToCell[color])
      childPopColors = {}
      childPopCount = self.popCount.succ newCount
    else:
      childPopColors = {}
      childPopCount = 0

  var childFieldCounts = self.fieldCounts
  when kind in ColorKinds and color in GoalColor.Red .. GoalColor.Purple:
    const GoalCell = GoalColorToCell[color]
    childFieldCounts[GoalCell].dec moveResult.cellCount GoalCell
  elif clearColor in GoalColor.Red .. GoalColor.Purple:
    const GoalCell = GoalColorToCell[clearColor]
    childFieldCounts[GoalCell].dec moveResult.cellCount GoalCell
  else:
    staticFor(cell2, Cell.Red .. Cell.Purple):
      childFieldCounts[cell2].dec moveResult.cellCount cell2

  var childStepsCounts = self.stepsCounts
  when stepKind == PairPlacement:
    let
      pivotCell = step.pair.pivot
      rotorCell = step.pair.rotor

    childFieldCounts[pivotCell].inc
    childFieldCounts[rotorCell].inc
    childStepsCounts[pivotCell].dec
    childStepsCounts[rotorCell].dec

  when kind in {Count, AccumCount} or clearColor in {All, GoalColor.Garbages}:
    let stepGarbageHardCount, isHard, isGarbage: int
    when stepKind == StepKind.Garbages:
      stepGarbageHardCount = step.garbagesCount
      isHard = step.dropHard.int
      isGarbage = (not step.dropHard).int
    else:
      stepGarbageHardCount = 0
      isHard = 0
      isGarbage = 0

    childFieldCounts[Hard].dec moveResult.popCounts[Hard] + moveResult.hardToGarbageCount -
      stepGarbageHardCount * isHard
    childFieldCounts[Garbage].dec moveResult.popCounts[Garbage] -
      moveResult.hardToGarbageCount - stepGarbageHardCount * isGarbage

    when stepKind == StepKind.Garbages:
      childStepsCounts[Garbage.pred isHard].dec stepGarbageHardCount

  when stepKind == Rotate:
    staticFor(col, Col):
      let cell = self.field[Row0, col]
      childFieldCounts[cell].dec (cell != Cell.None).int

  SolveNode[F].init(
    self.depth.succ, childField, moveResult, childPopColors, childPopCount,
    childFieldCounts, childStepsCounts,
  )

func childPairPlacement[F: TsuField or WaterField](
    self: SolveNode[F],
    kind: static GoalKind,
    color: static GoalColor,
    clearColor: static GoalColor,
    step: Step,
    placement: Placement,
): SolveNode[F] {.inline, noinit.} =
  ## Returns the child node with the `step` edge.
  ## This function requires that the field is settled.
  self.childImpl(kind, color, clearColor, step, PairPlacement):
    childField.move(step.pair, placement, static(kind in {Place, Connection}))

func childGarbages[F: TsuField or WaterField](
    self: SolveNode[F],
    kind: static GoalKind,
    color: static GoalColor,
    clearColor: static GoalColor,
    step: Step,
): SolveNode[F] {.inline, noinit.} =
  ## Returns the child node with the `step` edge.
  ## This function requires that the field is settled.
  self.childImpl(kind, color, clearColor, step, StepKind.Garbages):
    childField.move(step.counts, step.dropHard, static(kind in {Place, Connection}))

func childRotate[F: TsuField or WaterField](
    self: SolveNode[F],
    kind: static GoalKind,
    color: static GoalColor,
    clearColor: static GoalColor,
    step: Step,
): SolveNode[F] {.inline, noinit.} =
  ## Returns the child node with the `step` edge.
  self.childImpl(kind, color, clearColor, step, Rotate):
    childField.move(step.cross, static(kind in {Place, Connection}))

func children[F: TsuField or WaterField](
    self: SolveNode[F],
    kind: static GoalKind,
    color: static GoalColor,
    clearColor: static GoalColor,
    step: Step,
): seq[tuple[node: SolveNode[F], optPlacement: OptPlacement]] {.inline, noinit.} =
  ## Returns the children of the node.
  ## This function requires that the field is settled.
  ## `optPlacement` is set to `NonePlacement` if the edge is non-`PairPlacement`.
  case step.kind
  of PairPlacement:
    let placements =
      if step.pair.isDouble:
        self.field.validDoublePlacements
      else:
        self.field.validPlacements

    placements.mapIt (
      self.childPairPlacement(kind, color, clearColor, step, it), OptPlacement.ok it
    )
  of StepKind.Garbages:
    @[(self.childGarbages(kind, color, clearColor, step), NonePlacement)]
  of Rotate:
    @[(self.childRotate(kind, color, clearColor, step), NonePlacement)]

# ------------------------------------------------
# Accept
# ------------------------------------------------

func cellCount[F: TsuField or WaterField](
    self: SolveNode[F], cell: Cell
): int {.inline, noinit.} =
  ## Returns the number of `cell` in the node.
  self.fieldCounts[cell] + self.stepsCounts[cell]

func garbagesCount[F: TsuField or WaterField](
    self: SolveNode[F]
): int {.inline, noinit.} =
  ## Returns the number of hard and garbage puyos in the node.
  (self.fieldCounts[Hard] + self.fieldCounts[Garbage]) +
    (self.stepsCounts[Hard] + self.stepsCounts[Garbage])

func isAccepted[F: TsuField or WaterField](
    self: SolveNode[F],
    goal: Goal,
    kind: static GoalKind,
    color: static GoalColor,
    valOperator: static GoalValOperator,
    clearColor: static GoalColor,
): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  # check clear
  let fieldCount = staticCase:
    case clearColor
    of GoalColor.None:
      0
    of All:
      self.fieldCounts.sum
    of Colors:
      self.fieldCounts.sum Cell.Red .. Cell.Purple
    of GoalColor.Garbages:
      self.fieldCounts[Hard] + self.fieldCounts[Garbage]
    else:
      self.fieldCounts[static(GoalColorToCell[color])]
  if fieldCount > 0:
    return false

  # check kind-specific
  staticCase:
    case kind
    of GoalKind.None:
      true
    of Chain:
      goal.isSatisfiedChain(self.moveResult, valOperator)
    of Color:
      goal.isSatisfiedColor(self.moveResult, valOperator)
    of Count:
      goal.isSatisfiedCount(self.moveResult, valOperator, color)
    of Place:
      goal.isSatisfiedPlace(self.moveResult, valOperator, color)
    of Connection:
      goal.isSatisfiedConnection(self.moveResult, valOperator, color)
    of AccumColor:
      goal.isSatisfiedAccumColor(self.popColors, valOperator)
    of AccumCount:
      goal.isSatisfiedAccumCount(self.popCount, valOperator)

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
    result.assign x.filter4Nim
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
      result.assign x.filter4Nim

func canPrune[F: TsuField or WaterField](
    self: SolveNode[F],
    goal: Goal,
    kind: static GoalKind,
    color: static GoalColor,
    clearColor: static GoalColor,
): bool {.inline, noinit.} =
  ## Returns `true` if the node is unsolvable.
  # clear
  let canPrune = staticCase:
    case clearColor
    of GoalColor.None:
      false
    of All:
      var
        unpoppableColorExist = false
        poppableColorNotExist = true

      staticFor(cell2, Cell.Red .. Cell.Purple):
        let
          fieldCount = self.fieldCounts[cell2]
          count = fieldCount + self.stepsCounts[cell2]
          countLt4 = count < 4

        poppableColorNotExist.assign poppableColorNotExist and countLt4
        unpoppableColorExist.assign unpoppableColorExist or (
          fieldCount > 0 and countLt4
        )

      unpoppableColorExist or (
        poppableColorNotExist and
        (self.fieldCounts[Hard] + self.fieldCounts[Garbage] > 0)
      )
    of GoalColor.Garbages:
      var poppableColorNotExist = true

      staticFor(cell2, Cell.Red .. Cell.Purple):
        poppableColorNotExist.assign poppableColorNotExist and self.cellCount(cell2) < 4

      poppableColorNotExist and (self.fieldCounts[Hard] + self.fieldCounts[Garbage] > 0)
    of Colors:
      var unpoppableColorExist = false

      staticFor(cell2, Cell.Red .. Cell.Purple):
        let
          fieldCount = self.fieldCounts[cell2]
          count = fieldCount + self.stepsCounts[cell2]

        unpoppableColorExist.assign unpoppableColorExist or
          (fieldCount > 0 and count < 4)

      unpoppableColorExist
    else:
      const GoalCell = GoalColorToCell[color]
      let fieldCount = self.fieldCounts[GoalCell]

      fieldCount > 0 and fieldCount + self.stepsCounts[GoalCell] < 4
  if canPrune:
    return true

  # kind-specific
  staticCase:
    case kind
    of GoalKind.None:
      false
    of Chain:
      let possibleChain = sumIt[Cell, int](Cell.Red .. Cell.Purple):
        self.cellCount(it) div 4
      possibleChain < goal.val
    of Color:
      let possibleColorCount = sumIt[Cell, int](Cell.Red .. Cell.Purple):
        (self.cellCount(it) >= 4).int
      possibleColorCount < goal.val
    of Count, Connection, AccumCount:
      let
        nowPossibleCount = staticCase:
          case color
          of GoalColor.None, All, Colors, GoalColor.Garbages:
            let colorPossibleCount = sumIt[Cell, int](Cell.Red .. Cell.Purple):
              self.cellCount(it).filter4
            staticCase:
              case color
              of GoalColor.None, All:
                colorPossibleCount + (colorPossibleCount > 0).int * self.garbagesCount
              of Colors:
                colorPossibleCount
              of GoalColor.Garbages:
                (colorPossibleCount > 0).int * self.garbagesCount
              else:
                0 # dummy; not reach here
          else:
            self.cellCount(static(GoalColorToCell[color])).filter4

        possibleCount = staticCase:
          case kind
          of Count, Connection:
            nowPossibleCount
          of AccumCount:
            self.popCount + nowPossibleCount
          else:
            0 # dummy; not reach here

      possibleCount < goal.val
    of Place:
      let possiblePlace = staticCase:
        case color
        of GoalColor.None, All, Colors:
          sumIt[Cell, int](Cell.Red .. Cell.Purple):
            self.cellCount(it) div 4
        of GoalColor.Garbages:
          0 # dummy; not support
        else:
          self.cellCount(static(GoalColorToCell[color])) div 4

      possiblePlace < goal.val
    of AccumColor:
      let possibleVal = sumIt[Cell, int](Cell.Red .. Cell.Purple):
        (self.cellCount(it) >= 4).int
      possibleVal < goal.val

# ------------------------------------------------
# Static Getter
# ------------------------------------------------

template withStaticKind(goal: Goal, body: untyped): untyped =
  ## Runs `body` with `StaticKind` exposed.
  case goal.kind
  of GoalKind.None:
    const StaticKind {.inject.} = GoalKind.None
    body
  of Chain:
    const StaticKind {.inject.} = Chain
    body
  of Color:
    const StaticKind {.inject.} = Color
    body
  of Count:
    const StaticKind {.inject.} = Count
    body
  of Place:
    const StaticKind {.inject.} = Place
    body
  of Connection:
    const StaticKind {.inject.} = Connection
    body
  of AccumColor:
    const StaticKind {.inject.} = AccumColor
    body
  of AccumCount:
    const StaticKind {.inject.} = AccumCount
    body

template withStaticColor(goal: Goal, body: untyped): untyped =
  ## Runs `body` with `StaticColor` exposed.
  case goal.color
  of GoalColor.None:
    const StaticColor {.inject.} = GoalColor.None
    body
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

template withStaticValOperator(goal: Goal, body: untyped): untyped =
  ## Runs `body` with `StaticValOperator` exposed.
  case goal.valOperator
  of Exact:
    const StaticValOperator {.inject.} = Exact
    body
  of AtLeast:
    const StaticValOperator {.inject.} = AtLeast
    body

template withStaticClearColor(goal: Goal, body: untyped): untyped =
  ## Runs `body` with `StaticClearColor` exposed.
  case goal.clearColor
  of GoalColor.None:
    const StaticClearColor {.inject.} = GoalColor.None
    body
  of All:
    const StaticClearColor {.inject.} = All
    body
  of GoalColor.Red:
    const StaticClearColor {.inject.} = GoalColor.Red
    body
  of GoalColor.Green:
    const StaticClearColor {.inject.} = GoalColor.Green
    body
  of GoalColor.Blue:
    const StaticClearColor {.inject.} = GoalColor.Blue
    body
  of GoalColor.Yellow:
    const StaticClearColor {.inject.} = GoalColor.Yellow
    body
  of GoalColor.Purple:
    const StaticClearColor {.inject.} = GoalColor.Purple
    body
  of GoalColor.Garbages:
    const StaticClearColor {.inject.} = GoalColor.Garbages
    body
  of Colors:
    const StaticClearColor {.inject.} = Colors
    body

template withStatics(goal: Goal, body: untyped): untyped =
  ## Runs `body` with `StaticKind`, `StaticColor`, `StaticValOperator`, and
  ## `StaticClearColor` exposed.
  goal.withStaticKind:
    goal.withStaticColor:
      goal.withStaticValOperator:
        goal.withStaticClearColor:
          body

# ------------------------------------------------
# Child - Depth
# ------------------------------------------------

func childrenAtDepth[F: TsuField or WaterField](
    self: SolveNode[F],
    targetDepth: int,
    nodes: var seq[SolveNode[F]],
    optPlacementsSeq: var seq[seq[OptPlacement]],
    answers: var seq[seq[OptPlacement]],
    moveCount: int,
    calcAllAnswers: static bool,
    goal: Goal,
    kind: static GoalKind,
    color: static GoalColor,
    valOperator: static GoalValOperator,
    clearColor: static GoalColor,
    steps: Steps,
) {.inline, noinit.} =
  ## Calculates nodes with the given depth and sets them to `nodes`.
  ## A sequence of edges to reach them is set to `optPlacementsSeq`.
  ## Answers that have `targetDepth` or less steps are set to `answers` in reverse
  ## order.
  ## This function requires that the field is settled and `nodes`, `optPlacementsSeq`, and
  ## `answers` are empty.
  let
    step = steps[self.depth]
    childDepth = self.depth.succ
    childIsSpawned = childDepth == targetDepth
    childIsLeaf = childDepth == moveCount
    children = self.children(kind, color, clearColor, step)

  var
    nodesSeq = newSeqOfCap[seq[SolveNode[F]]](children.len)
    optPlacementsSeqSeq = newSeqOfCap[seq[seq[OptPlacement]]](children.len)
    answersSeq = newSeqOfCap[seq[seq[OptPlacement]]](children.len)
  for _ in 1 .. children.len:
    nodesSeq.add newSeqOfCap[SolveNode[F]](static(Placement.enumLen))
    optPlacementsSeqSeq.add newSeqOfCap[seq[OptPlacement]](static(Placement.enumLen))
    answersSeq.add newSeqOfCap[seq[OptPlacement]](static(Placement.enumLen))

  for childIndex, (child, optPlacement) in children.pairs:
    if child.isAccepted(goal, kind, color, valOperator, clearColor):
      var ans = newSeqOfCap[OptPlacement](childDepth)
      ans.add optPlacement

      answers.add ans

      when not calcAllAnswers:
        if answers.len > 1:
          return

      continue

    if childIsLeaf or child.canPrune(goal, kind, color, clearColor):
      continue

    if childIsSpawned:
      nodesSeq[childIndex].add child

      var optPlacements = newSeqOfCap[OptPlacement](childDepth)
      optPlacements.add optPlacement
      optPlacementsSeqSeq[childIndex].add optPlacements
    else:
      child.childrenAtDepth targetDepth,
        nodesSeq[childIndex],
        optPlacementsSeqSeq[childIndex],
        answersSeq[childIndex],
        moveCount,
        calcAllAnswers,
        goal,
        kind,
        color,
        valOperator,
        clearColor,
        steps

      for optPlacements in optPlacementsSeqSeq[childIndex].mitems:
        optPlacements.add optPlacement

    for answer in answersSeq[childIndex].mitems:
      answer.add optPlacement

    when not calcAllAnswers:
      if answers.len + answersSeq[childIndex].len > 1:
        answers &= answersSeq[childIndex]
        return

  nodes &= nodesSeq.concat
  optPlacementsSeq &= optPlacementsSeqSeq.concat
  answers &= answersSeq.concat

func childrenAtDepth*[F: TsuField or WaterField](
    self: SolveNode[F],
    targetDepth: int,
    nodes: var seq[SolveNode[F]],
    optPlacementsSeq: var seq[seq[OptPlacement]],
    answers: var seq[seq[OptPlacement]],
    moveCount: int,
    calcAllAnswers: static bool,
    goal: Goal,
    steps: Steps,
) {.inline, noinit.} =
  ## Calculates nodes with the given depth and sets them to `nodes`.
  ## A sequence of edges to reach them is set to `optPlacementsSeq`.
  ## Answers that have `TargetDepth` or less steps are set to `answers` in reverse
  ## order.
  ## This function requires that the field is settled and `nodes`, `optPlacementsSeq`, and
  ## `answers` are empty.
  goal.withStatics:
    self.childrenAtDepth targetDepth,
      nodes, optPlacementsSeq, answers, moveCount, calcAllAnswers, goal, StaticKind,
      StaticColor, StaticValOperator, StaticClearColor, steps

# ------------------------------------------------
# Solve
# ------------------------------------------------

func solveSingleThread[F: TsuField or WaterField](
    self: SolveNode[F],
    answers: var seq[seq[OptPlacement]],
    moveCount: int,
    calcAllAnswers: static bool,
    goal: Goal,
    kind: static GoalKind,
    color: static GoalColor,
    valOperator: static GoalValOperator,
    clearColor: static GoalColor,
    steps: Steps,
    checkPruneFirst: static bool = false,
) {.inline, noinit.} =
  ## Solves the Nazo Puyo at the node with a single thread.
  ## This function requires that the field is settled and `answers` is empty.
  ## Answers in `answers` are set in reverse order.
  when checkPruneFirst:
    if self.canPrune(goal, kind, color, clearColor):
      return

  let
    step = steps[self.depth]
    childDepth = self.depth.succ
    childIsLeaf = childDepth == moveCount
    children = self.children(kind, color, clearColor, step)

  var childAnswersSeq = newSeqOfCap[seq[seq[OptPlacement]]](children.len)
  for _ in 1 .. children.len:
    childAnswersSeq.add newSeqOfCap[seq[OptPlacement]](static(Placement.enumLen))

  for childIndex, (child, optPlacement) in children.pairs:
    if child.isAccepted(goal, kind, color, valOperator, clearColor):
      var answer = newSeqOfCap[OptPlacement](childDepth)
      answer.add optPlacement

      answers.add answer

      when not calcAllAnswers:
        if answers.len > 1:
          return

      continue

    if childIsLeaf or child.canPrune(goal, kind, color, clearColor):
      continue

    child.solveSingleThread childAnswersSeq[childIndex],
      moveCount,
      calcAllAnswers,
      goal,
      kind,
      color,
      valOperator,
      clearColor,
      steps,
      checkPruneFirst = false

    for answer in childAnswersSeq[childIndex].mitems:
      answer.add optPlacement

    when not calcAllAnswers:
      if answers.len + childAnswersSeq[childIndex].len > 1:
        answers &= childAnswersSeq[childIndex]
        return

  answers &= childAnswersSeq.concat

func solveSingleThread*[F: TsuField or WaterField](
    self: SolveNode[F],
    answers: var seq[seq[OptPlacement]],
    moveCount: int,
    calcAllAnswers: static bool,
    goal: Goal,
    steps: Steps,
    checkPruneFirst: static bool = false,
) {.inline, noinit.} =
  ## Solves the Nazo Puyo at the node with a single thread.
  ## This function requires that the field is settled and `answers` is empty.
  ## Answers in `answers` are set in reverse order.
  goal.withStatics:
    self.solveSingleThread answers,
      moveCount, calcAllAnswers, goal, StaticKind, StaticColor, StaticValOperator,
      StaticClearColor, steps, checkPruneFirst

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

    strs.add $self.chainCount
    strs.add self.popCounts.mapIt($it).join Sep1
    strs.add $self.hardToGarbageCount
    strs.add self.detailPopCounts.mapIt(it.map((count: int) => $count).join Sep1).join Sep2
    strs.add self.detailHardToGarbageCount.mapIt($it).join Sep1
    if self.fullPopCounts.isOk:
      strs.add self.fullPopCounts.unsafeValue.mapIt(
        it.map((counts: seq[int]) => counts.map((count: int) => $count).join Sep1).join Sep2
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
    strs.add $self.popCount

    strs.add $self.fieldCounts.toStr
    strs.add $self.stepsCounts.toStr

    strs

  func parseMoveResult(str: string): StrErrorResult[MoveResult] {.inline, noinit.} =
    ## Returns the move result converted from the string representation.
    let errMsg = "Invalid move result: {str}".fmt

    let strs = str.split2 Sep4
    if strs.len != 6:
      return err errMsg

    let chainCount = ?strs[0].parseInt.context errMsg

    let popCountsStrs = strs[1].split2 Sep1
    if popCountsStrs.len != static(Cell.enumLen):
      return err errMsg
    var popCounts {.noinit.}: array[Cell, int]
    for i, s in popCountsStrs:
      popCounts[Cell.low.succ i].assign ?s.parseInt.context errMsg

    let hardToGarbageCount = ?strs[2].parseInt.context errMsg

    let detailPopCounts = collect:
      for detailPopCountsStrSeqSeq in strs[3].split2 Sep2:
        let detailPopCountsStrSeq = detailPopCountsStrSeqSeq.split2 Sep1
        if detailPopCountsStrSeq.len != static(Cell.enumLen):
          return err errMsg

        var popCounts {.noinit.}: array[Cell, int]
        for i, s in detailPopCountsStrSeq:
          popCounts[Cell.low.succ i].assign ?s.parseInt.context errMsg

        popCounts

    let detailHardToGarbageCount = collect:
      for s in strs[4].split2 Sep1:
        ?s.parseInt.context errMsg

    if strs[5] == ErrStr:
      return ok MoveResult.init(
        chainCount, popCounts, hardToGarbageCount, detailPopCounts,
        detailHardToGarbageCount,
      )

    let fullPopCounts = collect:
      for fullPopCountsStrSeqSeq in strs[5].split2 Sep3:
        let fullPopCountsStrSeqs = fullPopCountsStrSeqSeq.split2 Sep2
        if fullPopCountsStrSeqs.len != static(Cell.enumLen):
          return err errMsg

        var counts {.noinit.}: array[Cell, seq[int]]
        for cellOrd, fullPopCountsStrSeq in fullPopCountsStrSeqs:
          counts[Cell.low.succ cellOrd].assign fullPopCountsStrSeq.split2(Sep1).mapIt ?it.parseInt.context errMsg

        counts

    ok MoveResult.init(
      chainCount, popCounts, hardToGarbageCount, detailPopCounts,
      detailHardToGarbageCount, fullPopCounts,
    )

  func parseCells(str: string): StrErrorResult[set[Cell]] {.inline, noinit.} =
    ## Returns the cells converted from the string representation.
    let errMsg = "Invalid cells: {str}".fmt

    var cells: set[Cell] = {}
    for c in str:
      cells.incl ?($c).parseCell.context errMsg

    ok cells

  func parseCounts(str: string): StrErrorResult[array[Cell, int]] {.inline, noinit.} =
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
  ): StrErrorResult[tuple[rule: Rule, goal: Goal, steps: Steps]] {.inline, noinit.} =
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
  ): StrErrorResult[SolveNode[F]] {.inline, noinit.} =
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
      popCount = ?strs[7].parseInt.context errMsg

    let
      fieldCounts = ?strs[8].parseCounts.context errMsg
      stepsCounts = ?strs[9].parseCounts.context errMsg

    ok SolveNode[F].init(
      depth, field, moveResult, popColors, popCount, fieldCounts, stepsCounts
    )

# ------------------------------------------------
# SolveAnswer <-> string
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  const NonePlacementStr = ".."

  func toStrs*(answers: seq[seq[OptPlacement]]): seq[string] {.inline, noinit.} =
    ## Returns the string representations of the answers.
    collect:
      for ans in answers:
        (
          ans.mapIt(
            if it.isOk:
              $it.unsafeValue
            else:
              NonePlacementStr
          )
        ).join

  func parseSolveAnswers*(
      strs: seq[string]
  ): StrErrorResult[seq[seq[OptPlacement]]] {.inline, noinit.} =
    ## Returns the answers converted from the run result.
    var answers = newSeqOfCap[seq[OptPlacement]](strs.len)
    for str in strs:
      let errMsg = "Invalid answers: {str}".fmt

      if str.len mod 2 == 1:
        return err errMsg

      let ans = collect:
        for charIndex in countup(0, str.len.pred, 2):
          ?str.substr(charIndex, charIndex.succ).parseOptPlacement.context errMsg
      answers.add ans

    ok answers

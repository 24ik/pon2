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

type SolveNode* = object ## Node of solutions search tree.
  depth: int

  field: Field
  moveResult: MoveResult

  popColors: set[Cell]
  popCount: int

  fieldCounts: array[Cell, int]
  stepsCounts: array[Cell, int]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init(
    T: type SolveNode,
    depth: int,
    field: Field,
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

func init*(T: type SolveNode, puyoPuyo: PuyoPuyo): T {.inline, noinit.} =
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
    DummyCell, Cell.Red, Cell.Green, Cell.Blue, Cell.Yellow, Cell.Purple, DummyCell,
    DummyCell,
  ]

func child(self: SolveNode, goal: Goal, step: Step): SolveNode {.inline, noinit.} =
  ## Returns the child node.
  ## This function requires that the field is settled.
  # move
  var childField = self.field
  let moveResult = childField.move(
    step,
    calcConnection =
      goal.mainOpt.isOk and goal.mainOpt.unsafeValue.kind in {Place, Connection},
  )

  # accum
  let
    childPopColors: set[Cell]
    childPopCount: int
  if goal.mainOpt.isOk:
    let main = goal.mainOpt.unsafeValue

    case main.kind
    of AccumColor:
      childPopColors = self.popColors + moveResult.colors
      childPopCount = 0
    of AccumCount:
      let newCount =
        case main.color
        of All:
          moveResult.puyoCount
        of Colors:
          moveResult.colorPuyoCount
        of GoalColor.Garbages:
          moveResult.garbagesCount
        else:
          moveResult.cellCount GoalColorToCell[main.color]
      childPopColors = {}
      childPopCount = self.popCount.succ newCount
    else:
      childPopColors = {}
      childPopCount = 0
  else:
    childPopColors = {}
    childPopCount = 0

  # moveResult
  var childFieldCounts = self.fieldCounts
  staticFor(cell2, Cell.Red .. Cell.Purple):
    childFieldCounts[cell2].dec moveResult.cellCount cell2

  # step
  var childStepsCounts = self.stepsCounts
  if step.kind == PairPlacement:
    let
      pivotCell = step.pair.pivot
      rotorCell = step.pair.rotor

    childFieldCounts[pivotCell].inc
    childFieldCounts[rotorCell].inc
    childStepsCounts[pivotCell].dec
    childStepsCounts[rotorCell].dec

  # garbages
  if (
    goal.clearColorOpt.isOk and
    goal.clearColorOpt.unsafeValue in {All, GoalColor.Garbages}
  ) or (
    goal.mainOpt.isOk and goal.mainOpt.unsafeValue.kind in {Count, AccumCount} and
    goal.mainOpt.unsafeValue.color in {All, GoalColor.Garbages}
  ):
    let stepGarbageHardCount, isHard, isGarbage: int
    if step.kind == StepKind.Garbages:
      stepGarbageHardCount = step.garbagesCount
      isHard = step.dropHard.int
      isGarbage = (not step.dropHard).int

      childStepsCounts[Garbage.pred isHard].dec stepGarbageHardCount
    else:
      stepGarbageHardCount = 0
      isHard = 0
      isGarbage = 0

    childFieldCounts[Hard].dec moveResult.popCounts[Hard] + moveResult.hardToGarbageCount -
      stepGarbageHardCount * isHard
    childFieldCounts[Garbage].dec moveResult.popCounts[Garbage] -
      moveResult.hardToGarbageCount - stepGarbageHardCount * isGarbage

  # rotate
  if step.kind == Rotate:
    staticFor(col, Col):
      let cell = self.field[Row0, col]
      childFieldCounts[cell].dec (cell != None).int

  SolveNode.init(
    self.depth.succ, childField, moveResult, childPopColors, childPopCount,
    childFieldCounts, childStepsCounts,
  )

func children(
    self: SolveNode, goal: Goal, step: Step
): seq[tuple[node: SolveNode, optPlacement: OptPlacement]] {.inline, noinit.} =
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

    placements.mapIt (self.child(goal, Step.init(step.pair, it)), OptPlacement.ok it)
  of StepKind.Garbages, Rotate:
    @[(self.child(goal, step), NonePlacement)]

# ------------------------------------------------
# Accept
# ------------------------------------------------

func cellCount(self: SolveNode, cell: Cell): int {.inline, noinit.} =
  ## Returns the number of `cell` in the node.
  self.fieldCounts[cell] + self.stepsCounts[cell]

func garbagesCount(self: SolveNode): int {.inline, noinit.} =
  ## Returns the number of hard and garbage puyos in the node.
  (self.fieldCounts[Hard] + self.fieldCounts[Garbage]) +
    (self.stepsCounts[Hard] + self.stepsCounts[Garbage])

func isAccepted(self: SolveNode, goal: Goal): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  # check clear
  if goal.clearColorOpt.isOk:
    let
      clearColor = goal.clearColorOpt.unsafeValue
      fieldCount =
        case clearColor
        of All:
          self.fieldCounts.sum
        of Colors:
          self.fieldCounts.sum Cell.Red .. Cell.Purple
        of GoalColor.Garbages:
          self.fieldCounts[Hard] + self.fieldCounts[Garbage]
        else:
          self.fieldCounts[GoalColorToCell[clearColor]]

    if fieldCount > 0:
      return false

  if goal.mainOpt.isErr:
    return true

  # check kind-specific
  case goal.mainOpt.unsafeValue.kind
  of Chain:
    goal.isSatisfiedChain self.moveResult
  of Color:
    goal.isSatisfiedColor self.moveResult
  of Count:
    goal.isSatisfiedCount self.moveResult
  of Place:
    goal.isSatisfiedPlace self.moveResult
  of Connection:
    goal.isSatisfiedConnection self.moveResult
  of AccumColor:
    goal.isSatisfiedAccumColor self.popColors
  of AccumCount:
    goal.isSatisfiedAccumCount self.popCount

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

func canPrune(self: SolveNode, goal: Goal): bool {.inline, noinit.} =
  ## Returns `true` if the node is unsolvable.
  # clear
  if goal.clearColorOpt.isOk:
    let clearColor = goal.clearColorOpt.unsafeValue

    case clearColor
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

      if unpoppableColorExist or (
        poppableColorNotExist and
        (self.fieldCounts[Hard] + self.fieldCounts[Garbage] > 0)
      ):
        return true
    of GoalColor.Garbages:
      var poppableColorNotExist = true

      staticFor(cell2, Cell.Red .. Cell.Purple):
        poppableColorNotExist.assign poppableColorNotExist and self.cellCount(cell2) < 4

      if poppableColorNotExist and
          (self.fieldCounts[Hard] + self.fieldCounts[Garbage] > 0):
        return true
    of Colors:
      var unpoppableColorExist = false

      staticFor(cell2, Cell.Red .. Cell.Purple):
        let
          fieldCount = self.fieldCounts[cell2]
          count = fieldCount + self.stepsCounts[cell2]

        unpoppableColorExist.assign unpoppableColorExist or
          (fieldCount > 0 and count < 4)

      if unpoppableColorExist:
        return true
    else:
      let
        goalCell = GoalColorToCell[clearColor]
        fieldCount = self.fieldCounts[goalCell]

      if fieldCount > 0 and fieldCount + self.stepsCounts[goalCell] < 4:
        return true

  if goal.mainOpt.isErr:
    return false
  let main = goal.mainOpt.unsafeValue

  # kind-specific
  case main.kind
  of Chain:
    let possibleChain = sum(
      self.cellCount(Cell.Red) div 4,
      self.cellCount(Cell.Green) div 4,
      self.cellCount(Cell.Blue) div 4,
      self.cellCount(Cell.Yellow) div 4,
      self.cellCount(Cell.Purple) div 4,
    )
    possibleChain < main.val
  of Color:
    let possibleColorCount = sum(
      (self.cellCount(Cell.Red) >= 4).int,
      (self.cellCount(Cell.Green) >= 4).int,
      (self.cellCount(Cell.Blue) >= 4).int,
      (self.cellCount(Cell.Yellow) >= 4).int,
      (self.cellCount(Cell.Purple) >= 4).int,
    )
    possibleColorCount < main.val
  of Count, Connection, AccumCount:
    let
      nowPossibleCount =
        case main.color
        of All, Colors, GoalColor.Garbages:
          let colorPossibleCount = sum(
            self.cellCount(Cell.Red).filter4,
            self.cellCount(Cell.Green).filter4,
            self.cellCount(Cell.Blue).filter4,
            self.cellCount(Cell.Yellow).filter4,
            self.cellCount(Cell.Purple).filter4,
          )
          case main.color
          of All:
            colorPossibleCount + (colorPossibleCount > 0).int * self.garbagesCount
          of Colors:
            colorPossibleCount
          else: # Garbages
            (colorPossibleCount > 0).int * self.garbagesCount
        else:
          self.cellCount(GoalColorToCell[main.color]).filter4

      possibleCount =
        case main.kind
        of Count, Connection:
          nowPossibleCount
        else: # AccumCount
          self.popCount + nowPossibleCount

    possibleCount < main.val
  of Place:
    let possiblePlace =
      case main.color
      of All, Colors:
        sum(
          self.cellCount(Cell.Red) div 4,
          self.cellCount(Cell.Green) div 4,
          self.cellCount(Cell.Blue) div 4,
          self.cellCount(Cell.Yellow) div 4,
          self.cellCount(Cell.Purple) div 4,
        )
      else:
        self.cellCount(GoalColorToCell[main.color]) div 4

    possiblePlace < main.val
  of AccumColor:
    let possibleVal = sum(
      (self.cellCount(Cell.Red) >= 4).int,
      (self.cellCount(Cell.Green) >= 4).int,
      (self.cellCount(Cell.Blue) >= 4).int,
      (self.cellCount(Cell.Yellow) >= 4).int,
      (self.cellCount(Cell.Purple) >= 4).int,
    )
    possibleVal < main.val

# ------------------------------------------------
# Child - Depth
# ------------------------------------------------

func childrenAtDepth*(
    self: SolveNode,
    targetDepth: int,
    nodes: var seq[SolveNode],
    optPlacementsSeq: var seq[seq[OptPlacement]],
    answers: var seq[seq[OptPlacement]],
    moveCount: int,
    calcAllAnswers: bool,
    goal: Goal,
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
    children = self.children(goal, step)
    childCount = children.len

  var
    nodesSeq = newSeqOfCap[seq[SolveNode]](childCount)
    optPlacementsSeqSeq = newSeqOfCap[seq[seq[OptPlacement]]](childCount)
    answersSeq = newSeqOfCap[seq[seq[OptPlacement]]](childCount)
  for _ in 1 .. childCount:
    nodesSeq.add newSeqOfCap[SolveNode](static(Placement.enumLen))
    optPlacementsSeqSeq.add newSeqOfCap[seq[OptPlacement]](static(Placement.enumLen))
    answersSeq.add newSeqOfCap[seq[OptPlacement]](static(Placement.enumLen))

  for childIndex, (child, optPlacement) in children.pairs:
    if child.isAccepted goal:
      var answer = newSeqOfCap[OptPlacement](childDepth)
      answer.add optPlacement

      answers.add answer

      if not calcAllAnswers and answers.len > 1:
        return

      continue

    if childIsLeaf or child.canPrune goal:
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
        steps

      for optPlacements in optPlacementsSeqSeq[childIndex].mitems:
        optPlacements.add optPlacement

    for answer in answersSeq[childIndex].mitems:
      answer.add optPlacement

    if not calcAllAnswers and answers.len + answersSeq[childIndex].len > 1:
      answers &= answersSeq[childIndex]
      return

  nodes &= nodesSeq.concat
  optPlacementsSeq &= optPlacementsSeqSeq.concat
  answers &= answersSeq.concat

# ------------------------------------------------
# Solve
# ------------------------------------------------

func solveSingleThread*(
    self: SolveNode,
    answers: var seq[seq[OptPlacement]],
    moveCount: int,
    calcAllAnswers: bool,
    goal: Goal,
    steps: Steps,
    checkPruneFirst = false,
) {.inline, noinit.} =
  ## Solves the Nazo Puyo at the node with a single thread.
  ## This function requires that the field is settled and `answers` is empty.
  ## Answers in `answers` are set in reverse order.
  if checkPruneFirst and self.canPrune goal:
    return

  let
    step = steps[self.depth]
    childDepth = self.depth.succ
    childIsLeaf = childDepth == moveCount
    children = self.children(goal, step)

  var childAnswersSeq = newSeqOfCap[seq[seq[OptPlacement]]](children.len)
  for _ in 1 .. children.len:
    childAnswersSeq.add newSeqOfCap[seq[OptPlacement]](static(Placement.enumLen))

  for childIndex, (child, optPlacement) in children.pairs:
    if child.isAccepted goal:
      var answer = newSeqOfCap[OptPlacement](childDepth)
      answer.add optPlacement

      answers.add answer

      if not calcAllAnswers and answers.len > 1:
        return

      continue

    if childIsLeaf or child.canPrune goal:
      continue

    child.solveSingleThread(
      childAnswersSeq[childIndex],
      moveCount,
      calcAllAnswers,
      goal,
      steps,
      checkPruneFirst = false,
    )

    for answer in childAnswersSeq[childIndex].mitems:
      answer.add optPlacement

    if not calcAllAnswers and answers.len + childAnswersSeq[childIndex].len > 1:
      answers &= childAnswersSeq[childIndex]
      return

  answers &= childAnswersSeq.concat

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
    if self.fullPopCountsOpt.isOk:
      strs.add self.fullPopCountsOpt.unsafeValue.mapIt(
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

  func toStrs*(
      self: SolveNode, goal: Goal, steps: Steps
  ): seq[string] {.inline, noinit.} =
    ## Returns the string representations of the node.
    var strs = newSeqOfCap[string](9)

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
    let errorMsg = "Invalid move result: {str}".fmt

    let strs = str.split2 Sep4
    if strs.len != 6:
      return err errorMsg

    let chainCount = ?strs[0].parseInt.context errorMsg

    let popCountsStrs = strs[1].split2 Sep1
    if popCountsStrs.len != static(Cell.enumLen):
      return err errorMsg
    var popCounts {.noinit.}: array[Cell, int]
    for i, s in popCountsStrs:
      popCounts[Cell.low.succ i].assign ?s.parseInt.context errorMsg

    let hardToGarbageCount = ?strs[2].parseInt.context errorMsg

    let detailPopCounts = collect:
      for detailPopCountsStrSeqSeq in strs[3].split2 Sep2:
        let detailPopCountsStrSeq = detailPopCountsStrSeqSeq.split2 Sep1
        if detailPopCountsStrSeq.len != static(Cell.enumLen):
          return err errorMsg

        var popCounts {.noinit.}: array[Cell, int]
        for i, s in detailPopCountsStrSeq:
          popCounts[Cell.low.succ i].assign ?s.parseInt.context errorMsg

        popCounts

    let detailHardToGarbageCount = collect:
      for s in strs[4].split2 Sep1:
        ?s.parseInt.context errorMsg

    if strs[5] == ErrStr:
      return ok MoveResult.init(
        chainCount, popCounts, hardToGarbageCount, detailPopCounts,
        detailHardToGarbageCount,
      )

    let fullPopCounts = collect:
      for fullPopCountsStrSeqSeq in strs[5].split2 Sep3:
        let fullPopCountsStrSeqs = fullPopCountsStrSeqSeq.split2 Sep2
        if fullPopCountsStrSeqs.len != static(Cell.enumLen):
          return err errorMsg

        var counts {.noinit.}: array[Cell, seq[int]]
        for cellOrd, fullPopCountsStrSeq in fullPopCountsStrSeqs:
          counts[Cell.low.succ cellOrd].assign fullPopCountsStrSeq.split2(Sep1).mapIt ?it.parseInt.context errorMsg

        counts

    ok MoveResult.init(
      chainCount, popCounts, hardToGarbageCount, detailPopCounts,
      detailHardToGarbageCount, fullPopCounts,
    )

  func parseCells(str: string): StrErrorResult[set[Cell]] {.inline, noinit.} =
    ## Returns the cells converted from the string representation.
    let errorMsg = "Invalid cells: {str}".fmt

    var cells: set[Cell] = {}
    for c in str:
      cells.incl ?($c).parseCell.context errorMsg

    ok cells

  func parseCounts(str: string): StrErrorResult[array[Cell, int]] {.inline, noinit.} =
    ## Returns the counts converted from the string representation.
    let errorMsg = "Invalid counts: {str}".fmt

    let strs = str.split2 Sep1
    if strs.len != static(Cell.enumLen):
      return err errorMsg

    var arr {.noinit.}: array[Cell, int]
    for i, s in strs:
      arr[Cell.low.succ i].assign ?s.parseInt.context errorMsg

    ok arr

  func parseSolveInfo*(
      strs: seq[string]
  ): StrErrorResult[tuple[goal: Goal, steps: Steps]] {.inline, noinit.} =
    ## Returns the rule of the solve node converted from the string representations.
    let errorMsg = "Invalid solve info: {strs}".fmt

    if strs.len != 9:
      return err errorMsg

    ok (
      ?strs[0].parseGoal(Pon2).context errorMsg,
      ?strs[1].parseSteps(Pon2).context errorMsg,
    )

  func parseSolveNode*(
      strs: seq[string]
  ): StrErrorResult[SolveNode] {.inline, noinit.} =
    ## Returns the solve node converted from the string representations.
    let errorMsg = "Invalid node: {strs}".fmt

    if strs.len != 9:
      return err errorMsg

    let
      depth = ?strs[2].parseInt.context errorMsg

      field = ?strs[3].parseField(Pon2).context errorMsg
      moveResult = ?strs[4].parseMoveResult.context errorMsg

      popColors = ?strs[5].parseCells.context errorMsg
      popCount = ?strs[6].parseInt.context errorMsg

      fieldCounts = ?strs[7].parseCounts.context errorMsg
      stepsCounts = ?strs[8].parseCounts.context errorMsg

    ok SolveNode.init(
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
      let errorMsg = "Invalid answers: {str}".fmt

      if str.len mod 2 == 1:
        return err errorMsg

      let ans = collect:
        for charIndex in countup(0, str.len.pred, 2):
          ?str.substr(charIndex, charIndex.succ).parseOptPlacement.context errorMsg
      answers.add ans

    ok answers

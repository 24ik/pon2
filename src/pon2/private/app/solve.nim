## This module implements helpers for Nazo Puyo solving.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils]
import ../../[core]
import ../../private/[assign, core, macros, math, staticfor]

when defined(js) or defined(nimsuggest):
  import std/[strformat, sugar, typetraits]
  import ../../[utils]
  import ../../private/[strutils]

  export core, utils

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

func init*(T: type SolveNode, nazoPuyo: NazoPuyo): T {.inline, noinit.} =
  var fieldCounts {.noinit.}, stepsCounts {.noinit.}: array[Cell, int]
  fieldCounts[Cell.None].assign 0
  stepsCounts[Cell.None].assign 0
  staticFor(cell2, Puyos):
    fieldCounts[cell2].assign nazoPuyo.puyoPuyo.field.cellCount cell2
    stepsCounts[cell2].assign nazoPuyo.puyoPuyo.steps.cellCount cell2

  T.init(0, nazoPuyo.puyoPuyo.field, MoveResult.init, {}, 0, fieldCounts, stepsCounts)

# ------------------------------------------------
# Child
# ------------------------------------------------

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
        of Nuisance:
          moveResult.nuisancePuyoCount
        of Colored:
          moveResult.coloredPuyoCount
        else:
          moveResult.cellCount main.color.ord.Cell
      childPopColors = {}
      childPopCount = self.popCount + newCount
    else:
      childPopColors = {}
      childPopCount = 0
  else:
    childPopColors = {}
    childPopCount = 0

  # moveResult
  var childFieldCounts = self.fieldCounts
  staticFor(cell2, ColoredPuyos):
    childFieldCounts[cell2] -= moveResult.cellCount cell2

  # step
  var childStepsCounts = self.stepsCounts
  if step.kind == PairPlace:
    let
      pivotCell = step.pair.pivot
      rotorCell = step.pair.rotor

    childFieldCounts[pivotCell] += 1
    childFieldCounts[rotorCell] += 1
    childStepsCounts[pivotCell] -= 1
    childStepsCounts[rotorCell] -= 1

  # nuisance
  if (goal.clearColorOpt.isOk and goal.clearColorOpt.unsafeValue in {All, Nuisance}) or (
    goal.mainOpt.isOk and goal.mainOpt.unsafeValue.kind in {Count, AccumCount} and
    goal.mainOpt.unsafeValue.color in {All, Nuisance}
  ):
    let stepNuisanceCount, isHard, isGarbage: int
    if step.kind == NuisanceDrop:
      stepNuisanceCount = step.nuisancePuyoCount
      isHard = step.hard.int
      isGarbage = (not step.hard).int

      childStepsCounts[Garbage.pred isHard] -= stepNuisanceCount
    else:
      stepNuisanceCount = 0
      isHard = 0
      isGarbage = 0

    childFieldCounts[Hard] -=
      moveResult.popCounts[Hard] + moveResult.hardToGarbageCount -
      stepNuisanceCount * isHard
    childFieldCounts[Garbage] -=
      moveResult.popCounts[Garbage] - moveResult.hardToGarbageCount -
      stepNuisanceCount * isGarbage

  # rotate
  if step.kind == FieldRotate:
    staticFor(col, Col):
      let cell = self.field[Row0, col]
      childFieldCounts[cell] -= (cell != Cell.None).int

  SolveNode.init(
    self.depth + 1,
    childField,
    moveResult,
    childPopColors,
    childPopCount,
    childFieldCounts,
    childStepsCounts,
  )

func children(
    self: SolveNode, goal: Goal, step: Step
): seq[tuple[node: SolveNode, placement: Placement]] {.inline, noinit.} =
  ## Returns the children of the node.
  ## This function requires that the field is settled.
  ## `placement` is set to `Placement.None` if the edge is not `PairPlace`.
  case step.kind
  of PairPlace:
    let placements =
      if step.pair.isDouble:
        self.field.validDoublePlacements
      else:
        self.field.validPlacements

    placements.mapIt (self.child(goal, Step.init(step.pair, it)), it)
  of NuisanceDrop, FieldRotate:
    @[(self.child(goal, step), Placement.None)]

# ------------------------------------------------
# Correct
# ------------------------------------------------

func cellCount(self: SolveNode, cell: Cell): int {.inline, noinit.} =
  ## Returns the number of `cell` in the node.
  self.fieldCounts[cell] + self.stepsCounts[cell]

func nuisancePuyoCount(self: SolveNode): int {.inline, noinit.} =
  ## Returns the number of hard and garbage puyos in the node.
  sum(
    self.fieldCounts[Hard],
    self.fieldCounts[Garbage],
    self.stepsCounts[Hard],
    self.stepsCounts[Garbage],
  )

func isCorrect(self: SolveNode, goal: Goal): bool {.inline, noinit.} =
  ## Returns `true` if the goal is satisfied.
  # check clear
  if goal.clearColorOpt.isOk:
    let
      clearColor = goal.clearColorOpt.unsafeValue
      fieldCount =
        case clearColor
        of All:
          self.fieldCounts.sum
        of Nuisance:
          self.fieldCounts[Hard] + self.fieldCounts[Garbage]
        of Colored:
          ColoredPuyos.sumIt self.fieldCounts[it]
        else:
          self.fieldCounts[clearColor.ord.Cell]

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

      staticFor(cell2, ColoredPuyos):
        let
          fieldCount = self.fieldCounts[cell2]
          count = fieldCount + self.stepsCounts[cell2]
          countLessThan4 = count < 4

        poppableColorNotExist.assign poppableColorNotExist and countLessThan4
        unpoppableColorExist.assign unpoppableColorExist or
          (fieldCount > 0 and countLessThan4)

      if unpoppableColorExist or (
        poppableColorNotExist and
        (self.fieldCounts[Hard] + self.fieldCounts[Garbage] > 0)
      ):
        return true
    of Nuisance:
      var poppableColorNotExist = true

      staticFor(cell2, ColoredPuyos):
        poppableColorNotExist.assign poppableColorNotExist and self.cellCount(cell2) < 4

      if poppableColorNotExist and
          (self.fieldCounts[Hard] + self.fieldCounts[Garbage] > 0):
        return true
    of Colored:
      var unpoppableColorExist = false

      staticFor(cell2, ColoredPuyos):
        let
          fieldCount = self.fieldCounts[cell2]
          count = fieldCount + self.stepsCounts[cell2]

        unpoppableColorExist.assign unpoppableColorExist or
          (fieldCount > 0 and count < 4)

      if unpoppableColorExist:
        return true
    else:
      let
        goalCell = clearColor.ord.Cell
        fieldCount = self.fieldCounts[goalCell]

      if fieldCount > 0 and fieldCount + self.stepsCounts[goalCell] < 4:
        return true

  if goal.mainOpt.isErr:
    return false
  let main = goal.mainOpt.unsafeValue

  # kind-specific
  case main.kind
  of Chain:
    ColoredPuyos.sumIt(self.cellCount(it) div 4) < main.val
  of Color:
    ColoredPuyos.sumIt((self.cellCount(it) >= 4).int) < main.val
  of Count, Connection, AccumCount:
    let
      nowPossibleCount =
        case main.color
        of All, Nuisance, Colored:
          let coloredPossibleCount = ColoredPuyos.sumIt(self.cellCount(it).filter4)
          case main.color
          of All:
            coloredPossibleCount +
              (coloredPossibleCount > 0).int * self.nuisancePuyoCount
          of Nuisance:
            (coloredPossibleCount > 0).int * self.nuisancePuyoCount
          else: # Colored
            coloredPossibleCount
        else:
          self.cellCount(main.color.ord.Cell).filter4

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
      of All, Colored:
        ColoredPuyos.sumIt self.cellCount(it) div 4
      else:
        self.cellCount(main.color.ord.Cell) div 4

    possiblePlace < main.val
  of AccumColor:
    ColoredPuyos.sumIt((self.cellCount(it) >= 4).int) < main.val

# ------------------------------------------------
# Child - Depth
# ------------------------------------------------

func childrenAtDepth*(
    self: SolveNode,
    targetDepth: int,
    nodes: var seq[SolveNode],
    placementsSeq: var seq[seq[Placement]],
    solutions: var seq[seq[Placement]],
    moveCount: int,
    calcAllSolutions: bool,
    goal: Goal,
    steps: Steps,
) {.inline, noinit.} =
  ## Calculates nodes with the given depth and sets them to `nodes`.
  ## A sequence of edges to reach them is set to `placementsSeq`.
  ## Solutions that have `targetDepth` or less steps are set to `solutions` in reverse
  ## order.
  ## This function requires that the field is settled and `nodes`, `placementsSeq`, and
  ## `solutions` are empty.
  let
    step = steps[self.depth]
    childDepth = self.depth + 1
    childIsSpawned = childDepth == targetDepth
    childIsLeaf = childDepth == moveCount
    children = self.children(goal, step)
    childCount = children.len

  var
    nodesSeq = newSeqOfCap[seq[SolveNode]](childCount)
    placementsSeqSeq = newSeqOfCap[seq[seq[Placement]]](childCount)
    solutionsSeq = newSeqOfCap[seq[seq[Placement]]](childCount)
  for _ in 1 .. childCount:
    nodesSeq.add newSeqOfCap[SolveNode](ActualPlacements.card)
    placementsSeqSeq.add newSeqOfCap[seq[Placement]](ActualPlacements.card)
    solutionsSeq.add newSeqOfCap[seq[Placement]](ActualPlacements.card)

  for childIndex, (child, placement) in children.pairs:
    if child.isCorrect goal:
      var solution = newSeqOfCap[Placement](childDepth)
      solution.add placement

      solutions.add solution

      if not calcAllSolutions and solutions.len > 1:
        return

      continue

    if childIsLeaf or child.canPrune goal:
      continue

    if childIsSpawned:
      nodesSeq[childIndex].add child

      var placements = newSeqOfCap[Placement](childDepth)
      placements.add placement
      placementsSeqSeq[childIndex].add placements
    else:
      child.childrenAtDepth targetDepth,
        nodesSeq[childIndex],
        placementsSeqSeq[childIndex],
        solutionsSeq[childIndex],
        moveCount,
        calcAllSolutions,
        goal,
        steps

      for placements in placementsSeqSeq[childIndex].mitems:
        placements.add placement

    for solution in solutionsSeq[childIndex].mitems:
      solution.add placement

    if not calcAllSolutions and solutions.len + solutionsSeq[childIndex].len > 1:
      solutions &= solutionsSeq[childIndex]
      return

  nodes &= nodesSeq.concat
  placementsSeq &= placementsSeqSeq.concat
  solutions &= solutionsSeq.concat

# ------------------------------------------------
# Solve
# ------------------------------------------------

func solveSingleThread*(
    self: SolveNode,
    solutions: var seq[seq[Placement]],
    moveCount: int,
    calcAllSolutions: bool,
    goal: Goal,
    steps: Steps,
    checkPruneFirst = false,
) {.inline, noinit.} =
  ## Solves the Nazo Puyo at the node with a single thread.
  ## This function requires that the field is settled and `solutions` is empty.
  ## Solutions in `solutions` are set in reverse order.
  if checkPruneFirst and self.canPrune goal:
    return

  let
    step = steps[self.depth]
    childDepth = self.depth + 1
    childIsLeaf = childDepth == moveCount
    children = self.children(goal, step)

  var childSolutionsSeq = newSeqOfCap[seq[seq[Placement]]](children.len)
  for _ in 1 .. children.len:
    childSolutionsSeq.add newSeqOfCap[seq[Placement]](ActualPlacements.card)

  for childIndex, (child, placement) in children.pairs:
    if child.isCorrect goal:
      var solution = newSeqOfCap[Placement](childDepth)
      solution.add placement

      solutions.add solution

      if not calcAllSolutions and solutions.len > 1:
        return

      continue

    if childIsLeaf or child.canPrune goal:
      continue

    child.solveSingleThread(
      childSolutionsSeq[childIndex],
      moveCount,
      calcAllSolutions,
      goal,
      steps,
      checkPruneFirst = false,
    )

    for solution in childSolutionsSeq[childIndex].mitems:
      solution.add placement

    if not calcAllSolutions and solutions.len + childSolutionsSeq[childIndex].len > 1:
      solutions &= childSolutionsSeq[childIndex]
      return

  solutions &= childSolutionsSeq.concat

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

  func parseMoveResult(str: string): Pon2Result[MoveResult] {.inline, noinit.} =
    ## Returns the move result converted from the string representation.
    let errorMsg = "Invalid move result: {str}".fmt

    let strs = str.split2 Sep4
    if strs.len != 6:
      return err errorMsg

    let chainCount = ?strs[0].parseInt.context errorMsg

    let popCountsStrs = strs[1].split2 Sep1
    if popCountsStrs.len != Cell.enumLen:
      return err errorMsg
    var popCounts {.noinit.}: array[Cell, int]
    for i, s in popCountsStrs:
      popCounts[i.Cell].assign ?s.parseInt.context errorMsg

    let hardToGarbageCount = ?strs[2].parseInt.context errorMsg

    let detailPopCounts = collect:
      for detailPopCountsStrSeqSeq in strs[3].split2 Sep2:
        let detailPopCountsStrSeq = detailPopCountsStrSeqSeq.split2 Sep1
        if detailPopCountsStrSeq.len != Cell.enumLen:
          return err errorMsg

        var popCounts {.noinit.}: array[Cell, int]
        for i, s in detailPopCountsStrSeq:
          popCounts[i.Cell].assign ?s.parseInt.context errorMsg

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
        if fullPopCountsStrSeqs.len != Cell.enumLen:
          return err errorMsg

        var counts {.noinit.}: array[Cell, seq[int]]
        for cellOrd, fullPopCountsStrSeq in fullPopCountsStrSeqs:
          counts[cellOrd.Cell].assign fullPopCountsStrSeq.split2(Sep1).mapIt ?it.parseInt.context errorMsg

        counts

    ok MoveResult.init(
      chainCount, popCounts, hardToGarbageCount, detailPopCounts,
      detailHardToGarbageCount, fullPopCounts,
    )

  func parseCells(str: string): Pon2Result[set[Cell]] {.inline, noinit.} =
    ## Returns the cells converted from the string representation.
    let errorMsg = "Invalid cells: {str}".fmt

    var cells: set[Cell] = {}
    for c in str:
      cells.incl ?($c).parseCell.context errorMsg

    ok cells

  func parseCounts(str: string): Pon2Result[array[Cell, int]] {.inline, noinit.} =
    ## Returns the counts converted from the string representation.
    let errorMsg = "Invalid counts: {str}".fmt

    let strs = str.split2 Sep1
    if strs.len != Cell.enumLen:
      return err errorMsg

    var counts {.noinit.}: array[Cell, int]
    for i, s in strs:
      counts[i.Cell].assign ?s.parseInt.context errorMsg

    ok counts

  func parseSolveInfo*(
      strs: seq[string]
  ): Pon2Result[tuple[goal: Goal, steps: Steps]] {.inline, noinit.} =
    ## Returns the rule of the solve node converted from the string representations.
    let errorMsg = "Invalid solve info: {strs}".fmt

    if strs.len != 9:
      return err errorMsg

    ok (
      ?strs[0].parseGoal(Pon2).context errorMsg,
      ?strs[1].parseSteps(Pon2).context errorMsg,
    )

  func parseSolveNode*(strs: seq[string]): Pon2Result[SolveNode] {.inline, noinit.} =
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
# SolveSolution <-> string
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  const NonePlacementStr = ".."

  func toStrs*(solutions: seq[seq[Placement]]): seq[string] {.inline, noinit.} =
    ## Returns the string representations of the solutions.
    collect:
      for solution in solutions:
        (
          solution.mapIt(
            case it
            of Placement.None:
              NonePlacementStr
            else:
              $it
          )
        ).join

  func parseSolutions*(
      strs: seq[string]
  ): Pon2Result[seq[seq[Placement]]] {.inline, noinit.} =
    ## Returns the solutions converted from the run result.
    var solutions = newSeqOfCap[seq[Placement]](strs.len)
    for str in strs:
      let errorMsg = "Invalid solutions: {str}".fmt

      if str.len mod 2 == 1:
        return err errorMsg

      let solution = collect:
        for charIndex in countup(0, str.len - 1, 2):
          let s = str[charIndex ..< charIndex + 2]
          if s == NonePlacementStr:
            Placement.None
          else:
            ?s.parsePlacement.context errorMsg
      solutions.add solution

    ok solutions

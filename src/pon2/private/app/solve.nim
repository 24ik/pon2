## This module implements solutions search trees of Nazo Puyo solvers.
## 

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[algorithm, sequtils]
import ../../[core]
import ../../private/[assign3, core, macros2, math2, staticfor2]

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

# TODO: iterator?
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
      var zero {.noinit.}: int
      asm """
xor %2, %2
cmp $4, %1
cmovl %2, %0
: "=&r"(`result`)
: "0"(`x`), "r"(`zero`)"""
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

func solve[F: TsuField or WaterField](
    self: SolveNode[F],
    answers: out seq[SolveAnswer],
    moveCnt: int,
    earlyStopping: static bool,
    goal: Goal,
    kind: static GoalKind,
    color: static GoalColor,
    steps: Steps,
    isZeroDepth: static bool,
) {.inline.} =
  ## Solves the nazo puyo.
  ## This function requires that the field is settled and `answers` is empty.
  when isZeroDepth:
    if self.canPrune(goal, kind, color, true):
      return

  let step = steps[self.depth]

  for (child, optPlcmt) in self.children(kind, color, step):
    if child.isAccepted(goal, kind, color):
      answers.add @[optPlcmt]
      continue

    if self.depth == moveCnt.pred:
      continue

    if child.canPrune(goal, kind, color, false):
      continue

    var childAnswers = newSeq[SolveAnswer]()
    child.solve(childAnswers, moveCnt, earlyStopping, goal, kind, color, steps, false)

    for ans in childAnswers.mitems:
      ans.add optPlcmt

    answers &= childAnswers

    when earlyStopping:
      if answers.len > 1:
        return

func solve[F: TsuField or WaterField](
    self: SolveNode[F],
    answers: out seq[SolveAnswer],
    moveCnt: int,
    earlyStopping: static bool,
    goal: Goal,
    kind: static GoalKind,
    steps: Steps,
    isZeroDepth: static bool,
) {.inline.} =
  ## Solves the nazo puyo.
  ## This function requires that the field is settled and `answers` is empty.
  case goal.optColor.expect
  of All:
    self.solve(answers, moveCnt, earlyStopping, goal, kind, All, steps, isZeroDepth)
  of GoalColor.Red:
    self.solve(
      answers, moveCnt, earlyStopping, goal, kind, GoalColor.Red, steps, isZeroDepth
    )
  of GoalColor.Green:
    self.solve(
      answers, moveCnt, earlyStopping, goal, kind, GoalColor.Green, steps, isZeroDepth
    )
  of GoalColor.Blue:
    self.solve(
      answers, moveCnt, earlyStopping, goal, kind, GoalColor.Blue, steps, isZeroDepth
    )
  of GoalColor.Yellow:
    self.solve(
      answers, moveCnt, earlyStopping, goal, kind, GoalColor.Yellow, steps, isZeroDepth
    )
  of GoalColor.Purple:
    self.solve(
      answers, moveCnt, earlyStopping, goal, kind, GoalColor.Purple, steps, isZeroDepth
    )
  of GoalColor.Garbages:
    self.solve(
      answers, moveCnt, earlyStopping, goal, kind, GoalColor.Garbages, steps,
      isZeroDepth,
    )
  of Colors:
    self.solve(answers, moveCnt, earlyStopping, goal, kind, Colors, steps, isZeroDepth)

func solve[F: TsuField or WaterField](
    self: SolveNode[F],
    answers: out seq[SolveAnswer],
    moveCnt: int,
    earlyStopping: static bool,
    goal: Goal,
    steps: Steps,
    isZeroDepth: static bool,
) {.inline.} =
  ## Solves the nazo puyo.
  ## This function requires that the field is settled and `answers` is empty.
  const DummyColor = All

  case goal.kind
  of Clear:
    self.solve(answers, moveCnt, earlyStopping, goal, Clear, steps, isZeroDepth)
  of AccColor:
    self.solve(
      answers, moveCnt, earlyStopping, goal, AccColor, DummyColor, steps, isZeroDepth
    )
  of AccColorMore:
    self.solve(
      answers, moveCnt, earlyStopping, goal, AccColorMore, DummyColor, steps,
      isZeroDepth,
    )
  of AccCnt:
    self.solve(answers, moveCnt, earlyStopping, goal, AccCnt, steps, isZeroDepth)
  of AccCntMore:
    self.solve(answers, moveCnt, earlyStopping, goal, AccCntMore, steps, isZeroDepth)
  of Chain:
    self.solve(
      answers, moveCnt, earlyStopping, goal, Chain, DummyColor, steps, isZeroDepth
    )
  of ChainMore:
    self.solve(
      answers, moveCnt, earlyStopping, goal, ChainMore, DummyColor, steps, isZeroDepth
    )
  of ClearChain:
    self.solve(answers, moveCnt, earlyStopping, goal, ClearChain, steps, isZeroDepth)
  of ClearChainMore:
    self.solve(
      answers, moveCnt, earlyStopping, goal, ClearChainMore, steps, isZeroDepth
    )
  of Color:
    self.solve(
      answers, moveCnt, earlyStopping, goal, Color, DummyColor, steps, isZeroDepth
    )
  of ColorMore:
    self.solve(
      answers, moveCnt, earlyStopping, goal, ColorMore, DummyColor, steps, isZeroDepth
    )
  of Cnt:
    self.solve(answers, moveCnt, earlyStopping, goal, Cnt, steps, isZeroDepth)
  of CntMore:
    self.solve(answers, moveCnt, earlyStopping, goal, CntMore, steps, isZeroDepth)
  of Place:
    self.solve(answers, moveCnt, earlyStopping, goal, Place, steps, isZeroDepth)
  of PlaceMore:
    self.solve(answers, moveCnt, earlyStopping, goal, PlaceMore, steps, isZeroDepth)
  of Conn:
    self.solve(answers, moveCnt, earlyStopping, goal, Conn, steps, isZeroDepth)
  of ConnMore:
    self.solve(answers, moveCnt, earlyStopping, goal, ConnMore, steps, isZeroDepth)

func solve*[F: TsuField or WaterField](
    self: SolveNode[F], earlyStopping: static bool, goal: Goal, steps: Steps
): seq[SolveAnswer] {.inline.} =
  ## Solves the nazo puyo.
  ## This function requires that the field is settled.
  if not goal.isSupported or steps.len == 0:
    return @[]

  var answers = newSeq[SolveAnswer]()
  self.solve(answers, steps.len, earlyStopping, goal, steps, true)

  # NOTE: somehow `applyIt` does not work (maybe Nim's bug)
  for answer in answers.mitems:
    answer.reverse

  answers

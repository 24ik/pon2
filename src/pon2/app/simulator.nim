## This module implements simulators.
##
## Compile Options:
## | Option               | Description             | Default                |
## | -------------------- | ----------------------- | ---------------------- |
## | `-d:pon2.path=<str>` | Path of the web studio. | `/pon2/stable/studio/` |
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, strformat, sugar, uri]
import ./[key]
import ../[core]
import
  ../private/[algorithm, arrayutils, assign, deques, staticfor, strutils, tables, utils]

export core, uri

type
  SimulatorMode* {.pure.} = enum
    ## Simulator's mode.
    ViewerPlay
    ViewerEdit
    EditorPlay
    EditorEdit
    Replay

  SimulatorState* {.pure.} = enum
    ## Simulator's state.
    Stable
    WillPop
    WillSettle
    AfterEdit

  SimulatorEditObjKind* {.pure.} = enum
    ## Kind of edit objects.
    EditCell
    EditRotate

  SimulatorEditObj* = object ## Edit object.
    case kind*: SimulatorEditObjKind
    of EditCell:
      cell*: Cell
    of EditRotate:
      cross*: bool

  SimulatorEditData* = object ## Edit information.
    editObj*: SimulatorEditObj
    focusField*: bool
    field*: tuple[row: Row, col: Col]
    step*: tuple[index: int, pivot: bool, col: Col]
    insert*: bool

  SimulatorDequeElem = object ## Element of Undo/Redo deques.
    nazoPuyo: NazoPuyo
    moveResult: MoveResult
    state: SimulatorState
    operatingIndex: int

  Simulator* = object ## Simulator for Puyo Puyo and Nazo Puyo.
    nazoPuyo: NazoPuyo
    moveResult: MoveResult

    mode: SimulatorMode
    state: SimulatorState

    editData: SimulatorEditData
    operatingPlacement: Placement
    operatingIndex: int

    undoDeque: Deque[SimulatorDequeElem]
    redoDeque: Deque[SimulatorDequeElem]

const
  ViewerModes* = {ViewerPlay, ViewerEdit}
  EditorModes* = {EditorPlay, EditorEdit}
  PlayModes* = {ViewerPlay, EditorPlay}
  EditModes* = {ViewerEdit, EditorEdit}

  Pon2Path* {.define: "pon2.path".} = "/pon2/stable/studio/"

static:
  doAssert Pon2Path.startsWith '/'

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const
  DefaultMode = ViewerPlay
  DefaultPlacement = Up2
  DefaultMoveResult = MoveResult.init true
  DefaultEditData = SimulatorEditData(
    editObj: SimulatorEditObj(kind: EditCell, cell: Cell.None),
    focusField: true,
    field: (Row.low, Col.low),
    step: (0, true, Col.low),
    insert: false,
  )

func init(T: type SimulatorEditObj, cell: Cell): T =
  T(kind: EditCell, cell: cell)

func init(T: type SimulatorEditObj, cross: bool): T =
  T(kind: EditRotate, cross: cross)

func init(T: type SimulatorDequeElem, simulator: Simulator): T =
  T(
    nazoPuyo: simulator.nazoPuyo,
    moveResult: simulator.moveResult,
    state: simulator.state,
    operatingIndex: simulator.operatingIndex,
  )

func init*(T: type Simulator, nazoPuyo: NazoPuyo, mode = DefaultMode): T =
  T(
    nazoPuyo: nazoPuyo,
    moveResult: DefaultMoveResult,
    mode: mode,
    state: if mode in EditModes: AfterEdit else: Stable,
    editData: DefaultEditData,
    operatingPlacement: DefaultPlacement,
    operatingIndex: 0,
    undoDeque: Deque[SimulatorDequeElem].init,
    redoDeque: Deque[SimulatorDequeElem].init,
  )

func init*(T: type Simulator, puyoPuyo: PuyoPuyo, mode = DefaultMode): T =
  T.init(NazoPuyo.init(puyoPuyo, Goal.init), mode)

func init*(T: type Simulator, mode = DefaultMode): T =
  T.init(NazoPuyo.init, mode)

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `==`*(obj1, obj2: SimulatorEditObj): bool =
  if obj1.kind != obj2.kind:
    return false

  case obj1.kind
  of EditCell:
    obj1.cell == obj2.cell
  of EditRotate:
    obj1.cross == obj2.cross

# ------------------------------------------------
# Undo / Redo
# ------------------------------------------------

func load(self: var Simulator, elem: SimulatorDequeElem) =
  ## Loads the deque elem.
  self.nazoPuyo.assign elem.nazoPuyo
  self.moveResult.assign elem.moveResult
  self.state.assign elem.state
  self.operatingIndex.assign elem.operatingIndex

func undo*(self: var Simulator) =
  ## Performs undo.
  if self.mode notin EditModes:
    return
  if self.undoDeque.len == 0:
    return

  self.redoDeque.addLast SimulatorDequeElem.init self
  self.load self.undoDeque.popLast

func redo*(self: var Simulator) =
  ## Performs redo.
  if self.mode notin EditModes:
    return
  if self.redoDeque.len == 0:
    return

  self.undoDeque.addLast SimulatorDequeElem.init self
  self.load self.redoDeque.popLast

# ------------------------------------------------
# Property - Getter
# ------------------------------------------------

func rule*(self: Simulator): Rule =
  ## Returns the rule of the Puyo Puyo or Nazo Puyo.
  self.nazoPuyo.puyoPuyo.field.rule

func nazoPuyo*(self: Simulator): NazoPuyo =
  ## Returns the Nazo Puyo of the simulator.
  self.nazoPuyo

func moveResult*(self: Simulator): MoveResult =
  ## Returns the moving result of the simulator.
  self.moveResult

func mode*(self: Simulator): SimulatorMode =
  ## Returns the mode of the simulator.
  self.mode

func state*(self: Simulator): SimulatorState =
  ## Returns the state of the simulator.
  self.state

func editData*(self: Simulator): SimulatorEditData =
  ## Returns the edit information.
  self.editData

func operatingPlacement*(self: Simulator): Placement =
  ## Returns the operating placement of the simulator.
  self.operatingPlacement

func operatingIndex*(self: Simulator): int =
  ## Returns the index of the step operated.
  self.operatingIndex

# ------------------------------------------------
# Property - Setter
# ------------------------------------------------

func undoAll(self: var Simulator) =
  ## Loads the data before any moves in the undo deque and clears it after the loaded
  ## step, and clears the redo deque.
  ## If the undo deque is empty, does nothing.
  if self.undoDeque.len == 0:
    return

  if self.mode == EditorEdit:
    while self.state != AfterEdit:
      self.undo
  else:
    self.load self.undoDeque.peekFirst
    self.undoDeque.clear

  self.redoDeque.clear

func prepareEdit(self: var Simulator, clearRedoDeque = true) =
  ## Saves the current simulator to the undo deque and clears the redo deque.
  self.undoDeque.addLast SimulatorDequeElem.init self
  if clearRedoDeque:
    self.redoDeque.clear

template editBlock(self: var Simulator, body: untyped) =
  ## Saves the current simulator to the undo deque and clears the redo deque
  ## and then runs `body`.
  ## The state of the simulator is set to `AfterEdit`.
  self.prepareEdit
  body
  self.state.assign AfterEdit

func `rule=`*(self: var Simulator, rule: Rule) =
  ## Sets the rule of the simulator.
  if self.mode != EditorEdit:
    return
  if rule == self.rule:
    return

  case rule
  of Tsu, Water:
    if self.nazoPuyo.puyoPuyo.steps.anyIt it.kind == Rotate:
      return
  of Spinner:
    if self.nazoPuyo.puyoPuyo.steps.anyIt(it.kind == Rotate and it.cross):
      return
  of CrossSpinner:
    if self.nazoPuyo.puyoPuyo.steps.anyIt(it.kind == Rotate and not it.cross):
      return

  self.editBlock:
    self.nazoPuyo.puyoPuyo.field.rule.assign rule

  self.undoDeque.clear
  self.redoDeque.clear

func `mode=`*(self: var Simulator, mode: SimulatorMode) =
  ## Sets the mode of the simulator.
  case self.mode
  of ViewerPlay:
    if mode != ViewerEdit:
      return
  of ViewerEdit:
    if mode != ViewerPlay:
      return
  of EditorPlay:
    if mode != EditorEdit:
      return
  of EditorEdit:
    if mode != EditorPlay:
      return
  of Replay:
    return

  self.undoAll

  self.mode.assign mode
  self.state.assign if mode in EditModes: AfterEdit else: Stable

  self.undoDeque.clear

func `editCell=`*(self: var Simulator, cell: Cell) =
  ## Writes the cell to `editData.editObj`.
  if self.mode notin EditModes:
    return

  self.editData.editObj.assign SimulatorEditObj.init cell

func `editCross=`*(self: var Simulator, cross: bool) =
  ## Writes the cell to `editData.editObj`.
  if self.mode notin EditModes:
    return

  self.editData.editObj.assign SimulatorEditObj.init cross

# ------------------------------------------------
# Edit - Cursor
# ------------------------------------------------

func moveCursorUp*(self: var Simulator) =
  ## Moves the cursor upward.
  if self.editData.focusField:
    if self.mode notin EditModes:
      return

    self.editData.field.row.rotateDec
  else:
    if self.mode != EditorEdit:
      return

    if self.editData.step.index == 0:
      self.editData.step.index.assign self.nazoPuyo.puyoPuyo.steps.len
    else:
      self.editData.step.index.dec

func moveCursorDown*(self: var Simulator) =
  ## Moves the cursor downward.
  if self.editData.focusField:
    if self.mode notin EditModes:
      return

    self.editData.field.row.rotateInc
  else:
    if self.mode != EditorEdit:
      return

    if self.editData.step.index == self.nazoPuyo.puyoPuyo.steps.len:
      self.editData.step.index.assign 0
    else:
      self.editData.step.index.inc

func moveCursorRight*(self: var Simulator) =
  ## Moves the cursor rightward.
  if self.editData.focusField:
    if self.mode notin EditModes:
      return

    self.editData.field.col.rotateInc
  else:
    if self.mode != EditorEdit:
      return

    if self.editData.step.index >= self.nazoPuyo.puyoPuyo.steps.len or
        self.nazoPuyo.puyoPuyo.steps[self.editData.step.index].kind == PairPlacement:
      self.editData.step.pivot.toggle
    else:
      self.editData.step.col.rotateInc

func moveCursorLeft*(self: var Simulator) =
  ## Moves the cursor leftward.
  if self.editData.focusField:
    if self.mode notin EditModes:
      return

    self.editData.field.col.rotateDec
  else:
    if self.mode != EditorEdit:
      return

    if self.editData.step.index >= self.nazoPuyo.puyoPuyo.steps.len or
        self.nazoPuyo.puyoPuyo.steps[self.editData.step.index].kind == PairPlacement:
      self.editData.step.pivot.toggle
    else:
      self.editData.step.col.rotateDec

# ------------------------------------------------
# Edit - Delete
# ------------------------------------------------

func delStep*(self: var Simulator, index: int) =
  ## Deletes the step.
  if self.mode != EditorEdit:
    return

  if index >= self.nazoPuyo.puyoPuyo.steps.len:
    return

  self.editBlock:
    self.nazoPuyo.puyoPuyo.steps.del index
    self.editData.step.index.assign min(
      self.editData.step.index, self.nazoPuyo.puyoPuyo.steps.len
    )

func delStep*(self: var Simulator) =
  ## Deletes the step at selecting index.
  self.delStep self.editData.step.index

# ------------------------------------------------
# Edit - Write
# ------------------------------------------------

func writeCell(self: var Simulator, row: Row, col: Col, cell: Cell) =
  ## Writes the cell to the field.
  if self.mode notin EditModes:
    return

  self.editBlock:
    if self.editData.insert:
      if cell == Cell.None:
        self.nazoPuyo.puyoPuyo.field.del row, col
      else:
        self.nazoPuyo.puyoPuyo.field.insert row, col, cell
    else:
      self.nazoPuyo.puyoPuyo.field[row, col] = cell

func writeCell*(self: var Simulator, row: Row, col: Col) =
  ## Writes the selecting cell to the field.
  case self.editData.editObj.kind
  of EditCell:
    self.writeCell row, col, self.editData.editObj.cell
  of EditRotate:
    discard

func writeCell(self: var Simulator, index: int, pivot: bool, cell: Cell) =
  ## Writes the cell to the step.
  const ZeroArray = Col.initArrayWith 0

  if self.mode != EditorEdit:
    return

  if index >= self.nazoPuyo.puyoPuyo.steps.len:
    case cell
    of Cell.None:
      return
    of Hard, Garbage:
      self.editBlock:
        self.nazoPuyo.puyoPuyo.steps.addLast Step.init(ZeroArray, cell == Hard)
    of Cell.Red .. Cell.Purple:
      self.editBlock:
        self.nazoPuyo.puyoPuyo.steps.addLast Step.init Pair.init(cell, cell)
  else:
    if cell == Cell.None:
      self.delStep index
      return

    if self.editData.insert:
      self.editBlock:
        case cell
        of Cell.None:
          discard # not reached here
        of Hard, Garbage:
          self.nazoPuyo.puyoPuyo.steps.insert Step.init(ZeroArray, cell == Hard), index
        of Cell.Red .. Cell.Purple:
          self.nazoPuyo.puyoPuyo.steps.insert Step.init(Pair.init(cell, cell)), index
    else:
      self.editBlock:
        case cell
        of Cell.None:
          discard # not reached here
        of Hard, Garbage:
          let cellIsHard = cell == Hard
          case self.nazoPuyo.puyoPuyo.steps[index].kind
          of PairPlacement, Rotate:
            self.nazoPuyo.puyoPuyo.steps[index].assign Step.init(ZeroArray, cellIsHard)
          of StepKind.Garbages:
            self.nazoPuyo.puyoPuyo.steps[index].dropHard.assign cellIsHard
        of Cell.Red .. Cell.Purple:
          case self.nazoPuyo.puyoPuyo.steps[index].kind
          of PairPlacement:
            if pivot:
              self.nazoPuyo.puyoPuyo.steps[index].pair.pivot = cell
            else:
              self.nazoPuyo.puyoPuyo.steps[index].pair.rotor = cell
          of StepKind.Garbages, Rotate:
            self.nazoPuyo.puyoPuyo.steps[index].assign Step.init Pair.init(cell, cell)

func writeRotate(self: var Simulator, index: int, pivot: bool, cross: bool) =
  ## Writes the rotation to the step.
  if self.mode != EditorEdit:
    return
  if not ((self.rule == Spinner and not cross) or (self.rule == CrossSpinner and cross)):
    return

  if index >= self.nazoPuyo.puyoPuyo.steps.len:
    self.editBlock:
      self.nazoPuyo.puyoPuyo.steps.addLast Step.init(cross = cross)
  else:
    if self.editData.insert:
      self.editBlock:
        self.nazoPuyo.puyoPuyo.steps.insert Step.init(cross = cross), index
    else:
      case self.nazoPuyo.puyoPuyo.steps[index].kind
      of PairPlacement, StepKind.Garbages:
        self.editBlock:
          self.nazoPuyo.puyoPuyo.steps[index].assign Step.init(cross = cross)
      of Rotate:
        if self.nazoPuyo.puyoPuyo.steps[index].cross != cross:
          self.editBlock:
            self.nazoPuyo.puyoPuyo.steps[index].cross.toggle

func writeCell*(self: var Simulator, index: int, pivot: bool) =
  ## Writes the selecting cell to the step.
  case self.editData.editObj.kind
  of EditCell:
    self.writeCell index, pivot, self.editData.editObj.cell
  of EditRotate:
    self.writeRotate index, pivot, self.editData.editObj.cross

func writeCell*(self: var Simulator, cell: Cell) =
  ## Writes the cell to the field or the step.
  if self.editData.focusField:
    self.writeCell self.editData.field.row, self.editData.field.col, cell
  else:
    self.writeCell self.editData.step.index, self.editData.step.pivot, cell

func writeRotate*(self: var Simulator, cross: bool) =
  ## Writes the rotate to the field or the step.
  if self.editData.focusField:
    discard
  else:
    self.writeRotate self.editData.step.index, self.editData.step.pivot, cross

func writeCount*(self: var Simulator, index: int, col: Col, count: int) =
  ## Writes the count to the step.
  if self.mode != EditorEdit:
    return

  if index >= self.nazoPuyo.puyoPuyo.steps.len:
    return
  if self.nazoPuyo.puyoPuyo.steps[index].kind != StepKind.Garbages:
    return

  self.editBlock:
    self.nazoPuyo.puyoPuyo.steps[index].counts[col].assign count

func writeCount*(self: var Simulator, count: int) =
  ## Writes the count to the step.
  self.writeCount self.editData.step.index, self.editData.step.col, count

# ------------------------------------------------
# Edit - Shift
# ------------------------------------------------

func shiftFieldUp*(self: var Simulator) =
  ## Shifts the field upward.
  if self.mode != EditorEdit:
    return

  self.editBlock:
    self.nazoPuyo.puyoPuyo.field.shiftUp

func shiftFieldDown*(self: var Simulator) =
  ## Shifts the field downward.
  if self.mode != EditorEdit:
    return

  self.editBlock:
    self.nazoPuyo.puyoPuyo.field.shiftDown

func shiftFieldRight*(self: var Simulator) =
  ## Shifts the field rightward.
  if self.mode != EditorEdit:
    return

  self.editBlock:
    self.nazoPuyo.puyoPuyo.field.shiftRight

func shiftFieldLeft*(self: var Simulator) =
  ## Shifts the field leftward.
  if self.mode != EditorEdit:
    return

  self.editBlock:
    self.nazoPuyo.puyoPuyo.field.shiftLeft

# ------------------------------------------------
# Edit - Flip
# ------------------------------------------------

func flipFieldVertical*(self: var Simulator) =
  ## Flips the field vertically.
  if self.mode != EditorEdit:
    return

  self.editBlock:
    self.nazoPuyo.puyoPuyo.field.flipVertical

func flipFieldHorizontal*(self: var Simulator) =
  ## Flips the field horizontally.
  if self.mode != EditorEdit:
    return

  self.editBlock:
    self.nazoPuyo.puyoPuyo.field.flipHorizontal

func flip*(self: var Simulator) =
  ## Flips the field or the step.
  if self.editData.focusField:
    self.flipFieldHorizontal
  else:
    if self.mode != EditorEdit:
      return

    if self.editData.step.index >= self.nazoPuyo.puyoPuyo.steps.len:
      return

    self.editBlock:
      case self.nazoPuyo.puyoPuyo.steps[self.editData.step.index].kind
      of PairPlacement:
        self.nazoPuyo.puyoPuyo.steps[self.editData.step.index].pair.swap
      of StepKind.Garbages:
        self.nazoPuyo.puyoPuyo.steps[self.editData.step.index].counts.reverse
      of Rotate:
        discard

# ------------------------------------------------
# Edit - Goal
# ------------------------------------------------

const
  DefaultGoalColor = All
  DefaultGoalVal = 0
  DefaultGoalValOperator = Exact

func normalizeGoal*(self: var Simulator) =
  ## Normalizes the goal.
  ## This function only affects to the goal.
  self.nazoPuyo.goal.normalize

func `goalKindOpt=`*(self: var Simulator, kindOpt: Opt[GoalKind]) =
  ## Sets the goal kind.
  if self.mode != EditorEdit:
    return

  self.editBlock:
    if kindOpt.isOk:
      let kind = kindOpt.unsafeValue

      if self.nazoPuyo.goal.mainOpt.isOk:
        self.nazoPuyo.goal.mainOpt.unsafeValue.kind.assign kind
      else:
        self.nazoPuyo.goal.mainOpt.ok GoalMain.init(
          kind, DefaultGoalColor, DefaultGoalVal, DefaultGoalValOperator
        )
    else:
      if self.nazoPuyo.goal.mainOpt.isOk: self.nazoPuyo.goal.mainOpt.err else: discard

    self.nazoPuyo.goal.normalize

func `goalColor=`*(self: var Simulator, color: GoalColor) =
  ## Sets the goal color.
  if self.mode != EditorEdit:
    return

  if self.nazoPuyo.goal.mainOpt.isErr:
    return

  self.editBlock:
    self.nazoPuyo.goal.mainOpt.unsafeValue.color.assign color
    self.nazoPuyo.goal.normalize

func `goalVal=`*(self: var Simulator, val: int) =
  ## Sets the goal value.
  if self.mode != EditorEdit:
    return

  if self.nazoPuyo.goal.mainOpt.isErr:
    return

  self.editBlock:
    self.nazoPuyo.goal.mainOpt.unsafeValue.val.assign val
    self.nazoPuyo.goal.normalize

func `goalValOperator=`*(self: var Simulator, valOperator: GoalValOperator) =
  ## Sets the goal exact.
  if self.mode != EditorEdit:
    return

  if self.nazoPuyo.goal.mainOpt.isErr:
    return

  self.editBlock:
    self.nazoPuyo.goal.mainOpt.unsafeValue.valOperator.assign valOperator
    self.nazoPuyo.goal.normalize

func `goalClearColorOpt=`*(self: var Simulator, clearColorOpt: Opt[GoalColor]) =
  ## Sets the goal clear color.
  if self.mode != EditorEdit:
    return

  self.editBlock:
    self.nazoPuyo.goal.clearColorOpt.assign clearColorOpt
    self.nazoPuyo.goal.normalize

# ------------------------------------------------
# Edit - Other
# ------------------------------------------------

func toggleFocus*(self: var Simulator) =
  ## Toggles focusing field or not.
  self.editData.focusField.toggle

func toggleInsert*(self: var Simulator) =
  ## Toggles inserting or not.
  self.editData.insert.toggle

# ------------------------------------------------
# Play - Placement
# ------------------------------------------------

func movePlacementRight*(self: var Simulator) =
  ## Moves the next placement right.
  self.operatingPlacement.moveRight

func movePlacementLeft*(self: var Simulator) =
  ## Moves the next placement left.
  self.operatingPlacement.moveLeft

func rotatePlacementRight*(self: var Simulator) =
  ## Rotates the next placement right (clockwise).
  self.operatingPlacement.rotateRight

func rotatePlacementLeft*(self: var Simulator) =
  ## Rotates the next placement left (counterclockwise).
  self.operatingPlacement.rotateLeft

# ------------------------------------------------
# Forward / Backward
# ------------------------------------------------

func forwardApply(self: var Simulator, replay = false, skip = false) =
  ## Forwards the simulator with `apply`.
  ## This functions requires that the initial field is settled.
  ## `skip` is prioritized over `replay`.
  if self.operatingIndex >= self.nazoPuyo.puyoPuyo.steps.len:
    return
  if self.mode in EditModes:
    return

  self.prepareEdit(clearRedoDeque = self.mode in PlayModes)

  self.moveResult.assign DefaultMoveResult

  # set placement
  if self.mode in PlayModes:
    if self.nazoPuyo.puyoPuyo.steps[self.operatingIndex].kind != PairPlacement:
      discard
    elif skip:
      self.nazoPuyo.puyoPuyo.steps[self.operatingIndex].optPlacement.err
    elif replay:
      discard
    else:
      self.nazoPuyo.puyoPuyo.steps[self.operatingIndex].optPlacement.ok self.operatingPlacement

  let step = self.nazoPuyo.puyoPuyo.steps[self.operatingIndex]
  self.nazoPuyo.puyoPuyo.field.apply step

  # set state
  if step.kind == Rotate:
    if self.nazoPuyo.puyoPuyo.field.isSettled:
      self.state.assign Stable

      if self.mode notin EditModes:
        self.operatingIndex.inc
        self.operatingPlacement.assign DefaultPlacement
    else:
      self.state.assign WillSettle
  elif self.nazoPuyo.puyoPuyo.field.canPop:
    self.state.assign WillPop
  else:
    self.state.assign Stable
    self.operatingIndex.inc
    self.operatingPlacement.assign DefaultPlacement

func forwardPop(self: var Simulator) =
  ## Forwards the simulator with `pop`.
  self.prepareEdit(clearRedoDeque = self.mode in PlayModes)

  let popResult = self.nazoPuyo.puyoPuyo.field.pop

  # update moving result
  self.moveResult.chainCount.inc
  var cellCounts {.noinit.}: array[Cell, int]
  cellCounts[Cell.None].assign 0
  staticFor(cell2, Hard .. Cell.Purple):
    let cellCount = popResult.cellCount cell2
    cellCounts[cell2].assign cellCount
    self.moveResult.popCounts[cell2].inc cellCount
  self.moveResult.detailPopCounts.add cellCounts
  self.moveResult.fullPopCountsOpt.unsafeValue.add popResult.connectionCounts
  let h2g = popResult.hardToGarbageCount
  self.moveResult.hardToGarbageCount.inc h2g
  self.moveResult.detailHardToGarbageCount.add h2g

  # check settle
  if self.nazoPuyo.puyoPuyo.field.isSettled:
    self.state.assign Stable

    if self.mode notin EditModes:
      self.operatingIndex.inc
      self.operatingPlacement.assign DefaultPlacement
  else:
    self.state.assign WillSettle

func forwardSettle(self: var Simulator) =
  ## Forwards the simulator with `settle`.
  self.prepareEdit(clearRedoDeque = self.mode in PlayModes)

  self.nazoPuyo.puyoPuyo.field.settle

  # check pop
  if self.nazoPuyo.puyoPuyo.field.canPop:
    self.state.assign WillPop
  else:
    self.state.assign Stable

    if self.mode notin EditModes:
      self.operatingIndex.inc
      self.operatingPlacement.assign DefaultPlacement

func forward*(self: var Simulator, replay = false, skip = false) =
  ## Forwards the simulator.
  ## This functions requires that the initial field is settled.
  ## `skip` is prioritized over `replay`.
  case self.state
  of Stable:
    self.forwardApply replay, skip
  of WillPop:
    self.forwardPop
  of WillSettle:
    self.forwardSettle
  of AfterEdit:
    if not self.nazoPuyo.puyoPuyo.field.isSettled:
      self.forwardSettle
    elif self.nazoPuyo.puyoPuyo.field.canPop:
      self.forwardPop
    else:
      return

func backward*(self: var Simulator, detail = false) =
  ## Backwards the simulator.
  if self.undoDeque.len == 0:
    return
  if self.state == AfterEdit:
    return

  # save the steps to keep the placements
  let steps = self.nazoPuyo.puyoPuyo.steps

  if not detail:
    while self.undoDeque.peekLast.state notin {Stable, AfterEdit}:
      self.undoDeque.popLast
  self.load self.undoDeque.popLast

  if self.mode notin EditModes:
    self.nazoPuyo.puyoPuyo.steps.assign steps

  if self.mode in PlayModes and self.state in {Stable, AfterEdit}:
    self.operatingPlacement.assign DefaultPlacement

func reset*(self: var Simulator) =
  ## Backwards the simulator to the pre-move state.
  let nowSteps = self.nazoPuyo.puyoPuyo.steps
  self.undoAll
  self.nazoPuyo.puyoPuyo.steps.assign nowSteps

  self.operatingPlacement.assign DefaultPlacement

# ------------------------------------------------
# Mark
# ------------------------------------------------

func mark*(self: Simulator): MarkResult =
  ## Marks the steps in the Nazo Puyo in the simulator.
  var nazoPuyo = self.nazoPuyo
  if self.mode == EditorEdit:
    if self.state != AfterEdit:
      for index in 1 .. self.undoDeque.len:
        let elem = self.undoDeque[^index]
        if elem.state == AfterEdit:
          nazoPuyo.assign elem.nazoPuyo
          break
  else:
    if self.undoDeque.len > 0:
      nazoPuyo.assign self.undoDeque.peekFirst.nazoPuyo

  nazoPuyo.puyoPuyo.steps.assign self.nazoPuyo.puyoPuyo.steps
  nazoPuyo.mark self.operatingIndex

# ------------------------------------------------
# Keyboard
# ------------------------------------------------

func initDigitKeys(): seq[KeyEvent] =
  ## Returns `DigitKeys`.
  collect:
    for c in '0' .. '9':
      KeyEvent.init c

const DigitKeys = initDigitKeys()

func operate*(self: var Simulator, key: KeyEvent): bool {.discardable.} =
  ## Performs an action specified by the key.
  ## Returns `true` if the key is handled.
  var handled = true

  case self.mode
  of PlayModes:
    # mode
    if key == static(KeyEvent.init 't'):
      if self.mode == ViewerPlay:
        self.`mode=` ViewerEdit
      else:
        self.`mode=` EditorEdit
    # rotate operating placement
    elif key == static(KeyEvent.init 'k'):
      self.rotatePlacementRight
    elif key == static(KeyEvent.init 'j'):
      self.rotatePlacementLeft
    # move operating placement
    elif key == static(KeyEvent.init 'd'):
      self.movePlacementRight
    elif key == static(KeyEvent.init 'a'):
      self.movePlacementLeft
    # forward / backward / reset
    elif key == static(KeyEvent.init 's'):
      self.forward
    elif key in static([KeyEvent.init 'x', KeyEvent.init 'w']):
      self.backward
    elif key == static(KeyEvent.init 'z'):
      self.reset
    elif key == static(KeyEvent.init "Space"):
      self.forward(skip = true)
    elif key == static(KeyEvent.init 'c'):
      self.forward(replay = true)
    else:
      handled.assign false
  of EditModes:
    # mode
    if key == static(KeyEvent.init 't'):
      if self.mode == ViewerEdit:
        self.`mode=` ViewerPlay
      else:
        self.`mode=` EditorPlay
    elif key == static(KeyEvent.init 'r') and self.mode == EditorEdit:
      self.rule = self.rule.rotateSucc
    elif key == static(KeyEvent.init 'e') and self.mode == EditorEdit:
      self.rule = self.rule.rotatePred
    # toggle insert / focus
    elif key == static(KeyEvent.init 'g'):
      self.toggleInsert
    elif key == static(KeyEvent.init "Tab"):
      self.toggleFocus
    # move cursor
    elif key == static(KeyEvent.init 'd'):
      self.moveCursorRight
    elif key == static(KeyEvent.init 'a'):
      self.moveCursorLeft
    elif key == static(KeyEvent.init 's'):
      self.moveCursorDown
    elif key == static(KeyEvent.init 'w'):
      self.moveCursorUp
    # write / delete cell
    elif key == static(KeyEvent.init 'h'):
      self.writeCell Cell.Red
    elif key == static(KeyEvent.init 'j'):
      self.writeCell Cell.Green
    elif key == static(KeyEvent.init 'k'):
      self.writeCell Cell.Blue
    elif key == static(KeyEvent.init 'l'):
      self.writeCell Cell.Yellow
    elif key == static(KeyEvent.init "Semicolon"):
      self.writeCell Cell.Purple
    elif key == static(KeyEvent.init 'o'):
      self.writeCell Garbage
    elif key == static(KeyEvent.init 'p'):
      self.writeCell Hard
    elif key == static(KeyEvent.init "Space"):
      self.writeCell Cell.None
    # write rotate
    elif key == static(KeyEvent.init 'n'):
      self.writeRotate(cross = false)
    elif key == static(KeyEvent.init 'm'):
      self.writeRotate(cross = true)
    # write count
    elif (let count = DigitKeys.find key; count >= 0):
      self.writeCount count
    # shift field
    elif key == static(KeyEvent.init 'D'):
      self.shiftFieldRight
    elif key == static(KeyEvent.init 'A'):
      self.shiftFieldLeft
    elif key == static(KeyEvent.init 'S'):
      self.shiftFieldDown
    elif key == static(KeyEvent.init 'W'):
      self.shiftFieldUp
    # flip field
    elif key == static(KeyEvent.init 'f'):
      self.flip
    # undo / redo
    elif key == static(KeyEvent.init 'Z'):
      self.undo
    elif key == static(KeyEvent.init 'X'):
      self.redo
    # forward / backward / reset
    elif key == static(KeyEvent.init 'c'):
      self.forward
    elif key == static(KeyEvent.init 'x'):
      self.backward
    elif key == static(KeyEvent.init 'z'):
      self.reset
    else:
      handled.assign false
  of Replay:
    # forward / backward / reset
    if key in static([KeyEvent.init 'x', KeyEvent.init 'w']):
      self.backward
    elif key in static([KeyEvent.init 'z', KeyEvent.init 'W']):
      self.reset
    elif key in static([KeyEvent.init 'c', KeyEvent.init 's']):
      self.forward(replay = true)
    else:
      handled.assign false

  handled

# ------------------------------------------------
# Simulator <-> URI
# ------------------------------------------------

const ModeKey = "mode"

func initPon2Paths(): seq[string] =
  ## Returns `Pon2Paths`.
  var paths = @[Pon2Path]

  if Pon2Path.endsWith '/':
    paths.add "{Pon2Path}index.html".fmt

  if Pon2Path.endsWith "/index.html":
    paths.add Pon2Path.dup(removeSuffix(_, "/index.html"))

  paths

const Pon2Paths = initPon2Paths()

func toUri*(self: Simulator, clearPlacements = false, fqdn = Pon2): Pon2Result[Uri] =
  ## Returns the URI converted from the simulator.
  var uri = initUri()
  uri.scheme.assign "https"
  uri.hostname.assign $fqdn

  uri.path.assign (
    case fqdn
    of Pon2:
      Pon2Path
    of Ishikawa, Ips:
      if self.nazoPuyo.goal != NoneGoal:
        "/simu/pn.html"
      else:
        case self.mode
        of PlayModes: "/simu/ps.html"
        of EditModes: "/simu/pe.html"
        of Replay: "/simu/pv.html"
  )

  var nazoPuyo = self.nazoPuyo
  if clearPlacements:
    for step in nazoPuyo.puyoPuyo.steps.mitems:
      if step.kind == PairPlacement:
        step.optPlacement.err
  let nazoPuyoQuery =
    ?nazoPuyo.toUriQuery(fqdn).context "Simulator that does not support URI conversion"
  uri.query.assign if fqdn == Pon2:
    "{ModeKey}={self.mode.ord}&{nazoPuyoQuery}".fmt
  else:
    nazoPuyoQuery

  ok uri

func parseSimulator*(uri: Uri): Pon2Result[Simulator] =
  ## Returns the simulator converted from the URI.
  ## Viewer modes and play modes are set to the result simulator preferentially
  ## if the FQDN is `Ishikawa` or `Ips`.
  let fqdn: SimulatorFqdn
  case uri.hostname
  of $Pon2:
    fqdn = Pon2
  of $Ishikawa:
    fqdn = Ishikawa
  of $Ips:
    fqdn = Ips
  else:
    fqdn = SimulatorFqdn.low # NOTE: dummy to compile
    return err "Invalid simulator (invalid FQDN): {uri}".fmt

  if uri.scheme notin ["https", "http"]:
    return err "Invalid simulator (invalid scheme): {uri}".fmt

  case fqdn
  of Pon2:
    if uri.path notin Pon2Paths:
      return err "Invalid simulator (invalid path): {uri}".fmt

    var
      keyVals = newSeq[tuple[key: string, value: string]]()
      mode = Opt[SimulatorMode].err
    for keyVal in uri.query.decodeQuery:
      if keyVal.key == ModeKey:
        if mode.isOk:
          return err "Invalid simulator (multiple mode detected): {uri}".fmt
        else:
          let
            modeErrorMsg = "Invalid mode: {keyVal.value}".fmt
            modeOrd = ?keyVal.value.parseInt.context modeErrorMsg
          if modeOrd notin SimulatorMode.low.ord .. SimulatorMode.high.ord:
            return err modeErrorMsg

          mode.ok modeOrd.SimulatorMode
      else:
        keyVals.add keyVal

    if mode.isErr:
      mode.ok DefaultMode

    ok Simulator.init(
      ?keyVals.encodeQuery.parseNazoPuyo(fqdn).context "Invalid simulator: {uri}".fmt,
      mode.unsafeValue,
    )
  of Ishikawa, Ips:
    let mode: SimulatorMode
    case uri.path
    of "/simu/pe.html":
      mode = ViewerEdit
    of "/simu/ps.html", "/simu/pn.html":
      mode = ViewerPlay
    of "/simu/pv.html":
      mode = Replay
    else:
      return err "Invalid simulator (invalid path): {uri}".fmt

    ok Simulator.init ?uri.query.parseNazoPuyo(fqdn).context "Invalid simulator: {uri}".fmt

func toExportUri*(
    self: Simulator, viewer = true, clearPlacements = true, fqdn = Pon2
): Pon2Result[Uri] =
  ## Returns the URI of the simulator with any moves reset.
  var simulator = self

  simulator.undoAll
  simulator.mode = if viewer: ViewerPlay else: EditorPlay

  if not clearPlacements:
    simulator.nazoPuyo.puyoPuyo.steps.assign self.nazoPuyo.puyoPuyo.steps

  simulator.toUri(clearPlacements, fqdn)

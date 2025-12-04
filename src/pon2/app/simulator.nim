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

import std/[strformat, sugar, uri]
import ./[key, nazopuyowrap]
import ../[core]
import
  ../private/
    [
      algorithm, arrayutils, assign, deques, results2, staticfor, strutils, tables,
      utils,
    ]

export core, nazopuyowrap, results2, uri

type
  SimulatorMode* {.pure.} = enum
    ## Simulator's mode.
    ViewerPlay = "vp"
    ViewerEdit = "ve"
    EditorPlay = "ep"
    EditorEdit = "ee"
    Replay = "r"

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
    nazoPuyoWrap: NazoPuyoWrap
    moveResult: MoveResult
    state: SimulatorState
    operatingIndex: int

  Simulator* = object ## Simulator for Puyo Puyo and Nazo Puyo.
    nazoPuyoWrap: NazoPuyoWrap
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
    nazoPuyoWrap: simulator.nazoPuyoWrap,
    moveResult: simulator.moveResult,
    state: simulator.state,
    operatingIndex: simulator.operatingIndex,
  )

func init*(T: type Simulator, wrap: NazoPuyoWrap, mode = DefaultMode): T =
  T(
    nazoPuyoWrap: wrap,
    moveResult: DefaultMoveResult,
    mode: mode,
    state: if mode in EditModes: AfterEdit else: Stable,
    editData: DefaultEditData,
    operatingPlacement: DefaultPlacement,
    operatingIndex: 0,
    undoDeque: Deque[SimulatorDequeElem].init,
    redoDeque: Deque[SimulatorDequeElem].init,
  )

func init*[F: TsuField or WaterField](
    T: type Simulator, nazo: NazoPuyo[F], mode = DefaultMode
): T =
  T.init(NazoPuyoWrap.init nazo, mode)

func init*[F: TsuField or WaterField](
    T: type Simulator, puyoPuyo: PuyoPuyo[F], mode = DefaultMode
): T =
  T.init(NazoPuyoWrap.init puyoPuyo, mode)

func init*(T: type Simulator, mode = DefaultMode): T =
  T.init(NazoPuyoWrap.init, mode)

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
  self.nazoPuyoWrap.assign elem.nazoPuyoWrap
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
  self.nazoPuyoWrap.rule

func nazoPuyoWrap*(self: Simulator): NazoPuyoWrap =
  ## Returns the Nazo Puyo wrapper of the simulator.
  self.nazoPuyoWrap

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

  self.editBlock:
    self.nazoPuyoWrap.assign self.nazoPuyoWrap.setRule rule

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

    let stepCount = unwrap self.nazoPuyoWrap:
      it.puyoPuyo.steps.len
    if self.editData.step.index == 0:
      self.editData.step.index.assign stepCount
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

    let stepCount = unwrap self.nazoPuyoWrap:
      it.puyoPuyo.steps.len
    if self.editData.step.index == stepCount:
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

    unwrap self.nazoPuyoWrap:
      let stepCount = it.puyoPuyo.steps.len
      if self.editData.step.index >= stepCount or
          it.puyoPuyo.steps[self.editData.step.index].kind == PairPlacement:
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

    unwrap self.nazoPuyoWrap:
      let stepCount = it.puyoPuyo.steps.len
      if self.editData.step.index >= stepCount or
          it.puyoPuyo.steps[self.editData.step.index].kind == PairPlacement:
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

  unwrap self.nazoPuyoWrap:
    if index >= it.puyoPuyo.steps.len:
      return

    self.editBlock:
      it.puyoPuyo.steps.del index
      self.editData.step.index.assign min(
        self.editData.step.index, it.puyoPuyo.steps.len
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
    unwrap self.nazoPuyoWrap:
      if self.editData.insert:
        if cell == Cell.None:
          it.puyoPuyo.field.del row, col
        else:
          it.puyoPuyo.field.insert row, col, cell
      else:
        it.puyoPuyo.field[row, col] = cell

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

  unwrap self.nazoPuyoWrap:
    if index >= it.puyoPuyo.steps.len:
      case cell
      of Cell.None:
        return
      of Hard, Garbage:
        self.editBlock:
          it.puyoPuyo.steps.addLast Step.init(ZeroArray, cell == Hard)
      of Cell.Red .. Cell.Purple:
        self.editBlock:
          it.puyoPuyo.steps.addLast Step.init Pair.init(cell, cell)
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
            it.puyoPuyo.steps.insert Step.init(ZeroArray, cell == Hard), index
          of Cell.Red .. Cell.Purple:
            it.puyoPuyo.steps.insert Step.init(Pair.init(cell, cell)), index
      else:
        self.editBlock:
          case cell
          of Cell.None:
            discard # not reached here
          of Hard, Garbage:
            let cellIsHard = cell == Hard
            case it.puyoPuyo.steps[index].kind
            of PairPlacement, Rotate:
              it.puyoPuyo.steps[index].assign Step.init(ZeroArray, cellIsHard)
            of StepKind.Garbages:
              it.puyoPuyo.steps[index].dropHard.assign cellIsHard
          of Cell.Red .. Cell.Purple:
            case it.puyoPuyo.steps[index].kind
            of PairPlacement:
              if pivot:
                it.puyoPuyo.steps[index].pair.pivot = cell
              else:
                it.puyoPuyo.steps[index].pair.rotor = cell
            of StepKind.Garbages, Rotate:
              it.puyoPuyo.steps[index].assign Step.init Pair.init(cell, cell)

func writeRotate(self: var Simulator, index: int, pivot: bool, cross: bool) =
  ## Writes the rotation to the step.
  if self.mode != EditorEdit:
    return

  unwrap self.nazoPuyoWrap:
    if index >= it.puyoPuyo.steps.len:
      self.editBlock:
        it.puyoPuyo.steps.addLast Step.init(cross = cross)
    else:
      if self.editData.insert:
        self.editBlock:
          it.puyoPuyo.steps.insert Step.init(cross = cross), index
      else:
        case it.puyoPuyo.steps[index].kind
        of PairPlacement, StepKind.Garbages:
          self.editBlock:
            it.puyoPuyo.steps[index].assign Step.init(cross = cross)
        of Rotate:
          if it.puyoPuyo.steps[index].cross != cross:
            self.editBlock:
              it.puyoPuyo.steps[index].cross.toggle

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

  unwrap self.nazoPuyoWrap:
    if index >= it.puyoPuyo.steps.len:
      return
    if it.puyoPuyo.steps[index].kind != StepKind.Garbages:
      return

    self.editBlock:
      it.puyoPuyo.steps[index].counts[col].assign count

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
    unwrap self.nazoPuyoWrap:
      it.puyoPuyo.field.shiftUp

func shiftFieldDown*(self: var Simulator) =
  ## Shifts the field downward.
  if self.mode != EditorEdit:
    return

  self.editBlock:
    unwrap self.nazoPuyoWrap:
      it.puyoPuyo.field.shiftDown

func shiftFieldRight*(self: var Simulator) =
  ## Shifts the field rightward.
  if self.mode != EditorEdit:
    return

  self.editBlock:
    unwrap self.nazoPuyoWrap:
      it.puyoPuyo.field.shiftRight

func shiftFieldLeft*(self: var Simulator) =
  ## Shifts the field leftward.
  if self.mode != EditorEdit:
    return

  self.editBlock:
    unwrap self.nazoPuyoWrap:
      it.puyoPuyo.field.shiftLeft

# ------------------------------------------------
# Edit - Flip
# ------------------------------------------------

func flipFieldVertical*(self: var Simulator) =
  ## Flips the field vertically.
  if self.mode != EditorEdit:
    return

  self.editBlock:
    unwrap self.nazoPuyoWrap:
      it.puyoPuyo.field.flipVertical

func flipFieldHorizontal*(self: var Simulator) =
  ## Flips the field horizontally.
  if self.mode != EditorEdit:
    return

  self.editBlock:
    unwrap self.nazoPuyoWrap:
      it.puyoPuyo.field.flipHorizontal

func flip*(self: var Simulator) =
  ## Flips the field or the step.
  if self.editData.focusField:
    self.flipFieldHorizontal
  else:
    if self.mode != EditorEdit:
      return

    unwrap self.nazoPuyoWrap:
      if self.editData.step.index >= it.puyoPuyo.steps.len:
        return

      self.editBlock:
        case it.puyoPuyo.steps[self.editData.step.index].kind
        of PairPlacement:
          it.puyoPuyo.steps[self.editData.step.index].pair.swap
        of StepKind.Garbages:
          it.puyoPuyo.steps[self.editData.step.index].counts.reverse
        of Rotate:
          it.puyoPuyo.steps[self.editData.step.index].cross.toggle

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
  self.nazoPuyoWrap.unwrap:
    it.goal.normalize

func `goalKindOpt=`*(self: var Simulator, kindOpt: Opt[GoalKind]) =
  ## Sets the goal kind.
  if self.mode != EditorEdit:
    return

  self.editBlock:
    self.nazoPuyoWrap.unwrap:
      if kindOpt.isOk:
        let kind = kindOpt.unsafeValue

        if it.goal.mainOpt.isOk:
          it.goal.mainOpt.unsafeValue.kind.assign kind
        else:
          it.goal.mainOpt.ok GoalMain.init(
            kind, DefaultGoalColor, DefaultGoalVal, DefaultGoalValOperator
          )
      else:
        if it.goal.mainOpt.isOk: it.goal.mainOpt.err else: discard

      it.goal.normalize

func `goalColor=`*(self: var Simulator, color: GoalColor) =
  ## Sets the goal color.
  if self.mode != EditorEdit:
    return

  self.nazoPuyoWrap.unwrap:
    if it.goal.mainOpt.isErr:
      return

    self.editBlock:
      it.goal.mainOpt.unsafeValue.color.assign color
      it.goal.normalize

func `goalVal=`*(self: var Simulator, val: int) =
  ## Sets the goal value.
  if self.mode != EditorEdit:
    return

  self.nazoPuyoWrap.unwrap:
    if it.goal.mainOpt.isErr:
      return

    self.editBlock:
      it.goal.mainOpt.unsafeValue.val.assign val
      it.goal.normalize

func `goalValOperator=`*(self: var Simulator, valOperator: GoalValOperator) =
  ## Sets the goal exact.
  if self.mode != EditorEdit:
    return

  self.nazoPuyoWrap.unwrap:
    if it.goal.mainOpt.isErr:
      return

    self.editBlock:
      it.goal.mainOpt.unsafeValue.valOperator.assign valOperator
      it.goal.normalize

func `goalClearColorOpt=`*(self: var Simulator, clearColorOpt: Opt[GoalColor]) =
  ## Sets the goal clear color.
  if self.mode != EditorEdit:
    return

  self.nazoPuyoWrap.unwrap:
    self.editBlock:
      it.goal.clearColorOpt.assign clearColorOpt
      it.goal.normalize

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
  unwrap self.nazoPuyoWrap:
    if self.operatingIndex >= it.puyoPuyo.steps.len:
      return
    if self.mode in EditModes:
      return

    self.prepareEdit(clearRedoDeque = self.mode in PlayModes)

    self.moveResult.assign DefaultMoveResult

    # set placement
    if self.mode in PlayModes:
      if it.puyoPuyo.steps[self.operatingIndex].kind != PairPlacement:
        discard
      elif skip:
        it.puyoPuyo.steps[self.operatingIndex].optPlacement.err
      elif replay:
        discard
      else:
        it.puyoPuyo.steps[self.operatingIndex].optPlacement.ok self.operatingPlacement

    let step = it.puyoPuyo.steps[self.operatingIndex]
    it.puyoPuyo.field.apply step

    # set state
    if step.kind == Rotate:
      if it.puyoPuyo.field.isSettled:
        self.state.assign Stable

        if self.mode notin EditModes:
          self.operatingIndex.inc
          self.operatingPlacement.assign DefaultPlacement
      else:
        self.state.assign WillSettle
    elif it.puyoPuyo.field.canPop:
      self.state.assign WillPop
    else:
      self.state.assign Stable
      self.operatingIndex.inc
      self.operatingPlacement.assign DefaultPlacement

func forwardPop(self: var Simulator) =
  ## Forwards the simulator with `pop`.
  self.prepareEdit(clearRedoDeque = self.mode in PlayModes)

  let popResult: PopResult
  unwrap self.nazoPuyoWrap:
    popResult = it.puyoPuyo.field.pop

  # update moving result
  self.moveResult.chainCount.inc
  var cellCounts {.noinit.}: array[Cell, int]
  cellCounts[Cell.None].assign 0
  staticFor(cell2, Hard .. Cell.Purple):
    let cellCount = popResult.cellCount cell2
    cellCounts[cell2].assign cellCount
    self.moveResult.popCounts[cell2].inc cellCount
  self.moveResult.detailPopCounts.add cellCounts
  self.moveResult.fullPopCounts.unsafeValue.add popResult.connectionCounts
  let h2g = popResult.hardToGarbageCount
  self.moveResult.hardToGarbageCount.inc h2g
  self.moveResult.detailHardToGarbageCount.add h2g

  # check settle
  unwrap self.nazoPuyoWrap:
    if it.puyoPuyo.field.isSettled:
      self.state.assign Stable

      if self.mode notin EditModes:
        self.operatingIndex.inc
        self.operatingPlacement.assign DefaultPlacement
    else:
      self.state.assign WillSettle

func forwardSettle(self: var Simulator) =
  ## Forwards the simulator with `settle`.
  self.prepareEdit(clearRedoDeque = self.mode in PlayModes)

  unwrap self.nazoPuyoWrap:
    it.puyoPuyo.field.settle

    # check pop
    if it.puyoPuyo.field.canPop:
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
    unwrap self.nazoPuyoWrap:
      if not it.puyoPuyo.field.isSettled:
        self.forwardSettle
      elif it.puyoPuyo.field.canPop:
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
  let steps = unwrap self.nazoPuyoWrap:
    it.puyoPuyo.steps

  if not detail:
    while self.undoDeque.peekLast.state notin {Stable, AfterEdit}:
      self.undoDeque.popLast
  self.load self.undoDeque.popLast

  if self.mode notin EditModes:
    unwrap self.nazoPuyoWrap:
      it.puyoPuyo.steps.assign steps

  if self.mode in PlayModes and self.state in {Stable, AfterEdit}:
    self.operatingPlacement.assign DefaultPlacement

func reset*(self: var Simulator) =
  ## Backwards the simulator to the pre-move state.
  unwrap self.nazoPuyoWrap:
    let nowSteps = it.puyoPuyo.steps
    self.undoAll
    it.puyoPuyo.steps.assign nowSteps

  self.operatingPlacement.assign DefaultPlacement

# ------------------------------------------------
# Mark
# ------------------------------------------------

func mark*(self: Simulator): MarkResult =
  ## Marks the steps in the Nazo Puyo in the simulator.
  var nazoWrap = self.nazoPuyoWrap
  if self.mode == EditorEdit:
    if self.state != AfterEdit:
      for index in 1 .. self.undoDeque.len:
        let elem = self.undoDeque[^index]
        if elem.state == AfterEdit:
          nazoWrap.assign elem.nazoPuyoWrap
          break
  else:
    if self.undoDeque.len > 0:
      nazoWrap.assign self.undoDeque.peekFirst.nazoPuyoWrap

  let nowSteps = self.nazoPuyoWrap.unwrap:
    it.puyoPuyo.steps
  nazoWrap.unwrap:
    it.puyoPuyo.steps.assign nowSteps
    it.mark self.operatingIndex

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
      case self.rule
      of Tsu:
        self.`rule=` Water
      of Water:
        self.`rule=` Tsu
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

const
  ModeKey = "mode"
  StrToMode = collect:
    for mode in SimulatorMode:
      {$mode: mode}

func initPon2Paths(): seq[string] =
  ## Returns `Pon2Paths`.
  var paths = @[Pon2Path]

  if Pon2Path.endsWith '/':
    paths.add "{Pon2Path}index.html".fmt

  if Pon2Path.endsWith "/index.html":
    paths.add Pon2Path.dup(removeSuffix(_, "/index.html"))

  paths

const Pon2Paths = initPon2Paths()

func toUri*(
    self: Simulator, clearPlacements = false, fqdn = Pon2
): StrErrorResult[Uri] =
  ## Returns the URI converted from the simulator.
  var uri = initUri()
  uri.scheme.assign "https"
  uri.hostname.assign $fqdn

  uri.path.assign (
    case fqdn
    of Pon2:
      Pon2Path
    of Ishikawa, Ips:
      unwrap self.nazoPuyoWrap:
        if it.goal != NoneGoal:
          "/simu/pn.html"
        else:
          case self.mode
          of PlayModes: "/simu/ps.html"
          of EditModes: "/simu/pe.html"
          of Replay: "/simu/pv.html"
  )

  var wrap = self.nazoPuyoWrap
  if clearPlacements:
    wrap.unwrap:
      for step in it.puyoPuyo.steps.mitems:
        if step.kind == PairPlacement:
          step.optPlacement.err
  let wrapQuery =
    ?wrap.toUriQuery(fqdn).context "Simulator that does not support URI conversion"
  uri.query.assign if fqdn == Pon2:
    "{ModeKey}={self.mode}&{wrapQuery}".fmt
  else:
    wrapQuery

  ok uri

func parseSimulator*(uri: Uri): StrErrorResult[Simulator] =
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
          mode.ok ?StrToMode[keyVal.value].context "Invalid mode: {keyVal.value}".fmt
      else:
        keyVals.add keyVal

    if mode.isErr:
      mode.ok DefaultMode

    ok Simulator.init(
      ?keyVals.encodeQuery.parseNazoPuyoWrap(fqdn).context "Invalid simulator: {uri}".fmt,
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

    ok Simulator.init ?uri.query.parseNazoPuyoWrap(fqdn).context "Invalid simulator: {uri}".fmt

func toExportUri*(
    self: Simulator, viewer = true, clearPlacements = true, fqdn = Pon2
): StrErrorResult[Uri] =
  ## Returns the URI of the simulator with any moves reset.
  var simulator = self

  simulator.undoAll
  simulator.mode = if viewer: ViewerPlay else: EditorPlay

  if not clearPlacements:
    let originalSteps = self.nazoPuyoWrap.unwrap:
      it.puyoPuyo.steps

    simulator.nazoPuyoWrap.unwrap:
      it.puyoPuyo.steps.assign originalSteps

  simulator.toUri(clearPlacements, fqdn)

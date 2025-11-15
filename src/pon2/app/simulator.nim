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

import std/[algorithm, strformat, sugar, uri]
import ./[key, nazopuyowrap]
import ../[core]
import
  ../private/
    [arrayutils, assign, deques, results2, staticfor, strutils2, tables2, utils]

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
    step*: tuple[idx: int, pivot: bool, col: Col]
    insert*: bool

  SimulatorDequeElem = object ## Element of Undo/Redo deques.
    nazoPuyoWrap: NazoPuyoWrap
    moveResult: MoveResult
    state: SimulatorState
    operatingIdx: int

  Simulator* = object ## Simulator for Puyo Puyo and Nazo Puyo.
    nazoPuyoWrap: NazoPuyoWrap
    moveResult: MoveResult

    mode: SimulatorMode
    state: SimulatorState

    editData: SimulatorEditData
    operatingPlacement: Placement
    operatingIdx: int

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
  DefaultPlcmt = Up2
  DefaultMoveRes = MoveResult.init true
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
    operatingIdx: simulator.operatingIdx,
  )

func init*(T: type Simulator, wrap: NazoPuyoWrap, mode = DefaultMode): T =
  T(
    nazoPuyoWrap: wrap,
    moveResult: DefaultMoveRes,
    mode: mode,
    state: if mode in EditModes: AfterEdit else: Stable,
    editData: DefaultEditData,
    operatingPlacement: DefaultPlcmt,
    operatingIdx: 0,
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
  self.operatingIdx.assign elem.operatingIdx

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

func operatingIdx*(self: Simulator): int =
  ## Returns the index of the step operated.
  self.operatingIdx

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
    self.nazoPuyoWrap.rule = rule

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

    self.editData.field.row.decRot
  else:
    if self.mode != EditorEdit:
      return

    let stepCnt = unwrapNazoPuyo self.nazoPuyoWrap:
      it.steps.len
    if self.editData.step.idx == 0:
      self.editData.step.idx.assign stepCnt
    else:
      self.editData.step.idx.dec

func moveCursorDown*(self: var Simulator) =
  ## Moves the cursor downward.
  if self.editData.focusField:
    if self.mode notin EditModes:
      return

    self.editData.field.row.incRot
  else:
    if self.mode != EditorEdit:
      return

    let stepCnt = unwrapNazoPuyo self.nazoPuyoWrap:
      it.steps.len
    if self.editData.step.idx == stepCnt:
      self.editData.step.idx.assign 0
    else:
      self.editData.step.idx.inc

func moveCursorRight*(self: var Simulator) =
  ## Moves the cursor rightward.
  if self.editData.focusField:
    if self.mode notin EditModes:
      return

    self.editData.field.col.incRot
  else:
    if self.mode != EditorEdit:
      return

    unwrapNazoPuyo self.nazoPuyoWrap:
      let stepCnt = it.steps.len
      if self.editData.step.idx >= stepCnt or
          it.steps[self.editData.step.idx].kind == PairPlacement:
        self.editData.step.pivot.toggle
      else:
        self.editData.step.col.incRot

func moveCursorLeft*(self: var Simulator) =
  ## Moves the cursor leftward.
  if self.editData.focusField:
    if self.mode notin EditModes:
      return

    self.editData.field.col.decRot
  else:
    if self.mode != EditorEdit:
      return

    unwrapNazoPuyo self.nazoPuyoWrap:
      let stepCnt = it.steps.len
      if self.editData.step.idx >= stepCnt or
          it.steps[self.editData.step.idx].kind == PairPlacement:
        self.editData.step.pivot.toggle
      else:
        self.editData.step.col.decRot

# ------------------------------------------------
# Edit - Delete
# ------------------------------------------------

func deleteStep*(self: var Simulator, idx: int) =
  ## Deletes the step.
  if self.mode != EditorEdit:
    return

  unwrapNazoPuyo self.nazoPuyoWrap:
    if idx >= it.steps.len:
      return

    self.editBlock:
      it.steps.del idx
      self.editData.step.idx.assign min(self.editData.step.idx, it.steps.len)

func deleteStep*(self: var Simulator) =
  ## Deletes the step at selecting index.
  self.deleteStep self.editData.step.idx

# ------------------------------------------------
# Edit - Write
# ------------------------------------------------

func writeCell(self: var Simulator, row: Row, col: Col, cell: Cell) =
  ## Writes the cell to the field.
  if self.mode notin EditModes:
    return

  self.editBlock:
    unwrapNazoPuyo self.nazoPuyoWrap:
      if self.editData.insert:
        if cell == Cell.None:
          it.field.delete row, col
        else:
          it.field.insert row, col, cell
      else:
        it.field[row, col] = cell

func writeCell*(self: var Simulator, row: Row, col: Col) =
  ## Writes the selecting cell to the field.
  case self.editData.editObj.kind
  of EditCell:
    self.writeCell row, col, self.editData.editObj.cell
  of EditRotate:
    discard

func writeCell(self: var Simulator, idx: int, pivot: bool, cell: Cell) =
  ## Writes the cell to the step.
  const ZeroArr = Col.initArrayWith 0

  if self.mode != EditorEdit:
    return

  unwrapNazoPuyo self.nazoPuyoWrap:
    if idx >= it.steps.len:
      case cell
      of Cell.None:
        return
      of Hard, Garbage:
        self.editBlock:
          it.steps.addLast Step.init(ZeroArr, cell == Hard)
      of Cell.Red .. Cell.Purple:
        self.editBlock:
          it.steps.addLast Step.init Pair.init(cell, cell)
    else:
      if cell == Cell.None:
        self.deleteStep idx
        return

      if self.editData.insert:
        self.editBlock:
          case cell
          of Cell.None:
            discard # not reached here
          of Hard, Garbage:
            it.steps.insert Step.init(ZeroArr, cell == Hard), idx
          of Cell.Red .. Cell.Purple:
            it.steps.insert Step.init(Pair.init(cell, cell)), idx
      else:
        self.editBlock:
          case cell
          of Cell.None:
            discard # not reached here
          of Hard, Garbage:
            let cellIsHard = cell == Hard
            case it.steps[idx].kind
            of PairPlacement, Rotate:
              it.steps[idx].assign Step.init(ZeroArr, cellIsHard)
            of StepKind.Garbages:
              it.steps[idx].dropHard.assign cellIsHard
          of Cell.Red .. Cell.Purple:
            case it.steps[idx].kind
            of PairPlacement:
              if pivot:
                it.steps[idx].pair.pivot = cell
              else:
                it.steps[idx].pair.rotor = cell
            of StepKind.Garbages, Rotate:
              it.steps[idx].assign Step.init Pair.init(cell, cell)

func writeRotate(self: var Simulator, idx: int, pivot: bool, cross: bool) =
  ## Writes the rotation to the step.
  if self.mode != EditorEdit:
    return

  unwrapNazoPuyo self.nazoPuyoWrap:
    if idx >= it.steps.len:
      self.editBlock:
        it.steps.addLast Step.init(cross = cross)
    else:
      if self.editData.insert:
        self.editBlock:
          it.steps.insert Step.init(cross = cross), idx
      else:
        case it.steps[idx].kind
        of PairPlacement, StepKind.Garbages:
          self.editBlock:
            it.steps[idx].assign Step.init(cross = cross)
        of Rotate:
          if it.steps[idx].cross != cross:
            self.editBlock:
              it.steps[idx].cross.toggle

func writeCell*(self: var Simulator, idx: int, pivot: bool) =
  ## Writes the selecting cell to the step.
  case self.editData.editObj.kind
  of EditCell:
    self.writeCell idx, pivot, self.editData.editObj.cell
  of EditRotate:
    self.writeRotate idx, pivot, self.editData.editObj.cross

func writeCell*(self: var Simulator, cell: Cell) =
  ## Writes the cell to the field or the step.
  if self.editData.focusField:
    self.writeCell self.editData.field.row, self.editData.field.col, cell
  else:
    self.writeCell self.editData.step.idx, self.editData.step.pivot, cell

func writeRotate*(self: var Simulator, cross: bool) =
  ## Writes the rotate to the field or the step.
  if self.editData.focusField:
    discard
  else:
    self.writeRotate self.editData.step.idx, self.editData.step.pivot, cross

func writeCnt*(self: var Simulator, idx: int, col: Col, cnt: int) =
  ## Writes the count to the step.
  if self.mode != EditorEdit:
    return

  unwrapNazoPuyo self.nazoPuyoWrap:
    if idx >= it.steps.len:
      return
    if it.steps[idx].kind != StepKind.Garbages:
      return

    self.editBlock:
      it.steps[idx].cnts[col].assign cnt

func writeCnt*(self: var Simulator, cnt: int) =
  ## Writes the count to the step.
  self.writeCnt self.editData.step.idx, self.editData.step.col, cnt

# ------------------------------------------------
# Edit - Shift
# ------------------------------------------------

func shiftFieldUp*(self: var Simulator) =
  ## Shifts the field upward.
  if self.mode != EditorEdit:
    return

  self.editBlock:
    unwrapNazoPuyo self.nazoPuyoWrap:
      it.field.shiftUp

func shiftFieldDown*(self: var Simulator) =
  ## Shifts the field downward.
  if self.mode != EditorEdit:
    return

  self.editBlock:
    unwrapNazoPuyo self.nazoPuyoWrap:
      it.field.shiftDown

func shiftFieldRight*(self: var Simulator) =
  ## Shifts the field rightward.
  if self.mode != EditorEdit:
    return

  self.editBlock:
    unwrapNazoPuyo self.nazoPuyoWrap:
      it.field.shiftRight

func shiftFieldLeft*(self: var Simulator) =
  ## Shifts the field leftward.
  if self.mode != EditorEdit:
    return

  self.editBlock:
    unwrapNazoPuyo self.nazoPuyoWrap:
      it.field.shiftLeft

# ------------------------------------------------
# Edit - Flip
# ------------------------------------------------

func flipFieldVertical*(self: var Simulator) =
  ## Flips the field vertically.
  if self.mode != EditorEdit:
    return

  self.editBlock:
    unwrapNazoPuyo self.nazoPuyoWrap:
      it.field.flipVertical

func flipFieldHorizontal*(self: var Simulator) =
  ## Flips the field horizontally.
  if self.mode != EditorEdit:
    return

  self.editBlock:
    unwrapNazoPuyo self.nazoPuyoWrap:
      it.field.flipHorizontal

func flip*(self: var Simulator) =
  ## Flips the field or the step.
  if self.editData.focusField:
    self.flipFieldHorizontal
  else:
    if self.mode != EditorEdit:
      return

    unwrapNazoPuyo self.nazoPuyoWrap:
      if self.editData.step.idx >= it.steps.len:
        return

      self.editBlock:
        case it.steps[self.editData.step.idx].kind
        of PairPlacement:
          it.steps[self.editData.step.idx].pair.swap
        of StepKind.Garbages:
          it.steps[self.editData.step.idx].cnts.reverse
        of Rotate:
          it.steps[self.editData.step.idx].cross.toggle

# ------------------------------------------------
# Edit - Goal
# ------------------------------------------------

const
  DefaultColor = All
  DefaultVal = 0

func `goalKind=`*(self: var Simulator, kind: GoalKind) =
  ## Sets the goal kind.
  if self.mode != EditorEdit:
    return
  if self.nazoPuyoWrap.optGoal.isErr:
    return

  self.editBlock:
    self.nazoPuyoWrap.optGoal.unsafeValue.kind.assign kind

    if kind in ColorKinds:
      if self.nazoPuyoWrap.optGoal.unsafeValue.optColor.isErr:
        self.nazoPuyoWrap.optGoal.unsafeValue.optColor.ok DefaultColor
    else:
      if self.nazoPuyoWrap.optGoal.unsafeValue.optColor.isOk:
        self.nazoPuyoWrap.optGoal.unsafeValue.optColor.err

    if kind in ValKinds:
      if self.nazoPuyoWrap.optGoal.unsafeValue.optVal.isErr:
        self.nazoPuyoWrap.optGoal.unsafeValue.optVal.ok DefaultVal
    else:
      if self.nazoPuyoWrap.optGoal.unsafeValue.optVal.isOk:
        self.nazoPuyoWrap.optGoal.unsafeValue.optVal.err

func `goalColor=`*(self: var Simulator, color: GoalColor) =
  ## Sets the goal color.
  if self.mode != EditorEdit:
    return
  if self.nazoPuyoWrap.optGoal.isErr:
    return

  let kind = self.nazoPuyoWrap.optGoal.unsafeValue.kind
  if kind in NoColorKinds:
    return

  self.editBlock:
    self.nazoPuyoWrap.optGoal.unsafeValue.optColor.ok color

func `goalVal=`*(self: var Simulator, val: GoalVal) =
  ## Sets the goal value.
  if self.mode != EditorEdit:
    return
  if self.nazoPuyoWrap.optGoal.isErr:
    return

  let kind = self.nazoPuyoWrap.optGoal.unsafeValue.kind
  if kind in NoValKinds:
    return

  self.editBlock:
    self.nazoPuyoWrap.optGoal.unsafeValue.optVal.ok val

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
  unwrapNazoPuyo self.nazoPuyoWrap:
    if self.operatingIdx >= it.steps.len:
      return
    if self.mode in EditModes:
      return

    self.prepareEdit(clearRedoDeque = self.mode in PlayModes)

    self.moveResult.assign DefaultMoveRes

    # set placement
    if self.mode in PlayModes:
      if it.steps[self.operatingIdx].kind != PairPlacement:
        discard
      elif skip:
        it.steps[self.operatingIdx].optPlacement.err
      elif replay:
        discard
      else:
        it.steps[self.operatingIdx].optPlacement.ok self.operatingPlacement

    let step = it.steps[self.operatingIdx]
    it.field.apply step

    # set state
    if step.kind == Rotate:
      if it.field.isSettled:
        self.state.assign Stable

        if self.mode notin EditModes:
          self.operatingIdx.inc
          self.operatingPlacement.assign DefaultPlcmt
      else:
        self.state.assign WillSettle
    elif it.field.canPop:
      self.state.assign WillPop
    else:
      self.state.assign Stable
      self.operatingIdx.inc
      self.operatingPlacement.assign DefaultPlcmt

func forwardPop(self: var Simulator) =
  ## Forwards the simulator with `pop`.
  self.prepareEdit(clearRedoDeque = self.mode in PlayModes)

  let popRes: PopResult
  unwrapNazoPuyo self.nazoPuyoWrap:
    popRes = it.field.pop

  # update moving result
  self.moveResult.chainCnt.inc
  var cellCnts {.noinit.}: array[Cell, int]
  cellCnts[Cell.None].assign 0
  staticFor(cell2, Hard .. Cell.Purple):
    let cellCnt = popRes.cellCnt cell2
    cellCnts[cell2].assign cellCnt
    self.moveResult.popCnts[cell2].inc cellCnt
  self.moveResult.detailPopCnts.add cellCnts
  self.moveResult.fullPopCnts.unsafeValue.add popRes.connCnts
  let h2g = popRes.hardToGarbageCnt
  self.moveResult.hardToGarbageCnt.inc h2g
  self.moveResult.detailHardToGarbageCnt.add h2g

  # check settle
  unwrapNazoPuyo self.nazoPuyoWrap:
    if it.field.isSettled:
      self.state.assign Stable

      if self.mode notin EditModes:
        self.operatingIdx.inc
        self.operatingPlacement.assign DefaultPlcmt
    else:
      self.state.assign WillSettle

func forwardSettle(self: var Simulator) =
  ## Forwards the simulator with `settle`.
  self.prepareEdit(clearRedoDeque = self.mode in PlayModes)

  unwrapNazoPuyo self.nazoPuyoWrap:
    it.field.settle

    # check pop
    if it.field.canPop:
      self.state.assign WillPop
    else:
      self.state.assign Stable

      if self.mode notin EditModes:
        self.operatingIdx.inc
        self.operatingPlacement.assign DefaultPlcmt

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
    unwrapNazoPuyo self.nazoPuyoWrap:
      if not it.field.isSettled:
        self.forwardSettle
      elif it.field.canPop:
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
  let steps = unwrapNazoPuyo self.nazoPuyoWrap:
    it.steps

  if not detail:
    while self.undoDeque.peekLast.state notin {Stable, AfterEdit}:
      self.undoDeque.popLast
  self.load self.undoDeque.popLast

  if self.mode notin EditModes:
    unwrapNazoPuyo self.nazoPuyoWrap:
      it.steps.assign steps

  if self.mode in PlayModes and self.state in {Stable, AfterEdit}:
    self.operatingPlacement.assign DefaultPlcmt

func reset*(self: var Simulator) =
  ## Backwards the simulator to the pre-move state.
  unwrapNazoPuyo self.nazoPuyoWrap:
    let nowSteps = it.steps
    self.undoAll
    it.steps.assign nowSteps

  self.operatingPlacement.assign DefaultPlcmt

# ------------------------------------------------
# Mark
# ------------------------------------------------

func mark*(self: Simulator): Opt[MarkResult] =
  ## Marks the steps in the Nazo Puyo in the simulator.
  if self.nazoPuyoWrap.optGoal.isErr:
    return err()

  var nazoWrap = self.nazoPuyoWrap
  if self.mode == EditorEdit:
    if self.state != AfterEdit:
      for idx in 1 .. self.undoDeque.len:
        let elem = self.undoDeque[^idx]
        if elem.state == AfterEdit:
          nazoWrap.assign elem.nazoPuyoWrap
          break
  else:
    if self.undoDeque.len > 0:
      nazoWrap.assign self.undoDeque.peekFirst.nazoPuyoWrap

  let nowSteps = self.nazoPuyoWrap.unwrapNazoPuyo:
    it.steps
  nazoWrap.unwrapNazoPuyo:
    it.steps.assign nowSteps
    ok itNazo.mark self.operatingIdx

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
  var catched = true

  case self.mode
  of PlayModes:
    # mode
    if key == static(KeyEvent.init 't'):
      if self.mode == ViewerPlay:
        self.`mode=` ViewerEdit
      else:
        self.`mode=` EditorEdit
    # rotate operating plcmt
    elif key == static(KeyEvent.init 'k'):
      self.rotatePlacementRight
    elif key == static(KeyEvent.init 'j'):
      self.rotatePlacementLeft
    # move operating plcmt
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
      catched.assign false
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
    # write cnt
    elif (let cnt = DigitKeys.find key; cnt >= 0):
      self.writeCnt cnt
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
      catched.assign false
  of Replay:
    # forward / backward / reset
    if key in static([KeyEvent.init 'x', KeyEvent.init 'w']):
      self.backward
    elif key in static([KeyEvent.init 'z', KeyEvent.init 'W']):
      self.reset
    elif key in static([KeyEvent.init 'c', KeyEvent.init 's']):
      self.forward(replay = true)
    else:
      catched.assign false

  catched

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

func toUri*(self: Simulator, clearPlacements = false, fqdn = Pon2): Res[Uri] =
  ## Returns the URI converted from the simulator.
  var uri = initUri()
  uri.scheme = "https"
  uri.hostname = $fqdn

  uri.path =
    case fqdn
    of Pon2:
      Pon2Path
    of Ishikawa, Ips:
      if self.nazoPuyoWrap.optGoal.isOk:
        "/simu/pn.html"
      else:
        case self.mode
        of PlayModes: "/simu/ps.html"
        of EditModes: "/simu/pe.html"
        of Replay: "/simu/pv.html"

  var wrap = self.nazoPuyoWrap
  if clearPlacements:
    wrap.unwrapNazoPuyo:
      for step in it.steps.mitems:
        if step.kind == PairPlacement:
          step.optPlacement.err
  let wrapQuery =
    ?wrap.toUriQuery(fqdn).context "Simulator that does not support URI conversion"
  uri.query = if fqdn == Pon2: "{ModeKey}={self.mode}&{wrapQuery}".fmt else: wrapQuery

  ok uri

func parseSimulator*(uri: Uri): Res[Simulator] =
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
          mode.ok ?StrToMode.getRes(keyVal.value).context "Invalid mode: {keyVal.value}".fmt
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
): Res[Uri] =
  ## Returns the URI of the simulator with any moves reset.
  var sim = self

  sim.undoAll
  sim.mode = if viewer: ViewerPlay else: EditorPlay

  sim.toUri(clearPlacements, fqdn)

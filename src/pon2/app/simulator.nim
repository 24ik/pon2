## This module implements simulators.
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
    [arrayops2, assign3, deques2, results2, staticfor2, strutils2, tables2, utils]

export deques2, results2

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

  SimulatorEditData* = object ## Edit information.
    cell*: Cell
    focusField*: bool
    field*: tuple[row: Row, col: Col]
    step*: tuple[idx: int, pivot: bool, col: Col]
    insert*: bool

  SimulatorDequeElem = object ## Element of Undo/Redo deques.
    nazoPuyoWrap: NazoPuyoWrap
    moveResult: MoveResult
    state: SimulatorState

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

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const
  DefaultMode = ViewerPlay
  DefaultPlcmt = Up2
  DefaultMoveRes = MoveResult.init true
  DefaultEditData = SimulatorEditData(
    cell: None,
    focusField: true,
    field: (Row.low, Col.low),
    step: (0, true, Col.low),
    insert: false,
  )

func init(T: type SimulatorDequeElem, simulator: Simulator): T {.inline.} =
  T(
    nazoPuyoWrap: simulator.nazoPuyoWrap,
    moveResult: simulator.moveResult,
    state: simulator.state,
  )

func init*(T: type Simulator, wrap: NazoPuyoWrap, mode = DefaultMode): T {.inline.} =
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
): T {.inline.} =
  T.init(NazoPuyoWrap.init nazo, mode)

func init*[F: TsuField or WaterField](
    T: type Simulator, puyoPuyo: PuyoPuyo[F], mode = DefaultMode
): T {.inline.} =
  T.init(NazoPuyoWrap.init puyoPuyo, mode)

func init*(T: type Simulator, mode = DefaultMode): T {.inline.} =
  T.init(NazoPuyoWrap.init, mode)

# ------------------------------------------------
# Undo / Redo
# ------------------------------------------------

func load(self: var Simulator, elem: SimulatorDequeElem) {.inline.} =
  ## Loads the deque elem.
  self.nazoPuyoWrap.assign elem.nazoPuyoWrap
  self.moveResult.assign elem.moveResult
  self.state.assign elem.state

func undo*(self: var Simulator) {.inline.} =
  ## Performs undo.
  if self.mode notin EditModes:
    return
  if self.undoDeque.len == 0:
    return

  self.redoDeque.addLast SimulatorDequeElem.init self
  self.load self.undoDeque.popLast

func redo*(self: var Simulator) {.inline.} =
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

func rule*(self: Simulator): Rule {.inline.} =
  ## Returns the rule of the Puyo Puyo or Nazo Puyo.
  self.nazoPuyoWrap.rule

func nazoPuyoWrap*(self: Simulator): NazoPuyoWrap {.inline.} =
  ## Returns the Nazo Puyo wrapper of the simulator.
  self.nazoPuyoWrap

func moveResult*(self: Simulator): MoveResult {.inline.} =
  ## Returns the moving result of the simulator.
  self.moveResult

func mode*(self: Simulator): SimulatorMode {.inline.} =
  ## Returns the mode of the simulator.
  self.mode

func state*(self: Simulator): SimulatorState {.inline.} =
  ## Returns the state of the simulator.
  self.state

func editData*(self: Simulator): SimulatorEditData {.inline.} =
  ## Returns the edit information.
  self.editData

func operatingPlacement*(self: Simulator): Placement {.inline.} =
  ## Returns the operating placement of the simulator.
  self.operatingPlacement

func operatingIdx*(self: Simulator): int {.inline.} =
  ## Returns the index of the step operated.
  self.operatingIdx

# ------------------------------------------------
# Property - Setter
# ------------------------------------------------

func undoAll(self: var Simulator) {.inline.} =
  ## Loads the first data in undo deque.
  ## If the undo deque is empty, does nothing.
  if self.undoDeque.len == 0:
    return

  self.redoDeque.addLast SimulatorDequeElem.init self
  self.load self.undoDeque.peekFirst

  self.undoDeque.clear

func prepareEdit(self: var Simulator) {.inline.} =
  ## Saves the current simulator to the undo deque and clears the redo deque.
  self.undoDeque.addLast SimulatorDequeElem.init self
  self.redoDeque.clear

template editBlock(self: var Simulator, body: untyped) =
  ## Saves the current simulator to the undo deque and clears the redo deque
  ## and then runs `body`.
  ## The state of the simulator is set to `AfterEdit`.
  self.prepareEdit
  body
  self.state.assign AfterEdit

func `rule=`*(self: var Simulator, rule: Rule) {.inline.} =
  ## Sets the rule of the simulator.
  if self.mode != EditorEdit:
    return
  if rule == self.rule:
    return

  self.editBlock:
    self.nazoPuyoWrap.rule = rule

func `mode=`*(self: var Simulator, mode: SimulatorMode) {.inline.} =
  ## Sets the mode of the simulator.
  case self.mode
  of ViewerPlay:
    if mode != ViewerEdit:
      return

    self.undoAll
  of ViewerEdit:
    if mode != ViewerPlay:
      return

    self.undoAll
  of EditorPlay:
    if mode != EditorEdit:
      return

    self.undoAll
  of EditorEdit:
    if mode != EditorPlay:
      return

    while self.state != AfterEdit:
      self.undo
  of Replay:
    return

  self.mode.assign mode
  self.operatingPlacement.assign DefaultPlcmt
  self.operatingIdx.assign 0
  self.undoDeque.clear
  self.redoDeque.clear

  self.state.assign if mode in EditModes: AfterEdit else: Stable

func `editCell=`*(self: var Simulator, cell: Cell) {.inline.} =
  ## Writes `editData.cell`.
  if self.mode notin EditModes:
    return

  self.editData.cell.assign cell

# ------------------------------------------------
# Edit - Cursor
# ------------------------------------------------

func moveCursorUp*(self: var Simulator) {.inline.} =
  ## Moves the cursor upward.
  if self.editData.focusField:
    if self.mode notin EditModes:
      return

    self.editData.field.row.decRot
  else:
    if self.mode != EditorEdit:
      return

    let stepCnt = runIt self.nazoPuyoWrap:
      it.steps.len
    if self.editData.step.idx == 0:
      self.editData.step.idx.assign stepCnt
    else:
      self.editData.step.idx.dec

func moveCursorDown*(self: var Simulator) {.inline.} =
  ## Moves the cursor downward.
  if self.editData.focusField:
    if self.mode notin EditModes:
      return

    self.editData.field.row.incRot
  else:
    if self.mode != EditorEdit:
      return

    let stepCnt = runIt self.nazoPuyoWrap:
      it.steps.len
    if self.editData.step.idx == stepCnt:
      self.editData.step.idx.assign 0
    else:
      self.editData.step.idx.inc

func moveCursorRight*(self: var Simulator) {.inline.} =
  ## Moves the cursor rightward.
  if self.editData.focusField:
    if self.mode notin EditModes:
      return

    self.editData.field.col.incRot
  else:
    if self.mode != EditorEdit:
      return

    runIt self.nazoPuyoWrap:
      let stepCnt = it.steps.len
      if self.editData.step.idx >= stepCnt or
          it.steps[self.editData.step.idx].kind == PairPlacement:
        self.editData.step.pivot.toggle
      else:
        self.editData.step.col.incRot

func moveCursorLeft*(self: var Simulator) {.inline.} =
  ## Moves the cursor leftward.
  if self.editData.focusField:
    if self.mode notin EditModes:
      return

    self.editData.field.col.decRot
  else:
    if self.mode != EditorEdit:
      return

    runIt self.nazoPuyoWrap:
      let stepCnt = it.steps.len
      if self.editData.step.idx >= stepCnt or
          it.steps[self.editData.step.idx].kind == PairPlacement:
        self.editData.step.pivot.toggle
      else:
        self.editData.step.col.decRot

# ------------------------------------------------
# Edit - Delete
# ------------------------------------------------

func deleteStep*(self: var Simulator, idx: int) {.inline.} =
  ## Deletes the step.
  if self.mode != EditorEdit:
    return

  runIt self.nazoPuyoWrap:
    if idx >= it.steps.len:
      return

    self.editBlock:
      it.steps.delete idx
      self.editData.step.idx.assign min(self.editData.step.idx, it.steps.len)

func deleteStep*(self: var Simulator) {.inline.} =
  ## Deletes the step at selecting index.
  self.deleteStep self.editData.step.idx

# ------------------------------------------------
# Edit - Write
# ------------------------------------------------

func writeCell(self: var Simulator, row: Row, col: Col, cell: Cell) {.inline.} =
  ## Writes the cell to the field.
  if self.mode notin EditModes:
    return

  self.editBlock:
    runIt self.nazoPuyoWrap:
      if self.editData.insert:
        if cell == None:
          it.field.delete row, col
        else:
          it.field.insert row, col, cell
      else:
        it.field[row, col] = cell

func writeCell*(self: var Simulator, row: Row, col: Col) {.inline.} =
  ## Writes the selecting cell to the field.
  self.writeCell row, col, self.editData.cell

func writeCell(self: var Simulator, idx: int, pivot: bool, cell: Cell) {.inline.} =
  ## Writes the cell to the step.
  const ZeroArr = initArrWith[Col, int](0)

  if self.mode != EditorEdit:
    return

  runIt self.nazoPuyoWrap:
    if idx >= it.steps.len:
      case cell
      of None:
        return
      of Hard, Garbage:
        self.editBlock:
          it.steps.addLast Step.init(ZeroArr, cell == Hard)
      of Cell.Red .. Cell.Purple:
        self.editBlock:
          it.steps.addLast Step.init Pair.init(cell, cell)
    else:
      if cell == None:
        self.deleteStep idx
        return

      if self.editData.insert:
        self.editBlock:
          case cell
          of None:
            discard # not reached here
          of Hard, Garbage:
            it.steps.insert Step.init(ZeroArr, cell == Hard), idx
          of Cell.Red .. Cell.Purple:
            it.steps.insert Step.init(Pair.init(cell, cell)), idx
      else:
        self.editBlock:
          case cell
          of None:
            discard # not reached here
          of Hard, Garbage:
            let cellIsHard = cell == Hard
            case it.steps[idx].kind
            of PairPlacement:
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
            of StepKind.Garbages:
              it.steps[idx].assign Step.init Pair.init(cell, cell)

func writeCell*(self: var Simulator, idx: int, pivot: bool) {.inline.} =
  ## Writes the selecting cell to the step.
  self.writeCell idx, pivot, self.editData.cell

func writeCell*(self: var Simulator, cell: Cell) {.inline.} =
  ## Writes the cell to the field or the step.
  if self.editData.focusField:
    self.writeCell self.editData.field.row, self.editData.field.col, cell
  else:
    self.writeCell self.editData.step.idx, self.editData.step.pivot, cell

# ------------------------------------------------
# Edit - Shift
# ------------------------------------------------

func shiftFieldUp*(self: var Simulator) {.inline.} =
  ## Shifts the field upward.
  if self.mode != EditorEdit:
    return

  self.editBlock:
    runIt self.nazoPuyoWrap:
      it.field.shiftUp

func shiftFieldDown*(self: var Simulator) {.inline.} =
  ## Shifts the field downward.
  if self.mode != EditorEdit:
    return

  self.editBlock:
    runIt self.nazoPuyoWrap:
      it.field.shiftDown

func shiftFieldRight*(self: var Simulator) {.inline.} =
  ## Shifts the field rightward.
  if self.mode != EditorEdit:
    return

  self.editBlock:
    runIt self.nazoPuyoWrap:
      it.field.shiftRight

func shiftFieldLeft*(self: var Simulator) {.inline.} =
  ## Shifts the field leftward.
  if self.mode != EditorEdit:
    return

  self.editBlock:
    runIt self.nazoPuyoWrap:
      it.field.shiftLeft

# ------------------------------------------------
# Edit - Flip
# ------------------------------------------------

func flipFieldVertical*(self: var Simulator) {.inline.} =
  ## Flips the field vertically.
  if self.mode != EditorEdit:
    return

  self.editBlock:
    runIt self.nazoPuyoWrap:
      it.field.flipVertical

func flipFieldHorizontal*(self: var Simulator) {.inline.} =
  ## Flips the field horizontally.
  if self.mode != EditorEdit:
    return

  self.editBlock:
    runIt self.nazoPuyoWrap:
      it.field.flipHorizontal

func flip*(self: var Simulator) {.inline.} =
  ## Flips the field or the step.
  if self.editData.focusField:
    self.flipFieldHorizontal
  else:
    if self.mode != EditorEdit:
      return

    runIt self.nazoPuyoWrap:
      if self.editData.step.idx >= it.steps.len:
        return

      self.editBlock:
        case it.steps[self.editData.step.idx].kind
        of PairPlacement:
          it.steps[self.editData.step.idx].pair.swap
        of StepKind.Garbages:
          it.steps[self.editData.step.idx].cnts.reverse

# ------------------------------------------------
# Edit - Goal
# ------------------------------------------------

const
  DefaultColor = All
  DefaultVal = 0

func `goalKind=`*(self: var Simulator, kind: GoalKind) {.inline.} =
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

func `goalColor=`*(self: var Simulator, color: GoalColor) {.inline.} =
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

func `goalVal=`*(self: var Simulator, val: GoalVal) {.inline.} =
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

func toggleFocus*(self: var Simulator) {.inline.} =
  ## Toggles focusing field or not.
  self.editData.focusField.toggle

func toggleInsert*(self: var Simulator) {.inline.} =
  ## Toggles inserting or not.
  self.editData.insert.toggle

# ------------------------------------------------
# Play - Placement
# ------------------------------------------------

func movePlacementRight*(self: var Simulator) {.inline.} =
  ## Moves the next placement right.
  self.operatingPlacement.moveRight

func movePlacementLeft*(self: var Simulator) {.inline.} =
  ## Moves the next placement left.
  self.operatingPlacement.moveLeft

func rotatePlacementRight*(self: var Simulator) {.inline.} =
  ## Rotates the next placement right (clockwise).
  self.operatingPlacement.rotateRight

func rotatePlacementLeft*(self: var Simulator) {.inline.} =
  ## Rotates the next placement left (counterclockwise).
  self.operatingPlacement.rotateLeft

# ------------------------------------------------
# Forward / Backward
# ------------------------------------------------

func forward*(self: var Simulator, replay = false, skip = false) {.inline.} =
  ## Forwards the simulator.
  ## This functions requires that the initial field is settled.
  ## `skip` is prioritized over `replay`.
  runIt self.nazoPuyoWrap:
    case self.state
    of Stable:
      if self.operatingIdx >= it.steps.len:
        return
      if self.mode in EditModes:
        return

      self.prepareEdit

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

      it.field.apply it.steps[self.operatingIdx]

      # check pop
      if it.field.canPop:
        self.state.assign WillPop
      else:
        self.state.assign Stable
        self.operatingIdx.inc
        self.operatingPlacement.assign DefaultPlcmt
    of WillPop:
      self.prepareEdit

      let popRes = it.field.pop

      # update moving result
      self.moveResult.chainCnt.inc
      var cellCnts {.noinit.}: array[Cell, int]
      cellCnts[None].assign 0
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
      if it.field.isSettled:
        self.state.assign Stable
        self.operatingIdx.inc
        self.operatingPlacement.assign DefaultPlcmt
      else:
        self.state.assign WillSettle
    of WillSettle:
      self.prepareEdit

      # check pop
      it.field.settle
      if it.field.canPop:
        self.state.assign WillPop
      else:
        self.state.assign Stable
        self.operatingIdx.inc
        self.operatingPlacement.assign DefaultPlcmt
    of AfterEdit:
      if not it.field.isSettled:
        self.prepareEdit
        self.state.assign WillSettle
        self.forward
        self.undoDeque.popLast
      elif it.field.canPop:
        self.prepareEdit
        self.state.assign WillPop
        self.forward
        self.undoDeque.popLast
      else:
        discard

func backward*(self: var Simulator, detail = false) {.inline.} =
  ## Backwards the simulator.
  if self.undoDeque.len == 0:
    return

  # save the steps to keep the placements
  let steps = runIt self.nazoPuyoWrap:
    it.steps

  if self.mode in PlayModes and self.state == Stable:
    self.operatingIdx.dec

  if not detail:
    while self.undoDeque.peekLast.state notin {Stable, AfterEdit}:
      self.undoDeque.popLast
  self.load self.undoDeque.popLast

  if self.mode in PlayModes:
    self.operatingPlacement.assign DefaultPlcmt
    runIt self.nazoPuyoWrap:
      it.steps.assign steps

func reset*(self: var Simulator) {.inline.} =
  ## Backwards the simulator to the initial one.
  if self.undoDeque.len == 0:
    return

  # save the steps to keep the placements
  let steps = runIt self.nazoPuyoWrap:
    it.steps

  self.load self.undoDeque.peekFirst
  if self.mode in PlayModes:
    runIt self.nazoPuyoWrap:
      it.steps.assign steps
  self.operatingPlacement.assign DefaultPlcmt
  self.operatingIdx.assign 0
  self.undoDeque.clear
  self.redoDeque.clear

# ------------------------------------------------
# Keyboard
# ------------------------------------------------

func operate*(self: var Simulator, key: KeyEvent): bool {.inline, discardable.} =
  ## Performs an action specified by the key.
  ## Returns `true` if the key is catched.
  var catched = true

  case self.mode
  of ViewerPlay, EditorPlay:
    # mode
    if key == static(KeyEvent.init 'm'):
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
    elif key in static([KeyEvent.init '2', KeyEvent.init 'w']):
      self.backward
    elif key in static([KeyEvent.init('2', shift = true), KeyEvent.init 'W']):
      self.backward(detail = true)
    elif key == static(KeyEvent.init '1'):
      self.reset
    elif key == static(KeyEvent.init "Space"):
      self.forward(skip = true)
    elif key == static(KeyEvent.init '3'):
      self.forward(replay = true)
    else:
      catched.assign false
  of ViewerEdit, EditorEdit:
    # mode
    if key == static(KeyEvent.init 'm'):
      if self.mode == ViewerEdit:
        self.`mode=` ViewerPlay
      else:
        self.`mode=` EditorPlay
    # toggle insert / focus
    elif key == static(KeyEvent.init 'i'):
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
      self.writeCell None
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
    elif key == static(KeyEvent.init 'Y'):
      self.redo
    # forward / backward / reset
    elif key == static(KeyEvent.init '3'):
      self.forward
    elif key == static(KeyEvent.init '2'):
      self.backward
    elif key == static(KeyEvent.init('2', shift = true)):
      self.backward(detail = true)
    elif key == static(KeyEvent.init '1'):
      self.reset
    else:
      catched.assign false
  of Replay:
    # forward / backward / reset
    if key in static([KeyEvent.init '2', KeyEvent.init 'w']):
      self.backward
    elif key in static([KeyEvent.init('2', shift = true), KeyEvent.init 'W']):
      self.backward(detail = true)
    elif key == static(KeyEvent.init '1'):
      self.reset
    elif key in static([KeyEvent.init '3', KeyEvent.init 's']):
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

func toUriQuery*(
    self: Simulator, clearPlacements = false, fqdn = Pon2
): Res[string] {.inline.} =
  ## Returns the URI query converted from the simulator.
  var wrap = self.nazoPuyoWrap
  if clearPlacements:
    wrap.runIt:
      for step in it.steps.mitems:
        if step.kind == PairPlacement:
          step.optPlacement.err

  let wrapQuery =
    ?wrap.toUriQuery(fqdn).context "Simulator that does not support URI conversion"
  case fqdn
  of Pon2:
    ok if self.mode == DefaultMode:
      wrapQuery
    else:
      "{ModeKey}={self.mode}&{wrapQuery}".fmt
  else:
    ok wrapQuery

func parseSimulator*(query: string, fqdn: SimulatorFqdn): Res[Simulator] {.inline.} =
  ## Returns the simulator converted from the URI.
  ## If `fqdn` is `Ishikawa` or `Ips`, the mode of result simulator is set to
  ## `ViewerPlay`.
  case fqdn
  of Pon2:
    var
      keyVals = newSeq[tuple[key: string, value: string]]()
      mode = Opt[SimulatorMode].err
    for keyVal in query.decodeQuery:
      if keyVal.key == ModeKey:
        if mode.isOk:
          return err "Invalid simulator (multiple mode detected): {query}".fmt
        else:
          mode.ok ?StrToMode.getRes(keyVal.value).context "Invalid mode: {keyVal.value}".fmt
      else:
        keyVals.add keyVal

    if mode.isErr:
      mode.ok DefaultMode

    ok Simulator.init(
      ?keyVals.encodeQuery.parseNazoPuyoWrap(fqdn).context "Invalid simulator: {query}".fmt,
      mode.unsafeValue,
    )
  of Ishikawa, Ips:
    ok Simulator.init ?query.parseNazoPuyoWrap(fqdn).context "Invalid simulator: {query}".fmt

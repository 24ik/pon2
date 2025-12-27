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
    PlayViewer
    PlayEditor
    EditViewer
    EditEditor
    Replay

  SimulatorState* {.pure.} = enum
    ## Simulator's state.
    Stable
    WillPop
    WillSettle
    AfterEdit

  SimulatorEditData* = object ## Edit information.
    selecting*: tuple[cellOpt: Opt[Cell], crossOpt: Opt[bool]]
    field*: tuple[row: Row, col: Col]
    steps*: tuple[index: int, pivot: bool, col: Col]
    focusField*: bool
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
    operating: tuple[index: int, placement: Placement]

    undoDeque: Deque[SimulatorDequeElem]
    redoDeque: Deque[SimulatorDequeElem]

const
  PlayModes* = {PlayViewer, PlayEditor}
  EditModes* = {EditViewer, EditEditor}
  ViewerModes* = {PlayViewer, EditViewer}
  EditorModes* = {PlayEditor, EditEditor}

  Pon2Path* {.define: "pon2.path".} = "/pon2/stable/studio/"

static:
  doAssert Pon2Path.startsWith '/'

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const
  DefaultMode = PlayViewer
  DefaultPlacement = Up2
  DefaultMoveResult = MoveResult.init
  DefaultEditData = SimulatorEditData(
    selecting: (Opt[Cell].ok Cell.None, Opt[bool].err),
    field: (Row.low, Col.low),
    steps: (0, true, Col.low),
    focusField: true,
    insert: false,
  )

func init(T: type SimulatorDequeElem, simulator: Simulator): T =
  T(
    nazoPuyo: simulator.nazoPuyo,
    moveResult: simulator.moveResult,
    state: simulator.state,
    operatingIndex: simulator.operating.index,
  )

func init*(T: type Simulator, nazoPuyo: NazoPuyo, mode = DefaultMode): T =
  T(
    nazoPuyo: nazoPuyo,
    moveResult: DefaultMoveResult,
    mode: mode,
    state: if mode in EditModes: AfterEdit else: Stable,
    editData: DefaultEditData,
    operating: (0, DefaultPlacement),
    undoDeque: Deque[SimulatorDequeElem].init,
    redoDeque: Deque[SimulatorDequeElem].init,
  )

func init*(T: type Simulator, puyoPuyo: PuyoPuyo, mode = DefaultMode): T =
  T.init(NazoPuyo.init(puyoPuyo, Goal.init), mode)

func init*(T: type Simulator, mode = DefaultMode): T =
  T.init(NazoPuyo.init, mode)

# ------------------------------------------------
# Undo / Redo / Edit
# ------------------------------------------------

func load(self: var Simulator, elem: SimulatorDequeElem) =
  ## Loads the deque elem.
  self.nazoPuyo.assign elem.nazoPuyo
  self.moveResult.assign elem.moveResult
  self.state.assign elem.state
  self.operating.index.assign elem.operatingIndex

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

func undoAll(self: var Simulator) =
  ## Loads the data before any moves and clears the redo deque.
  if self.undoDeque.len == 0:
    return

  if self.mode == EditEditor:
    while self.state != AfterEdit:
      self.load self.undoDeque.popLast
  else:
    self.load self.undoDeque.peekFirst
    self.undoDeque.clear

  self.redoDeque.clear

template edit(self: var Simulator, body: untyped): untyped =
  ## Runs `body` with edit wrappers.
  let oldSimulator = self

  body

  if self != oldSimulator:
    self.undoDeque.addLast SimulatorDequeElem.init oldSimulator
    self.redoDeque.clear
    self.state.assign AfterEdit

# ------------------------------------------------
# Mark
# ------------------------------------------------

func mark*(self: Simulator): MarkResult =
  ## Marks the steps in the Nazo Puyo in the simulator.
  var simulator = self
  simulator.undoAll
  simulator.nazoPuyo.puyoPuyo.steps.assign self.nazoPuyo.puyoPuyo.steps

  simulator.nazoPuyo.mark self.operating.index

# ------------------------------------------------
# Property - Getter
# ------------------------------------------------

func rule*(self: Simulator): Rule =
  ## Returns the rule of the Nazo Puyo in the simulator.
  self.nazoPuyo.puyoPuyo.field.rule

func nazoPuyo*(self: Simulator): NazoPuyo =
  ## Returns the Nazo Puyo in the simulator.
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
  ## Returns the edit information of the simulator.
  self.editData

func operating*(self: Simulator): tuple[index: int, placement: Placement] =
  ## Returns the operating data of the simulator.
  self.operating

# ------------------------------------------------
# Property - Setter
# ------------------------------------------------

func `rule=`*(self: var Simulator, rule: Rule) =
  ## Sets the rule of the simulator.
  self.edit:
    self.nazoPuyo.puyoPuyo.field.rule.assign rule

func `mode=`*(self: var Simulator, mode: SimulatorMode) =
  ## Sets the mode of the simulator.
  if self.mode == mode:
    return

  self.undoAll

  self.mode.assign mode
  self.state.assign if mode in EditModes: AfterEdit else: Stable

  self.undoDeque.clear
  self.redoDeque.clear

func `selectingCell=`*(self: var Simulator, cell: Cell) =
  ## Sets the selecting cell.
  self.editData.selecting.cellOpt.ok cell
  self.editData.selecting.crossOpt.err

func `selectingCross=`*(self: var Simulator, cross: bool) =
  ## Sets the selecting cross.
  self.editData.selecting.cellOpt.err
  self.editData.selecting.crossOpt.ok cross

func setRule*(self: var Simulator, rule: Rule) =
  ## Sets the rule of the simulator.
  ## This function is a "safe" version.
  let safe: bool
  case rule
  of Rule.Tsu, Rule.Water:
    safe = self.nazoPuyo.puyoPuyo.steps.allIt it.kind != FieldRotate
    if safe and self.editData.selecting.crossOpt.isOk:
      self.selectingCell = Cell.None
  of Spinner:
    safe = self.nazoPuyo.puyoPuyo.steps.allIt it.kind != FieldRotate or not it.cross
    if safe and self.editData.selecting.crossOpt == Opt[bool].ok true:
      self.selectingCross = false
  of CrossSpinner:
    safe = self.nazoPuyo.puyoPuyo.steps.allIt it.kind != FieldRotate or it.cross
    if safe and self.editData.selecting.crossOpt == Opt[bool].ok false:
      self.selectingCross = true

  if safe:
    self.edit:
      self.nazoPuyo.puyoPuyo.field.rule.assign rule

      if rule == Rule.Water:
        for step in self.nazoPuyo.puyoPuyo.steps.mitems:
          if step.kind != NuisanceDrop:
            continue

          var counts = [0, 0, 0, 0, 0, 0]
          staticFor(col, Col):
            counts[step.counts[col]] += 1
          let fillCount = counts.find counts.max

          for count in step.counts.mitems:
            count.assign fillCount

# ------------------------------------------------
# Toggle
# ------------------------------------------------

func toggleFocus*(self: var Simulator) =
  ## Toggles focusing field or not.
  self.editData.focusField.toggle

func toggleInsert*(self: var Simulator) =
  ## Toggles inserting or not.
  self.editData.insert.toggle

# ------------------------------------------------
# Placement
# ------------------------------------------------

func movePlacementRight*(self: var Simulator) =
  ## Moves the next placement right.
  self.operating.placement.moveRight

func movePlacementLeft*(self: var Simulator) =
  ## Moves the next placement left.
  self.operating.placement.moveLeft

func rotatePlacementRight*(self: var Simulator) =
  ## Rotates the next placement right (clockwise).
  self.operating.placement.rotateRight

func rotatePlacementLeft*(self: var Simulator) =
  ## Rotates the next placement left (counterclockwise).
  self.operating.placement.rotateLeft

# ------------------------------------------------
# Cursor
# ------------------------------------------------

func moveCursorUp*(self: var Simulator) =
  ## Moves the cursor upward.
  if self.editData.focusField:
    self.editData.field.row.rotateDec
  else:
    if self.editData.steps.index == 0:
      self.editData.steps.index.assign self.nazoPuyo.puyoPuyo.steps.len
    else:
      self.editData.steps.index -= 1

func moveCursorDown*(self: var Simulator) =
  ## Moves the cursor downward.
  if self.editData.focusField:
    self.editData.field.row.rotateInc
  else:
    if self.editData.steps.index == self.nazoPuyo.puyoPuyo.steps.len:
      self.editData.steps.index.assign 0
    else:
      self.editData.steps.index += 1

func moveCursorRight*(self: var Simulator) =
  ## Moves the cursor rightward.
  if self.editData.focusField:
    self.editData.field.col.rotateInc
  else:
    if self.editData.steps.index < self.nazoPuyo.puyoPuyo.steps.len:
      case self.nazoPuyo.puyoPuyo.steps[self.editData.steps.index].kind
      of PairPlace: self.editData.steps.pivot.toggle
      of NuisanceDrop: self.editData.steps.col.rotateInc
      of FieldRotate: discard
    else:
      self.editData.steps.pivot.toggle

func moveCursorLeft*(self: var Simulator) =
  ## Moves the cursor leftward.
  if self.editData.focusField:
    self.editData.field.col.rotateDec
  else:
    if self.editData.steps.index < self.nazoPuyo.puyoPuyo.steps.len:
      case self.nazoPuyo.puyoPuyo.steps[self.editData.steps.index].kind
      of PairPlace: self.editData.steps.pivot.toggle
      of NuisanceDrop: self.editData.steps.col.rotateDec
      of FieldRotate: discard
    else:
      self.editData.steps.pivot.toggle

# ------------------------------------------------
# Delete - Step
# ------------------------------------------------

func delStep*(self: var Simulator, index: int) =
  ## Deletes the step at the specified index.
  if index notin 0 ..< self.nazoPuyo.puyoPuyo.steps.len:
    return

  self.edit:
    self.nazoPuyo.puyoPuyo.steps.del index
    self.editData.steps.index.assign min(
      self.editData.steps.index, self.nazoPuyo.puyoPuyo.steps.len
    )

# ------------------------------------------------
# Write - Cell - Field
# ------------------------------------------------

func writeCell(self: var Simulator, row: Row, col: Col, cell: Cell) =
  ## Writes the cell to the specified position in the field.
  self.edit:
    if self.editData.insert:
      if cell == Cell.None:
        self.nazoPuyo.puyoPuyo.field.del row, col
      else:
        self.nazoPuyo.puyoPuyo.field.insert row, col, cell
    else:
      self.nazoPuyo.puyoPuyo.field[row, col] = cell

func writeCell*(self: var Simulator, row: Row, col: Col) =
  ## Writes the selecting cell to the specified position in the field.
  if self.editData.selecting.cellOpt.isOk:
    self.writeCell row, col, self.editData.selecting.cellOpt.unsafeValue

func writeCellToField(self: var Simulator, cell: Cell) =
  ## Writes the cell to the selecting position in the field.
  self.writeCell self.editData.field.row, self.editData.field.col, cell

# ------------------------------------------------
# Write - Cell - Step
# ------------------------------------------------

func writeCell(self: var Simulator, index: int, pivot: bool, cell: Cell) =
  ## Writes the cell to the specified position in the steps.
  if index < 0:
    return

  # add step
  if index >= self.nazoPuyo.puyoPuyo.steps.len:
    case cell
    of Cell.None:
      discard
    of NuisancePuyos:
      self.edit:
        self.nazoPuyo.puyoPuyo.steps.addLast Step.init(
          Col.initArrayWith 0, hard = cell == Hard
        )
    of ColoredPuyos:
      self.edit:
        self.nazoPuyo.puyoPuyo.steps.addLast Step.init Pair.init(cell, cell)

    return

  # delete step
  if cell == Cell.None:
    self.delStep index
    return

  # insert step
  if self.editData.insert:
    self.edit:
      case cell
      of Cell.None:
        discard # dummy; not reach here
      of NuisancePuyos:
        self.nazoPuyo.puyoPuyo.steps.insert Step.init(
          Col.initArrayWith 0, hard = cell == Hard
        ), index
      of Cell.Red .. Cell.Purple:
        self.nazoPuyo.puyoPuyo.steps.insert Step.init(Pair.init(cell, cell)), index

    return

  # change step
  self.edit:
    case cell
    of Cell.None:
      discard # dummy; not reach here
    of NuisancePuyos:
      case self.nazoPuyo.puyoPuyo.steps[index].kind
      of PairPlace, FieldRotate:
        self.nazoPuyo.puyoPuyo.steps[index].assign Step.init(
          Col.initArrayWith 0, hard = cell == Hard
        )
      of NuisanceDrop:
        self.nazoPuyo.puyoPuyo.steps[index].hard.assign cell == Hard
    of ColoredPuyos:
      case self.nazoPuyo.puyoPuyo.steps[index].kind
      of PairPlace:
        if pivot:
          self.nazoPuyo.puyoPuyo.steps[index].pair.pivot = cell
        else:
          self.nazoPuyo.puyoPuyo.steps[index].pair.rotor = cell
      of NuisanceDrop, FieldRotate:
        self.nazoPuyo.puyoPuyo.steps[index].assign Step.init Pair.init(cell, cell)

func writeCell*(self: var Simulator, index: int, pivot: bool) =
  ## Writes the selecting cell to the specified position in the steps.
  if self.editData.selecting.cellOpt.isOk:
    self.writeCell index, pivot, self.editData.selecting.cellOpt.unsafeValue

func writeCellToSteps(self: var Simulator, cell: Cell) =
  ## Writes the cell to the selecting position in the steps.
  self.writeCell self.editData.steps.index, self.editData.steps.pivot, cell

# ------------------------------------------------
# Write - Cell
# ------------------------------------------------

func writeCell*(self: var Simulator, cell: Cell) =
  ## Writes the cell to the selecting position in the field or steps.
  if self.editData.focusField:
    self.writeCellToField cell
  else:
    self.writeCellToSteps cell

# ------------------------------------------------
# Write - Cross
# ------------------------------------------------

func writeCross(self: var Simulator, index: int, cross: bool) =
  ## Writes the rotation to the specified position in the steps.
  if index < 0:
    return

  # add step
  if index >= self.nazoPuyo.puyoPuyo.steps.len:
    self.edit:
      self.nazoPuyo.puyoPuyo.steps.addLast Step.init(cross = cross)

    return

  # insert step
  if self.editData.insert:
    self.edit:
      self.nazoPuyo.puyoPuyo.steps.insert Step.init(cross = cross), index

    return

  # change step
  self.edit:
    case self.nazoPuyo.puyoPuyo.steps[index].kind
    of PairPlace, NuisanceDrop:
      self.nazoPuyo.puyoPuyo.steps[index].assign Step.init(cross = cross)
    of FieldRotate:
      self.nazoPuyo.puyoPuyo.steps[index].cross.assign cross

func writeCross*(self: var Simulator, index: int) =
  ## Writes the selecting rotation to the specified position in the steps.
  if self.editData.selecting.crossOpt.isOk:
    self.writeCross index, self.editData.selecting.crossOpt.unsafeValue

func writeCross*(self: var Simulator, cross: bool) =
  ## Writes the rotation to the selecting position in the steps.
  self.writeCross self.editData.steps.index, cross

# ------------------------------------------------
# Write - Count
# ------------------------------------------------

func writeCount*(self: var Simulator, index: int, col: Col, count: int) =
  ## Writes the nuisance count to the specified position in the steps.
  if index notin 0 ..< self.nazoPuyo.puyoPuyo.steps.len:
    return
  if self.nazoPuyo.puyoPuyo.steps[index].kind != NuisanceDrop:
    return

  self.edit:
    self.nazoPuyo.puyoPuyo.steps[index].counts[col].assign count

func writeCount*(self: var Simulator, count: int) =
  ## Writes the nuisance count to the selecting position in the steps.
  self.writeCount self.editData.steps.index, self.editData.steps.col, count

func writeCountClamp*(self: var Simulator, index: int, col: Col, count: int) =
  ## Writes the nuisance clamped count to the specified position in the steps.
  if index notin 0 ..< self.nazoPuyo.puyoPuyo.steps.len:
    return
  if self.nazoPuyo.puyoPuyo.steps[index].kind != NuisanceDrop:
    return

  self.edit:
    case self.rule
    of Rule.Tsu, Spinner, CrossSpinner:
      self.nazoPuyo.puyoPuyo.steps[index].counts[col].assign count

      staticFor(col2, Col):
        self.nazoPuyo.puyoPuyo.steps[index].counts[col2].assign self.nazoPuyo.puyoPuyo.steps[
          index
        ].counts[col2].clamp(count - 1, count + 1)
    of Rule.Water:
      staticFor(col2, Col):
        self.nazoPuyo.puyoPuyo.steps[index].counts[col2].assign count

func writeCountClamp(self: var Simulator, count: int) =
  ## Writes the nuisance clamped count to the specified position in the steps.
  self.writeCountClamp self.editData.steps.index, self.editData.steps.col, count

# ------------------------------------------------
# Shift
# ------------------------------------------------

func shiftFieldUp*(self: var Simulator) =
  ## Shifts the field upward.
  self.edit:
    self.nazoPuyo.puyoPuyo.field.shiftUp

func shiftFieldDown*(self: var Simulator) =
  ## Shifts the field downward.
  self.edit:
    self.nazoPuyo.puyoPuyo.field.shiftDown

func shiftFieldRight*(self: var Simulator) =
  ## Shifts the field rightward.
  self.edit:
    self.nazoPuyo.puyoPuyo.field.shiftRight

func shiftFieldLeft*(self: var Simulator) =
  ## Shifts the field leftward.
  self.edit:
    self.nazoPuyo.puyoPuyo.field.shiftLeft

# ------------------------------------------------
# Flip
# ------------------------------------------------

func flipFieldVertical*(self: var Simulator) =
  ## Flips the field vertically.
  self.edit:
    self.nazoPuyo.puyoPuyo.field.flipVertical

func flipFieldHorizontal*(self: var Simulator) =
  ## Flips the field horizontally.
  self.edit:
    self.nazoPuyo.puyoPuyo.field.flipHorizontal

func flip*(self: var Simulator) =
  ## Flips the field or the step.
  if self.editData.focusField:
    self.flipFieldHorizontal
    return

  if self.editData.steps.index notin 0 ..< self.nazoPuyo.puyoPuyo.steps.len:
    return

  self.edit:
    case self.nazoPuyo.puyoPuyo.steps[self.editData.steps.index].kind
    of PairPlace:
      self.nazoPuyo.puyoPuyo.steps[self.editData.steps.index].pair.swap
    of NuisanceDrop:
      self.nazoPuyo.puyoPuyo.steps[self.editData.steps.index].counts.reverse
    of FieldRotate:
      discard

# ------------------------------------------------
# Goal
# ------------------------------------------------

const
  DefaultGoalColor = All
  DefaultGoalVal = 0
  DefaultGoalOperator = Exact

func normalizeGoal*(self: var Simulator) =
  ## Normalizes the goal.
  ## This function does not affects undo/redo.
  self.nazoPuyo.goal.normalize

func `goalKindOpt=`*(self: var Simulator, kindOpt: Opt[GoalKind]) =
  ## Sets the goal kind.
  self.edit:
    if kindOpt.isOk:
      let kind = kindOpt.unsafeValue

      if self.nazoPuyo.goal.mainOpt.isOk:
        self.nazoPuyo.goal.mainOpt.unsafeValue.kind.assign kind
      else:
        self.nazoPuyo.goal.mainOpt.ok GoalMain.init(
          kind, DefaultGoalColor, DefaultGoalVal, DefaultGoalOperator
        )
    else:
      if self.nazoPuyo.goal.mainOpt.isOk: self.nazoPuyo.goal.mainOpt.err else: discard

    self.nazoPuyo.goal.normalize

func `goalColor=`*(self: var Simulator, color: GoalColor) =
  ## Sets the goal color.
  if self.nazoPuyo.goal.mainOpt.isErr:
    return

  self.edit:
    self.nazoPuyo.goal.mainOpt.unsafeValue.color.assign color
    self.nazoPuyo.goal.normalize

func `goalVal=`*(self: var Simulator, val: int) =
  ## Sets the goal value.
  if self.nazoPuyo.goal.mainOpt.isErr:
    return

  self.edit:
    self.nazoPuyo.goal.mainOpt.unsafeValue.val.assign val
    self.nazoPuyo.goal.normalize

func `goalOperator=`*(self: var Simulator, operator: GoalOperator) =
  ## Sets the goal operator.
  if self.nazoPuyo.goal.mainOpt.isErr:
    return

  self.edit:
    self.nazoPuyo.goal.mainOpt.unsafeValue.operator.assign operator
    self.nazoPuyo.goal.normalize

func `goalClearColorOpt=`*(self: var Simulator, clearColorOpt: Opt[GoalColor]) =
  ## Sets the goal clear color.
  self.edit:
    self.nazoPuyo.goal.clearColorOpt.assign clearColorOpt
    self.nazoPuyo.goal.normalize

# ------------------------------------------------
# Forward / Backward
# ------------------------------------------------

func forwardApply(self: var Simulator, replay = false, skip = false) =
  ## Forwards the simulator with `apply`.
  ## This functions requires that the initial field is settled.
  ## `skip` is prioritized over `replay`.
  if self.operating.index >= self.nazoPuyo.puyoPuyo.steps.len:
    return

  # prepare deques
  self.undoDeque.addLast SimulatorDequeElem.init self
  self.redoDeque.clear

  # set placement
  if self.mode in PlayModes:
    if self.nazoPuyo.puyoPuyo.steps[self.operating.index].kind != PairPlace:
      discard
    elif skip:
      self.nazoPuyo.puyoPuyo.steps[self.operating.index].placement.assign Placement.None
    elif replay:
      discard
    else:
      self.nazoPuyo.puyoPuyo.steps[self.operating.index].placement.assign self.operating.placement

  # apply
  self.nazoPuyo.puyoPuyo.field.apply(
    self.nazoPuyo.puyoPuyo.steps[self.operating.index],
    requireSettled = self.operating.index != 0,
  )

  # set move result
  self.moveResult.assign DefaultMoveResult

  # set state
  if self.nazoPuyo.puyoPuyo.steps[self.operating.index].kind == FieldRotate:
    if self.nazoPuyo.puyoPuyo.field.isSettled:
      self.state.assign Stable

      if self.mode notin EditModes:
        self.operating.index += 1
        self.operating.placement.assign DefaultPlacement
    else:
      self.state.assign WillSettle
  elif self.nazoPuyo.puyoPuyo.field.canPop:
    self.state.assign WillPop
  else:
    self.state.assign Stable
    self.operating.index += 1
    self.operating.placement.assign DefaultPlacement

func forwardPop(self: var Simulator) =
  ## Forwards the simulator with `pop`.
  # prepare deques
  self.undoDeque.addLast SimulatorDequeElem.init self
  self.redoDeque.clear

  # pop
  let popResult = self.nazoPuyo.puyoPuyo.field.pop

  # update move result
  self.moveResult.chainCount += 1
  var cellCounts {.noinit.}: array[Cell, int]
  cellCounts[Cell.None].assign 0
  staticFor(cell2, Puyos):
    let cellCount = popResult.cellCount cell2
    cellCounts[cell2].assign cellCount
    self.moveResult.popCounts[cell2] += cellCount
  self.moveResult.detailPopCounts.add cellCounts
  self.moveResult.fullPopCountsOpt.unsafeValue.add popResult.connectionCounts
  let h2g = popResult.hardToGarbageCount
  self.moveResult.hardToGarbageCount += h2g
  self.moveResult.detailHardToGarbageCount.add h2g

  # check settle
  if self.nazoPuyo.puyoPuyo.field.isSettled:
    self.state.assign Stable

    if self.mode notin EditModes:
      self.operating.index += 1
      self.operating.placement.assign DefaultPlacement
  else:
    self.state.assign WillSettle

func forwardSettle(self: var Simulator) =
  ## Forwards the simulator with `settle`.
  # prepare deques
  self.undoDeque.addLast SimulatorDequeElem.init self
  self.redoDeque.clear

  # settle
  self.nazoPuyo.puyoPuyo.field.settle

  # check pop
  if self.nazoPuyo.puyoPuyo.field.canPop:
    self.state.assign WillPop
  else:
    self.state.assign Stable

    if self.mode notin EditModes:
      self.operating.index += 1
      self.operating.placement.assign DefaultPlacement

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
      discard

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
    self.operating.placement.assign DefaultPlacement

func reset*(self: var Simulator) =
  ## Backwards the simulator to the pre-move state.
  let steps = self.nazoPuyo.puyoPuyo.steps

  self.undoAll

  self.nazoPuyo.puyoPuyo.steps.assign steps
  self.operating.placement.assign DefaultPlacement

# ------------------------------------------------
# Key
# ------------------------------------------------

func operate*(self: var Simulator, key: KeyEvent): bool {.discardable.} =
  ## Performs an action specified by the key.
  ## Returns `true` if the key is handled.
  var handled = true

  case self.mode
  of PlayModes:
    # mode
    if key == KeyEventT:
      if self.mode == PlayViewer:
        self.`mode=` EditViewer
      else: # PlayEditor
        self.`mode=` EditEditor
    # rotate operating placement
    elif key == KeyEventK:
      self.rotatePlacementRight
    elif key == KeyEventJ:
      self.rotatePlacementLeft
    # move operating placement
    elif key == KeyEventD:
      self.movePlacementRight
    elif key == KeyEventA:
      self.movePlacementLeft
    # forward / backward / reset
    elif key == KeyEventS:
      self.forward
    elif key in [KeyEventX, KeyEventW]:
      self.backward
    elif key == KeyEventZ:
      self.reset
    elif key == KeyEventSpace:
      self.forward(skip = true)
    elif key == KeyEventC:
      self.forward(replay = true)
    else:
      handled.assign false
  of EditModes:
    # mode
    if key == KeyEventT:
      if self.mode == EditViewer:
        self.`mode=` PlayViewer
      else: # EditEditor
        self.`mode=` PlayEditor
    # move cursor
    elif key == KeyEventD:
      self.moveCursorRight
    elif key == KeyEventA:
      self.moveCursorLeft
    elif key == KeyEventS:
      self.moveCursorDown
    elif key == KeyEventW:
      self.moveCursorUp
    # write / delete cell
    elif key == KeyEventH:
      self.writeCell Cell.Red
    elif key == KeyEventJ:
      self.writeCell Cell.Green
    elif key == KeyEventK:
      self.writeCell Cell.Blue
    elif key == KeyEventL:
      self.writeCell Cell.Yellow
    elif key == KeyEventSemicolon:
      self.writeCell Cell.Purple
    elif key == KeyEventO:
      self.writeCell Garbage
    elif key == KeyEventP:
      self.writeCell Hard
    elif key == KeyEventSpace:
      self.writeCell Cell.None
    # undo / redo
    elif key == KeyEventShiftZ:
      self.undo
    elif key == KeyEventShiftX:
      self.redo
    # forward / backward / reset
    elif key == KeyEventC:
      self.forward
    elif key == KeyEventX:
      self.backward
    elif key == KeyEventZ:
      self.reset
    elif self.mode == EditEditor:
      # rule
      if key == KeyEventR:
        self.setRule self.rule.rotateSucc
      elif key == KeyEventE:
        self.setRule self.rule.rotatePred
      # toggle insert / focus
      elif key == KeyEventG:
        self.toggleInsert
      elif key == KeyEventTab:
        self.toggleFocus
      # write rotate
      elif key == KeyEventN:
        if self.rule == Spinner:
          self.writeCross(cross = false)
      elif key == KeyEventM:
        if self.rule == CrossSpinner:
          self.writeCross(cross = true)
      # write count
      elif key == KeyEvent0:
        self.writeCountClamp 0
      elif key == KeyEvent1:
        self.writeCountClamp 1
      elif key == KeyEvent2:
        self.writeCountClamp 2
      elif key == KeyEvent3:
        self.writeCountClamp 3
      elif key == KeyEvent4:
        self.writeCountClamp 4
      elif key == KeyEvent5:
        self.writeCountClamp 5
      # shift field
      elif key == KeyEventShiftD:
        self.shiftFieldRight
      elif key == KeyEventShiftA:
        self.shiftFieldLeft
      elif key == KeyEventShiftS:
        self.shiftFieldDown
      elif key == KeyEventShiftW:
        self.shiftFieldUp
      # flip field
      elif key == KeyEventF:
        self.flip
      else:
        handled.assign false
    else:
      handled.assign false
  of Replay:
    # forward / backward / reset
    if key in [KeyEventX, KeyEventW]:
      self.backward
    elif key in [KeyEventZ, KeyEventShiftW]:
      self.reset
    elif key in [KeyEventC, KeyEventS]:
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
    of IshikawaPuyo, Ips:
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
      if step.kind == PairPlace:
        step.placement.assign Placement.None
  let nazoPuyoQuery =
    ?nazoPuyo.toUriQuery(fqdn).context "Simulator that does not support URI conversion"
  uri.query.assign (
    if fqdn == Pon2: "{ModeKey}={self.mode.ord}&{nazoPuyoQuery}".fmt else: nazoPuyoQuery
  )

  ok uri

func parseSimulator*(uri: Uri): Pon2Result[Simulator] =
  ## Returns the simulator converted from the URI.
  ## Viewer modes are set to the result simulator preferentially if the FQDN is
  ## `IshikawaPuyo` or `Ips`.
  if uri.scheme notin ["https", "http"]:
    return err "Invalid simulator (invalid scheme): {uri}".fmt

  let fqdn = ?uri.hostname.parseSimulatorFqdn.context "Invalid simulator: {uri}".fmt
  case fqdn
  of Pon2:
    if uri.path notin Pon2Paths:
      return err "Invalid simulator (invalid path): {uri}".fmt

    var
      keyVals = newSeq[tuple[key: string, value: string]]()
      modeOpt = Opt[SimulatorMode].err
    for keyVal in uri.query.decodeQuery:
      if keyVal.key == ModeKey:
        if modeOpt.isOk:
          return err "Invalid simulator (multiple mode detected): {uri}".fmt
        else:
          modeOpt.ok ?parseOrdinal[SimulatorMode](keyVal.value).context "Invalid mode: {keyVal.value}".fmt
      else:
        keyVals.add keyVal

    if modeOpt.isErr:
      modeOpt.ok DefaultMode

    ok Simulator.init(
      ?keyVals.encodeQuery.parseNazoPuyo(fqdn).context "Invalid simulator: {uri}".fmt,
      modeOpt.unsafeValue,
    )
  of IshikawaPuyo, Ips:
    let mode: SimulatorMode
    case uri.path
    of "/simu/pe.html":
      mode = EditViewer
    of "/simu/ps.html", "/simu/pn.html":
      mode = PlayViewer
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
  simulator.mode = if viewer: PlayViewer else: PlayEditor

  if not clearPlacements:
    simulator.nazoPuyo.puyoPuyo.steps.assign self.nazoPuyo.puyoPuyo.steps

  simulator.toUri(clearPlacements, fqdn)

## This module implements Puyo Puyo simulators.
##

{.experimental: "strictDefs".}

import std/[deques, options, sequtils, uri]
import ../corepkg/[cell, environment, field, misc, pair, position]
import ../nazopuyopkg/[nazopuyo]

type
  SimulatorState* {.pure.} = enum
    ## Simulator state.
    Stable
    WillDisappear
    Disappearing

  Simulator* = object
    ## Puyo Puyo simulator.
    environments*: Environments
    originalEnvironments*: Environments

    positions*: Positions
    requirement*: Requirement

    kind: IzumiyaSimulatorKind
    mode: IzumiyaSimulatorMode
    state*: SimulatorState

    selectingCell*: Cell
    selectingFieldPosition*: tuple[row: Row, column: Column]
    selectingPairPosition*: tuple[index: Natural, isAxis: bool]
    inserting*: bool
    showCursor*: bool
    focusField*: bool

    undoDeque: Deque[tuple[environments: Environments,
                           requirement: Requirement]]
    redoDeque: Deque[tuple[environments: Environments,
                           requirement: Requirement]]

    nextIdx*: Natural
    nextPosition*: Position

  KeyEvent* = object
    ## Keyboard Event.
    code: string ## [KeyboardEvent.code](https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/code)
    shift: bool
    control: bool
    alt: bool
    meta: bool

using
  self: Simulator
  mSelf: var Simulator

# ------------------------------------------------
# Constructor - KeyEvent
# ------------------------------------------------

func initKeyEvent*(code: string, shift = false, control = false, alt = false,
                   meta = false): KeyEvent {.inline.} =
  ## Constructor of `KeyEvent`.
  result.code = code
  result.shift = shift
  result.control = control
  result.alt = alt
  result.meta = meta

# ------------------------------------------------
# Constructor - Simulator
# ------------------------------------------------

const
  InitPos = Up2
  DefaultReq = Requirement(kind: Clear, color: some RequirementColor.All,
                           number: none RequirementNumber)

func initSimulator*(env: Environment, positions: Positions, mode = Play,
                    showCursor: bool): Simulator {.inline.} =
  ## Constructor of `Simulator`.
  when env.F is TsuField:
    result.rule = Tsu
    result.environments.tsu = env
    result.environments.water = initWaterEnvironment 0
  else:
    result.rule = Water
    result.environments.tsu = initTsuEnvironment 0
    result.environments.water = env
  result.originalEnvironments.tsu = result.environments.tsu
  result.originalEnvironments.water = result.environments.water

  result.positions = positions
  result.positions.setLen env.pairs.len
  result.requirement = DefaultReq

  result.kind = Regular
  result.mode = mode
  result.state = Stable

  result.selectingCell = None
  result.selectingFieldPosition = (Row.low, Column.low)
  result.selectingPairPosition = (Natural.low, true)
  result.inserting = false
  result.showCursor = showCursor
  result.focusField = true

  result.undoDeque = initDeque[
    tuple[environments: Environments,
          requirement: Requirement]] env.pairs.len
  result.redoDeque = initDeque[
    tuple[environments: Environments,
          requirement: Requirement]] env.pairs.len

  result.nextIdx = Natural 0
  result.nextPosition = InitPos

func initSimulator*(env: Environment, mode = Play,
                    showCursor = true): Simulator {.inline.} =
  ## Constructor of `Simulator`.
  env.initSimulator(Position.none.repeat env.pairs.len, mode, showCursor)

func initSimulator*[F: TsuField or WaterField](
    nazo: NazoPuyo[F], positions: Positions, mode = Play,
    showCursor = true): Simulator {.inline.} =
  ## Constructor of `Simulator`.
  result = nazo.environment.initSimulator(positions, mode, showCursor)
  result.kind = IzumiyaSimulatorKind.Nazo
  result.requirement = nazo.requirement

func initSimulator*[F:TsuField or WaterField](
    nazo: NazoPuyo[F], mode = Play, showCursor = true): Simulator {.inline.} =
  ## Constructor of `Simulator`.
  nazo.initSimulator(Position.none.repeat nazo.moveCount, mode, showCursor)
  
# ------------------------------------------------
# Property - Rule / Kind / Mode
# ------------------------------------------------

func `rule`*(self): Rule {.inline.} = self.environments.rule
func `kind`*(self): IzumiyaSimulatorKind {.inline.} = self.kind
func `mode`*(self): IzumiyaSimulatorMode {.inline.} = self.mode

func `rule=`*(mSelf; rule: Rule) {.inline.} =
  if rule == mSelf.rule:
    return

  mSelf.environments.rule = rule

  case rule
  of Tsu: mSelf.environments.tsu = mSelf.environments.water.toTsuEnvironment
  of Water: mSelf.environments.water = mSelf.environments.tsu.toWaterEnvironment

func `kind=`*(mSelf; kind: IzumiyaSimulatorKind) {.inline.} =
  if kind == mSelf.kind:
    return

  mSelf.kind = kind

func `mode=`*(mSelf; mode: IzumiyaSimulatorMode) {.inline.} =
  if mode == mSelf.mode:
    return

  if mode == IzumiyaSimulatorMode.Edit or
      mSelf.mode == IzumiyaSimulatorMode.Edit:
    mSelf.environments = mSelf.originalEnvironments
    mSelf.state = Stable
    mSelf.undoDeque.clear
    mSelf.redoDeque.clear

  mSelf.mode = mode

# ------------------------------------------------
# Property - Nazo
# ------------------------------------------------

func tsuNazoPuyo*(self): NazoPuyo[TsuField] {.inline.} =
  ## Returns the Tsu nazo puyo.
  result.environment = self.environments.tsu
  result.requirement = self.requirement

func waterNazoPuyo*(self): NazoPuyo[WaterField] {.inline.} =
  ## Returns the Water nazo puyo.
  result.environment = self.environments.water
  result.requirement = self.requirement

# ------------------------------------------------
# Property - Nazo - Original
# ------------------------------------------------

func originalTsuNazoPuyo*(self): NazoPuyo[TsuField] {.inline.} =
  ## Returns the original Tsu nazo puyo.
  result.environment = self.originalEnvironments.tsu
  result.requirement = self.requirement

func originalWaterNazoPuyo*(self): NazoPuyo[WaterField] {.inline.} =
  ## Returns the original Water nazo puyo.
  result.environment = self.originalEnvironments.water
  result.requirement = self.requirement

# ------------------------------------------------
# Property - Pairs
# ------------------------------------------------

func pairs*(self): Pairs {.inline.} =
  ## Returns the pairs.
  case self.rule
  of Tsu: self.environments.tsu.pairs
  of Water: self.environments.water.pairs

func pairs*(mSelf): var Pairs {.inline.} =
  ## Returns the pairs.
  case mSelf.rule
  of Tsu: result = mSelf.environments.tsu.pairs
  of Water: result = mSelf.environments.water.pairs

# ------------------------------------------------
# Property - Pairs - Original
# ------------------------------------------------

func originalPairs*(self): Pairs {.inline.} =
  ## Returns the original pairs.
  case self.rule
  of Tsu: self.originalEnvironments.tsu.pairs
  of Water: self.originalEnvironments.water.pairs

func originalPairs*(mSelf): var Pairs {.inline.} =
  ## Returns the original pairs.
  case mSelf.rule
  of Tsu: result = mSelf.originalEnvironments.tsu.pairs
  of Water: result = mSelf.originalEnvironments.water.pairs

# ------------------------------------------------
# With
# ------------------------------------------------

template withNazoPuyo*(self: Simulator, body: untyped): untyped =
  ## Runs `body` with `nazoPuyo` exposed.
  case self.rule
  of Tsu:
    let nazoPuyo {.inject.} = self.tsuNazoPuyo
    body
  of Water:
    let nazoPuyo {.inject.} = self.waterNazoPuyo
    body

template withEnvironment*(self: Simulator, body: untyped): untyped =
  ## Runs `body` with `environment` exposed.
  self.environments.flattenAnd:
    body

template withField*(self: Simulator, body: untyped): untyped =
  ## Runs `body` with `field` exposed.
  self.environments.flattenAnd:
    let field {.inject.} = environment.field
    body

# ------------------------------------------------
# Edit
# ------------------------------------------------

func toggleInserting*(mSelf) {.inline.} = mSelf.inserting = not mSelf.inserting
  ## Toggles inserting or not.

func toggleFocus*(mSelf) {.inline.} = mSelf.focusField = not mSelf.focusField
  ## Toggles focusing field or not.

func save(mSelf) {.inline.} =
  ## Saves the current simulator.
  mSelf.undoDeque.addLast (mSelf.environments, mSelf.requirement)
  mSelf.redoDeque.clear

template change(mSelf; body: untyped) =
  ## Helper template for operations that changes `originalEnvironment`.
  mSelf.save
  body
  mSelf.originalEnvironments = mSelf.environments

# ------------------------------------------------
# Edit - Cursor
# ------------------------------------------------

func moveCursorUp*(mSelf) {.inline.} =
  ## Moves the cursor upward.
  if mSelf.focusField:
    if mSelf.selectingFieldPosition.row == Row.low:
      mSelf.selectingFieldPosition.row = Row.high
    else:
      mSelf.selectingFieldPosition.row.dec
  else:
    if mSelf.selectingPairPosition.index == Natural.low:
      mSelf.selectingPairPosition.index = mSelf.pairs.len
    else:
      mSelf.selectingPairPosition.index.dec

func moveCursorDown*(mSelf) {.inline.} =
  ## Moves the cursor downward.
  if mSelf.focusField:
    if mSelf.selectingFieldPosition.row == Row.high:
      mSelf.selectingFieldPosition.row = Row.low
    else:
      mSelf.selectingFieldPosition.row.inc
  else:
    if mSelf.selectingPairPosition.index == mSelf.pairs.len:
      mSelf.selectingPairPosition.index = Natural.low
    else:
      mSelf.selectingPairPosition.index.inc

func moveCursorRight*(mSelf) {.inline.} =
  ## Moves the cursor rightward.
  if mSelf.focusField:
    if mSelf.selectingFieldPosition.column == Column.high:
      mSelf.selectingFieldPosition.column = Column.low
    else:
      mSelf.selectingFieldPosition.column.inc
  else:
    mSelf.selectingPairPosition.isAxis = not mSelf.selectingPairPosition.isAxis

func moveCursorLeft*(mSelf) {.inline.} =
  ## Moves the cursor leftward.
  if mSelf.focusField:
    if mSelf.selectingFieldPosition.column == Column.low:
      mSelf.selectingFieldPosition.column = Column.high
    else:
      mSelf.selectingFieldPosition.column.dec
  else:
    mSelf.selectingPairPosition.isAxis = not mSelf.selectingPairPosition.isAxis

# ------------------------------------------------
# Edit - Delete
# ------------------------------------------------

func delete[T](deque: var Deque[T], idx: Natural) {.inline.} =
    var s = deque.toSeq
    s.delete idx
    deque = s.toDeque

func deletePair*(mSelf; idx: Natural) {.inline.} =
  ## Deletes the pair.
  if idx >= mSelf.pairs.len:
    return

  mSelf.change:
    mSelf.pairs.delete idx
    mSelf.positions.delete idx

func deletePair*(mSelf) {.inline.} =
  ## Deletes the pair at selecting index.
  mSelf.deletePair mSelf.selectingPairPosition.index

# ------------------------------------------------
# Edit - Write
# ------------------------------------------------

func insert[T](deque: var Deque[T], item: T, idx: Natural) {.inline.} =
    var s = deque.toSeq
    s.insert item, idx
    deque = s.toDeque

func writeCell(mSelf; row: Row, col: Column, cell: Cell) {.inline.} =
  ## Writes the cell to the field.
  mSelf.change:
    if mSelf.inserting:
      if cell == None:
        case mSelf.rule
        of Tsu: mSelf.environments.tsu.field.removeSqueeze row, col
        of Water: mSelf.environments.water.field.removeSqueeze row, col
      else:
        case mSelf.rule
        of Tsu: mSelf.environments.tsu.field.insert row, col, cell
        of Water: mSelf.environments.water.field.insert row, col, cell
    else:
      case mSelf.rule
      of Tsu: mSelf.environments.tsu.field[row, col] = cell
      of Water: mSelf.environments.water.field[row, col] = cell

func writeCell*(mSelf; row: Row, col: Column) {.inline.} =
  ## Writes the selecting cell to the field.
  mSelf.writeCell row, col, mSelf.selectingCell

func writeCell(mSelf; idx: Natural, isAxis: bool, cell: Cell) {.inline.} =
  ## Writes the cell to the pairs.
  case cell
  of None:
    mSelf.deletePair idx
  of Hard, Cell.Garbage:
    discard
  of Cell.Red..Cell.Purple:
    let color = ColorPuyo cell
    mSelf.change:
      if idx == mSelf.pairs.len:
        mSelf.pairs.addLast initPair(color, color)
        mSelf.positions.add none Position
      else:
        if mSelf.inserting:
          mSelf.pairs.insert initPair(color, color), idx
          mSelf.positions.insert Position.none, idx
        else:
          if isAxis:
            mSelf.pairs[idx].axis = color
          else:
            mSelf.pairs[idx].child = color

func writeCell*(mSelf; idx: Natural, isAxis: bool) {.inline.} =
  ## Writes the selecting cell to the pairs.
  mSelf.writeCell idx, isAxis, mSelf.selectingCell

func writeCell*(mSelf; cell: Cell) {.inline.} =
  ## Writes the cell to the field or pairs.
  if mSelf.focusField:
    mSelf.writeCell mSelf.selectingFieldPosition.row,
      mSelf.selectingFieldPosition.column, cell
  else:
    mSelf.writeCell mSelf.selectingPairPosition.index,
      mSelf.selectingPairPosition.isAxis, cell

# ------------------------------------------------
# Edit - Shift
# ------------------------------------------------

func shiftFieldUp*(mSelf) {.inline.} =
  ## Shifts the field upward.
  mSelf.change:
    case mSelf.rule
    of Tsu: mSelf.environments.tsu.field.shiftUp
    of Water: mSelf.environments.water.field.shiftUp

func shiftFieldDown*(mSelf) {.inline.} =
  ## Shifts the field downward.
  mSelf.change:
    case mSelf.rule
    of Tsu: mSelf.environments.tsu.field.shiftDown
    of Water: mSelf.environments.water.field.shiftDown

func shiftFieldRight*(mSelf) {.inline.} =
  ## Shifts the field rightward.
  mSelf.change:
    case mSelf.rule
    of Tsu: mSelf.environments.tsu.field.shiftRight
    of Water: mSelf.environments.water.field.shiftRight

func shiftFieldLeft*(mSelf) {.inline.} =
  ## Shifts the field leftward.
  mSelf.change:
    case mSelf.rule
    of Tsu: mSelf.environments.tsu.field.shiftLeft
    of Water: mSelf.environments.water.field.shiftLeft

# ------------------------------------------------
# Edit - Flip
# ------------------------------------------------

func flipFieldV*(mSelf) {.inline.} =
  ## Flips the field vertically.
  mSelf.change:
    case mSelf.rule
    of Tsu: mSelf.environments.tsu.field.flipV
    of Water: mSelf.environments.water.field.flipV

func flipFieldH*(mSelf) {.inline.} =
  ## Flips the field horizontally.
  mSelf.change:
    case mSelf.rule
    of Tsu: mSelf.environments.tsu.field.flipH
    of Water: mSelf.environments.water.field.flipH

# ------------------------------------------------
# Edit - Requirement
# ------------------------------------------------

func `requirementKind=`*(mSelf; kind: RequirementKind) {.inline.} =
  ## Sets the requirement kind.
  mSelf.change:
    mSelf.requirement.kind = kind

    if kind in ColorKinds and mSelf.requirement.color.isNone:
      mSelf.requirement.color = some RequirementColor.low
    if kind in NumberKinds and mSelf.requirement.number.isNone:
      mSelf.requirement.number = some RequirementNumber.low

func `requirementColor=`*(mSelf; color: RequirementColor) {.inline.} =
  ## Sets the requirement color.
  if mSelf.requirement.kind in NoColorKinds:
    return

  mSelf.change:
    mSelf.requirement.color = some color

func `requirementNumber=`*(mSelf; num: RequirementNumber) {.inline.} =
  ## Sets the requirement number.
  if mSelf.requirement.kind in NoNumberKinds:
    return

  mSelf.change:
    mSelf.requirement.number = some num

# ------------------------------------------------
# Edit - Undo / Redo
# ------------------------------------------------

func adjustPositions(mSelf) {.inline.} = mSelf.positions.setLen mSelf.pairs.len
  ## Adjust the positions' length.

func undo*(mSelf) {.inline.} =
  ## Performs undo.
  if mSelf.undoDeque.len == 0:
    return

  mSelf.redoDeque.addLast (mSelf.environments, mSelf.requirement)
  (mSelf.environments, mSelf.requirement) = mSelf.undoDeque.popLast

  mSelf.originalEnvironments = mSelf.environments
  mSelf.adjustPositions

func redo*(mSelf) {.inline.} =
  ## Performs redo.
  if mSelf.redoDeque.len == 0:
    return

  mSelf.undoDeque.addLast (mSelf.environments, mSelf.requirement)
  (mSelf.environments, mSelf.requirement) = mSelf.redoDeque.popLast

  mSelf.originalEnvironments = mSelf.environments
  mSelf.adjustPositions

# ------------------------------------------------
# Play - Position
# ------------------------------------------------

func moveNextPositionRight*(mSelf) {.inline.} = mSelf.nextPosition.moveRight
  ## Moves the next position right.

func moveNextPositionLeft*(mSelf) {.inline.} = mSelf.nextPosition.moveLeft
  ## Moves the next position left.

func rotateNextPositionRight*(mSelf) {.inline.} = mSelf.nextPosition.rotateRight
  ## Rotates the next position right.

func rotateNextPositionLeft*(mSelf) {.inline.} = mSelf.nextPosition.rotateLeft
  ## Rotates the next position left.

# ------------------------------------------------
# Forward / Backward
# ------------------------------------------------

func forward*(mSelf; useNextPosition = true, skip = false) {.inline.} =
  ## Forwards the simulator.
  ## If `skip` is `true`, `useNextPositions` will be ignored.
  case mSelf.state
  of Stable:
    if mSelf.pairs.len == 0:
      return

    mSelf.save

    if useNextPosition:
      mSelf.positions[mSelf.nextIdx] = some mSelf.nextPosition
    if skip:
      mSelf.positions[mSelf.nextIdx] = none Position

    # put
    block:
      let
        pair = mSelf.pairs.popFirst
        pos = mSelf.positions[mSelf.nextIdx]

      if pos.isSome:
        case mSelf.rule
        of Tsu:
          mSelf.environments.tsu.field.put pair, pos.get
        of Water:
          mSelf.environments.water.field.put pair, pos.get

    # disappear
    block:
      let disappear = case mSelf.rule
      of Tsu: mSelf.environments.tsu.field.willDisappear
      of Water: mSelf.environments.water.field.willDisappear

      if disappear:
        mSelf.state = WillDisappear
      else:
        mSelf.state = Stable
        mSelf.nextIdx.inc
        mSelf.nextPosition = InitPos
  of WillDisappear:
    case mSelf.rule
    of Tsu: mSelf.environments.tsu.field.disappear
    of Water: mSelf.environments.water.field.disappear

    mSelf.state = Disappearing
  of Disappearing:
    let disappear = case mSelf.rule
    of Tsu:
      mSelf.environments.tsu.field.drop
      mSelf.environments.tsu.field.willDisappear
    of Water:
      mSelf.environments.water.field.drop
      mSelf.environments.water.field.willDisappear

    if disappear:
      mSelf.state = WillDisappear
    else:
      mSelf.state = Stable
      mSelf.nextIdx.inc
      mSelf.nextPosition = InitPos

func backward*(mSelf) {.inline.} =
  ## Backwards the simulator.
  if mSelf.undoDeque.len == 0:
    return

  if mSelf.state == Stable:
    mSelf.nextIdx.dec

  (mSelf.environments, mSelf.requirement) = mSelf.undoDeque.popLast
  mSelf.state = Stable
  mSelf.nextPosition = InitPos

func reset*(mSelf; resetPosition = true) {.inline.} =
  ## Resets the simulator.
  mSelf.state = Stable
  mSelf.environments = mSelf.originalEnvironments
  mSelf.undoDeque.clear
  mSelf.redoDeque.clear
  mSelf.nextIdx = 0
  mSelf.nextPosition = InitPos

  if resetPosition:
    mSelf.positions = Position.none.repeat mSelf.pairs.len

# ------------------------------------------------
# Simulator -> URI
# ------------------------------------------------

func toUri*(self; withPositions = true): Uri {.inline.} =
  ## Converts the simulator to the URI.
  case self.kind
  of Regular:
    self.withEnvironment:
      result =
        if withPositions: environment.toUri(self.positions, mode = self.mode)
        else: environment.toUri(mode = self.mode)
  of IzumiyaSimulatorKind.Nazo:
    self.withNazoPuyo:
      result =
        if withPositions: nazoPuyo.toUri(self.positions, mode = self.mode)
        else: nazoPuyo.toUri(mode = self.mode)

# ------------------------------------------------
# Keyboard Operation
# ------------------------------------------------

func operate*(mSelf; event: KeyEvent): bool {.discardable.} =
  ## Handler for keyboard input.
  ## Returns `true` if any action is executed.
  result = true

  case mSelf.mode
  of IzumiyaSimulatorMode.Edit:
    # insert, focus
    if event == initKeyEvent("KeyI"):
      mSelf.toggleInserting
    elif event == initKeyEvent("KeyQ"):
      mSelf.toggleFocus
    # move cursor
    elif event == initKeyEvent("KeyA"):
      mSelf.moveCursorLeft
    elif event == initKeyEvent("KeyD"):
      mSelf.moveCursorRight
    elif event == initKeyEvent("KeyS"):
      mSelf.moveCursorDown
    elif event == initKeyEvent("KeyW"):
      mSelf.moveCursorUp
    # write cell
    elif event == initKeyEvent("KeyH"):
      mSelf.writeCell Cell.Red
    elif event == initKeyEvent("KeyJ"):
      mSelf.writeCell Cell.Green
    elif event == initKeyEvent("KeyK"):
      mSelf.writeCell Cell.Blue
    elif event == initKeyEvent("KeyL"):
      mSelf.writeCell Cell.Yellow
    elif event == initKeyEvent("Semicolon"):
      mSelf.writeCell Cell.Purple
    elif event == initKeyEvent("KeyO"):
      mSelf.writeCell Cell.Garbage
    elif event == initKeyEvent("Space"):
      mSelf.writeCell None
    # shift field
    elif event == initKeyEvent("KeyA", shift = true):
      mSelf.shiftFieldLeft
    elif event == initKeyEvent("KeyD", shift = true):
      mSelf.shiftFieldRight
    elif event == initKeyEvent("KeyS", shift = true):
      mSelf.shiftFieldDown
    elif event == initKeyEvent("KeyW", shift = true):
      mSelf.shiftFieldUp
    # flip field
    elif event == initKeyEvent("KeyF"):
      mSelf.flipFieldH
    # undo, redo
    elif event == initKeyEvent("KeyZ", shift = true):
      mSelf.undo
    elif event == initKeyEvent("KeyX", shift = true):
      mSelf.redo
    else:
      result = false
  of Play:
    # rotate position
    if event == initKeyEvent("KeyJ"):
      mSelf.rotateNextPositionLeft
    elif event == initKeyEvent("KeyK"):
      mSelf.rotateNextPositionRight
    # move position
    elif event == initKeyEvent("KeyA"):
      mSelf.moveNextPositionLeft
    elif event == initKeyEvent("KeyD"):
      mSelf.moveNextPositionRight
    # forward / backward / reset
    elif event == initKeyEvent("KeyS"):
      mSelf.forward
    elif event == initKeyEvent("KeyW"):
      mSelf.backward
    elif event == initKeyEvent("Digit0"):
      mSelf.reset(resetPosition = false)
    elif event == initKeyEvent("Space"):
      mSelf.forward(skip = true)
    elif event == initKeyEvent("KeyN"):
      mSelf.forward(useNextPosition = false)
    else:
      result = false
  of Replay:
    # forward / backward / reset
    if event == initKeyEvent("KeyW"):
      mSelf.backward
    elif event == initKeyEvent("KeyS"):
      mSelf.forward(useNextPosition = false)
    elif event == initKeyEvent("Digit0"):
      mSelf.reset(resetPosition = false)
    else:
      result = false
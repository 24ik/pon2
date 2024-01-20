## This module implements Puyo Puyo simulators.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques, options, sequtils, uri]
import ./[misc]
import ../corepkg/[cell, environment, field, misc, pair, position]
import ../nazopuyopkg/[nazopuyo]
import ../private/[misc]

type
  SimulatorState* {.pure.} = enum
    ## Simulator state.
    Stable
    WillDisappear
    Disappearing

  Simulator* = object
    ## Puyo Puyo simulator.
    ## Note that `editor` does not affect the behaviour; it is used only by
    ## rendering.
    environments*: Environments
    originalEnvironments*: Environments
    positions*: Positions
    requirement*: Requirement

    editor*: bool
    state*: SimulatorState
    kind: SimulatorKind
    mode: SimulatorMode

    undoDeque: Deque[tuple[environments: Environments,
                           requirement: Requirement]]
    redoDeque: Deque[tuple[environments: Environments,
                           requirement: Requirement]]

    next*: tuple[index: Natural, position: Position]
    editing*: tuple[
      cell: Cell, field: tuple[row: Row, column: Column],
      pair: tuple[index: Natural, axis: bool], focusField: bool, insert: bool]

using
  self: Simulator
  mSelf: var Simulator

# ------------------------------------------------
# Constructor - Simulator
# ------------------------------------------------

const
  InitPos = Up2
  DefaultReq = Requirement(kind: Clear, color: some RequirementColor.All,
                           number: none RequirementNumber)

func initSimulator*[F: TsuField or WaterField](
    env: Environment[F], positions: Positions, mode = Play,
    editor = false): Simulator {.inline.} =
  ## Constructor of `Simulator`.
  ## If `mode` is `Edit`, `editor` will be ignored (*i.e.*, regarded as `true`).
  when F is TsuField:
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

  result.editor = editor or mode == Edit
  result.state = Stable
  result.kind = Regular
  result.mode = mode

  result.undoDeque = initDeque[
    tuple[environments: Environments,
          requirement: Requirement]](env.pairs.len)
  result.redoDeque = initDeque[
    tuple[environments: Environments,
          requirement: Requirement]](env.pairs.len)

  result.next.index = Natural 0
  result.next.position = InitPos
  result.editing.cell = None
  result.editing.field = (Row.low, Column.low)
  result.editing.pair = (Natural 0, true)
  result.editing.focusField = true
  result.editing.insert = false

func initSimulator*[F: TsuField or WaterField](
    env: Environment[F], mode = Play, editor = false): Simulator {.inline.} =
  ## Constructor of `Simulator`.
  ## If `mode` is `Edit`, `editor` will be ignored (*i.e.*, regarded as `true`).
  env.initSimulator(Position.none.repeat env.pairs.len, mode, editor)

func initSimulator*[F: TsuField or WaterField](
    nazo: NazoPuyo[F], positions: Positions, mode = Play,
    editor = false): Simulator {.inline.} =
  ## Constructor of `Simulator`.
  ## If `mode` is `Edit`, `editor` will be ignored (*i.e.*, regarded as `true`).
  result = nazo.environment.initSimulator(positions, mode, editor)
  result.kind = Nazo
  result.requirement = nazo.requirement

func initSimulator*[F: TsuField or WaterField](
    nazo: NazoPuyo[F], mode = Play, editor = false): Simulator {.inline.} =
  ## Constructor of `Simulator`.
  ## If `mode` is `Edit`, `editor` will be ignored (*i.e.*, regarded as `true`).
  nazo.initSimulator(Position.none.repeat nazo.moveCount, mode, editor)

# ------------------------------------------------
# Property - Rule / Kind / Mode
# ------------------------------------------------

func rule*(self): Rule {.inline.} = self.environments.rule
func kind*(self): SimulatorKind {.inline.} = self.kind
func mode*(self): SimulatorMode {.inline.} = self.mode

func `rule=`*(mSelf; rule: Rule) {.inline.} =
  if rule == mSelf.rule:
    return

  mSelf.environments.rule = rule

  case rule
  of Tsu: mSelf.environments.tsu = mSelf.environments.water.toTsuEnvironment
  of Water: mSelf.environments.water = mSelf.environments.tsu.toWaterEnvironment

func `kind=`*(mSelf; kind: SimulatorKind) {.inline.} =
  if kind == mSelf.kind:
    return

  mSelf.kind = kind

func `mode=`*(mSelf; mode: SimulatorMode) {.inline.} =
  if mode == mSelf.mode:
    return

  if mode == Edit:
    mSelf.editor = true

  if mode == Edit or mSelf.mode == Edit:
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

template withOriginalNazoPuyo*(self: Simulator, body: untyped): untyped =
  ## Runs `body` with `originalNazoPuyo` exposed.
  case self.rule
  of Tsu:
    let originalNazoPuyo {.inject.} = self.originalTsuNazoPuyo
    body
  of Water:
    let originalNazoPuyo {.inject.} = self.originalWaterNazoPuyo
    body

template withEnvironment*(self: Simulator, body: untyped): untyped =
  ## Runs `body` with `environment` exposed.
  self.environments.flattenAnd:
    body

template withOriginalEnvironment*(self: Simulator, body: untyped): untyped =
  ## Runs `body` with `originalEnvironment` exposed.
  self.originalEnvironments.flattenAnd:
    let originalEnvironment {.inject.} = environment
    body

template withField*(self: Simulator, body: untyped): untyped =
  ## Runs `body` with `field` exposed.
  self.environments.flattenAnd:
    let field {.inject.} = environment.field
    body

template withOriginalField*(self: Simulator, body: untyped): untyped =
  ## Runs `body` with `originalField` exposed.
  self.originalEnvironments.flattenAnd:
    let originalField {.inject.} = environment.field
    body

# ------------------------------------------------
# Edit - Other
# ------------------------------------------------

func toggleInserting*(mSelf) {.inline.} = mSelf.editing.insert.toggle
  ## Toggles inserting or not.

func toggleFocus*(mSelf) {.inline.} = mSelf.editing.focusField.toggle
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

func incRot[T: Ordinal](x: var T) {.inline.} =
  ## Rotating `inc`.
  if x == T.high: x = T.low else: x.inc

func decRot[T: Ordinal](x: var T) {.inline.} =
  ## Rotating `dec`.
  if x == T.low: x = T.high else: x.dec

func moveCursorUp*(mSelf) {.inline.} =
  ## Moves the cursor upward.
  if mSelf.editing.focusField:
    mSelf.editing.field.row.decRot
  else:
    if mSelf.editing.pair.index == 0:
      mSelf.editing.pair.index = mSelf.pairs.len
    else:
      mSelf.editing.pair.index.dec

func moveCursorDown*(mSelf) {.inline.} =
  ## Moves the cursor downward.
  if mSelf.editing.focusField:
    mSelf.editing.field.row.incRot
  else:
    if mSelf.editing.pair.index == mSelf.pairs.len:
      mSelf.editing.pair.index = Natural 0
    else:
      mSelf.editing.pair.index.inc

func moveCursorRight*(mSelf) {.inline.} =
  ## Moves the cursor rightward.
  if mSelf.editing.focusField:
    mSelf.editing.field.column.incRot
  else:
    mSelf.editing.pair.axis.toggle

func moveCursorLeft*(mSelf) {.inline.} =
  ## Moves the cursor leftward.
  if mSelf.editing.focusField:
    mSelf.editing.field.column.decRot
  else:
    mSelf.editing.pair.axis.toggle

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
  mSelf.deletePair mSelf.editing.pair.index

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
    if mSelf.editing.insert:
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
  mSelf.writeCell row, col, mSelf.editing.cell

func writeCell(mSelf; idx: Natural, axis: bool, cell: Cell) {.inline.} =
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
        if mSelf.editing.insert:
          mSelf.pairs.insert initPair(color, color), idx
          mSelf.positions.insert Position.none, idx
        else:
          if axis:
            mSelf.pairs[idx].axis = color
          else:
            mSelf.pairs[idx].child = color

func writeCell*(mSelf; idx: Natural, axis: bool) {.inline.} =
  ## Writes the selecting cell to the pairs.
  mSelf.writeCell idx, axis, mSelf.editing.cell

func writeCell*(mSelf; cell: Cell) {.inline.} =
  ## Writes the cell to the field or pairs.
  if mSelf.editing.focusField:
    mSelf.writeCell mSelf.editing.field.row, mSelf.editing.field.column, cell
  else:
    mSelf.writeCell mSelf.editing.pair.index, mSelf.editing.pair.axis, cell

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

func moveNextPositionRight*(mSelf) {.inline.} = mSelf.next.position.moveRight
  ## Moves the next position right.

func moveNextPositionLeft*(mSelf) {.inline.} = mSelf.next.position.moveLeft
  ## Moves the next position left.

func rotateNextPositionRight*(mSelf) {.inline.} =
  ## Rotates the next position right.
  mSelf.next.position.rotateRight

func rotateNextPositionLeft*(mSelf) {.inline.} = mSelf.next.position.rotateLeft
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
      mSelf.positions[mSelf.next.index] = some mSelf.next.position
    if skip:
      mSelf.positions[mSelf.next.index] = none Position

    # put
    block:
      let
        pair = mSelf.pairs.popFirst
        pos = mSelf.positions[mSelf.next.index]

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
        mSelf.next.index.inc
        mSelf.next.position = InitPos
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
      mSelf.next.index.inc
      mSelf.next.position = InitPos

func backward*(mSelf) {.inline.} =
  ## Backwards the simulator.
  if mSelf.undoDeque.len == 0:
    return

  if mSelf.state == Stable:
    mSelf.next.index.dec

  (mSelf.environments, mSelf.requirement) = mSelf.undoDeque.popLast
  mSelf.state = Stable
  mSelf.next.position = InitPos

func reset*(mSelf; resetPosition = true) {.inline.} =
  ## Resets the simulator.
  mSelf.state = Stable
  mSelf.environments = mSelf.originalEnvironments
  mSelf.undoDeque.clear
  mSelf.redoDeque.clear
  mSelf.next.index = 0
  mSelf.next.position = InitPos

  if resetPosition:
    mSelf.positions = Position.none.repeat mSelf.pairs.len

# ------------------------------------------------
# Simulator -> URI
# ------------------------------------------------

func toUri*(self; editor: bool, withPositions: bool): Uri {.inline.} =
  ## Converts the simulator to the URI.
  ## `self.editor` will be overridden with `editor`.
  case self.kind
  of Regular:
    self.withEnvironment:
      result =
        if withPositions:
          environment.toUri(self.positions, kind = self.kind, mode = self.mode,
                            editor = editor)
        else:
          environment.toUri(kind = self.kind, mode = self.mode,
                            editor = editor)
  of Nazo:
    self.withNazoPuyo:
      result =
        if withPositions: nazoPuyo.toUri(self.positions, mode = self.mode,
                                         editor = editor)
        else:
          nazoPuyo.toUri(mode = self.mode, editor = editor)

func toUri*(self; withPositions: bool): Uri {.inline.} =
  ## Converts the simulator to the URI.
  self.toUri(self.editor, withPositions)

# ------------------------------------------------
# Keyboard Operation
# ------------------------------------------------

func operate*(mSelf; event: KeyEvent): bool {.discardable.} =
  ## Handler for keyboard input.
  ## Returns `true` if any action is executed.
  result = true

  case mSelf.mode
  of Edit:
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

# ------------------------------------------------
# Backend-specific Implementation
# ------------------------------------------------

when defined(js):
  import std/[dom, sugar]
  import karax/[karax, karaxdsl, vdom]
  import ../private/app/web/[controller, field, immediatepairs, messages,
                             nextpair, pairs as pairsModule, palette,
                             requirement, select, share]

  # ------------------------------------------------
  # JS - Keyboard Handler
  # ------------------------------------------------

  proc runKeyboardEventHandler*(mSelf; event: KeyEvent) {.inline.} =
    ## Keybaord event handler.
    let needRedraw = mSelf.operate event
    if needRedraw and not kxi.surpressRedraws:
      kxi.redraw

  proc runKeyboardEventHandler*(mSelf; event: dom.Event) {.inline.} =
    ## Keybaord event handler.
    # HACK: somehow this assertion fails
    # assert event of KeyboardEvent
    mSelf.runKeyboardEventHandler cast[KeyboardEvent](event).toKeyEvent

  func initKeyboardEventHandler*(mSelf): (event: dom.Event) -> void {.inline.} =
    ## Returns the keyboard event handler.
    (event: dom.Event) => mSelf.runKeyboardEventHandler event

  # ------------------------------------------------
  # JS - Node
  # ------------------------------------------------

  proc initSimulatorNode(mSelf; id: string): VNode {.inline.} =
    ## Returns the node without the external section.
    ## `id` is shared with other node-creating procedures and need to be unique.
    buildHtml(tdiv):
      tdiv(class = "block"):
        mSelf.initRequirementNode(id = id)
      tdiv(class = "block"):
        tdiv(class = "columns is-mobile is-variable is-1"):
          tdiv(class = "column is-narrow"):
            if mSelf.mode != Edit:
              tdiv(class = "block"):
                mSelf.initNextPairNode
            tdiv(class = "block"):
              mSelf.initFieldNode
            if mSelf.mode != Edit:
              tdiv(class = "block"):
                mSelf.initMessagesNode
            if mSelf.editor:
              tdiv(class = "block"):
                mSelf.initSelectNode
            tdiv(class = "block"):
              mSelf.initShareNode id
          if mSelf.mode != Edit:
            tdiv(class = "column is-narrow"):
              tdiv(class = "block"):
                mSelf.initImmediatePairsNode
          tdiv(class = "column is-narrow"):
            tdiv(class = "block"):
              mSelf.initControllerNode
            if mSelf.mode == Edit:
              tdiv(class = "block"):
                mSelf.initPaletteNode
            tdiv(class = "block"):
              mSelf.initPairsNode

  proc initSimulatorNode*(mSelf; setKeyHandler = true, wrapSection = true,
                          id = ""): VNode {.inline.} =
    ## Returns the simulator node.
    ## `id` is shared with other node-creating procedures and need to be unique.
    if setKeyHandler:
      document.onkeydown = mSelf.initKeyboardEventHandler

    if wrapSection:
      result = buildHtml(section(class = "section")):
        mSelf.initSimulatorNode id
    else:
      result = mSelf.initSimulatorNode id

  proc initSimulatorNode*[F: TsuField or WaterField](
      nazoEnv: NazoPuyo[F] or Environment[F], mode = Play, editor = false,
      setKeyHandler = true, wrapSection = true, id = ""): VNode {.inline.} =
    ## Returns the simulator node.
    ## `id` is shared with other node-creating procedures and need to be unique.
    var simulator = nazoEnv.initSimulator(mode, editor)
    result = simulator.initSimulatorNode(setKeyHandler, wrapSection, id)

  proc initSimulatorNode*[F: TsuField or WaterField](
      nazoEnv: NazoPuyo[F] or Environment[F], positions: Positions, mode = Play,
      editor = false, setKeyHandler = true, wrapSection = true, id = ""): VNode
      {.inline.} =
    ## Returns the simulator node.
    ## `id` is shared with other node-creating procedures and need to be unique.
    var simulator = nazoEnv.initSimulator(positions, mode, editor)
    result = simulator.initSimulatorNode(setKeyHandler, wrapSection, id)
else:
  import std/[sugar]
  import nigui
  import ../private/app/native/[assets, field, immediatepairs, messages,
                                nextpair, pairs as pairsModule, requirement,
                                select, share]

  type
    SimulatorControl* = ref object of LayoutContainer
      ## Root control of the simulator.
      simulator*: ref Simulator

    SimulatorWindow* = ref object of WindowImpl
      ## Application window for the simulator.
      simulator*: ref Simulator

  # ------------------------------------------------
  # Native - Keyboard Handler
  # ------------------------------------------------

  proc runKeyboardEventHandler*(window: SimulatorWindow, event: KeyboardEvent,
                                keys = downKeys()) {.inline.} =
    ## Keyboard event handler.
    let needRedraw = window.simulator[].operate event.toKeyEvent keys
    if needRedraw:
      event.window.control.forceRedraw

  proc keyboardEventHandler(event: KeyboardEvent) =
    ## Keyboard event handler.
    let rawWindow = event.window
    assert rawWindow of SimulatorWindow

    cast[SimulatorWindow](rawWindow).runKeyboardEventHandler event

  func initKeyboardEventHandler*: (event: KeyboardEvent) -> void {.inline.} =
    ## Returns the keyboard event handler.
    keyboardEventHandler

  # ------------------------------------------------
  # Native - Control
  # ------------------------------------------------

  proc initSimulatorControl*(simulator: ref Simulator): SimulatorControl
                            {.inline.} =
    ## Returns the simulator control.
    result = new SimulatorControl
    result.init
    result.layout = Layout_Vertical

    result.simulator = simulator

    let assetsRef = new Assets
    assetsRef[] = initAssets()

    # row=0
    let reqControl = simulator.initRequirementControl
    result.add reqControl

    # row=1
    let secondRow = newLayoutContainer Layout_Horizontal
    result.add secondRow

    # row=1, left
    let left = newLayoutContainer Layout_Vertical
    secondRow.add left

    let
      field = simulator.initFieldControl assetsRef
      messages = simulator.initMessagesControl assetsRef
    left.add simulator.initNextPairControl assetsRef
    left.add field
    left.add messages
    left.add simulator.initSelectControl reqControl
    left.add simulator.initShareControl

    # row=1, center
    secondRow.add simulator.initImmediatePairsControl assetsRef

    # row=1, right
    secondRow.add simulator.initPairsControl assetsRef

    # set size
    reqControl.setWidth secondRow.naturalWidth
    messages.setWidth field.naturalWidth

  proc initSimulatorWindow*(simulator: ref Simulator, title = "ぷよぷよシミュレータ",
                            setKeyHandler = true): SimulatorWindow {.inline.} =
    ## Returns the simulator window.
    result = new SimulatorWindow
    result.init

    result.simulator = simulator

    result.title = title
    result.resizable = false
    if setKeyHandler:
      result.onKeyDown = keyboardEventHandler

    let rootControl = simulator.initSimulatorControl
    result.add rootControl

    when defined(windows):
      # HACK: somehow this adjustment is needed on Windows
      # TODO: better implementation
      result.width = (rootControl.naturalWidth.float * 1.1).int
      result.height = (rootControl.naturalHeight.float * 1.1).int
    else:
      result.width = rootControl.naturalWidth
      result.height = rootControl.naturalHeight

export toKeyEvent

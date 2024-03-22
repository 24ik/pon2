## This module implements Puyo Puyo simulators.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques, sequtils, strformat, sugar, tables, uri]
import ./[key, nazopuyo]
import
  ../core/[
    cell, field, fieldtype, host, moveresult, nazopuyo, pair, pairposition, position,
    puyopuyo, requirement, rule,
  ]
import ../private/[intrinsic, misc]

when UseAvx2:
  import ../private/core/field/avx2/[disappearresult]
else:
  import ../private/core/field/primitive/[disappearresult]

type
  SimulatorKind* {.pure.} = enum
    ## simulator kind.
    Regular = "r"
    Nazo = "n"

  SimulatorMode* {.pure.} = enum
    ## simulator mode.
    Edit = "e"
    Play = "p"
    Replay = "r"

  SimulatorState* {.pure.} = enum
    ## Simulator state.
    Stable
    WillDisappear
    Disappearing

  SimulatorEditing* = object ## Editing information.
    cell*: Cell
    field*: tuple[row: Row, column: Column]
    pair*: tuple[index: Natural, axis: bool]
    focusField*: bool
    insert*: bool

  Simulator* = object
    ## Puyo Puyo simulator.
    ## Note that `editor` field does not affect the behaviour; it is used only
    ## by rendering.
    nazoPuyoWrap: NazoPuyoWrap
    moveResult: MoveResult

    editor: bool
    state: SimulatorState
    kind: SimulatorKind
    mode: SimulatorMode

    undoDeque: Deque[NazoPuyoWrap]
    redoDeque: Deque[NazoPuyoWrap]

    operatingPosition: Position
    editing: SimulatorEditing

using
  self: Simulator
  mSelf: var Simulator

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const
  InitPos = Up2
  DefaultReq = Requirement(kind: Clear, color: RequirementColor.All, number: 0)
  DefaultMoveResult =
    initMoveResult(0, [0, 0, 0, 0, 0, 0, 0], newSeq[array[ColorPuyo, seq[int]]](0))

func initSimulator*(
    nazoPuyoWrap: NazoPuyoWrap, mode = Play, editor = false
): Simulator {.inline.} =
  ## Returns a new simulator.
  ## If `mode` is `Edit`, `editor` will be ignored (*i.e.*, regarded as `true`).
  result.nazoPuyoWrap = nazoPuyoWrap
  result.moveResult = DefaultMoveResult

  result.editor = editor or mode == Edit
  result.state = Stable
  result.kind = Nazo
  result.mode = mode

  nazoPuyoWrap.get:
    result.undoDeque = initDeque[NazoPuyoWrap](wrappedNazoPuyo.moveCount)
    result.redoDeque = initDeque[NazoPuyoWrap](wrappedNazoPuyo.moveCount)

  result.operatingPosition = InitPos
  result.editing.cell = Cell.None
  result.editing.field = (Row.low, Column.low)
  result.editing.pair = (Natural 0, true)
  result.editing.focusField = true
  result.editing.insert = false

func initSimulator*[F: TsuField or WaterField](
    nazo: NazoPuyo[F], mode = Play, editor = false
): Simulator {.inline.} =
  ## Returns a new simulator.
  ## If `mode` is `Edit`, `editor` will be ignored (*i.e.*, regarded as `true`).
  initNazoPuyoWrap(nazo).initSimulator(mode, editor)

func initSimulator*[F: TsuField or WaterField](
    puyoPuyo: PuyoPuyo[F], mode = Play, editor = false
): Simulator {.inline.} =
  ## Returns a new simulator.
  ## If `mode` is `Edit`, `editor` will be ignored (*i.e.*, regarded as `true`).
  result =
    NazoPuyo[F](puyoPuyo: puyoPuyo, requirement: DefaultReq).initSimulator(mode, editor)
  result.kind = Regular

# ------------------------------------------------
# Property - Rule / Kind / Mode
# ------------------------------------------------

func rule*(self): Rule {.inline.} =
  self.nazoPuyoWrap.rule

func kind*(self): SimulatorKind {.inline.} =
  self.kind

func mode*(self): SimulatorMode {.inline.} =
  self.mode

func `rule=`*(mSelf; rule: Rule) {.inline.} =
  mSelf.nazoPuyoWrap.rule = rule

func `kind=`*(mSelf; kind: SimulatorKind) {.inline.} =
  mSelf.kind = kind

func `mode=`*(mSelf; mode: SimulatorMode) {.inline.} =
  if mode == mSelf.mode:
    return

  if mode == Edit:
    mSelf.editor = true

  if mode == Edit or mSelf.mode == Edit:
    if mSelf.undoDeque.len > 0:
      mSelf.nazoPuyoWrap = mSelf.undoDeque.popFirst
    mSelf.state = Stable
    mSelf.undoDeque.clear
    mSelf.redoDeque.clear

  mSelf.mode = mode

# ------------------------------------------------
# Property - Nazo Puyo
# ------------------------------------------------

func nazoPuyoWrap*(self): NazoPuyoWrap {.inline.} =
  ## Returns the wrapped Nazo Puyo.
  self.nazoPuyoWrap

func nazoPuyoWrap*(mSelf): var NazoPuyoWrap {.inline.} =
  ## Returns the wrapped Nazo Puyo.
  result = mSelf.nazoPuyoWrap

func originalNazoPuyoWrap*(self): NazoPuyoWrap {.inline.} =
  ## Returns the wrapped Nazo Puyo before any moves.
  if self.undoDeque.len > 0: self.undoDeque.peekFirst else: self.nazoPuyoWrap

# ------------------------------------------------
# Property - Other
# ------------------------------------------------

func editor*(self): bool {.inline.} =
  ## Returns `true` if the simulator is in the editor mode.
  self.editor

func state*(self): SimulatorState {.inline.} =
  ## Returns the simulator state.
  self.state

func score*(self): int {.inline.} = ## Returns the score.
  self.moveResult.score

func operatingPosition*(self): Position {.inline.} =
  ## Returns the operating position.
  self.operatingPosition

func editing*(self): SimulatorEditing {.inline.} =
  ## Returns the editing information.
  self.editing

func editing*(mSelf): var SimulatorEditing {.inline.} =
  ## Returns the editing information.
  result = mSelf.editing

# ------------------------------------------------
# Edit - Other
# ------------------------------------------------

func toggleInserting*(mSelf) {.inline.} = ## Toggles inserting or not.
  mSelf.editing.insert.toggle

func toggleFocus*(mSelf) {.inline.} = ## Toggles focusing field or not.
  mSelf.editing.focusField.toggle

func save(mSelf) {.inline.} =
  ## Saves the current simulator.
  mSelf.undoDeque.addLast mSelf.nazoPuyoWrap
  mSelf.redoDeque.clear

template change(mSelf; body: untyped) =
  ## Helper template for operations that changes `originalNazoPuyoWrap`.
  mSelf.save
  body

# ------------------------------------------------
# Edit - Cursor
# ------------------------------------------------

func moveCursorUp*(mSelf) {.inline.} =
  ## Moves the cursor upward.
  if mSelf.editing.focusField:
    mSelf.editing.field.row.decRot
  else:
    if mSelf.editing.pair.index == 0:
      mSelf.editing.pair.index = mSelf.nazoPuyoWrap.get:
        wrappedNazoPuyo.puyoPuyo.pairsPositions.len
    else:
      mSelf.editing.pair.index.dec

func moveCursorDown*(mSelf) {.inline.} =
  ## Moves the cursor downward.
  if mSelf.editing.focusField:
    mSelf.editing.field.row.incRot
  else:
    let lastIdx = mSelf.nazoPuyoWrap.get:
      wrappedNazoPuyo.puyoPuyo.pairsPositions.len
    if mSelf.editing.pair.index == lastIdx:
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

func deletePairPosition*(mSelf; idx: Natural) {.inline.} =
  ## Deletes the pair&position.
  mSelf.nazoPuyoWrap.get:
    if idx >= wrappedNazoPuyo.puyoPuyo.pairsPositions.len:
      return

    mSelf.change:
      wrappedNazoPuyo.puyoPuyo.pairsPositions.delete idx

func deletePairPosition*(mSelf) {.inline.} =
  ## Deletes the pair&position at selecting index.
  mSelf.deletePairPosition mSelf.editing.pair.index

# ------------------------------------------------
# Edit - Write
# ------------------------------------------------

func writeCell(mSelf; row: Row, col: Column, cell: Cell) {.inline.} =
  ## Writes the cell to the field.
  mSelf.change:
    mSelf.nazoPuyoWrap.get:
      if mSelf.editing.insert:
        if cell == Cell.None:
          wrappedNazoPuyo.puyoPuyo.field.removeSqueeze row, col
        else:
          wrappedNazoPuyo.puyoPuyo.field.insert row, col, cell
      else:
        wrappedNazoPuyo.puyoPuyo.field[row, col] = cell

func writeCell*(mSelf; row: Row, col: Column) {.inline.} =
  ## Writes the selecting cell to the field.
  mSelf.writeCell row, col, mSelf.editing.cell

func writeCell(mSelf; idx: Natural, axis: bool, cell: Cell) {.inline.} =
  ## Writes the cell to the pairs.
  case cell
  of Cell.None:
    mSelf.deletePairPosition idx
  of Hard, Cell.Garbage:
    discard
  of Cell.Red .. Cell.Purple:
    let color = ColorPuyo cell
    mSelf.change:
      mSelf.nazoPuyoWrap.get:
        if idx == wrappedNazoPuyo.puyoPuyo.pairsPositions.len:
          wrappedNazoPuyo.puyoPuyo.pairsPositions.add PairPosition(
            pair: initPair(color, color), position: Position.None
          )
        else:
          if mSelf.editing.insert:
            wrappedNazoPuyo.puyoPuyo.pairsPositions.insert PairPosition(
              pair: initPair(color, color), position: Position.None
            ), idx
          else:
            if axis:
              wrappedNazoPuyo.puyoPuyo.pairsPositions[idx].pair.axis = color
            else:
              wrappedNazoPuyo.puyoPuyo.pairsPositions[idx].pair.child = color

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
    mSelf.nazoPuyoWrap.get:
      wrappedNazoPuyo.puyoPuyo.field.shiftUp

func shiftFieldDown*(mSelf) {.inline.} =
  ## Shifts the field downward.
  mSelf.change:
    mSelf.nazoPuyoWrap.get:
      wrappedNazoPuyo.puyoPuyo.field.shiftDown

func shiftFieldRight*(mSelf) {.inline.} =
  ## Shifts the field rightward.
  mSelf.change:
    mSelf.nazoPuyoWrap.get:
      wrappedNazoPuyo.puyoPuyo.field.shiftRight

func shiftFieldLeft*(mSelf) {.inline.} =
  ## Shifts the field leftward.
  mSelf.change:
    mSelf.nazoPuyoWrap.get:
      wrappedNazoPuyo.puyoPuyo.field.shiftLeft

# ------------------------------------------------
# Edit - Flip
# ------------------------------------------------

func flipFieldV*(mSelf) {.inline.} =
  ## Flips the field vertically.
  mSelf.change:
    mSelf.nazoPuyoWrap.get:
      wrappedNazoPuyo.puyoPuyo.field.flipV

func flipFieldH*(mSelf) {.inline.} =
  ## Flips the field horizontally.
  mSelf.change:
    mSelf.nazoPuyoWrap.get:
      wrappedNazoPuyo.puyoPuyo.field.flipH

# ------------------------------------------------
# Edit - Requirement
# ------------------------------------------------

func `requirementKind=`*(mSelf; kind: RequirementKind) {.inline.} =
  ## Sets the requirement kind.
  mSelf.nazoPuyoWrap.get:
    if kind == wrappedNazoPuyo.requirement.kind:
      return

    {.cast(uncheckedAssign).}:
      mSelf.change:
        if kind in ColorKinds:
          if wrappedNazoPuyo.requirement.kind in ColorKinds:
            wrappedNazoPuyo.requirement.kind = kind
          else:
            wrappedNazoPuyo.requirement = Requirement(
              kind: kind,
              color: RequirementColor.low,
              number: wrappedNazoPuyo.requirement.number,
            )
        else:
          wrappedNazoPuyo.requirement =
            Requirement(kind: kind, number: wrappedNazoPuyo.requirement.number)

func `requirementColor=`*(mSelf; color: RequirementColor) {.inline.} =
  ## Sets the requirement color.
  mSelf.nazoPuyoWrap.get:
    if wrappedNazoPuyo.requirement.kind in NoColorKinds:
      return
    if color == wrappedNazoPuyo.requirement.color:
      return

    mSelf.change:
      wrappedNazoPuyo.requirement.color = color

func `requirementNumber=`*(mSelf; num: RequirementNumber) {.inline.} =
  ## Sets the requirement number.
  mSelf.nazoPuyoWrap.get:
    if wrappedNazoPuyo.requirement.kind in NoNumberKinds:
      return
    if num == wrappedNazoPuyo.requirement.number:
      return

    mSelf.change:
      wrappedNazoPuyo.requirement.number = num

# ------------------------------------------------
# Edit - Undo / Redo
# ------------------------------------------------

func undo*(mSelf) {.inline.} =
  ## Performs undo.
  if mSelf.undoDeque.len == 0:
    return

  mSelf.redoDeque.addLast mSelf.nazoPuyoWrap
  mSelf.nazoPuyoWrap = mSelf.undoDeque.popLast

func redo*(mSelf) {.inline.} =
  ## Performs redo.
  if mSelf.redoDeque.len == 0:
    return

  mSelf.undoDeque.addLast mSelf.nazoPuyoWrap
  mSelf.nazoPuyoWrap = mSelf.redoDeque.popLast

# ------------------------------------------------
# Play - Position
# ------------------------------------------------

func moveOperatingPositionRight*(mSelf) {.inline.} =
  ## Moves the operating position right.
  mSelf.operatingPosition.moveRight

func moveOperatingPositionLeft*(mSelf) {.inline.} =
  ## Moves the operating position left.
  mSelf.operatingPosition.moveLeft

func rotateOperatingPositionRight*(mSelf) {.inline.} =
  ## Rotates the operating position right.
  mSelf.operatingPosition.rotateRight

func rotateOperatingPositionLeft*(mSelf) {.inline.} =
  ## Rotates the operating position left.
  mSelf.operatingPosition.rotateLeft

# ------------------------------------------------
# Forward / Backward
# ------------------------------------------------

func forward*(mSelf; replay = false, skip = false) {.inline.} =
  ## Forwards the simulator.
  ## `replay` is prioritized over `skip`.
  mSelf.nazoPuyoWrap.get:
    case mSelf.state
    of Stable:
      if wrappedNazoPuyo.puyoPuyo.movingCompleted:
        return

      mSelf.moveResult = DefaultMoveResult
      mSelf.save

      # put
      if not replay:
        wrappedNazoPuyo.puyoPuyo.operatingPairPosition.position =
          if skip: Position.None else: mSelf.operatingPosition
      wrappedNazoPuyo.puyoPuyo.field.put wrappedNazoPuyo.puyoPuyo.operatingPairPosition

      # disappear
      if wrappedNazoPuyo.puyoPuyo.field.willDisappear:
        mSelf.state = WillDisappear
      else:
        mSelf.state = Stable
        mSelf.operatingPosition = InitPos
        wrappedNazoPuyo.puyoPuyo.incrementOperatingIndex
    of WillDisappear:
      let disappearRes = wrappedNazoPuyo.puyoPuyo.field.disappear

      for puyo in Puyo.low .. Puyo.high:
        mSelf.moveResult.disappearCounts[puyo].inc disappearRes.puyoCount puyo
      mSelf.moveResult.fullDisappearCounts.add disappearRes.connectionCounts

      mSelf.state = Disappearing
    of Disappearing:
      wrappedNazoPuyo.puyoPuyo.field.drop
      if wrappedNazoPuyo.puyoPuyo.field.willDisappear:
        mSelf.state = WillDisappear
      else:
        mSelf.state = Stable
        mSelf.operatingPosition = InitPos
        wrappedNazoPuyo.puyoPuyo.incrementOperatingIndex

func backward*(mSelf) {.inline.} =
  ## Backwards the simulator.
  if mSelf.undoDeque.len == 0:
    return

  mSelf.moveResult = DefaultMoveResult

  let pairsPositions: PairsPositions
  mSelf.nazoPuyoWrap.get:
    pairsPositions = wrappedNazoPuyo.puyoPuyo.pairsPositions

  mSelf.nazoPuyoWrap = mSelf.undoDeque.popLast
  mSelf.state = Stable
  mSelf.operatingPosition = InitPos

  mSelf.nazoPuyoWrap.get:
    wrappedNazoPuyo.puyoPuyo.pairsPositions = pairsPositions

func reset*(mSelf; resetPosition = true) {.inline.} =
  ## Resets the simulator.
  mSelf.nazoPuyoWrap.get:
    let savePairsPositions = wrappedNazoPuyo.puyoPuyo.pairsPositions
    mSelf.state = Stable
    if mSelf.undoDeque.len > 0:
      mSelf.nazoPuyoWrap = mSelf.undoDeque.popFirst
    mSelf.undoDeque.clear
    mSelf.redoDeque.clear
    mSelf.operatingPosition = InitPos
    mSelf.moveResult = DefaultMoveResult

    for i in 0 ..< wrappedNazoPuyo.puyoPuyo.pairsPositions.len:
      wrappedNazoPuyo.puyoPuyo.pairsPositions[i].position =
        if resetPosition:
          Position.None
        else:
          savePairsPositions[i].position

# ------------------------------------------------
# Simulator <-> URI
# ------------------------------------------------

const
  EditorKey = "editor"
  KindKey = "kind"
  ModeKey = "mode"

  StrToKind = collect:
    for kind in SimulatorKind:
      {$kind: kind}
  StrToMode = collect:
    for mode in SimulatorMode:
      {$mode: mode}

func toUri*(self; withPositions: bool, editor: bool, host = Izumiya): Uri {.inline.} =
  ## Returns the URI converted from the simulator.
  ## `self.editor` will be overridden with `editor`.
  result = initUri()
  result.scheme =
    case host
    of Izumiya, Ishikawa: "https"
    of Ips: "http"
  result.hostname = $host

  # path
  case host
  of Izumiya:
    result.path = "/pon2/gui/index.html"
  of Ishikawa, Ips:
    let modeChar =
      case self.kind
      of Regular:
        case self.mode
        of Edit: 'e'
        of Play: 's'
        of Replay: 'v'
      of Nazo:
        'n'
    result.path = &"/simu/p{modeChar}.html"

  let mainQuery: string
  self.nazoPuyoWrap.get:
    # position
    var nazo = wrappedNazoPuyo
    if not withPositions:
      for pairPos in nazo.puyoPuyo.pairsPositions.mitems:
        pairPos.position = Position.None

    # nazopuyo / puyopuyo
    mainQuery =
      case self.kind
      of Regular:
        nazo.puyoPuyo.toUriQuery host
      of Nazo:
        nazo.toUriQuery host

  case host
  of Izumiya:
    # editor, kind, mode
    var queries = newSeq[(string, string)](0)
    if editor:
      queries.add (EditorKey, "")
    queries.add (KindKey, $self.kind)
    queries.add (ModeKey, $self.mode)

    result.query = &"{queries.encodeQuery}&{mainQuery}"
  of Ishikawa, Ips:
    result.query = mainQuery

func toUri*(self; withPositions: bool, host = Izumiya): Uri {.inline.} =
  ## Returns the URI converted from the simulator.
  self.toUri(withPositions, self.editor, host)

func parseSimulator*(uri: Uri): Simulator {.inline.} =
  ## Returns the simulator converted from the URI.
  ## If the URI is invalid, `ValueError` is raised.
  result = initPuyoPuyo[TsuField]().initSimulator # HACK: dummy to suppress warning

  case uri.hostname
  of $Izumiya:
    if uri.path != "/pon2/gui/index.html":
      raise newException(ValueError, "Invalid simulator: " & $uri)

    var
      editor = false
      kindVal = "<invalid>"
      modeVal = "<invalid>"
      mainQueries = newSeq[(string, string)](0)
    assert kindVal notin StrToKind
    assert modeVal notin StrToMode

    for (key, val) in uri.query.decodeQuery:
      case key
      of EditorKey:
        if val == "":
          editor = true
        else:
          raise newException(ValueError, "Invalid simulator: " & $uri)
      of KindKey:
        kindVal = val
      of ModeKey:
        modeVal = val
      else:
        mainQueries.add (key, val)

    if kindVal notin StrToKind or modeVal notin StrToMode:
      raise newException(ValueError, "Invalid simulator: " & $uri)

    let
      kind = StrToKind[kindVal]
      mode = StrToMode[modeVal]
      mainQuery = mainQueries.encodeQuery

    case kind
    of Regular:
      try:
        result = parsePuyoPuyo[TsuField](mainQuery, Izumiya).initSimulator(mode, editor)
      except ValueError:
        try:
          result =
            parsePuyoPuyo[WaterField](mainQuery, Izumiya).initSimulator(mode, editor)
        except ValueError:
          raise newException(ValueError, "Invalid simulator: " & $uri)
    of Nazo:
      try:
        result = parseNazoPuyo[TsuField](mainQuery, Izumiya).initSimulator(mode, editor)
      except ValueError:
        try:
          result =
            parseNazoPuyo[WaterField](mainQuery, Izumiya).initSimulator(mode, editor)
        except ValueError:
          raise newException(ValueError, "Invalid simulator: " & $uri)
  of $Ishikawa, $Ips:
    var
      kind = SimulatorKind.low
      mode = SimulatorMode.low
    case uri.path
    of "/simu/pe.html":
      kind = Regular
      mode = Edit
    of "/simu/ps.html":
      kind = Regular
      mode = Play
    of "/simu/pv.html":
      kind = Regular
      mode = Replay
    of "/simu/pn.html":
      kind = Nazo
      mode = Play
    else:
      raise newException(ValueError, "Invalid simulator: " & $uri)

    let host = if uri.hostname == $Ishikawa: Ishikawa else: Ips

    case kind
    of Regular:
      result = parsePuyoPuyo[TsuField](uri.query, host).initSimulator(mode, true)
    of Nazo:
      result = parseNazoPuyo[TsuField](uri.query, host).initSimulator(mode, true)
  else:
    raise newException(ValueError, "Invalid simulator: " & $uri)

# ------------------------------------------------
# Keyboard Operation
# ------------------------------------------------

func operate*(mSelf; event: KeyEvent): bool {.discardable.} =
  ## Does operation specified by the keyboard input.
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
      mSelf.writeCell Cell.None
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
      mSelf.rotateOperatingPositionLeft
    elif event == initKeyEvent("KeyK"):
      mSelf.rotateOperatingPositionRight
    # move position
    elif event == initKeyEvent("KeyA"):
      mSelf.moveOperatingPositionLeft
    elif event == initKeyEvent("KeyD"):
      mSelf.moveOperatingPositionRight
    # forward / backward / reset
    elif event == initKeyEvent("KeyS"):
      mSelf.forward
    elif event == initKeyEvent("KeyW"):
      mSelf.backward
    elif event == initKeyEvent("Digit0"):
      mSelf.reset false
    elif event == initKeyEvent("Space"):
      mSelf.forward(skip = true)
    elif event == initKeyEvent("KeyN"):
      mSelf.forward(replay = true)
    else:
      result = false
  of Replay:
    # forward / backward / reset
    if event == initKeyEvent("KeyW"):
      mSelf.backward
    elif event == initKeyEvent("KeyS"):
      mSelf.forward(replay = true)
    elif event == initKeyEvent("Digit0"):
      mSelf.reset false
    else:
      result = false

# ------------------------------------------------
# Backend-specific Implementation
# ------------------------------------------------

when defined(js):
  import karax/[karax, karaxdsl, kdom, vdom]
  import
    ../private/app/simulator/web/[
      controller,
      field,
      immediatepairs,
      messages,
      operating as operatingModule,
      pairs as pairsModule,
      palette,
      requirement,
      select,
      share,
    ]

  # ------------------------------------------------
  # JS - Keyboard Handler
  # ------------------------------------------------

  proc runKeyboardEventHandler*(mSelf; event: KeyEvent) {.inline.} =
    ## Runs the keybaord event handler.
    let needRedraw = mSelf.operate event
    if needRedraw and not kxi.surpressRedraws:
      kxi.redraw

  proc runKeyboardEventHandler*(mSelf; event: dom.Event) {.inline.} =
    ## Runs the keybaord event handler.
    # assert event of KeyboardEvent # HACK: somehow this assertion fails
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
                mSelf.initOperatingNode
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

  proc initSimulatorNode*(
      mSelf; setKeyHandler = true, wrapSection = true, id = ""
  ): VNode {.inline.} =
    ## Returns the simulator node.
    ## `id` is shared with other node-creating procedures and need to be unique.
    if setKeyHandler:
      document.onkeydown = mSelf.initKeyboardEventHandler

    if wrapSection:
      result = buildHtml(section(class = "section")):
        mSelf.initSimulatorNode id
    else:
      result = mSelf.initSimulatorNode id

else:
  import nigui
  import
    ../private/app/simulator/native/[
      assets,
      field,
      immediatepairs,
      messages,
      operating as operatingModule,
      pairs as pairsModule,
      requirement,
      select,
      share,
    ]

  type
    SimulatorControl* = ref object of LayoutContainer ## Root control of the simulator.
      simulator*: ref Simulator

    SimulatorWindow* = ref object of WindowImpl ## Application window for the simulator.
      simulator*: ref Simulator

  # ------------------------------------------------
  # Native - Keyboard Handler
  # ------------------------------------------------

  proc runKeyboardEventHandler*(
      window: SimulatorWindow, event: KeyboardEvent, keys = downKeys()
  ) {.inline.} =
    ## Runs the keyboard event handler.
    let needRedraw = window.simulator[].operate event.toKeyEvent keys
    if needRedraw:
      event.window.control.forceRedraw

  proc runKeyboardEventHandler(event: KeyboardEvent) =
    ## Runs the keyboard event handler.
    let rawWindow = event.window
    assert rawWindow of SimulatorWindow

    cast[SimulatorWindow](rawWindow).runKeyboardEventHandler event

  func initKeyboardEventHandler*(): (event: KeyboardEvent) -> void {.inline.} =
    ## Returns the keyboard event handler.
    runKeyboardEventHandler

  # ------------------------------------------------
  # Native - Control
  # ------------------------------------------------

  proc initSimulatorControl*(simulator: ref Simulator): SimulatorControl {.inline.} =
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
    left.add simulator.initOperatingControl assetsRef
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

  proc initSimulatorWindow*(
      simulator: ref Simulator,
      title = "Pon!通シミュレーター",
      setKeyHandler = true,
  ): SimulatorWindow {.inline.} =
    ## Returns the simulator window.
    result = new SimulatorWindow
    result.init

    result.simulator = simulator

    result.title = title
    result.resizable = false
    if setKeyHandler:
      result.onKeyDown = runKeyboardEventHandler

    let rootControl = simulator.initSimulatorControl
    result.add rootControl

    when defined(windows):
      # FIXME: ad hoc adjustment needed on Windows and need improvement
      result.width = (rootControl.naturalWidth.float * 1.1).int
      result.height = (rootControl.naturalHeight.float * 1.1).int
    else:
      result.width = rootControl.naturalWidth
      result.height = rootControl.naturalHeight

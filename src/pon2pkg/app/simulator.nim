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
    Play = "p"
    PlayEditor = "P"
    Edit = "e"
    View = "v"

  SimulatorState* {.pure.} = enum
    ## Simulator state.
    Stable
    WillDisappear
    WillDrop

  SimulatorEditing* = object ## Editing information.
    cell*: Cell
    field*: tuple[row: Row, column: Column]
    pair*: tuple[index: Natural, axis: bool]
    focusField*: bool
    insert*: bool

  Simulator* = object ## Puyo Puyo simulator.
    nazoPuyoWrap: NazoPuyoWrap
    moveResult: MoveResult

    state: SimulatorState
    kind: SimulatorKind
    mode: SimulatorMode

    undoDeque: Deque[NazoPuyoWrap]
    redoDeque: Deque[NazoPuyoWrap]
    moveDeque: Deque[
      tuple[nazoPuyoWrap: NazoPuyoWrap, state: SimulatorState, moveResult: MoveResult]
    ]

    operatingPos: Position
    editing: SimulatorEditing

using
  self: Simulator
  mSelf: var Simulator
  rSelf: ref Simulator

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const
  InitPos = Up2
  DefaultReq = Requirement(kind: Clear, color: RequirementColor.All, number: 0)
  DefaultMoveResult =
    initMoveResult(0, [0, 0, 0, 0, 0, 0, 0], newSeq[array[ColorPuyo, seq[int]]](0))

func initSimulator*(nazoPuyoWrap: NazoPuyoWrap, mode = Play): Simulator {.inline.} =
  ## Returns a new simulator.
  result.nazoPuyoWrap = nazoPuyoWrap
  result.moveResult = DefaultMoveResult

  result.state = Stable
  result.kind = Nazo
  result.mode = mode

  nazoPuyoWrap.get:
    result.undoDeque = initDeque[NazoPuyoWrap](wrappedNazoPuyo.moveCount)
    result.redoDeque = initDeque[NazoPuyoWrap](wrappedNazoPuyo.moveCount)
  result.moveDeque = initDeque[
    tuple[nazoPuyoWrap: NazoPuyoWrap, state: SimulatorState, moveResult: MoveResult]
  ]()

  result.operatingPos = InitPos
  result.editing.cell = Cell.None
  result.editing.field = (Row.low, Column.low)
  result.editing.pair = (Natural 0, true)
  result.editing.focusField = true
  result.editing.insert = false

func initSimulator*[F: TsuField or WaterField](
    nazo: NazoPuyo[F], mode = Play
): Simulator {.inline.} =
  ## Returns a new simulator.
  initNazoPuyoWrap(nazo).initSimulator mode

func initSimulator*[F: TsuField or WaterField](
    puyoPuyo: PuyoPuyo[F], mode = Play
): Simulator {.inline.} =
  ## Returns a new simulator.
  result = NazoPuyo[F](puyoPuyo: puyoPuyo, requirement: DefaultReq).initSimulator mode
  result.kind = Regular

# ------------------------------------------------
# Copy
# ------------------------------------------------

func copy*(self): Simulator {.inline.} =
  ## Copies the simulator.
  ## The function may work even when a normal assignment would raise an error.
  result.nazoPuyoWrap = self.nazoPuyoWrap
  result.moveResult = self.moveResult

  result.state = self.state
  result.kind = self.kind
  result.mode = self.mode

  result.undoDeque = initDeque[NazoPuyoWrap](self.undoDeque.len)
  result.redoDeque = initDeque[NazoPuyoWrap](self.redoDeque.len)
  result.moveDeque = initDeque[
    tuple[nazoPuyoWrap: NazoPuyoWrap, state: SimulatorState, moveResult: MoveResult]
  ](self.moveDeque.len)
  for data in self.undoDeque:
    result.undoDeque.addLast data
  for data in self.redoDeque:
    result.redoDeque.addLast data
  for data in self.moveDeque:
    result.moveDeque.addLast data

  result.operatingPos = self.operatingPos
  result.editing = self.editing

# ------------------------------------------------
# Property - Nazo Puyo / Pairs&Positions
# ------------------------------------------------

func nazoPuyoWrap*(self): NazoPuyoWrap {.inline.} =
  ## Returns the wrapped Nazo Puyo.
  self.nazoPuyoWrap

func nazoPuyoWrapBeforeMoves*(self): NazoPuyoWrap {.inline.} =
  ## Returns the wrapped Nazo Puyo before any moves.
  if self.moveDeque.len > 0:
    self.moveDeque.peekFirst.nazoPuyoWrap
  else:
    self.nazoPuyoWrap

func `pairsPositions=`*(mSelf; pairsPositions: PairsPositions) {.inline.} =
  mSelf.nazoPuyoWrap.get:
    wrappedNazoPuyo.puyoPuyo.pairsPositions = pairsPositions

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

# TODO
func `mode=`*(mSelf; mode: SimulatorMode) {.inline.} =
  if mode == mSelf.mode:
    return

  if mSelf.mode in {Play, View}:
    return

  mSelf.nazoPuyoWrap = mSelf.nazoPuyoWrapBeforeMoves
  mSelf.mode = mode
  mSelf.state = Stable
  mSelf.undoDeque.clear
  mSelf.redoDeque.clear
  mSelf.moveDeque.clear

# ------------------------------------------------
# Property - Editing
# ------------------------------------------------

func editing*(self): SimulatorEditing {.inline.} =
  ## Returns the editing information.
  self.editing

func `editingCell=`*(mSelf; cell: Cell) {.inline.} =
  mSelf.editing.cell = cell

# ------------------------------------------------
# Property - Other
# ------------------------------------------------

func state*(self): SimulatorState {.inline.} =
  ## Returns the simulator state.
  self.state

func score*(self): int {.inline.} = ## Returns the score.
  self.moveResult.score

func operatingPosition*(self): Position {.inline.} =
  ## Returns the operating position.
  self.operatingPos

# ------------------------------------------------
# Edit - Other
# ------------------------------------------------

func toggleInserting*(mSelf) {.inline.} = ## Toggles inserting or not.
  mSelf.editing.insert.toggle

func toggleFocus*(mSelf) {.inline.} = ## Toggles focusing field or not.
  mSelf.editing.focusField.toggle

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

func prepareChange(mSelf) {.inline.} =
  ## Prepares for changing the simulator.
  mSelf.undoDeque.addLast mSelf.nazoPuyoWrap
  mSelf.redoDeque.clear

func deletePairPosition*(mSelf; idx: Natural) {.inline.} =
  ## Deletes the pair&position.
  mSelf.nazoPuyoWrap.get:
    if idx >= wrappedNazoPuyo.puyoPuyo.pairsPositions.len:
      return

    mSelf.prepareChange
    wrappedNazoPuyo.puyoPuyo.pairsPositions.delete idx

func deletePairPosition*(mSelf) {.inline.} =
  ## Deletes the pair&position at selecting index.
  mSelf.deletePairPosition mSelf.editing.pair.index

# ------------------------------------------------
# Edit - Write
# ------------------------------------------------

func writeCell(mSelf; row: Row, col: Column, cell: Cell) {.inline.} =
  ## Writes the cell to the field.
  mSelf.prepareChange

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
    mSelf.prepareChange
    mSelf.deletePairPosition idx
  of Hard, Cell.Garbage:
    discard
  of Cell.Red .. Cell.Purple:
    mSelf.prepareChange

    let color = ColorPuyo cell
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
  mSelf.prepareChange
  mSelf.nazoPuyoWrap.get:
    wrappedNazoPuyo.puyoPuyo.field.shiftUp

func shiftFieldDown*(mSelf) {.inline.} =
  ## Shifts the field downward.
  mSelf.prepareChange
  mSelf.nazoPuyoWrap.get:
    wrappedNazoPuyo.puyoPuyo.field.shiftDown

func shiftFieldRight*(mSelf) {.inline.} =
  ## Shifts the field rightward.
  mSelf.prepareChange
  mSelf.nazoPuyoWrap.get:
    wrappedNazoPuyo.puyoPuyo.field.shiftRight

func shiftFieldLeft*(mSelf) {.inline.} =
  ## Shifts the field leftward.
  mSelf.prepareChange
  mSelf.nazoPuyoWrap.get:
    wrappedNazoPuyo.puyoPuyo.field.shiftLeft

# ------------------------------------------------
# Edit - Flip
# ------------------------------------------------

func flipFieldV*(mSelf) {.inline.} =
  ## Flips the field vertically.
  mSelf.prepareChange
  mSelf.nazoPuyoWrap.get:
    wrappedNazoPuyo.puyoPuyo.field.flipV

func flipFieldH*(mSelf) {.inline.} =
  ## Flips the field horizontally.
  mSelf.prepareChange
  mSelf.nazoPuyoWrap.get:
    wrappedNazoPuyo.puyoPuyo.field.flipH

func flip*(mSelf) {.inline.} =
  ## Flips the field or pairs.
  mSelf.nazoPuyoWrap.get:
    if mSelf.editing.focusField:
      wrappedNazoPuyo.puyoPuyo.field.flipH
    else:
      wrappedNazoPuyo.puyoPuyo.pairsPositions[mSelf.editing.pair.index].pair.swap

# ------------------------------------------------
# Edit - Requirement
# ------------------------------------------------

func `requirementKind=`*(mSelf; kind: RequirementKind) {.inline.} =
  ## Sets the requirement kind.
  mSelf.nazoPuyoWrap.get:
    if kind == wrappedNazoPuyo.requirement.kind:
      return

    mSelf.prepareChange

    {.cast(uncheckedAssign).}:
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

    mSelf.prepareChange
    wrappedNazoPuyo.requirement.color = color

func `requirementNumber=`*(mSelf; num: RequirementNumber) {.inline.} =
  ## Sets the requirement number.
  mSelf.nazoPuyoWrap.get:
    if wrappedNazoPuyo.requirement.kind in NoNumberKinds:
      return
    if num == wrappedNazoPuyo.requirement.number:
      return

    mSelf.prepareChange
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
  mSelf.operatingPos.moveRight

func moveOperatingPositionLeft*(mSelf) {.inline.} =
  ## Moves the operating position left.
  mSelf.operatingPos.moveLeft

func rotateOperatingPositionRight*(mSelf) {.inline.} =
  ## Rotates the operating position right.
  mSelf.operatingPos.rotateRight

func rotateOperatingPositionLeft*(mSelf) {.inline.} =
  ## Rotates the operating position left.
  mSelf.operatingPos.rotateLeft

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

      # set position
      if not replay:
        wrappedNazoPuyo.puyoPuyo.operatingPairPosition.position =
          if skip: Position.None else: mSelf.operatingPos

      # save to the deque
      mSelf.moveDeque.addLast (mSelf.nazoPuyoWrap, mSelf.state, mSelf.moveResult)

      # put
      wrappedNazoPuyo.puyoPuyo.field.put wrappedNazoPuyo.puyoPuyo.operatingPairPosition

      # check disappear
      if wrappedNazoPuyo.puyoPuyo.field.willDisappear:
        mSelf.state = WillDisappear
      else:
        mSelf.state = Stable
        mSelf.operatingPos = InitPos
        wrappedNazoPuyo.puyoPuyo.incrementOperatingIndex
    of WillDisappear:
      mSelf.moveDeque.addLast (mSelf.nazoPuyoWrap, mSelf.state, mSelf.moveResult)

      let disappearRes = wrappedNazoPuyo.puyoPuyo.field.disappear

      for puyo in Puyo.low .. Puyo.high:
        mSelf.moveResult.disappearCounts[puyo].inc disappearRes.puyoCount puyo
      mSelf.moveResult.fullDisappearCounts.add disappearRes.connectionCounts

      if wrappedNazoPuyo.puyoPuyo.field.willDrop:
        mSelf.state = WillDrop
      else:
        mSelf.state = Stable
        mSelf.operatingPos = InitPos
        wrappedNazoPuyo.puyoPuyo.incrementOperatingIndex
    of WillDrop:
      mSelf.moveDeque.addLast (mSelf.nazoPuyoWrap, mSelf.state, mSelf.moveResult)

      wrappedNazoPuyo.puyoPuyo.field.drop
      if wrappedNazoPuyo.puyoPuyo.field.willDisappear:
        mSelf.state = WillDisappear
      else:
        mSelf.state = Stable
        mSelf.operatingPos = InitPos
        wrappedNazoPuyo.puyoPuyo.incrementOperatingIndex

func backward*(mSelf; toStable = true) {.inline.} =
  ## Backwards the simulator.
  if mSelf.moveDeque.len == 0:
    return

  let pairsPositions = mSelf.nazoPuyoWrap.get:
    wrappedNazoPuyo.puyoPuyo.pairsPositions

  if toStable:
    while mSelf.moveDeque.peekLast.state != Stable:
      mSelf.moveDeque.popLast

  (mSelf.nazoPuyoWrap, mSelf.state, mSelf.moveResult) = mSelf.moveDeque.popLast
  mSelf.operatingPos = InitPos
  mSelf.nazoPuyoWrap.get:
    wrappedNazoPuyo.puyoPuyo.pairsPositions = pairsPositions

func reset*(mSelf) {.inline.} =
  ## Backwards the simulator to the initial state.
  if mSelf.moveDeque.len == 0:
    return

  let pairsPositions = mSelf.nazoPuyoWrap.get:
    wrappedNazoPuyo.puyoPuyo.pairsPositions

  mSelf.nazoPuyoWrap = mSelf.moveDeque.peekFirst.nazoPuyoWrap
  mSelf.nazoPuyoWrap.get:
    wrappedNazoPuyo.puyoPuyo.pairsPositions = pairsPositions

  mSelf.state = Stable
  mSelf.undoDeque.clear
  mSelf.redoDeque.clear
  mSelf.moveDeque.clear
  mSelf.operatingPos = InitPos
  mSelf.moveResult = DefaultMoveResult

# ------------------------------------------------
# Simulator <-> URI
# ------------------------------------------------

const
  KindKey = "kind"
  ModeKey = "mode"

  StrToKind = collect:
    for kind in SimulatorKind:
      {$kind: kind}
  StrToMode = collect:
    for mode in SimulatorMode:
      {$mode: mode}

func toUri*(self; withPositions: bool, host = Ik): Uri {.inline.} =
  ## Returns the URI converted from the simulator.
  ## Any moves are reset.
  ## `self.editor` is overridden with `editor`.
  result = initUri()
  result.scheme =
    case host
    of Ik, Ishikawa: "https"
    of Ips: "http"
  result.hostname = $host

  # path
  case host
  of Ik:
    result.path = "/pon2/"
  of Ishikawa, Ips:
    let modeChar =
      case self.kind
      of Regular:
        case self.mode
        of Play, PlayEditor: 's'
        of Edit: 'e'
        of View: 'v'
      of Nazo:
        'n'
    result.path = &"/simu/p{modeChar}.html"

  let
    mainQuery: string
    pairsPositions = self.nazoPuyoWrap.get:
      wrappedNazoPuyo.puyoPuyo.pairsPositions
  self.nazoPuyoWrapBeforeMoves.get:
    var nazo = wrappedNazoPuyo
    if withPositions:
      nazo.puyoPuyo.pairsPositions = pairsPositions
    else:
      for pairPos in nazo.puyoPuyo.pairsPositions.mitems:
        pairPos.position = Position.None

    mainQuery =
      case self.kind
      of Regular:
        nazo.puyoPuyo.toUriQuery host
      of Nazo:
        nazo.toUriQuery host

  case host
  of Ik:
    # editor, kind, mode
    let kindModeQuery = [(KindKey, $self.kind), (ModeKey, $self.mode)].encodeQuery
    result.query = &"{kindModeQuery}&{mainQuery}"
  of Ishikawa, Ips:
    result.query = mainQuery

func parseSimulator*(uri: Uri): Simulator {.inline.} =
  ## Returns the simulator converted from the URI.
  ## If the URI is invalid, `ValueError` is raised.
  result = initPuyoPuyo[TsuField]().initSimulator # HACK: dummy to suppress warning

  case uri.hostname
  of $Ik:
    if uri.path notin ["/pon2/", "/pon2", "/pon2/index.html"]:
      raise newException(ValueError, "Invalid simulator: " & $uri)

    var
      kindVal = "<invalid>"
      modeVal = "<invalid>"
      mainQueries = newSeq[(string, string)](0)
    assert kindVal notin StrToKind
    assert modeVal notin StrToMode

    for (key, val) in uri.query.decodeQuery:
      case key
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
        result = parsePuyoPuyo[TsuField](mainQuery, Ik).initSimulator mode
      except ValueError:
        try:
          result = parsePuyoPuyo[WaterField](mainQuery, Ik).initSimulator mode
        except ValueError:
          raise newException(ValueError, "Invalid simulator: " & $uri)
    of Nazo:
      try:
        result = parseNazoPuyo[TsuField](mainQuery, Ik).initSimulator mode
      except ValueError:
        try:
          result = parseNazoPuyo[WaterField](mainQuery, Ik).initSimulator mode
        except ValueError:
          raise newException(ValueError, "Invalid simulator: " & $uri)
  of $Ishikawa, $Ips:
    let
      kind: SimulatorKind
      mode: SimulatorMode
    case uri.path
    of "/simu/pe.html":
      kind = Regular
      mode = Edit
    of "/simu/ps.html":
      kind = Regular
      mode = Play
    of "/simu/pv.html":
      kind = Regular
      mode = View
    of "/simu/pn.html":
      kind = Nazo
      mode = Play
    else:
      # HACK: dummy to compile
      kind = SimulatorKind.low
      mode = SimulatorMode.low

      raise newException(ValueError, "Invalid simulator: " & $uri)

    let host = if uri.hostname == $Ishikawa: Ishikawa else: Ips

    case kind
    of Regular:
      result = parsePuyoPuyo[TsuField](uri.query, host).initSimulator mode
    of Nazo:
      result = parseNazoPuyo[TsuField](uri.query, host).initSimulator mode
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
  of Play, PlayEditor:
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
    elif event == initKeyEvent("KeyW", shift = true):
      mSelf.backward(toStable = false)
    elif event == initKeyEvent("KeyW", control = true):
      mSelf.reset
    elif event == initKeyEvent("Space"):
      mSelf.forward(skip = true)
    elif event == initKeyEvent("KeyS", shift = true):
      mSelf.forward(replay = true)
    else:
      result = false
  of Edit:
    # insert, focus
    if event == initKeyEvent("KeyI"):
      mSelf.toggleInserting
    elif event == initKeyEvent("Tab"):
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
      mSelf.flip
    # undo, redo
    elif event == initKeyEvent("KeyZ", control = true):
      mSelf.undo
    elif event == initKeyEvent("KeyY", control = true):
      mSelf.redo
    else:
      result = false
  of View:
    # forward / backward / reset
    if event == initKeyEvent("KeyW"):
      mSelf.backward
    elif event == initKeyEvent("KeyW", shift = true):
      mSelf.backward(toStable = false)
    elif event == initKeyEvent("KeyS"):
      mSelf.forward(replay = true)
    elif event == initKeyEvent("KeyW", control = true):
      mSelf.reset
    else:
      result = false

# ------------------------------------------------
# Backend-specific Implementation
# ------------------------------------------------

when defined(js):
  import karax/[karaxdsl, vdom]
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
  # JS - Node
  # ------------------------------------------------

  proc initSimulatorNode(rSelf; id: string): VNode {.inline.} =
    ## Returns the node without the external section.
    ## `id` is shared with other node-creating procedures and need to be unique.
    buildHtml(tdiv):
      tdiv(class = "block"):
        rSelf.initRequirementNode(id = id)
      tdiv(class = "block"):
        tdiv(class = "columns is-mobile is-variable is-1"):
          tdiv(class = "column is-narrow"):
            if rSelf.mode != Edit:
              tdiv(class = "block"):
                rSelf.initOperatingNode
            tdiv(class = "block"):
              rSelf.initFieldNode
            if rSelf.mode != Edit:
              tdiv(class = "block"):
                rSelf.initMessagesNode
            tdiv(class = "block"):
              rSelf.initSelectNode
            tdiv(class = "block"):
              rSelf.initShareNode id
          if rSelf.mode != Edit:
            tdiv(class = "column is-narrow"):
              tdiv(class = "block"):
                rSelf.initImmediatePairsNode
          tdiv(class = "column is-narrow"):
            tdiv(class = "block"):
              rSelf.initControllerNode
            if rSelf.mode == Edit:
              tdiv(class = "block"):
                rSelf.initPaletteNode
            tdiv(class = "block"):
              rSelf.initPairsNode

  proc initSimulatorNode*(rSelf; wrapSection = true, id = ""): VNode {.inline.} =
    ## Returns the simulator node.
    ## `id` is shared with other node-creating procedures and need to be unique.
    let node = rSelf.initSimulatorNode id

    if wrapSection:
      result = buildHtml(section(class = "section")):
        node
    else:
      result = node

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

  type SimulatorControl* = ref object of LayoutContainer
    ## Root control of the simulator.

  # ------------------------------------------------
  # Native - Control
  # ------------------------------------------------

  proc initSimulatorControl*(rSelf): SimulatorControl {.inline.} =
    ## Returns the simulator control.
    result = new SimulatorControl
    result.init
    result.layout = Layout_Vertical

    # row=0
    let reqControl = rSelf.initRequirementControl
    result.add reqControl

    # row=1
    let secondRow = newLayoutContainer Layout_Horizontal
    result.add secondRow

    # row=1, left
    let left = newLayoutContainer Layout_Vertical
    secondRow.add left

    let
      assets = initAssets()
      field = rSelf.initFieldControl assets
      messages = rSelf.initMessagesControl assets
    left.add rSelf.initOperatingControl assets
    left.add field
    left.add messages
    left.add rSelf.initSelectControl reqControl
    left.add rSelf.initShareControl

    # row=1, center
    secondRow.add rSelf.initImmediatePairsControl assets

    # row=1, right
    secondRow.add rSelf.initPairsControl assets

    # set size
    reqControl.setWidth secondRow.naturalWidth
    messages.setWidth field.naturalWidth

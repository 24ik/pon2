## This module implements Puyo Puyo simulators.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques, options, sequtils, strformat, strutils, sugar, tables, uri]
import ./[key, nazopuyo]
import
  ../core/[
    cell, field, fieldtype, fqdn, moveresult, nazopuyo, pair, pairposition, position,
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
    PlayEditor = "pe"
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

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const
  InitPos = Up2
  DefaultReq = initRequirement(Clear, All)
  DefaultMoveResult = initMoveResult(0, [0, 0, 0, 0, 0, 0, 0], @[], @[])

func initSimulator*(nazoPuyoWrap: NazoPuyoWrap, mode = Play): Simulator {.inline.} =
  ## Returns a new simulator.
  nazoPuyoWrap.get:
    {.push warning[Uninit]: off.}
    result = Simulator(
      nazoPuyoWrap: nazoPuyoWrap,
      moveResult: DefaultMoveResult,
      state: Stable,
      kind: Nazo,
      mode: mode,
      undoDeque: initDeque(wrappedNazoPuyo.moveCount),
      redoDeque: initDeque(wrappedNazoPuyo.moveCount),
      moveDeque: initDeque(),
      operatingPos: InitPos,
      editing: SimulatorEditing(
        cell: Cell.None,
        field: (Row.low, Column.low),
        pair: (0.Natural, true),
        focusField: true,
        insert: false,
      ),
    )
    {.pop.}

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

func copy*(self: Simulator): Simulator {.inline.} =
  ## Copies the simulator.
  {.push warning[Uninit]: off.}
  result = Simulator(
    nazoPuyoWrap: self.nazoPuyoWrap,
    moveResult: self.moveResult,
    state: self.state,
    kind: self.kind,
    mode: self.mode,
    undoDeque: self.undoDeque.toSeq.toDeque,
    redoDeque: self.redoDeque.toSeq.toDeque,
    moveDeque: self.moveDeque.toSeq.toDeque,
    operatingPos: self.operatingPos,
    editing: self.editing,
  )
  {.pop.}

# ------------------------------------------------
# Property - Nazo Puyo
# ------------------------------------------------

func nazoPuyoWrap*(self: Simulator): NazoPuyoWrap {.inline.} =
  ## Returns the wrapped Nazo Puyo.
  self.nazoPuyoWrap

func nazoPuyoWrap*(self: var Simulator): var NazoPuyoWrap {.inline.} =
  ## Returns the wrapped Nazo Puyo.
  self.nazoPuyoWrap

func nazoPuyoWrapBeforeMoves*(self: Simulator): NazoPuyoWrap {.inline.} =
  ## Returns the wrapped Nazo Puyo before any moves.
  if self.moveDeque.len > 0:
    self.moveDeque.peekFirst.nazoPuyoWrap
  else:
    self.nazoPuyoWrap

# ------------------------------------------------
# Property - Rule / Kind / Mode
# ------------------------------------------------

func rule*(self: Simulator): Rule {.inline.} =
  self.nazoPuyoWrap.rule

func kind*(self: Simulator): SimulatorKind {.inline.} =
  self.kind

func mode*(self: Simulator): SimulatorMode {.inline.} =
  self.mode

func `rule=`*(self: var Simulator, rule: Rule) {.inline.} =
  self.nazoPuyoWrap.rule = rule

func `kind=`*(self: var Simulator, kind: SimulatorKind) {.inline.} =
  self.kind = kind

func `mode=`*(self: var Simulator, mode: SimulatorMode) {.inline.} =
  if mode == self.mode:
    return

  self.nazoPuyoWrap = self.nazoPuyoWrapBeforeMoves
  self.mode = mode
  self.state = Stable
  self.undoDeque.clear
  self.redoDeque.clear
  self.moveDeque.clear

# ------------------------------------------------
# Property - Editing
# ------------------------------------------------

func editing*(self: Simulator): SimulatorEditing {.inline.} =
  ## Returns the editing information.
  self.editing

func `editingCell=`*(self: var Simulator, cell: Cell) {.inline.} =
  self.editing.cell = cell

# ------------------------------------------------
# Property - Other
# ------------------------------------------------

func state*(self: Simulator): SimulatorState {.inline.} =
  ## Returns the simulator state.
  self.state

func score*(self: Simulator): int {.inline.} = ## Returns the score.
  self.moveResult.score

func operatingPosition*(self: Simulator): Position {.inline.} =
  ## Returns the operating position.
  self.operatingPos

# ------------------------------------------------
# Edit - Other
# ------------------------------------------------

func toggleInserting*(self: var Simulator) {.inline.} = ## Toggles inserting or not.
  self.editing.insert.toggle

func toggleFocus*(self: var Simulator) {.inline.} = ## Toggles focusing field or not.
  self.editing.focusField.toggle

# ------------------------------------------------
# Edit - Cursor
# ------------------------------------------------

func moveCursorUp*(self: var Simulator) {.inline.} =
  ## Moves the cursor upward.
  if self.editing.focusField:
    self.editing.field.row.decRot
  else:
    if self.editing.pair.index == 0:
      let nazo = self.nazoPuyoWrap
      self.editing.pair.index = nazo.get:
        wrappedNazoPuyo.puyoPuyo.pairsPositions.len
    else:
      self.editing.pair.index.dec

func moveCursorDown*(self: var Simulator) {.inline.} =
  ## Moves the cursor downward.
  if self.editing.focusField:
    self.editing.field.row.incRot
  else:
    let nazo = self.nazoPuyoWrap
    let lastIdx = nazo.get:
      wrappedNazoPuyo.puyoPuyo.pairsPositions.len
    if self.editing.pair.index == lastIdx:
      self.editing.pair.index = 0
    else:
      self.editing.pair.index.inc

func moveCursorRight*(self: var Simulator) {.inline.} =
  ## Moves the cursor rightward.
  if self.editing.focusField:
    self.editing.field.column.incRot
  else:
    self.editing.pair.axis.toggle

func moveCursorLeft*(self: var Simulator) {.inline.} =
  ## Moves the cursor leftward.
  if self.editing.focusField:
    self.editing.field.column.decRot
  else:
    self.editing.pair.axis.toggle

# ------------------------------------------------
# Edit - Delete
# ------------------------------------------------

func prepareChange(self: var Simulator) {.inline.} =
  ## Prepares for changing the simulator.
  self.undoDeque.addLast self.nazoPuyoWrap
  self.redoDeque.clear

func deletePairPosition*(self: var Simulator, idx: Natural) {.inline.} =
  ## Deletes the pair&position.
  self.nazoPuyoWrap.get:
    wrappedNazoPuyo.puyoPuyo.pairsPositions.delete idx

func deletePairPosition*(self: var Simulator) {.inline.} =
  ## Deletes the pair&position at selecting index.
  self.deletePairPosition self.editing.pair.index

# ------------------------------------------------
# Edit - Write
# ------------------------------------------------

func writeCell(self: var Simulator, row: Row, col: Column, cell: Cell) {.inline.} =
  ## Writes the cell to the field.
  self.prepareChange

  self.nazoPuyoWrap.get:
    if self.editing.insert:
      if cell == Cell.None:
        wrappedNazoPuyo.puyoPuyo.field.removeSqueeze row, col
      else:
        wrappedNazoPuyo.puyoPuyo.field.insert row, col, cell
    else:
      wrappedNazoPuyo.puyoPuyo.field[row, col] = cell

func writeCell*(self: var Simulator, row: Row, col: Column) {.inline.} =
  ## Writes the selecting cell to the field.
  self.writeCell row, col, self.editing.cell

func writeCell(self: var Simulator, idx: Natural, axis: bool, cell: Cell) {.inline.} =
  ## Writes the cell to the pairs.
  case cell
  of Cell.None:
    self.prepareChange
    self.deletePairPosition idx
  of Hard, Cell.Garbage:
    discard
  of Cell.Red .. Cell.Purple:
    self.prepareChange

    let color = ColorPuyo cell
    self.nazoPuyoWrap.get:
      if idx == wrappedNazoPuyo.puyoPuyo.pairsPositions.len:
        wrappedNazoPuyo.puyoPuyo.pairsPositions.add PairPosition(
          pair: initPair(color, color), position: Position.None
        )
      else:
        if self.editing.insert:
          wrappedNazoPuyo.puyoPuyo.pairsPositions.insert PairPosition(
            pair: initPair(color, color), position: Position.None
          ), idx
        else:
          if axis:
            wrappedNazoPuyo.puyoPuyo.pairsPositions[idx].pair.axis = color
          else:
            wrappedNazoPuyo.puyoPuyo.pairsPositions[idx].pair.child = color

func writeCell*(self: var Simulator, idx: Natural, axis: bool) {.inline.} =
  ## Writes the selecting cell to the pairs.
  self.writeCell idx, axis, self.editing.cell

func writeCell*(self: var Simulator, cell: Cell) {.inline.} =
  ## Writes the cell to the field or pairs.
  if self.editing.focusField:
    self.writeCell self.editing.field.row, self.editing.field.column, cell
  else:
    self.writeCell self.editing.pair.index, self.editing.pair.axis, cell

# ------------------------------------------------
# Edit - Shift
# ------------------------------------------------

func shiftFieldUp*(self: var Simulator) {.inline.} =
  ## Shifts the field upward.
  self.prepareChange
  self.nazoPuyoWrap.get:
    wrappedNazoPuyo.puyoPuyo.field.shiftUp

func shiftFieldDown*(self: var Simulator) {.inline.} =
  ## Shifts the field downward.
  self.prepareChange
  self.nazoPuyoWrap.get:
    wrappedNazoPuyo.puyoPuyo.field.shiftDown

func shiftFieldRight*(self: var Simulator) {.inline.} =
  ## Shifts the field rightward.
  self.prepareChange
  self.nazoPuyoWrap.get:
    wrappedNazoPuyo.puyoPuyo.field.shiftRight

func shiftFieldLeft*(self: var Simulator) {.inline.} =
  ## Shifts the field leftward.
  self.prepareChange
  self.nazoPuyoWrap.get:
    wrappedNazoPuyo.puyoPuyo.field.shiftLeft

# ------------------------------------------------
# Edit - Flip
# ------------------------------------------------

func flipFieldV*(self: var Simulator) {.inline.} =
  ## Flips the field vertically.
  self.prepareChange
  self.nazoPuyoWrap.get:
    wrappedNazoPuyo.puyoPuyo.field.flipV

func flipFieldH*(self: var Simulator) {.inline.} =
  ## Flips the field horizontally.
  self.prepareChange
  self.nazoPuyoWrap.get:
    wrappedNazoPuyo.puyoPuyo.field.flipH

func flip*(self: var Simulator) {.inline.} =
  ## Flips the field or pairs.
  self.nazoPuyoWrap.get:
    if self.editing.focusField:
      wrappedNazoPuyo.puyoPuyo.field.flipH
    else:
      wrappedNazoPuyo.puyoPuyo.pairsPositions[self.editing.pair.index].pair.swap

# ------------------------------------------------
# Edit - Requirement
# ------------------------------------------------

func `requirementKind=`*(self: var Simulator, kind: RequirementKind) {.inline.} =
  ## Sets the requirement kind.
  self.nazoPuyoWrap.get:
    if kind == wrappedNazoPuyo.requirement.kind:
      return

    self.prepareChange
    wrappedNazoPuyo.requirement.kind = kind

func `requirementColor=`*(self: var Simulator, color: RequirementColor) {.inline.} =
  ## Sets the requirement color.
  self.nazoPuyoWrap.get:
    if wrappedNazoPuyo.requirement.kind in NoColorKinds:
      return
    if color == wrappedNazoPuyo.requirement.color:
      return

    self.prepareChange
    wrappedNazoPuyo.requirement.color = color

func `requirementNumber=`*(self: var Simulator, num: RequirementNumber) {.inline.} =
  ## Sets the requirement number.
  self.nazoPuyoWrap.get:
    if wrappedNazoPuyo.requirement.kind in NoNumberKinds:
      return
    if num == wrappedNazoPuyo.requirement.number:
      return

    self.prepareChange
    wrappedNazoPuyo.requirement.number = num

# ------------------------------------------------
# Edit - Undo / Redo
# ------------------------------------------------

func undo*(self: var Simulator) {.inline.} =
  ## Performs undo.
  if self.undoDeque.len == 0:
    return

  self.redoDeque.addLast self.nazoPuyoWrap
  self.nazoPuyoWrap = self.undoDeque.popLast

func redo*(self: var Simulator) {.inline.} =
  ## Performs redo.
  if self.redoDeque.len == 0:
    return

  self.undoDeque.addLast self.nazoPuyoWrap
  self.nazoPuyoWrap = self.redoDeque.popLast

# ------------------------------------------------
# Play - Position
# ------------------------------------------------

func moveOperatingPositionRight*(self: var Simulator) {.inline.} =
  ## Moves the operating position right.
  self.operatingPos.moveRight

func moveOperatingPositionLeft*(self: var Simulator) {.inline.} =
  ## Moves the operating position left.
  self.operatingPos.moveLeft

func rotateOperatingPositionRight*(self: var Simulator) {.inline.} =
  ## Rotates the operating position right.
  self.operatingPos.rotateRight

func rotateOperatingPositionLeft*(self: var Simulator) {.inline.} =
  ## Rotates the operating position left.
  self.operatingPos.rotateLeft

# ------------------------------------------------
# Forward / Backward
# ------------------------------------------------

func forward*(self: var Simulator, replay = false, skip = false) {.inline.} =
  ## Forwards the simulator.
  ## `replay` is prioritized over `skip`.
  self.nazoPuyoWrap.get:
    case self.state
    of Stable:
      if wrappedNazoPuyo.puyoPuyo.movingCompleted:
        return

      self.moveResult = DefaultMoveResult

      # set position
      if not replay:
        wrappedNazoPuyo.puyoPuyo.operatingPairPosition.position =
          if skip: Position.None else: self.operatingPos

      # save to the deque
      self.moveDeque.addLast (self.nazoPuyoWrap, self.state, self.moveResult)

      # put
      wrappedNazoPuyo.puyoPuyo.field.put wrappedNazoPuyo.puyoPuyo.operatingPairPosition

      # check disappear
      if wrappedNazoPuyo.puyoPuyo.field.willDisappear:
        self.state = WillDisappear
      else:
        self.state = Stable
        self.operatingPos = InitPos
        wrappedNazoPuyo.puyoPuyo.incrementOperatingIndex
    of WillDisappear:
      self.moveDeque.addLast (self.nazoPuyoWrap, self.state, self.moveResult)

      let disappearRes = wrappedNazoPuyo.puyoPuyo.field.disappear

      var counts: array[Puyo, int]
      counts[Puyo.low] = int.low # HACK: dummy to suppress warning
      for puyo in Puyo.low .. Puyo.high:
        let count = disappearRes.puyoCount puyo
        counts[puyo] = count
        self.moveResult.disappearCounts[puyo].inc count
      self.moveResult.detailDisappearCounts.get.add counts
      self.moveResult.fullDisappearCounts.get.add disappearRes.connectionCounts

      if wrappedNazoPuyo.puyoPuyo.field.willDrop:
        self.state = WillDrop
      else:
        self.state = Stable
        self.operatingPos = InitPos
        wrappedNazoPuyo.puyoPuyo.incrementOperatingIndex
    of WillDrop:
      self.moveDeque.addLast (self.nazoPuyoWrap, self.state, self.moveResult)

      wrappedNazoPuyo.puyoPuyo.field.drop
      if wrappedNazoPuyo.puyoPuyo.field.willDisappear:
        self.state = WillDisappear
      else:
        self.state = Stable
        self.operatingPos = InitPos
        wrappedNazoPuyo.puyoPuyo.incrementOperatingIndex

func backward*(self: var Simulator, toStable = true) {.inline.} =
  ## Backwards the simulator.
  if self.moveDeque.len == 0:
    return

  let pairsPositions = self.nazoPuyoWrap.get:
    wrappedNazoPuyo.puyoPuyo.pairsPositions

  if toStable:
    while self.moveDeque.peekLast.state != Stable:
      self.moveDeque.popLast

  (self.nazoPuyoWrap, self.state, self.moveResult) = self.moveDeque.popLast
  self.operatingPos = InitPos
  self.nazoPuyoWrap.get:
    wrappedNazoPuyo.puyoPuyo.pairsPositions = pairsPositions

func reset*(self: var Simulator) {.inline.} =
  ## Backwards the simulator to the initial state.
  if self.moveDeque.len == 0:
    return

  let pairsPositions = self.nazoPuyoWrap.get:
    wrappedNazoPuyo.puyoPuyo.pairsPositions

  self.nazoPuyoWrap = self.moveDeque.peekFirst.nazoPuyoWrap
  self.nazoPuyoWrap.get:
    wrappedNazoPuyo.puyoPuyo.pairsPositions = pairsPositions

  self.state = Stable
  self.undoDeque.clear
  self.redoDeque.clear
  self.moveDeque.clear
  self.operatingPos = InitPos
  self.moveResult = DefaultMoveResult

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

func toUriQuery*(
    self: Simulator, withPositions = true, fqdn = Pon2
): string {.inline.} =
  ## Returns the URI query converted from the simulator.
  ## Any moves are reset.

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
        nazo.puyoPuyo.toUriQuery fqdn
      of Nazo:
        nazo.toUriQuery fqdn

  case fqdn
  of Pon2:
    # kind, mode
    let kindModeQuery = [(KindKey, $self.kind), (ModeKey, $self.mode)].encodeQuery
    result = &"{kindModeQuery}&{mainQuery}"
  of Ishikawa, Ips:
    result = mainQuery

func parseSimulator*(query: string, fqdn: IdeFqdn): Simulator {.inline.} =
  ## Returns the simulator converted from the URI query.
  ## If the URI is invalid, `ValueError` is raised.
  ## If the FQDN is not `Pon2`, the kind is set to `Regular`, and the mode is
  ## set to `Play`.
  result = initPuyoPuyo[TsuField]().initSimulator # HACK: dummy to suppress warning

  case fqdn
  of Pon2:
    var
      kindVal = "<invalid>"
      modeVal = "<invalid>"
      mainQueries = newSeq[(string, string)](0)
    assert kindVal notin StrToKind
    assert modeVal notin StrToMode

    for (key, val) in query.decodeQuery:
      case key
      of KindKey:
        kindVal = val
      of ModeKey:
        modeVal = val
      else:
        mainQueries.add (key, val)

    if kindVal notin StrToKind or modeVal notin StrToMode:
      raise newException(ValueError, "Invalid simulator: " & query)

    let
      kind = StrToKind[kindVal]
      mode = StrToMode[modeVal]
      mainQuery = mainQueries.encodeQuery

    case kind
    of Regular:
      try:
        result = parsePuyoPuyo[TsuField](mainQuery, Pon2).initSimulator mode
      except ValueError:
        try:
          result = parsePuyoPuyo[WaterField](mainQuery, Pon2).initSimulator mode
        except ValueError:
          raise newException(ValueError, "Invalid simulator: " & query)
    of Nazo:
      try:
        result = parseNazoPuyo[TsuField](mainQuery, Pon2).initSimulator mode
      except ValueError:
        try:
          result = parseNazoPuyo[WaterField](mainQuery, Pon2).initSimulator mode
        except ValueError:
          raise newException(ValueError, "Invalid simulator: " & query)
  of Ishikawa, Ips:
    result = parsePuyoPuyo[TsuField](query, fqdn).initSimulator Play

# ------------------------------------------------
# Keyboard Operation
# ------------------------------------------------

func operate*(self: var Simulator, event: KeyEvent): bool {.discardable.} =
  ## Does operation specified by the keyboard input.
  ## Returns `true` if any action is executed.
  result = true

  case self.mode
  of Play, PlayEditor:
    # mode
    if event == initKeyEvent("KeyM") and self.mode == PlayEditor:
      self.mode = Edit
    # rotate position
    elif event == initKeyEvent("KeyJ"):
      self.rotateOperatingPositionLeft
    elif event == initKeyEvent("KeyK"):
      self.rotateOperatingPositionRight
    # move position
    elif event == initKeyEvent("KeyA"):
      self.moveOperatingPositionLeft
    elif event == initKeyEvent("KeyD"):
      self.moveOperatingPositionRight
    # forward / backward / reset
    elif event == initKeyEvent("KeyS"):
      self.forward
    elif event in [initKeyEvent("Digit2"), initKeyEvent("KeyW")]:
      self.backward
    elif event in
        [initKeyEvent("Digit2", shift = true), initKeyEvent("KeyW", shift = true)]:
      self.backward(toStable = false)
    elif event == initKeyEvent("Digit1"):
      self.reset
    elif event == initKeyEvent("Space"):
      self.forward(skip = true)
    elif event == initKeyEvent("Digit3"):
      self.forward(replay = true)
    else:
      result = false
  of Edit:
    # mode
    if event == initKeyEvent("KeyM"):
      self.mode = PlayEditor
    # insert, focus
    elif event == initKeyEvent("KeyI"):
      self.toggleInserting
    elif event == initKeyEvent("Tab"):
      self.toggleFocus
    # move cursor
    elif event == initKeyEvent("KeyA"):
      self.moveCursorLeft
    elif event == initKeyEvent("KeyD"):
      self.moveCursorRight
    elif event == initKeyEvent("KeyS"):
      self.moveCursorDown
    elif event == initKeyEvent("KeyW"):
      self.moveCursorUp
    # write cell
    elif event == initKeyEvent("KeyH"):
      self.writeCell Cell.Red
    elif event == initKeyEvent("KeyJ"):
      self.writeCell Cell.Green
    elif event == initKeyEvent("KeyK"):
      self.writeCell Cell.Blue
    elif event == initKeyEvent("KeyL"):
      self.writeCell Cell.Yellow
    elif event == initKeyEvent("Semicolon"):
      self.writeCell Cell.Purple
    elif event == initKeyEvent("KeyO"):
      self.writeCell Cell.Garbage
    elif event == initKeyEvent("Space"):
      self.writeCell Cell.None
    # shift field
    elif event == initKeyEvent("KeyA", shift = true):
      self.shiftFieldLeft
    elif event == initKeyEvent("KeyD", shift = true):
      self.shiftFieldRight
    elif event == initKeyEvent("KeyS", shift = true):
      self.shiftFieldDown
    elif event == initKeyEvent("KeyW", shift = true):
      self.shiftFieldUp
    # flip field
    elif event == initKeyEvent("KeyF"):
      self.flip
    # undo, redo
    elif event == initKeyEvent("KeyZ", control = true):
      self.undo
    elif event == initKeyEvent("KeyY", control = true):
      self.redo
    else:
      result = false
  of View:
    # forward / backward / reset
    if event in [initKeyEvent("Digit2"), initKeyEvent("KeyW")]:
      self.backward
    elif event in
        [initKeyEvent("Digit2", shift = true), initKeyEvent("KeyW", shift = true)]:
      self.backward(toStable = false)
    elif event in [initKeyEvent("Digit3"), initKeyEvent("KeyS")]:
      self.forward(replay = true)
    elif event == initKeyEvent("Digit1"):
      self.reset
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
    ]

  # ------------------------------------------------
  # JS - Node
  # ------------------------------------------------

  const ReqIdPrefix = "pon2-simulator-req-"

  proc newSimulatorNode(self: ref Simulator, id: string): VNode {.inline.} =
    ## Returns the node without the external section.
    buildHtml(tdiv):
      tdiv(class = "block"):
        self.newRequirementNode(id = &"{ReqIdPrefix}{id}")
      tdiv(class = "block"):
        tdiv(class = "columns is-mobile is-variable is-1"):
          tdiv(class = "column is-narrow"):
            if self.mode != Edit:
              tdiv(class = "block"):
                self.newOperatingNode
            tdiv(class = "block"):
              self.newFieldNode
            if self.mode != Edit:
              tdiv(class = "block"):
                self.newMessagesNode
            if self.mode in {PlayEditor, Edit}:
              tdiv(class = "block"):
                self.newSelectNode
          if self.mode != Edit:
            tdiv(class = "column is-narrow"):
              tdiv(class = "block"):
                self.newImmediatePairsNode
          tdiv(class = "column is-narrow"):
            tdiv(class = "block"):
              self.newControllerNode
            if self.mode == Edit:
              tdiv(class = "block"):
                self.newPaletteNode
            tdiv(class = "block"):
              self.newPairsNode

  proc newSimulatorNode*(
      self: ref Simulator, wrapSection = true, id = ""
  ): VNode {.inline.} =
    ## Returns the simulator node.
    let node = self.newSimulatorNode id

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
    ]

  type SimulatorControl* = ref object of LayoutContainer
    ## Root control of the simulator.

  # ------------------------------------------------
  # Native - Control
  # ------------------------------------------------

  proc newSimulatorControl*(self: ref Simulator): SimulatorControl {.inline.} =
    ## Returns the simulator control.
    {.push warning[ProveInit]: off.}
    result.new
    {.pop.}
    result.init
    result.layout = Layout_Vertical

    # row=0
    let reqControl = self.newRequirementControl
    result.add reqControl

    # row=1
    let secondRow = newLayoutContainer Layout_Horizontal
    result.add secondRow

    # row=1, left
    let left = newLayoutContainer Layout_Vertical
    secondRow.add left

    let
      assets = newAssets()
      field = self.newFieldControl assets
      messages = self.newMessagesControl assets
    left.add self.newOperatingControl assets
    left.add field
    left.add messages
    left.add self.newSelectControl reqControl

    # row=1, center
    secondRow.add self.newImmediatePairsControl assets

    # row=1, right
    secondRow.add self.newPairsControl assets

    # set size
    reqControl.setWidth secondRow.naturalWidth
    messages.setWidth field.naturalWidth

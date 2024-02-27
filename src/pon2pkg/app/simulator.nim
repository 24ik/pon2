## This module implements Puyo Puyo simulators.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques, options, sequtils, strformat, sugar, tables, uri]
import ./[key, misc, nazopuyo]
import
  ../core/[
    cell, field, fieldtype, host, misc, moveresult, nazopuyo, pair, position, puyopuyo,
    requirement, rule
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

  Simulator* = object
    ## Puyo Puyo simulator.
    ## Note that `editor` field does not affect the behaviour; it is used only
    ## by rendering.
    nazoPuyoWrap*: NazoPuyoWrap
    originalNazoPuyoWrap*: NazoPuyoWrap
    moveResult: MoveResult

    editor*: bool
    state*: SimulatorState
    kind: SimulatorKind
    mode: SimulatorMode

    undoDeque: Deque[NazoPuyoWrap]
    redoDeque: Deque[NazoPuyoWrap]

    next*: tuple[index: Natural, position: Position]
    editing*:
      tuple[
        cell: Cell,
        field: tuple[row: Row, column: Column],
        pair: tuple[index: Natural, axis: bool],
        focusField: bool,
        insert: bool
      ]

using
  self: Simulator
  mSelf: var Simulator

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const
  InitPos = Up2
  DefaultReq = Requirement(kind: Clear, color: RequirementColor.All, number: 0)

func initSimulator*(
    nazoPuyoWrap: NazoPuyoWrap, mode = Play, editor = false
): Simulator {.inline.} =
  ## Returns a new simulator.
  ## If `mode` is `Edit`, `editor` will be ignored (*i.e.*, regarded as `true`).
  result.nazoPuyoWrap = nazoPuyoWrap
  result.originalNazoPuyoWrap = nazoPuyoWrap
  result.moveResult = initMoveResult(0, [0, 0, 0, 0, 0, 0, 0], @[], @[])

  result.editor = editor or mode == Edit
  result.state = Stable
  result.kind = Nazo
  result.mode = mode

  result.undoDeque = initDeque[NazoPuyoWrap](nazo.moveCount)
  result.redoDeque = initDeque[NazoPuyoWrap](nazo.moveCount)

  result.next.index = Natural 0
  result.next.position = InitPos
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
    mSelf.nazoPuyoWrap = mSelf.originalNazoPuyoWrap
    mSelf.state = Stable
    mSelf.undoDeque.clear
    mSelf.redoDeque.clear

  mSelf.mode = mode

# ------------------------------------------------
# Property - Score
# ------------------------------------------------

func score*(self): int {.inline.} = ## Returns the score.
  self.moveResult.score

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
  mSelf.originalNazoPuyoWrap = mSelf.nazoPuyoWrap

# ------------------------------------------------
# Edit - Cursor
# ------------------------------------------------

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

func deletePairPosition*(mSelf; idx: Natural) {.inline.} =
  ## Deletes the pair&position.
  if idx >= mSelf.pairsPositions.len:
    return

  mSelf.change:
    mSelf.pairsPositions.delete idx

func deletePairPosition*(mSelf) {.inline.} =
  ## Deletes the pair&position at selecting index.
  mSelf.deletePairPosition mSelf.editing.pair.index

# ------------------------------------------------
# Edit - Write
# ------------------------------------------------

func writeCell(mSelf; row: Row, col: Column, cell: Cell) {.inline.} =
  ## Writes the cell to the field.
  mSelf.change:
    if mSelf.editing.insert:
      if cell == Cell.None:
        case mSelf.rule
        of Tsu:
          mSelf.nazoPuyoWrap.tsu.field.removeSqueeze row, col
        of Water:
          mSelf.nazoPuyoWrap.water.field.removeSqueeze row, col
      else:
        case mSelf.rule
        of Tsu:
          mSelf.nazoPuyoWrap.tsu.field.insert row, col, cell
        of Water:
          mSelf.nazoPuyoWrap.water.field.insert row, col, cell
    else:
      case mSelf.rule
      of Tsu:
        mSelf.nazoPuyoWrap.tsu.field[row, col] = cell
      of Water:
        mSelf.nazoPuyoWrap.water.field[row, col] = cell

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
      if idx == mSelf.nazoPuyoWrap.pairsPositions.len:
        mSelf.nazoPuyoWrap.pairsPositions.add PairPosition(
          pair: initPair(color, color), position: Position.None
        )
      else:
        if mSelf.editing.insert:
          mSelf.nazoPuyoWrap.pairsPositions.insert PairPosition(
            pair: initPair(color, color), position: Position.None
          ), idx
        else:
          if axis:
            mSelf.nazoPuyoWrap.pairsPositions[idx].pair.axis = color
          else:
            mSelf.nazoPuyoWrap.pairsPositions[idx].pair.child = color

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
    of Tsu: mSelf.nazoPuyoWrap.tsu.field.shiftUp
    of Water: mSelf.nazoPuyoWrap.water.field.shiftUp

func shiftFieldDown*(mSelf) {.inline.} =
  ## Shifts the field downward.
  mSelf.change:
    case mSelf.rule
    of Tsu: mSelf.nazoPuyoWrap.tsu.field.shiftDown
    of Water: mSelf.nazoPuyoWrap.water.field.shiftDown

func shiftFieldRight*(mSelf) {.inline.} =
  ## Shifts the field rightward.
  mSelf.change:
    case mSelf.rule
    of Tsu: mSelf.nazoPuyoWrap.tsu.field.shiftRight
    of Water: mSelf.nazoPuyoWrap.water.field.shiftRight

func shiftFieldLeft*(mSelf) {.inline.} =
  ## Shifts the field leftward.
  mSelf.change:
    case mSelf.rule
    of Tsu: mSelf.nazoPuyoWrap.tsu.field.shiftLeft
    of Water: mSelf.nazoPuyoWrap.water.field.shiftLeft

# ------------------------------------------------
# Edit - Flip
# ------------------------------------------------

func flipFieldV*(mSelf) {.inline.} =
  ## Flips the field vertically.
  mSelf.change:
    case mSelf.rule
    of Tsu: mSelf.nazoPuyoWrap.tsu.field.flipV
    of Water: mSelf.nazoPuyoWrap.water.field.flipV

func flipFieldH*(mSelf) {.inline.} =
  ## Flips the field horizontally.
  mSelf.change:
    case mSelf.rule
    of Tsu: mSelf.nazoPuyoWrap.tsu.field.flipH
    of Water: mSelf.nazoPuyoWrap.water.field.flipH

# ------------------------------------------------
# Edit - Requirement
# ------------------------------------------------

func `requirementKind=`*(mSelf; kind: RequirementKind) {.inline.} =
  ## Sets the requirement kind.
  if kind == mSelf.nazoPuyoWrap.requirement:
    return

  mSelf.change:
    if kind in ColorKinds:
      if mSelf.nazoPuyoWrap.requirement.kind in ColorKinds:
        mSelf.requirement = Requirement(
          kind: kind, color: mSelf.requirement.color, number: mSelf.requirement.number
        )
      else:
        mSelf.requirement = Requirement(
          kind: kind, color: RequirementColor.low, number: mSelf.requirement.number
        )
    else:
      mSelf.requirement = Requirement(kind: kind, number: mSelf.requirement.number)

func `requirementColor=`*(mSelf; color: RequirementColor) {.inline.} =
  ## Sets the requirement color.
  if mSelf.nazoPuyoWrap.requirement.kind in NoColorKinds:
    return
  if color == mSelf.nazoPuyoWrap.requirement.color:
    return

  mSelf.change:
    mSelf.nazoPuyoWrap.requirement.color = color

func `requirementNumber=`*(mSelf; num: RequirementNumber) {.inline.} =
  ## Sets the requirement number.
  if mSelf.requirement.kind in NoNumberKinds:
    return
  if num == mSelf.nazoPuyoWrap.requirement.number:
    return

  mSelf.change:
    mSelf.nazoPuyoWrap.requirement.number = num

# ------------------------------------------------
# Edit - Undo / Redo
# ------------------------------------------------

func undo*(mSelf) {.inline.} =
  ## Performs undo.
  if mSelf.undoDeque.len == 0:
    return

  mSelf.redoDeque.addLast mSelf.nazoPuyoWrap
  mSelf.nazoPuyoWrap = mSelf.undoDeque.popLast

  mSelf.originalNazoPuyoWrap = mSelf.nazoPuyoWrap

func redo*(mSelf) {.inline.} =
  ## Performs redo.
  if mSelf.redoDeque.len == 0:
    return

  mSelf.undoDeque.addLast mSelf.nazoPuyoWrap
  mSelf.nazoPuyoWrap = mSelf.redoDeque.popLast

  mSelf.originalNazoPuyoWrap = mSelf.nazoPuyoWrap

# ------------------------------------------------
# Play - Position
# ------------------------------------------------

func moveNextPositionRight*(mSelf) {.inline.} = ## Moves the next position right.
  mSelf.next.position.moveRight

func moveNextPositionLeft*(mSelf) {.inline.} = ## Moves the next position left.
  mSelf.next.position.moveLeft

func rotateNextPositionRight*(mSelf) {.inline.} =
  ## Rotates the next position right.
  mSelf.next.position.rotateRight

func rotateNextPositionLeft*(mSelf) {.inline.} = ## Rotates the next position left.
  mSelf.next.position.rotateLeft

# ------------------------------------------------
# Forward / Backward
# ------------------------------------------------

func forward*(mSelf; replay = false, skip = false) {.inline.} =
  ## Forwards the simulator.
  ## `replay` is prioritized over `skip`.
  case mSelf.state
  of Stable:
    if mSelf.nazoPuyoWrap.pairsPositions.len == 0:
      return

    mSelf.moveResult = initMoveResult(0, [0, 0, 0, 0, 0, 0, 0], @[], @[])
    mSelf.save

    if not replay:
      mSelf.nazoPuyoWrap.pairsPositions[mSelf.next.index].position =
        if skip: Position.None else: mSelf.next.position

    # put
    block:
      let
        pairPos = mSelf.nazoPuyoWrap.pairsPositions[mSelf.next.index]
        pair = pairPos.pair
        pos = pairPos.position

      case mSelf.nazoPuyoWrap.rule
      of Tsu:
        mSelf.nazoPuyoWrap.tsu.field.put pair, pos
      of Water:
        mSelf.nazoPuyoWrap.water.field.put pair, pos

    # disappear
    block:
      let willDisappear2 =
        case mSelf.rule
        of Tsu: mSelf.nazoPuyoWrap.tsu.field.willDisappear
        of Water: mSelf.nazoPuyoWrap.water.field.willDisappear

      if willDisappear2:
        mSelf.state = WillDisappear
      else:
        mSelf.state = Stable
        mSelf.next.index.inc
        mSelf.next.position = InitPos
  of WillDisappear:
    let disappearRes =
      case mSelf.rule
      of Tsu: mSelf.nazoPuyoWrap.tsu.field.disappear
      of Water: mSelf.nazoPuyoWrap.water.field.disappear

    var counts: array[Puyo, int] = [0, 0, 0, 0, 0, 0, 0]
    for puyo in Puyo.low .. Puyo.high:
      let count = disappearRes.puyoCount puyo
      counts[puyo] = count
      mSelf.moveResult.totalDisappearCounts.get[puyo].inc count
    mSelf.moveResult.disappearCounts.get.add counts
    mSelf.moveResult.detailDisappearCounts.get.add disappearRes.connectionCounts

    mSelf.state = Disappearing
  of Disappearing:
    let willDisappear2 =
      case mSelf.rule
      of Tsu:
        mSelf.nazoPuyoWrap.tsu.field.drop
        mSelf.nazoPuyoWrap.tsu.field.willDisappear
      of Water:
        mSelf.nazoPuyoWrap.water.field.drop
        mSelf.nazoPuyoWrap.water.field.willDisappear

    if willDisappear2:
      mSelf.state = WillDisappear
    else:
      mSelf.state = Stable
      mSelf.next.index.inc
      mSelf.next.position = InitPos

func backward*(mSelf) {.inline.} =
  ## Backwards the simulator.
  if mSelf.undoDeque.len == 0:
    return

  mSelf.moveResult = initMoveResult(0, [0, 0, 0, 0, 0, 0, 0], @[], @[])

  if mSelf.state == Stable:
    mSelf.next.index.dec

  mSelf.nazoPuyoWrap = mSelf.undoDeque.popLast
  mSelf.state = Stable
  mSelf.next.position = InitPos

func reset*(mSelf; resetPosition = true) {.inline.} =
  ## Resets the simulator.
  mSelf.state = Stable
  mSelf.nazoPuyoWrap = mSelf.originalNazoPuyoWrap
  mSelf.undoDeque.clear
  mSelf.redoDeque.clear
  mSelf.next.index = 0
  mSelf.next.position = InitPos
  mSelf.moveResult = initMoveResult(0, [0, 0, 0, 0, 0, 0, 0], @[], @[])

  if resetPosition:
    for pairPos in mSelf.nazoPuyoWrap.pairsPositions.mitems:
      pairPos.position = Position.None

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

func toUri*(self; withPositions: bool, editor: bool): Uri {.inline.} =
  ## Returns the URI converted from the simulator.
  ## `self.editor` will be overridden with `editor`.
  result = initUri()
  result.hostname = $Izumiya
  result.path = "/pon2/app/index.html"

  self.originalNazoPuyoWrap.flattenAnd:
    var nazo = nazoPuyo
    if not withPositions:
      for pairPos in nazo.puyoPuyo.pairsPositions.mitems:
        pairPos.position = Position.None

    # editor, kind, mode
    var queries = newSeq[(string, string)](0)
    if self.editor:
      queries.add (EditorKey, "")
    queries.add (KindKey, $self.kind)
    queries.add (ModeKey, $self.mode)

    # nazopuyo / puyopuyo
    let mainQuery =
      case self.kind
      of Regular:
        nazo.puyoPuyo.toUriQuery Izumiya
      of Nazo:
        nazo.toUriQuery Izumiya

    result.query = &"{queries.encodeQuery}&{mainQuery}"

func toUri*(self; withPositions: bool): Uri {.inline.} =
  ## Returns the URI converted from the simulator.
  self.toUri(withPositions, self.editor)

func parseSimulator*(uri: Uri) {.inline.} =
  ## Returns the simulator converted from the URI.
  ## If the URI is invalid, `ValueError` is raised.
  var
    editor = false
    kindVal = "<invalid>"
    modeVal = "<invalid>"
    simulatorQueries = initTable[string, string]()
    mainQueries = newSeq[(string, string)](0)
  assert kindVal notin StrToKind
  assert modeVal notin StrToMode

  for (key, val) in uri.decodeQuery:
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

  case kind
  of Regular:
    try:
      result = parsePuyoPuyo[TsuField](mainQuery, Izumiya).initSimulator(mode, editor)
    except ValueError:
      result = parsePuyoPuyo[WaterField](mainQuery, Izumiya).initSimulator(mode, editor)
  of Nazo:
    try:
      result = parseNazoPuyo[TsuField](mainQuery, Izumiya).initSimulator(mode, editor)
    except ValueError:
      result = parseNazoPuyo[WaterField](mainQuery, Izumiya).initSimulator(mode, editor)

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
  import std/[sugar]
  import karax/[karax, karaxdsl, kdom, vdom]
  import
    ../private/app/simulator/web/[
      controller,
      field,
      immediatepairs,
      messages,
      nextpair,
      pairs as pairsModule,
      palette,
      requirement,
      select,
      share
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
  import std/[sugar]
  import nigui
  import
    ../private/app/simulator/native/[
      assets,
      field,
      immediatepairs,
      messages,
      nextpair,
      pairs as pairsModule,
      requirement,
      select,
      share
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

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques, importutils, options, sequtils, strformat, unittest, uri]
import ../../src/pon2/app/[nazopuyo, simulator]
import
  ../../src/pon2/core/[
    cell, field, fieldtype, fqdn, moveresult, nazopuyo, pair, pairposition, position,
    puyopuyo, requirement, rule,
  ]

proc main*() =
  # ------------------------------------------------
  # Constructor
  # ------------------------------------------------

  # newSimulator
  block:
    let simulator = newSimulator[WaterField]()
    check simulator.nazoPuyoWrap == initNazoPuyo[WaterField]().initNazoPuyoWrap
    check simulator.nazoPuyoWrapBeforeMoves ==
      initNazoPuyo[WaterField]().initNazoPuyoWrap
    check simulator.state == Stable
    check simulator.positions.len == 0
    check simulator.operatingIndex == 0
    check simulator.operatingPosition == Up2
    check simulator.editing.cell == Cell.None
    check simulator.editing.field == (Row.low, Column.low)
    check simulator.editing.pair == (0.Natural, true)
    check simulator.editing.focusField
    check not simulator.editing.insert

  # ------------------------------------------------
  # Property - Rule / Kind / Mode
  # ------------------------------------------------

  # rule, kind, mode, `rule=`, `kind=`, `mode=`
  block:
    let simulator = newSimulator[TsuField](PlayEditor)
    check simulator.rule == Tsu
    check simulator.kind == Regular
    check simulator.mode == PlayEditor

    simulator.rule = Water
    check simulator.rule == Water

    simulator.kind = Nazo
    check simulator.kind == Nazo

    simulator.mode = Edit
    check simulator.mode == Edit

    simulator.mode = Play
    check simulator.mode == Play

    simulator.mode = View
    check simulator.mode == View

  # ------------------------------------------------
  # Property - Pairs&Positions
  # ------------------------------------------------

  # `pairsPositions=`, `positions=`
  block:
    let
      simulator = newSimulator[TsuField]()
      pairsPositions = "rb|\npp|3N".parsePairsPositions
      positions = pairsPositions.mapIt(it.position).toDeque

    simulator.pairsPositions = pairsPositions
    simulator.nazoPuyoWrap.get:
      check wrappedNazoPuyo.puyoPuyo.pairsPositions == pairsPositions
    check simulator.positions == positions

    let positions2 = [Up2].toDeque
    var pairsPositions2 = pairsPositions.copy
    pairsPositions2.positions = positions2

    simulator.positions = positions2
    simulator.nazoPuyoWrap.get:
      check wrappedNazoPuyo.puyoPuyo.pairsPositions == pairsPositions2
    check simulator.positions == positions2

  # ------------------------------------------------
  # Property - Other
  # ------------------------------------------------

  # score
  block:
    let simulator = parsePuyoPuyo[TsuField](
      """
....g.
....g.
....pg
....rg
....gr
....go
....gp
....bg
....bp
...bgp
...bgr
...orb
...gbb
------
rb|4F
rg|"""
    ).newSimulator

    simulator.forward(replay = true)
    while simulator.state != Stable:
      simulator.forward

    check simulator.score == 2720

  # ------------------------------------------------
  # Edit - Other
  # ------------------------------------------------

  # toggleInserting, toggleFocus
  block:
    let simulator = newSimulator[TsuField]()

    simulator.toggleInserting
    check simulator.editing.insert

    simulator.toggleFocus
    check not simulator.editing.focusField

  # ------------------------------------------------
  # Edit - Cursor
  # ------------------------------------------------

  # moveCursorUp, moveCursorDown, moveCursorRight, moveCursorLeft
  block:
    let simulator = newSimulator[TsuField]()

    simulator.moveCursorUp
    check simulator.editing.field == (Row.high, Column.low)

    simulator.moveCursorDown
    check simulator.editing.field == (Row.low, Column.low)

    simulator.moveCursorRight
    check simulator.editing.field == (Row.low, Column.low.succ)

    simulator.moveCursorLeft
    check simulator.editing.field == (Row.low, Column.low)

  # ------------------------------------------------
  # Edit - Delete
  # ------------------------------------------------

  # deletePairPosition
  block:
    let
      pairPos1 = PairPosition(pair: RedGreen, position: Position.None)
      pairPos2 = PairPosition(pair: BlueYellow, position: Position.None)
      pairPos3 = PairPosition(pair: PurplePurple, position: Position.None)
    var puyoPuyo = initPuyoPuyo[TsuField]()
    puyoPuyo.pairsPositions.addLast pairPos1
    puyoPuyo.pairsPositions.addLast pairPos2
    puyoPuyo.pairsPositions.addLast pairPos3
    let simulator = puyoPuyo.newSimulator

    simulator.nazoPuyoWrap.get:
      simulator.deletePairPosition 0
      check wrappedNazoPuyo.puyoPuyo.pairsPositions == @[pairPos2, pairPos3].toDeque

      simulator.toggleFocus
      simulator.moveCursorDown
      simulator.deletePairPosition
      check wrappedNazoPuyo.puyoPuyo.pairsPositions == @[pairPos2].toDeque

  # ------------------------------------------------
  # Edit - Write
  # ------------------------------------------------

  # writeCell (field)
  block:
    let simulator = newSimulator[TsuField]()

    simulator.nazoPuyoWrap.get:
      simulator.editingCell = Cell.Red
      simulator.writeCell Row.high, Column.high
      check wrappedNazoPuyo.puyoPuyo.field == parseField[TsuField]("t-r", Pon2)

      simulator.moveCursorUp
      simulator.writeCell Cell.Garbage
      check wrappedNazoPuyo.puyoPuyo.field == parseField[TsuField]("t-o....r", Pon2)

  # writeCell (pair)
  block:
    let simulator = newSimulator[TsuField]()

    simulator.nazoPuyoWrap.get:
      simulator.editingCell = Cell.Red
      simulator.writeCell 0, true
      check wrappedNazoPuyo.puyoPuyo.pairsPositions == "rr|".parsePairsPositions

      simulator.editingCell = Cell.Green
      simulator.writeCell 0, false
      check wrappedNazoPuyo.puyoPuyo.pairsPositions == "rg|".parsePairsPositions

      simulator.editingCell = Cell.Blue
      simulator.writeCell 1, true
      check wrappedNazoPuyo.puyoPuyo.pairsPositions == "rg|\nbb|".parsePairsPositions

      simulator.toggleFocus
      simulator.moveCursorDown
      simulator.moveCursorRight
      simulator.writeCell Cell.Yellow
      check wrappedNazoPuyo.puyoPuyo.pairsPositions == "rg|\nby|".parsePairsPositions

      simulator.editingCell = Cell.None
      simulator.writeCell 0, true
      check wrappedNazoPuyo.puyoPuyo.pairsPositions == "by|".parsePairsPositions

  # ------------------------------------------------
  # Edit - Shift / Flip
  # ------------------------------------------------

  # shiftFieldUp, shiftFieldDown, shiftFieldRight, shiftFieldLeft, flipFieldV, flipFieldH
  block:
    var
      field2 = parseField[TsuField]("t-rgb...ypo...", Pon2)
      puyoPuyo = initPuyoPuyo[TsuField]()
    puyoPuyo.field = field2
    let simulator = puyoPuyo.newSimulator

    simulator.nazoPuyoWrap.get:
      simulator.shiftFieldUp
      field2.shiftUp
      check wrappedNazoPuyo.puyoPuyo.field == field2

      simulator.shiftFieldDown
      field2.shiftDown
      check wrappedNazoPuyo.puyoPuyo.field == field2

      simulator.shiftFieldRight
      field2.shiftRight
      check wrappedNazoPuyo.puyoPuyo.field == field2

      simulator.shiftFieldLeft
      field2.shiftLeft
      check wrappedNazoPuyo.puyoPuyo.field == field2

      simulator.flipFieldH
      field2.flipH
      check wrappedNazoPuyo.puyoPuyo.field == field2

      simulator.flipFieldV
      field2.flipV
      check wrappedNazoPuyo.puyoPuyo.field == field2

  # flip
  block:
    var
      field2 = parseField[TsuField]("t-rgb...ypo...", Pon2)
      pairsPositions2 = @[PairPosition(pair: RedGreen, position: Right2)].toDeque
      puyoPuyo = initPuyoPuyo[TsuField]()
    puyoPuyo.field = field2
    puyoPuyo.pairsPositions = pairsPositions2
    let simulator = puyoPuyo.newSimulator

    simulator.nazoPuyoWrap.get:
      simulator.flip
      field2.flipH
      check wrappedNazoPuyo.puyoPuyo.field == field2
      check wrappedNazoPuyo.puyoPuyo.pairsPositions == pairsPositions2

      simulator.toggleFocus
      simulator.flip
      pairsPositions2[0].pair.swap
      check wrappedNazoPuyo.puyoPuyo.field == field2
      check wrappedNazoPuyo.puyoPuyo.pairsPositions == pairsPositions2

  # ------------------------------------------------
  # Edit - Requirement
  # ------------------------------------------------

  # `requirementKind=`, `requirementColor=`, `requirementNumber=`
  block:
    let simulator = newSimulator[TsuField]()

    simulator.nazoPuyoWrap.get:
      check wrappedNazoPuyo.requirement == initRequirement(Clear, All)

      simulator.requirementColor = RequirementColor.Color
      check wrappedNazoPuyo.requirement == initRequirement(
        Clear, RequirementColor.Color
      )

      simulator.requirementNumber = 0
      check wrappedNazoPuyo.requirement == initRequirement(
        Clear, RequirementColor.Color
      )

      simulator.requirementKind = Chain
      check wrappedNazoPuyo.requirement == initRequirement(Chain, 0)

      simulator.requirementNumber = 1
      check wrappedNazoPuyo.requirement == initRequirement(Chain, 1)

      simulator.requirementColor = RequirementColor.Garbage
      check wrappedNazoPuyo.requirement == initRequirement(Chain, 1)

      simulator.requirementKind = ChainClear
      check wrappedNazoPuyo.requirement == initRequirement(ChainClear, All, 1)

  # ------------------------------------------------
  # Edit - Undo / Redo
  # ------------------------------------------------

  # undo, redo
  block:
    let
      simulator = newSimulator[TsuField]()
      nazo1 = simulator.nazoPuyoWrap

    simulator.undo
    check simulator.nazoPuyoWrap == nazo1

    simulator.writeCell Cell.Red
    let nazo2 = simulator.nazoPuyoWrap

    simulator.flipFieldH
    let nazo3 = simulator.nazoPuyoWrap

    simulator.undo
    check simulator.nazoPuyoWrap == nazo2

    simulator.undo
    check simulator.nazoPuyoWrap == nazo1

    simulator.redo
    check simulator.nazoPuyoWrap == nazo2

    simulator.redo
    check simulator.nazoPuyoWrap == nazo3

    simulator.undo
    simulator.flipFieldV
    let nazo4 = simulator.nazoPuyoWrap

    simulator.redo
    check simulator.nazoPuyoWrap == nazo4

    simulator.undo
    check simulator.nazoPuyoWrap == nazo2

  # ------------------------------------------------
  # Play - Operating
  # ------------------------------------------------

  # moveOperatingPositionRight, moveOperatingPositionLeft, rotateOperatingPositionRight,
  # rotateOperatingPositionLeft
  block:
    let simulator = newSimulator[TsuField]()
    var pos = simulator.operatingPosition

    simulator.moveOperatingPositionRight
    pos.moveRight
    check simulator.operatingPosition == pos

    simulator.moveOperatingPositionLeft
    pos.moveLeft
    check simulator.operatingPosition == pos

    simulator.rotateOperatingPositionRight
    pos.rotateRight
    check simulator.operatingPosition == pos

    simulator.rotateOperatingPositionLeft
    pos.rotateLeft
    check simulator.operatingPosition == pos

  # ------------------------------------------------
  # Forward / Backward
  # ------------------------------------------------

  # forward, backward w/ arguments
  block:
    let
      nazo0 = parseNazoPuyo[TsuField]("Mp6j92mS_o1q1__u03", Ishikawa)
      nazo1 = parseNazoPuyo[TsuField]("30010Mp6j92mS_q1__u03", Ishikawa)
      nazo2 = parseNazoPuyo[TsuField]("30000Mo6j02m0_q1__u03", Ishikawa)
      nazo3 = parseNazoPuyo[TsuField]("M06j02mr_q1__u03", Ishikawa)

      moveRes0 = initMoveResult(0, [0, 0, 0, 0, 0, 0, 0], @[], @[])
      moveRes1 = moveRes0
      detail: array[Puyo, int] = [0, 2, 4, 0, 0, 0, 0]
      full: array[ColorPuyo, seq[int]] = [@[4], @[], @[], @[], @[]]
      moveRes2 = initMoveResult(0, [0, 2, 4, 0, 0, 0, 0], @[detail], @[full])
      moveRes3 = moveRes2

      simulator = nazo0.newSimulator

    simulator.nazoPuyoWrap.get:
      check simulator.state == Stable
      check wrappedNazoPuyo == nazo0
      check simulator.positions == [Position.None, Position.None].toDeque
      check simulator.operatingIndex == 0
      block:
        simulator.type.privateAccess
        check simulator.moveResult == moveRes0

      for _ in 1 .. 3:
        simulator.moveOperatingPositionRight
      simulator.forward
      check simulator.state == WillDisappear
      check wrappedNazoPuyo == nazo1
      check simulator.positions == [Up5, None].toDeque
      check simulator.operatingIndex == 0
      block:
        simulator.type.privateAccess
        check simulator.moveResult == moveRes1

      simulator.forward
      check simulator.state == WillDrop
      check wrappedNazoPuyo == nazo2
      check simulator.positions == [Up5, None].toDeque
      check simulator.operatingIndex == 0
      block:
        simulator.type.privateAccess
        check simulator.moveResult == moveRes2

      simulator.forward
      check simulator.state == Stable
      check wrappedNazoPuyo == nazo3
      check simulator.positions == [Up5, None].toDeque
      check simulator.operatingIndex == 1
      block:
        simulator.type.privateAccess
        check simulator.moveResult == moveRes3

      simulator.backward(toStable = false)
      check simulator.state == WillDrop
      check wrappedNazoPuyo == nazo2
      check simulator.positions == [Up5, None].toDeque
      check simulator.operatingIndex == 0
      block:
        simulator.type.privateAccess
        check simulator.moveResult == moveRes2

      simulator.backward(toStable = false)
      check simulator.state == WillDisappear
      check wrappedNazoPuyo == nazo1
      check simulator.positions == [Up5, None].toDeque
      check simulator.operatingIndex == 0
      block:
        simulator.type.privateAccess
        check simulator.moveResult == moveRes1

      simulator.backward(toStable = false)
      check simulator.state == Stable
      check wrappedNazoPuyo == nazo0
      check simulator.positions == [Up5, None].toDeque
      check simulator.operatingIndex == 0
      block:
        simulator.type.privateAccess
        check simulator.moveResult == moveRes0

  # forward w/ arguments
  block:
    # replay
    block:
      let simulator =
        parseNazoPuyo[TsuField]("Mp6j92mS_oaq1__u03", Ishikawa).newSimulator
      simulator.forward(replay = true)
      simulator.nazoPuyoWrap.get:
        check wrappedNazoPuyo ==
          parseNazoPuyo[TsuField]("30010Mp6j92mS_q1__u03", Ishikawa)
      check simulator.positions == [Up5, None].toDeque
      check simulator.operatingIndex == 0

    # skip
    block:
      let simulator =
        parseNazoPuyo[TsuField]("Mp6j92mS_oaq1__u03", Ishikawa).newSimulator
      simulator.forward(skip = true)
      simulator.nazoPuyoWrap.get:
        check wrappedNazoPuyo == parseNazoPuyo[TsuField]("Mp6j92mS_q1__u03", Ishikawa)
      check simulator.positions == [Position.None, Position.None].toDeque
      check simulator.operatingIndex == 1

  # backward, reset
  block:
    let simulator = parseNazoPuyo[TsuField]("Mp6j92mS_o1q1__u03", Ishikawa).newSimulator

    simulator.nazoPuyoWrap.get:
      for _ in 1 .. 3:
        simulator.moveOperatingPositionRight
      simulator.forward
      simulator.backward
      check simulator.state == Stable
      check wrappedNazoPuyo == parseNazoPuyo[TsuField]("Mp6j92mS_o1q1__u03", Ishikawa)
      check simulator.positions == [Up5, None].toDeque
      check simulator.operatingIndex == 0

      for _ in 1 .. 3:
        simulator.moveOperatingPositionRight
      simulator.forward
      simulator.forward
      simulator.backward
      check simulator.state == Stable
      check wrappedNazoPuyo == parseNazoPuyo[TsuField]("Mp6j92mS_o1q1__u03", Ishikawa)
      check simulator.positions == [Up5, None].toDeque
      check simulator.operatingIndex == 0

      for _ in 1 .. 3:
        simulator.moveOperatingPositionRight
      simulator.forward
      simulator.forward
      simulator.forward
      simulator.backward
      check simulator.state == Stable
      check wrappedNazoPuyo == parseNazoPuyo[TsuField]("Mp6j92mS_o1q1__u03", Ishikawa)
      check simulator.positions == [Up5, None].toDeque
      check simulator.operatingIndex == 0

      for _ in 1 .. 3:
        simulator.moveOperatingPositionRight
      simulator.forward
      simulator.forward
      simulator.forward
      for _ in 1 .. 2:
        simulator.moveOperatingPositionLeft
      simulator.rotateOperatingPositionRight
      simulator.forward
      simulator.backward
      check simulator.state == Stable
      check wrappedNazoPuyo == parseNazoPuyo[TsuField]("M06j02mr_q1__u03", Ishikawa)
      check simulator.positions == [Up5, Right0].toDeque
      check simulator.operatingIndex == 1

      simulator.reset
      check simulator.state == Stable
      check wrappedNazoPuyo == parseNazoPuyo[TsuField]("Mp6j92mS_o1q1__u03", Ishikawa)
      check simulator.positions == [Up5, Right0].toDeque
      check simulator.operatingIndex == 0

  # no-op forward, backward
  block:
    let
      nazo0 = parseNazoPuyo[TsuField]("Mp6j92mS_oa__u03", Ishikawa)
      nazo1 = parseNazoPuyo[TsuField]("M06j02mr__u03", Ishikawa)

      simulator = nazo0.newSimulator

    simulator.nazoPuyoWrap.get:
      simulator.forward(replay = true)
      simulator.forward
      simulator.forward
      check simulator.state == Stable
      check wrappedNazoPuyo == nazo1
      check simulator.positions == [Up5].toDeque
      check simulator.operatingIndex == 1

      simulator.forward
      check simulator.state == Stable
      check wrappedNazoPuyo == nazo1
      check simulator.positions == [Up5].toDeque
      check simulator.operatingIndex == 1

      simulator.backward
      check simulator.state == Stable
      check wrappedNazoPuyo == nazo0
      check simulator.positions == [Up5].toDeque
      check simulator.operatingIndex == 0

      simulator.backward
      check simulator.state == Stable
      check wrappedNazoPuyo == nazo0
      check simulator.positions == [Up5].toDeque
      check simulator.operatingIndex == 0

  # ------------------------------------------------
  # Simulator <-> URI
  # ------------------------------------------------

  # toUriQuery, toUri, parseSimulator
  block:
    let
      mainQuery = "field=t-rrb&pairs=rgby12&req-kind=0&req-color=7"
      mainQueryNoPos = "field=t-rrb&pairs=rgby&req-kind=0&req-color=7"
      kindModeQuery = "kind=n&mode=e"
      query = &"{kindModeQuery}&{mainQuery}"
      queryNoPos = &"{kindModeQuery}&{mainQueryNoPos}"
      simulator = query.parseSimulator Pon2
      nazo = parseNazoPuyo[TsuField](mainQuery, Pon2)

    check simulator.nazoPuyoWrap == nazo.initNazoPuyoWrap
    check simulator.kind == Nazo
    check simulator.mode == Edit

    check simulator.toUriQuery(withPositions = true) == query
    check simulator.toUriQuery(withPositions = false) == queryNoPos

    check simulator.toUriQuery(withPositions = true, fqdn = Ishikawa) == "1b_c1Ec__270"

    let
      simUri = parseUri &"https://{Pon2}{SimulatorUriPath}?{query}"
      simUriNoPos = parseUri &"https://{Pon2}{SimulatorUriPath}?{queryNoPos}"

    check simulator.toUri(withPositions = true) == simUri
    check simulator.toUri(withPositions = false) == simUriNoPos

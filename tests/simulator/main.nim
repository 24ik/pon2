{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options, strutils, unittest, uri]
import ../../src/pon2pkg/app/[nazopuyo, simulator {.all.}]
import
  ../../src/pon2pkg/core/[
    cell, field, fieldtype, host, nazopuyo, pair, pairposition, position, puyopuyo,
    requirement, rule,
  ]

proc checkNazoPuyoEqual[F1: TsuField or WaterField, F2: TsuField or WaterField](
    nazo1: NazoPuyo[F1], nazo2: NazoPuyo[F2]
) =
  check nazo1.puyoPuyo.field == nazo2.puyoPuyo.field
  check nazo1.puyoPuyo.pairsPositions == nazo2.puyoPuyo.pairsPositions
  check nazo1.requirement == nazo2.requirement

proc main*() =
  # ------------------------------------------------
  # Constructor
  # ------------------------------------------------

  # initSimulator
  block:
    let simulator = initPuyoPuyo[WaterField]().initSimulator
    check simulator.nazoPuyoWrap == initNazoPuyo[WaterField]().initNazoPuyoWrap
    check simulator.originalNazoPuyoWrap == initNazoPuyo[WaterField]().initNazoPuyoWrap
    check simulator.editor == false
    check simulator.state == Stable
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
    var simulator = initPuyoPuyo[TsuField]().initSimulator
    check simulator.rule == Tsu
    check simulator.kind == Regular
    check simulator.mode == Play

    simulator.rule = Water
    check simulator.rule == Water

    simulator.kind = Nazo
    check simulator.kind == Nazo

    simulator.mode = Replay
    check simulator.mode == Replay

  # ------------------------------------------------
  # Property - Score
  # ------------------------------------------------

  # score
  block:
    var simulator = parsePuyoPuyo[TsuField](
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
    ).initSimulator

    simulator.forward(replay = true)
    while simulator.state != Stable:
      simulator.forward

    check simulator.score == 2720

  # ------------------------------------------------
  # Edit - Other
  # ------------------------------------------------

  # toggleInserting, toggleFocus
  block:
    var simulator = initPuyoPuyo[TsuField]().initSimulator

    simulator.toggleInserting
    check simulator.editing.insert

    simulator.toggleFocus
    check not simulator.editing.focusField

  # ------------------------------------------------
  # Edit - Cursor
  # ------------------------------------------------

  # moveCursorUp, moveCursorDown, moveCursorRight, moveCursorLeft
  block:
    var simulator = initPuyoPuyo[TsuField]().initSimulator

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
    puyoPuyo.pairsPositions &= [pairPos1, pairPos2, pairPos3]
    var simulator = puyoPuyo.initSimulator

    simulator.nazoPuyoWrap.get:
      simulator.deletePairPosition 0
      check wrappedNazoPuyo.puyoPuyo.pairsPositions == @[pairPos2, pairPos3]

      simulator.toggleFocus
      simulator.moveCursorDown
      simulator.deletePairPosition
      check wrappedNazoPuyo.puyoPuyo.pairsPositions == @[pairPos2]

  # ------------------------------------------------
  # Edit - Write
  # ------------------------------------------------

  # writeCell (field)
  block:
    var simulator = initPuyoPuyo[TsuField]().initSimulator

    simulator.nazoPuyoWrap.get:
      simulator.editingCell = Cell.Red
      simulator.writeCell Row.high, Column.high
      check wrappedNazoPuyo.puyoPuyo.field == parseField[TsuField]("t-r", Izumiya)

      simulator.moveCursorUp
      simulator.writeCell Cell.Garbage
      check wrappedNazoPuyo.puyoPuyo.field == parseField[TsuField]("t-o....r", Izumiya)

  # writeCell (pair)
  block:
    var simulator = initPuyoPuyo[TsuField]().initSimulator

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
      field2 = parseField[TsuField]("t-rgb...ypo...", Izumiya)
      puyoPuyo = initPuyoPuyo[TsuField]()
    puyoPuyo.field = field2
    var simulator = puyoPuyo.initSimulator

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

  # ------------------------------------------------
  # Edit - Requirement
  # ------------------------------------------------

  # `requirementKind=`, `requirementColor=`, `requirementNumber=`
  block:
    var simulator = initPuyoPuyo[TsuField]().initSimulator

    simulator.nazoPuyoWrap.get:
      check wrappedNazoPuyo.requirement ==
        Requirement(kind: Clear, color: RequirementColor.low, number: 0)

      simulator.requirementColor = RequirementColor.Color
      check wrappedNazoPuyo.requirement ==
        Requirement(kind: Clear, color: RequirementColor.Color, number: 0)

      simulator.requirementNumber = 1
      check wrappedNazoPuyo.requirement ==
        Requirement(kind: Clear, color: RequirementColor.Color, number: 0)

      simulator.requirementKind = Chain
      check wrappedNazoPuyo.requirement == Requirement(kind: Chain, number: 0)

      simulator.requirementNumber = 1
      check wrappedNazoPuyo.requirement == Requirement(kind: Chain, number: 1)

      simulator.requirementColor = RequirementColor.Garbage
      check wrappedNazoPuyo.requirement == Requirement(kind: Chain, number: 1)

      simulator.requirementKind = ChainClear
      check wrappedNazoPuyo.requirement ==
        Requirement(kind: ChainClear, color: RequirementColor.low, number: 1)

  # ------------------------------------------------
  # Edit - Undo / Redo
  # ------------------------------------------------

  # undo, redo
  block:
    var simulator = initPuyoPuyo[TsuField]().initSimulator
    let nazo1 = simulator.nazoPuyoWrap

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
    var
      simulator = initPuyoPuyo[TsuField]().initSimulator
      pos = simulator.operatingPosition

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

  # forward
  block:
    var simulator =
      "https://ishikawapuyo.net/simu/pn.html?Mp6j92mS_o1q1__u03".parseUri.parseSimulator

    simulator.nazoPuyoWrap.get:
      for _ in 1 .. 3:
        simulator.moveOperatingPositionRight
      simulator.forward
      check simulator.state == WillDisappear
      wrappedNazoPuyo.checkNazoPuyoEqual parseNazoPuyo[TsuField](
        "30010Mp6j92mS_oaq1__u03", Ishikawa
      )
      check wrappedNazoPuyo.puyoPuyo.operatingIndex == 0

      simulator.forward
      check simulator.state == Disappearing
      wrappedNazoPuyo.checkNazoPuyoEqual parseNazoPuyo[TsuField](
        "30000Mo6j02m0_oaq1__u03", Ishikawa
      )
      check wrappedNazoPuyo.puyoPuyo.operatingIndex == 0

      simulator.forward
      check simulator.state == Stable
      wrappedNazoPuyo.checkNazoPuyoEqual parseNazoPuyo[TsuField](
        "M06j02mr_oaq1__u03", Ishikawa
      )
      check wrappedNazoPuyo.puyoPuyo.operatingIndex == 1

  # forward w/ arguments
  block:
    block:
      var simulator =
        "https://ishikawapuyo.net/simu/pn.html?Mp6j92mS_oaq1__u03".parseUri.parseSimulator
      simulator.forward(replay = true)
      simulator.nazoPuyoWrap.get:
        wrappedNazoPuyo.checkNazoPuyoEqual parseNazoPuyo[TsuField](
          "30010Mp6j92mS_oaq1__u03", Ishikawa
        )

    block:
      var simulator =
        "https://ishikawapuyo.net/simu/pn.html?Mp6j92mS_oaq1__u03".parseUri.parseSimulator
      simulator.forward(skip = true)
      simulator.nazoPuyoWrap.get:
        wrappedNazoPuyo.checkNazoPuyoEqual parseNazoPuyo[TsuField](
          "Mp6j92mS_o1q1__u03", Ishikawa
        )

  # backward, reset
  block:
    var simulator =
      parseNazoPuyo[TsuField]("Mp6j92mS_o1q1__u03", Ishikawa).initSimulator

    simulator.nazoPuyoWrap.get:
      for _ in 1 .. 3:
        simulator.moveOperatingPositionRight
      simulator.forward
      simulator.backward
      wrappedNazoPuyo.checkNazoPuyoEqual parseNazoPuyo[TsuField](
        "Mp6j92mS_oaq1__u03", Ishikawa
      )
      check simulator.state == Stable
      check wrappedNazoPuyo.puyoPuyo.operatingIndex == 0

      for _ in 1 .. 3:
        simulator.moveOperatingPositionRight
      simulator.forward
      simulator.forward
      simulator.backward
      wrappedNazoPuyo.checkNazoPuyoEqual parseNazoPuyo[TsuField](
        "Mp6j92mS_oaq1__u03", Ishikawa
      )
      check simulator.state == Stable
      check wrappedNazoPuyo.puyoPuyo.operatingIndex == 0

      for _ in 1 .. 3:
        simulator.moveOperatingPositionRight
      simulator.forward
      simulator.forward
      simulator.forward
      simulator.backward
      wrappedNazoPuyo.checkNazoPuyoEqual parseNazoPuyo[TsuField](
        "Mp6j92mS_oaq1__u03", Ishikawa
      )
      check simulator.state == Stable
      check wrappedNazoPuyo.puyoPuyo.operatingIndex == 0

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
      wrappedNazoPuyo.checkNazoPuyoEqual parseNazoPuyo[TsuField](
        "M06j02mr_oaqc__u03", Ishikawa
      )
      check simulator.state == Stable
      check wrappedNazoPuyo.puyoPuyo.operatingIndex == 1

      simulator.reset false
      wrappedNazoPuyo.checkNazoPuyoEqual parseNazoPuyo[TsuField](
        "Mp6j92mS_oaqc__u03", Ishikawa
      )
      check simulator.state == Stable
      check wrappedNazoPuyo.puyoPuyo.operatingIndex == 0

      simulator.reset
      wrappedNazoPuyo.checkNazoPuyoEqual parseNazoPuyo[TsuField](
        "Mp6j92mS_o1q1__u03", Ishikawa
      )
      check simulator.state == Stable
      check wrappedNazoPuyo.puyoPuyo.operatingIndex == 0

  # ------------------------------------------------
  # Simulator <-> URI
  # ------------------------------------------------

  # toUri, parseSimulator
  block:
    let
      uriStr =
        "https://izumiya-keisuke.github.io/pon2/gui/index.html?" &
        "editor&kind=n&mode=e&field=t-rrb&pairs=rgby12&req-kind=0&req-color=7"
      uriStrNoPos =
        "https://izumiya-keisuke.github.io/pon2/gui/index.html?" &
        "editor&kind=n&mode=e&field=t-rrb&pairs=rgby&req-kind=0&req-color=7"
      simulator = uriStr.parseUri.parseSimulator
      nazo = parseNazoPuyo[TsuField](
        "field=t-rrb&pairs=rgby12&req-kind=0&req-color=7", Izumiya
      )

    check simulator.nazoPuyoWrap == nazo.initNazoPuyoWrap
    check simulator.editor
    check simulator.kind == Nazo
    check simulator.mode == Edit

    check simulator.toUri(withPositions = true) == uriStr.parseUri
    check simulator.toUri(withPositions = false) == uriStrNoPos.parseUri

    check simulator.toUri(withPositions = true, editor = false) ==
      uriStr.replace("editor&", "").parseUri
    check simulator.toUri(withPositions = false, editor = false) ==
      uriStrNoPos.replace("editor&", "").parseUri

    check simulator.toUri(withPositions = true, host = Ishikawa) ==
      "https://ishikawapuyo.net/simu/pn.html?1b_c1Ec__270".parseUri

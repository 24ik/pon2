{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[algorithm, unittest, uri]
import ../../src/pon2/[core]
import ../../src/pon2/app/[key, nazopuyowrap, simulator]
import ../../src/pon2/private/[assign3]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

block: # init
  check Simulator.init == Simulator.init NazoPuyoWrap.init
  check Simulator.init(PuyoPuyo[WaterField].init, EditorEdit).mode == EditorEdit

# ------------------------------------------------
# Edit - Undo / Redo
# ------------------------------------------------

block: # undo, redo
  var sim = Simulator.init EditorEdit

  sim.writeCell Cell.Green
  let wrap1 = sim.nazoPuyoWrap

  sim.undo
  check sim.nazoPuyoWrap == NazoPuyoWrap.init

  sim.undo
  check sim.nazoPuyoWrap == NazoPuyoWrap.init

  sim.redo
  check sim.nazoPuyoWrap == wrap1

  sim.redo
  check sim.nazoPuyoWrap == wrap1

# ------------------------------------------------
# Property - Getter
# ------------------------------------------------

block:
  # rule, nazoPuyoWrap, moveResult, mode, state, editData,
  # operatingPlacement, operatingIdx
  let sim = Simulator.init

  check sim.rule == Tsu
  check sim.nazoPuyoWrap == NazoPuyoWrap.init
  check sim.moveResult == MoveResult.init true
  check sim.mode == ViewerPlay
  check sim.state == Stable
  check sim.editData ==
    SimulatorEditData(
      cell: None,
      focusField: true,
      field: (Row.low, Col.low),
      step: (0, true, Col.low),
      insert: false,
    )
  check sim.operatingPlacement == Up2
  check sim.operatingIdx == 0

# ------------------------------------------------
# Property - Setter
# ------------------------------------------------

block: # `rule=`
  var sim = Simulator.init EditorEdit

  sim.rule = Tsu
  check sim.rule == Tsu
  check sim.nazoPuyoWrap == NazoPuyoWrap.init

  sim.rule = Water
  check sim.rule == Water
  check sim.nazoPuyoWrap == NazoPuyoWrap.init NazoPuyo[WaterField].init

  sim.rule = Water
  check sim.rule == Water
  check sim.nazoPuyoWrap == NazoPuyoWrap.init NazoPuyo[WaterField].init

block: # `mode=`
  let nazo = parseNazoPuyo[TsuField](
    """
3連鎖するべし
======
......
......
......
......
......
......
......
......
......
......
.....g
......
......
------
rb|
(0,0,0,0,0,1)
py|"""
  ).unsafeValue

  block: # from ViewerPlay
    let field0 = nazo.puyoPuyo.field

    var sim = Simulator.init nazo
    sim.forward
    sim.mode = ViewerEdit

    sim.nazoPuyoWrap.runIt:
      check it.field == field0

  block: # from ViewerEdit
    let field0 = nazo.puyoPuyo.field

    var sim = Simulator.init(nazo, ViewerEdit)
    sim.forward
    sim.mode = ViewerPlay

    sim.nazoPuyoWrap.runIt:
      check it.field == field0

  block: # from EditorPlay
    let field0 = nazo.puyoPuyo.field

    var sim = Simulator.init(nazo, EditorPlay)
    sim.forward
    sim.mode = EditorEdit

    sim.nazoPuyoWrap.runIt:
      check it.field == field0

  block: # from EditorEdit
    let field0 = nazo.puyoPuyo.field

    var sim = Simulator.init(nazo, EditorEdit)
    sim.forward
    sim.mode = EditorPlay

    sim.nazoPuyoWrap.runIt:
      check it.field == field0

block: # `editCell=`
  var sim = Simulator.init ViewerEdit

  sim.editCell = None
  check sim.editData.cell == None

  sim.editCell = Cell.Red
  check sim.editData.cell == Cell.Red

  sim.editCell = Garbage
  check sim.editData.cell == Garbage

# ------------------------------------------------
# Edit - Cursor
# ------------------------------------------------

block: # moveCursorUp, moveCursorDown, moveCursorRight, moveCursorLeft
  let nazo = parseNazoPuyo[TsuField](
    """
3連鎖するべし
======
......
......
......
......
......
......
......
......
......
......
......
......
......
------
rb|
(0,0,0,0,0,1)
py|"""
  ).unsafeValue
  var sim = Simulator.init(nazo, EditorEdit)

  sim.moveCursorUp
  check sim.editData.field == (Row12, Col0)

  sim.moveCursorRight
  check sim.editData.field == (Row12, Col1)

  sim.moveCursorDown
  check sim.editData.field == (Row0, Col1)

  sim.moveCursorLeft
  check sim.editData.field == (Row0, Col0)

  sim.toggleFocus

  sim.moveCursorUp
  check sim.editData.step == (3, true, Col0)

  sim.moveCursorRight
  check sim.editData.step == (3, false, Col0)

  sim.moveCursorUp
  check sim.editData.step == (2, false, Col0)

  sim.moveCursorUp
  check sim.editData.step == (1, false, Col0)

  sim.moveCursorLeft
  check sim.editData.step == (1, false, Col5)

# ------------------------------------------------
# Edit - Delete
# ------------------------------------------------

block: # deleteStep
  let nazo = parseNazoPuyo[TsuField](
    """
3連鎖するべし
======
......
......
......
......
......
......
......
......
......
......
......
......
......
------
rb|3N
(0,0,0,0,0,1)
py|"""
  ).unsafeValue
  var
    steps = nazo.puyoPuyo.steps
    sim = Simulator.init(nazo, EditorEdit)

  sim.deleteStep
  steps.delete 0
  sim.nazoPuyoWrap.runIt:
    check it.steps == steps

  sim.deleteStep 1
  steps.delete 1
  sim.nazoPuyoWrap.runIt:
    check it.steps == steps

  sim.deleteStep 1
  sim.nazoPuyoWrap.runIt:
    check it.steps == steps

# ------------------------------------------------
# Edit - Write
# ------------------------------------------------

block: # writeCell
  let nazo = parseNazoPuyo[TsuField](
    """
3連鎖するべし
======
......
......
......
......
......
......
......
......
......
......
......
......
......
------
rb|3N
(0,0,0,0,0,1)
py|"""
  ).unsafeValue
  var
    field = nazo.puyoPuyo.field
    steps = nazo.puyoPuyo.steps
    sim = Simulator.init(nazo, EditorEdit)

  sim.editCell = Green
  sim.writeCell Row3, Col4
  field[Row3, Col4] = Green
  sim.nazoPuyoWrap.runIt:
    check it.field == field

  sim.writeCell Blue
  field[Row0, Col0] = Blue
  sim.nazoPuyoWrap.runIt:
    check it.field == field

  sim.toggleInsert

  sim.writeCell Row6, Col4
  field.insert Row6, Col4, Green
  sim.nazoPuyoWrap.runIt:
    check it.field == field

  sim.editCell = None
  sim.writeCell Row8, Col4
  field.delete Row8, Col4
  sim.nazoPuyoWrap.runIt:
    check it.field == field

  sim.toggleFocus

  sim.writeCell Yellow
  steps.insert Step.init(YellowYellow), 0
  sim.nazoPuyoWrap.runIt:
    check it.steps == steps

  sim.writeCell None
  steps.delete 0
  sim.nazoPuyoWrap.runIt:
    check it.steps == steps

  sim.toggleInsert

  sim.editCell = Blue
  sim.writeCell 2, false
  steps[2].pair.rotor = Blue
  sim.nazoPuyoWrap.runIt:
    check it.steps == steps

  sim.editCell = Garbage
  sim.writeCell 1, false
  sim.nazoPuyoWrap.runIt:
    check it.steps == steps

  sim.editCell = Hard
  sim.writeCell 1, true
  steps[1].dropHard.assign true
  sim.nazoPuyoWrap.runIt:
    check it.steps == steps

  sim.writeCell 2, true
  steps[2] = Step.init([0, 0, 0, 0, 0, 0], true)
  sim.nazoPuyoWrap.runIt:
    check it.steps == steps

  sim.editCell = Purple
  sim.writeCell 3, true
  steps.addLast Step.init PurplePurple
  sim.nazoPuyoWrap.runIt:
    check it.steps == steps

# ------------------------------------------------
# Edit - Shift / Flip
# ------------------------------------------------

block: # shiftFieldUp, shiftFieldDown, shiftFieldRight, shiftFieldLeft
  let nazo = parseNazoPuyo[TsuField](
    """
ぷよ全て消すべし
======
......
......
......
......
......
......
......
......
......
.r....
..o...
...h..
......
------
rg|
(0,1,2,3,4,5)"""
  ).unsafeValue
  var
    field = nazo.puyoPuyo.field
    steps = nazo.puyoPuyo.steps
    sim = Simulator.init(nazo, EditorEdit)

  sim.shiftFieldUp
  field.shiftUp
  sim.nazoPuyoWrap.runIt:
    check it.field == field

  sim.shiftFieldDown
  field.shiftDown
  sim.nazoPuyoWrap.runIt:
    check it.field == field

  sim.shiftFieldRight
  field.shiftRight
  sim.nazoPuyoWrap.runIt:
    check it.field == field

  sim.shiftFieldLeft
  field.shiftLeft
  sim.nazoPuyoWrap.runIt:
    check it.field == field

  sim.flipFieldVertical
  field.flipVertical
  sim.nazoPuyoWrap.runIt:
    check it.field == field

  sim.flipFieldHorizontal
  field.flipHorizontal
  sim.nazoPuyoWrap.runIt:
    check it.field == field

  sim.flip
  field.flipHorizontal
  sim.nazoPuyoWrap.runIt:
    check it.field == field

  sim.toggleFocus

  sim.flip
  steps[0].pair.swap
  sim.nazoPuyoWrap.runIt:
    check it.steps == steps

  sim.moveCursorDown
  sim.flip
  steps[1].cnts.reverse
  sim.nazoPuyoWrap.runIt:
    check it.steps == steps

  sim.moveCursorDown
  sim.flip
  sim.nazoPuyoWrap.runIt:
    check it.steps == steps

# ------------------------------------------------
# Edit - Goal
# ------------------------------------------------

block: # `goalKind=`, `goalColor=`, `goalVal=`
  var sim = Simulator.init EditorEdit

  sim.goalKind = Chain
  check sim.nazoPuyoWrap.optGoal == Opt[Goal].ok Goal.init(Chain, 0)

  sim.goalColor = GoalColor.Yellow
  check sim.nazoPuyoWrap.optGoal == Opt[Goal].ok Goal.init(Chain, 0)

  sim.goalVal = 3
  check sim.nazoPuyoWrap.optGoal == Opt[Goal].ok Goal.init(Chain, 3)

  sim.goalKind = AccCnt
  check sim.nazoPuyoWrap.optGoal == Opt[Goal].ok Goal.init(AccCnt, All, 3)

  sim.goalColor = GoalColor.Red
  check sim.nazoPuyoWrap.optGoal == Opt[Goal].ok Goal.init(AccCnt, GoalColor.Red, 3)

  sim.goalVal = 1
  check sim.nazoPuyoWrap.optGoal == Opt[Goal].ok Goal.init(AccCnt, GoalColor.Red, 1)

# ------------------------------------------------
# Edit - Other
# ------------------------------------------------

block: # toggleFocus, toggleInsert
  var sim = Simulator.init EditorEdit

  sim.toggleFocus
  check not sim.editData.focusField

  sim.toggleFocus
  check sim.editData.focusField

  sim.toggleInsert
  check sim.editData.insert

  sim.toggleInsert
  check not sim.editData.insert

# ------------------------------------------------
# Play - Placement
# ------------------------------------------------

block:
  # movePlacementRight, movePlacementLeft, rotatePlacementRight, rotatePlacementLeft
  var
    sim = Simulator.init
    plcmt = Up2

  check sim.operatingPlacement == plcmt

  sim.movePlacementRight
  plcmt.moveRight
  check sim.operatingPlacement == plcmt

  sim.movePlacementLeft
  plcmt.moveLeft
  check sim.operatingPlacement == plcmt

  sim.rotatePlacementRight
  plcmt.rotateRight
  check sim.operatingPlacement == plcmt

  sim.rotatePlacementLeft
  plcmt.rotateLeft
  check sim.operatingPlacement == plcmt

# ------------------------------------------------
# Forward / Backward
# ------------------------------------------------

block: # forward, backward, reset
  block: # play
    let
      wrap0 = NazoPuyoWrap.init parseNazoPuyo[TsuField](
        """
3連鎖するべし
======
......
......
......
......
......
......
......
......
......
......
..o.br
.ogbrr
.ggooo
------
rb|"""
      ).unsafeValue
      wrap0P = NazoPuyoWrap.init parseNazoPuyo[TsuField](
        """
3連鎖するべし
======
......
......
......
......
......
......
......
......
......
......
..o.br
.ogbrr
.ggooo
------
rb|6N"""
      ).unsafeValue
      wrap1 = NazoPuyoWrap.init parseNazoPuyo[TsuField](
        """
3連鎖するべし
======
......
......
......
......
......
......
......
......
.....b
.....r
..o.br
.ogbrr
.ggooo
------
rb|6N"""
      ).unsafeValue
      wrap2 = NazoPuyoWrap.init parseNazoPuyo[TsuField](
        """
3連鎖するべし
======
......
......
......
......
......
......
......
......
.....b
......
..o.b.
.ogb..
.ggo..
------
rb|6N"""
      ).unsafeValue
      wrap3 = NazoPuyoWrap.init parseNazoPuyo[TsuField](
        """
3連鎖するべし
======
......
......
......
......
......
......
......
......
......
......
..o...
.ogb..
.ggobb
------
rb|6N"""
      ).unsafeValue

      cnts: array[Cell, int] = [0, 0, 2, 4, 0, 0, 0, 0]
      full: array[Cell, seq[int]] = [@[], @[], @[], @[4], @[], @[], @[], @[]]
      moveRes0 = MoveResult.init true
      moveRes1 = MoveResult.init true
      moveRes2 = MoveResult.init(1, cnts, 0, @[cnts], @[0], @[full])
      moveRes3 = moveRes2

    var sim = Simulator.init wrap0
    check sim.moveResult == moveRes0

    for _ in 1 .. 3:
      sim.movePlacementRight
    sim.forward
    check sim.nazoPuyoWrap == wrap1
    check sim.moveResult == moveRes1

    sim.forward
    check sim.nazoPuyoWrap == wrap2
    check sim.moveResult == moveRes2

    sim.forward
    check sim.nazoPuyoWrap == wrap3
    check sim.moveResult == moveRes3

    sim.forward
    check sim.nazoPuyoWrap == wrap3
    check sim.moveResult == moveRes3

    sim.forward(replay = true)
    check sim.nazoPuyoWrap == wrap3
    check sim.moveResult == moveRes3

    sim.forward(skip = true)
    check sim.nazoPuyoWrap == wrap3
    check sim.moveResult == moveRes3

    sim.backward(detail = true)
    check sim.nazoPuyoWrap == wrap2
    check sim.moveResult == moveRes2

    sim.backward(detail = true)
    check sim.nazoPuyoWrap == wrap1
    check sim.moveResult == moveRes1

    sim.backward(detail = true)
    check sim.nazoPuyoWrap == wrap0P
    check sim.moveResult == moveRes0

    sim.backward(detail = true)
    check sim.nazoPuyoWrap == wrap0P
    check sim.moveResult == moveRes0

    sim.backward
    check sim.nazoPuyoWrap == wrap0P
    check sim.moveResult == moveRes0

    sim.forward(replay = true)
    check sim.nazoPuyoWrap == wrap1
    check sim.moveResult == moveRes1

    sim.reset
    check sim.nazoPuyoWrap == wrap0P
    check sim.moveResult == moveRes0

    sim.forward(skip = true)
    check sim.nazoPuyoWrap == wrap0
    check sim.moveResult == moveRes0

  block: # edit
    let nazo0 = parseNazoPuyo[TsuField](
      """
3連鎖するべし
======
......
......
......
......
.....b
.....r
.....r
.....r
.....r
......
..o.br
.ogbrr
.ggooo
------
rb|"""
    ).unsafeValue
    var
      field = nazo0.puyoPuyo.field
      sim = Simulator.init(nazo0, EditorEdit)
    let field0 = field
    check sim.state == AfterEdit

    sim.forward
    field.settle
    check sim.state == WillPop
    sim.nazoPuyoWrap.runIt:
      check it.field == field

    sim.forward
    discard field.pop
    let field1 = field
    check sim.state == WillSettle
    sim.nazoPuyoWrap.runIt:
      check it.field == field

    sim.backward
    check sim.state == AfterEdit
    sim.nazoPuyoWrap.runIt:
      check it.field == field0

    for _ in 1 .. 3:
      sim.forward
    sim.reset
    check sim.state == AfterEdit
    sim.nazoPuyoWrap.runIt:
      check it.field == field0

    sim.forward
    sim.forward

    sim.writeCell Cell.Purple
    field[Row0, Col0] = Cell.Purple
    let field2 = field
    check sim.state == AfterEdit
    sim.nazoPuyoWrap.runIt:
      check it.field == field

    sim.forward
    field.settle
    check sim.state == Stable
    sim.nazoPuyoWrap.runIt:
      check it.field == field

    sim.forward
    check sim.state == Stable
    sim.nazoPuyoWrap.runIt:
      check it.field == field

    sim.writeCell Cell.Yellow
    field[Row0, Col0] = Cell.Yellow
    sim.forward
    sim.reset
    check sim.state == AfterEdit
    sim.nazoPuyoWrap.runIt:
      check it.field == field

    sim.backward
    check sim.state == AfterEdit
    sim.nazoPuyoWrap.runIt:
      check it.field == field

# ------------------------------------------------
# Mark
# ------------------------------------------------

block: # mark
  let nazo = parseNazoPuyo[TsuField](
    """
1連鎖するべし
======
......
......
......
......
......
......
......
......
......
......
......
......
.yyy..
------
yy|
yy|"""
  ).unsafeValue
  var sim = Simulator.init nazo
  check sim.mark == Opt[MarkResult].ok WrongAnswer

  sim.movePlacementRight
  sim.movePlacementRight
  sim.movePlacementRight
  sim.forward
  while sim.state != Stable:
    sim.forward
  check sim.mark == Opt[MarkResult].ok WrongAnswer

  sim.forward
  while sim.state != Stable:
    sim.forward
  check sim.mark == Opt[MarkResult].ok Accept

  sim.backward
  check sim.mark == Opt[MarkResult].ok WrongAnswer

  sim.backward
  check sim.mark == Opt[MarkResult].ok WrongAnswer

  sim.movePlacementLeft
  sim.forward
  while sim.state != Stable:
    sim.forward
  check sim.mark == Opt[MarkResult].ok Accept

  sim.forward
  while sim.state != Stable:
    sim.forward
  check sim.mark == Opt[MarkResult].ok Accept

  sim.backward
  check sim.mark == Opt[MarkResult].ok Accept

  sim.backward
  check sim.mark == Opt[MarkResult].ok WrongAnswer

block: # mark (PuyoPuyo)
  check Simulator.init(PuyoPuyo[TsuField].init).mark.isErr

# ------------------------------------------------
# Keyboard
# ------------------------------------------------

block: # operate
  let nazo = parseNazoPuyo[TsuField](
    """
1連鎖するべし
======
......
......
......
......
......
......
......
......
......
......
......
......
......
------
rg|1N
by|
pp|23"""
  ).unsafeValue
  var
    sim1 = Simulator.init nazo
    sim2 = Simulator.init nazo
  check sim1 == sim2

  sim1.rotatePlacementLeft
  check sim2.operate KeyEvent.init 'j'
  check sim1 == sim2

  sim1.rotatePlacementRight
  check sim2.operate KeyEvent.init 'k'
  check sim1 == sim2

  sim1.movePlacementLeft
  check sim2.operate KeyEvent.init 'a'
  check sim1 == sim2

  sim1.movePlacementRight
  check sim2.operate KeyEvent.init 'd'
  check sim1 == sim2

  sim1.forward
  check sim2.operate KeyEvent.init 's'
  check sim1 == sim2

  sim1.forward(replay = true)
  check sim2.operate KeyEvent.init 'c'
  check sim1 == sim2

  sim1.forward(skip = true)
  check sim2.operate KeyEvent.init "Space"
  check sim1 == sim2

  sim1.backward(detail = true)
  check sim2.operate KeyEvent.init 'W'
  check sim1 == sim2

  sim1.backward(detail = true)
  check sim2.operate KeyEvent.init 'X'
  check sim1 == sim2

  sim1.backward
  check sim2.operate KeyEvent.init 'w'
  check sim1 == sim2

  sim1.backward
  check sim2.operate KeyEvent.init 'x'
  check sim1 == sim2

  sim1.reset
  check sim2.operate KeyEvent.init 'z'
  check sim1 == sim2

  check not sim2.operate KeyEvent.init "Tab"
  check sim1 == sim2

  sim1.mode = ViewerEdit
  check sim2.operate KeyEvent.init 'm'
  check sim1 == sim2

  sim1.toggleInsert
  check sim2.operate KeyEvent.init 'i'
  check sim1 == sim2

  sim1.toggleFocus
  check sim2.operate KeyEvent.init "Tab"
  check sim1 == sim2

  sim1.moveCursorRight
  check sim2.operate KeyEvent.init 'd'
  check sim1 == sim2

  sim1.moveCursorLeft
  check sim2.operate KeyEvent.init 'a'
  check sim1 == sim2

  sim1.moveCursorUp
  check sim2.operate KeyEvent.init 'w'
  check sim1 == sim2

  sim1.moveCursorDown
  check sim2.operate KeyEvent.init 's'
  check sim1 == sim2

  sim1.writeCell Cell.Red
  check sim2.operate KeyEvent.init 'h'
  check sim1 == sim2

  sim1.writeCell Cell.Green
  check sim2.operate KeyEvent.init 'j'
  check sim1 == sim2

  sim1.writeCell Cell.Blue
  check sim2.operate KeyEvent.init 'k'
  check sim1 == sim2

  sim1.writeCell Cell.Yellow
  check sim2.operate KeyEvent.init 'l'
  check sim1 == sim2

  sim1.writeCell Cell.Purple
  check sim2.operate KeyEvent.init "Semicolon"
  check sim1 == sim2

  sim1.writeCell Garbage
  check sim2.operate KeyEvent.init 'o'
  check sim1 == sim2

  sim1.writeCell Hard
  check sim2.operate KeyEvent.init 'p'
  check sim1 == sim2

  sim1.writeCell None
  check sim2.operate KeyEvent.init "Space"
  check sim1 == sim2

  sim1.shiftFieldRight
  check sim2.operate KeyEvent.init 'D'
  check sim1 == sim2

  sim1.shiftFieldLeft
  check sim2.operate KeyEvent.init 'A'
  check sim1 == sim2

  sim1.shiftFieldUp
  check sim2.operate KeyEvent.init 'W'
  check sim1 == sim2

  sim1.shiftFieldDown
  check sim2.operate KeyEvent.init 'S'
  check sim1 == sim2

  sim1.flip
  check sim2.operate KeyEvent.init 'f'
  check sim1 == sim2

  sim1.undo
  check sim2.operate KeyEvent.init 'Z'
  check sim1 == sim2

  sim1.redo
  check sim2.operate KeyEvent.init 'Y'
  check sim1 == sim2

  sim1.forward
  check sim2.operate KeyEvent.init 'c'
  check sim1 == sim2

  sim1.backward(detail = true)
  check sim2.operate KeyEvent.init 'X'
  check sim1 == sim2

  sim1.backward
  check sim2.operate KeyEvent.init 'x'
  check sim1 == sim2

  sim1.reset
  check sim2.operate KeyEvent.init 'z'
  check sim1 == sim2

  check not sim2.operate KeyEvent.init 'v'
  check sim1 == sim2

  sim1.mode = ViewerPlay
  check sim2.operate KeyEvent.init 'm'
  check sim1 == sim2

  var
    sim3 = Simulator.init(nazo, Replay)
    sim4 = Simulator.init(nazo, Replay)
  check sim3 == sim4

  sim3.forward(replay = true)
  check sim4.operate KeyEvent.init 'c'
  check sim3 == sim4

  sim3.forward(replay = true)
  check sim4.operate KeyEvent.init 's'
  check sim3 == sim4

  sim3.backward(detail = true)
  check sim4.operate KeyEvent.init 'W'
  check sim3 == sim4

  sim3.backward(detail = true)
  check sim4.operate KeyEvent.init 'X'
  check sim3 == sim4

  sim3.backward
  check sim4.operate KeyEvent.init 'w'
  check sim3 == sim4

  sim3.backward
  check sim4.operate KeyEvent.init 'x'
  check sim3 == sim4

  sim3.reset
  check sim4.operate KeyEvent.init 'z'
  check sim3 == sim4

  check not sim4.operate KeyEvent.init 'Z'
  check sim3 == sim4

  var
    sim5 = Simulator.init(nazo, EditorEdit)
    sim6 = Simulator.init(nazo, EditorEdit)
  check sim5 == sim6

  sim5.rule = Water
  check sim6.operate KeyEvent.init 'r'
  check sim5 == sim6

  sim5.rule = Tsu
  check sim6.operate KeyEvent.init 'r'
  check sim5 == sim6

  sim5.toggleFocus
  check sim6.operate KeyEvent.init "Tab"
  check sim5 == sim6

  sim5.writeCell Garbage
  check sim6.operate KeyEvent.init 'o'
  check sim5 == sim6

  for i in 0 .. 9:
    sim5.writeCnt i
    check sim6.operate KeyEvent.init '0'.succ i
    check sim5 == sim6

# ------------------------------------------------
# Simulator <-> URI
# ------------------------------------------------

block: # toUri, parseSimulator
  block: # Nazo Puyo
    let
      sim = Simulator.init
      uriPon2 =
        "https://24ik.github.io/pon2/stable/studio/?field=t_&steps&goal=0_0_".parseUri
      uriIshikawa = "https://ishikawapuyo.net/simu/pn.html?___200".parseUri
      uriIps = "https://ips.karou.jp/simu/pn.html?___200".parseUri
      uriPon22 =
        "https://24ik.github.io/pon2/stable/studio/?mode=vp&field=t_&steps&goal=0_0_".parseUri
      uriPon23 =
        "http://24ik.github.io/pon2/stable/studio/?field=t_&steps&goal=0_0_".parseUri
      uriPon24 =
        "https://24ik.github.io/pon2/stable/studio/index.html?field=t_&steps&goal=0_0_".parseUri
      uriIshikawa2 = "http://ishikawapuyo.net/simu/pn.html?___200".parseUri
      uriIps2 = "http://ishikawapuyo.net/simu/pn.html?___200".parseUri

    check sim.toUri(fqdn = Pon2) == Res[Uri].ok uriPon2
    check sim.toUri(fqdn = Ishikawa) == Res[Uri].ok uriIshikawa
    check sim.toUri(fqdn = Ips) == Res[Uri].ok uriIps

    check uriPon2.parseSimulator == Res[Simulator].ok sim
    check uriIshikawa.parseSimulator == Res[Simulator].ok sim
    check uriIps.parseSimulator == Res[Simulator].ok sim
    check uriPon22.parseSimulator == Res[Simulator].ok sim
    check uriPon23.parseSimulator == Res[Simulator].ok sim
    check uriPon24.parseSimulator == Res[Simulator].ok sim
    check uriIshikawa2.parseSimulator == Res[Simulator].ok sim
    check uriIps2.parseSimulator == Res[Simulator].ok sim

  block: # Puyo Puyo
    let
      sim = Simulator.init PuyoPuyo[TsuField].init
      uriPon2 = "https://24ik.github.io/pon2/stable/studio/?field=t_&steps".parseUri
      uriIshikawa = "https://ishikawapuyo.net/simu/ps.html".parseUri
      uriIps = "https://ips.karou.jp/simu/ps.html".parseUri
      uriIshikawa2 = "https://ishikawapuyo.net/simu/ps.html?".parseUri

    check sim.toUri(fqdn = Pon2) == Res[Uri].ok uriPon2
    check sim.toUri(fqdn = Ishikawa) == Res[Uri].ok uriIshikawa
    check sim.toUri(fqdn = Ips) == Res[Uri].ok uriIps

    check uriPon2.parseSimulator == Res[Simulator].ok sim
    check uriIshikawa.parseSimulator == Res[Simulator].ok sim
    check uriIps.parseSimulator == Res[Simulator].ok sim
    check uriIshikawa2.parseSimulator == Res[Simulator].ok sim

  block: # clearPlacements
    let nazo = parseNazoPuyo[TsuField](
      """
6連鎖するべし
======
......
......
......
......
......
......
......
......
......
......
......
......
...b..
------
rb|1N
pp|
gy|23"""
    ).unsafeValue

    check Simulator.init(nazo).toUri(clearPlacements = true) ==
      Res[Uri].ok "https://24ik.github.io/pon2/stable/studio/?field=t_b..&steps=rbppgy&goal=5__6".parseUri

block: # toExportUri
  # EditorEdit
  block:
    var sim = Simulator.init EditorEdit
    sim.moveCursorUp
    sim.moveCursorUp
    sim.moveCursorLeft
    sim.writeCell Cell.Green
    sim.forward

    check sim.toUri ==
      Res[Uri].ok "https://24ik.github.io/pon2/stable/studio/?mode=ee&field=t_g&steps&goal=0_0_".parseUri
    check sim.toExportUri ==
      Res[Uri].ok "https://24ik.github.io/pon2/stable/studio/?field=t_g......&steps&goal=0_0_".parseUri
    check sim.toExportUri(viewer = false) ==
      Res[Uri].ok "https://24ik.github.io/pon2/stable/studio/?mode=ep&field=t_g......&steps&goal=0_0_".parseUri

  # ViewerEdit
  block:
    var sim = Simulator.init ViewerEdit
    sim.moveCursorUp
    sim.moveCursorUp
    sim.moveCursorLeft
    sim.writeCell Cell.Green
    sim.forward

    check sim.toExportUri ==
      Res[Uri].ok "https://24ik.github.io/pon2/stable/studio/?field=t_&steps&goal=0_0_".parseUri

  # ViewerPlay
  block:
    let nazo = parseNazoPuyo[TsuField](
      """
1連鎖するべし
======
......
......
......
......
......
......
......
......
......
......
......
......
......
------
rb|"""
    ).unsafeValue

    var sim = Simulator.init nazo
    sim.rotatePlacementRight
    sim.forward

    check sim.toUri ==
      Res[Uri].ok "https://24ik.github.io/pon2/stable/studio/?field=t_rb..&steps=rb34&goal=5__1".parseUri
    check sim.toExportUri ==
      Res[Uri].ok "https://24ik.github.io/pon2/stable/studio/?field=t_&steps=rb&goal=5__1".parseUri

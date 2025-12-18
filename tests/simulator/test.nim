{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, unittest, uri]
import ../../src/pon2/[core]
import ../../src/pon2/app/[key, simulator]
import ../../src/pon2/private/[algorithm, assign]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

block: # init
  check Simulator.init == Simulator.init NazoPuyo.init
  check Simulator.init(PuyoPuyo.init Rule.Water, EditEditor).mode == EditEditor

# ------------------------------------------------
# Edit - Undo / Redo
# ------------------------------------------------

block: # undo, redo
  var simulator = Simulator.init EditEditor

  simulator.writeCell Cell.Green
  let nazoPuyo1 = simulator.nazoPuyo

  simulator.undo
  check simulator.nazoPuyo == NazoPuyo.init

  simulator.undo
  check simulator.nazoPuyo == NazoPuyo.init

  simulator.redo
  check simulator.nazoPuyo == nazoPuyo1

  simulator.redo
  check simulator.nazoPuyo == nazoPuyo1

# ------------------------------------------------
# Property - Getter
# ------------------------------------------------

block:
  # rule, nazoPuyo, moveResult, mode, state, editData,
  # operatingPlacement, operatingIndex
  let simulator = Simulator.init

  check simulator.rule == Tsu
  check simulator.nazoPuyo == NazoPuyo.init
  check simulator.moveResult == MoveResult.init true
  check simulator.mode == PlayViewer
  check simulator.state == Stable
  check simulator.editData ==
    SimulatorEditData(
      editObj: SimulatorEditObj(kind: EditCell, cell: Cell.None),
      focusField: true,
      field: (Row.low, Col.low),
      step: (0, true, Col.low),
      insert: false,
    )
  check simulator.operatingPlacement == Up2
  check simulator.operatingIndex == 0

# ------------------------------------------------
# Property - Setter
# ------------------------------------------------

block: # `rule=`
  var simulator = Simulator.init EditEditor

  simulator.rule = Tsu
  check simulator.rule == Tsu
  check simulator.nazoPuyo == NazoPuyo.init

  simulator.rule = Water
  check simulator.rule == Water
  check simulator.nazoPuyo == NazoPuyo.init Rule.Water

  simulator.rule = Water
  check simulator.rule == Water
  check simulator.nazoPuyo == NazoPuyo.init Rule.Water

block: # `mode=`
  let nazoPuyo =
    """
ちょうど3連鎖するべし
======
[通]
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
py|""".parseNazoPuyo.unsafeValue

  block: # from PlayViewer
    let field0 = nazoPuyo.puyoPuyo.field

    var simulator = Simulator.init nazoPuyo
    simulator.forward
    simulator.mode = EditViewer

    check simulator.nazoPuyo.puyoPuyo.field == field0

  block: # from EditViewer
    let field0 = nazoPuyo.puyoPuyo.field

    var simulator = Simulator.init(nazoPuyo, EditViewer)
    simulator.forward
    simulator.mode = PlayViewer

    check simulator.nazoPuyo.puyoPuyo.field == field0

  block: # from PlayEditor
    let field0 = nazoPuyo.puyoPuyo.field

    var simulator = Simulator.init(nazoPuyo, PlayEditor)
    simulator.forward
    simulator.mode = EditEditor

    check simulator.nazoPuyo.puyoPuyo.field == field0

  block: # from EditEditor
    let field0 = nazoPuyo.puyoPuyo.field

    var simulator = Simulator.init(nazoPuyo, EditEditor)
    simulator.forward
    simulator.mode = PlayEditor

    check simulator.nazoPuyo.puyoPuyo.field == field0

block: # `editCell=`
  var simulator = Simulator.init EditViewer

  simulator.editCell = Cell.None
  check simulator.editData.editObj.cell == Cell.None

  simulator.editCell = Cell.Red
  check simulator.editData.editObj.cell == Cell.Red

  simulator.editCell = Garbage
  check simulator.editData.editObj.cell == Garbage

block: # `editCross=`
  var simulator = Simulator.init EditViewer

  simulator.editCross = true
  check simulator.editData.editObj.cross

  simulator.editCross = false
  check not simulator.editData.editObj.cross

# ------------------------------------------------
# Edit - Cursor
# ------------------------------------------------

block: # moveCursorUp, moveCursorDown, moveCursorRight, moveCursorLeft
  let nazoPuyo =
    """
ちょうど3連鎖するべし
======
[通]
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
py|""".parseNazoPuyo.unsafeValue
  var simulator = Simulator.init(nazoPuyo, EditEditor)

  simulator.moveCursorUp
  check simulator.editData.field == (Row12, Col0)

  simulator.moveCursorRight
  check simulator.editData.field == (Row12, Col1)

  simulator.moveCursorDown
  check simulator.editData.field == (Row0, Col1)

  simulator.moveCursorLeft
  check simulator.editData.field == (Row0, Col0)

  simulator.toggleFocus

  simulator.moveCursorUp
  check simulator.editData.step == (3, true, Col0)

  simulator.moveCursorRight
  check simulator.editData.step == (3, false, Col0)

  simulator.moveCursorUp
  check simulator.editData.step == (2, false, Col0)

  simulator.moveCursorUp
  check simulator.editData.step == (1, false, Col0)

  simulator.moveCursorLeft
  check simulator.editData.step == (1, false, Col5)

# ------------------------------------------------
# Edit - Delete
# ------------------------------------------------

block: # delStep
  let nazoPuyo =
    """
ちょうど3連鎖するべし
======
[通]
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
py|""".parseNazoPuyo.unsafeValue
  var
    steps = nazoPuyo.puyoPuyo.steps
    simulator = Simulator.init(nazoPuyo, EditEditor)

  simulator.delStep
  steps.del 0
  check simulator.nazoPuyo.puyoPuyo.steps == steps

  simulator.delStep 1
  steps.del 1
  check simulator.nazoPuyo.puyoPuyo.steps == steps

  simulator.delStep 1
  check simulator.nazoPuyo.puyoPuyo.steps == steps

# ------------------------------------------------
# Edit - Write
# ------------------------------------------------

block: # writeCell, writeRotate
  let nazoPuyo =
    """
ちょうど3連鎖するべし
======
[だいかいてん]
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
py|
R""".parseNazoPuyo.unsafeValue
  var
    field = nazoPuyo.puyoPuyo.field
    steps = nazoPuyo.puyoPuyo.steps
    simulator = Simulator.init(nazoPuyo, EditEditor)

  simulator.editCell = Green
  simulator.writeCell Row3, Col4
  field[Row3, Col4] = Green
  check simulator.nazoPuyo.puyoPuyo.field == field

  simulator.writeCell Blue
  field[Row0, Col0] = Blue
  check simulator.nazoPuyo.puyoPuyo.field == field

  simulator.editCross = true
  simulator.writeCell Row3, Col4
  check simulator.nazoPuyo.puyoPuyo.field == field

  simulator.toggleInsert

  simulator.editCell = Green
  simulator.writeCell Row6, Col4
  field.insert Row6, Col4, Green
  check simulator.nazoPuyo.puyoPuyo.field == field

  simulator.editCell = Cell.None
  simulator.writeCell Row8, Col4
  field.del Row8, Col4
  check simulator.nazoPuyo.puyoPuyo.field == field

  simulator.toggleFocus

  simulator.writeCell Yellow
  steps.insert Step.init(YellowYellow), 0
  check simulator.nazoPuyo.puyoPuyo.steps == steps

  simulator.writeCell Cell.None
  steps.del 0
  check simulator.nazoPuyo.puyoPuyo.steps == steps

  simulator.toggleInsert

  simulator.editCell = Blue
  simulator.writeCell 2, false
  steps[2].pair.rotor = Blue
  check simulator.nazoPuyo.puyoPuyo.steps == steps

  simulator.editCell = Garbage
  simulator.writeCell 1, false
  check simulator.nazoPuyo.puyoPuyo.steps == steps

  simulator.editCell = Hard
  simulator.writeCell 1, true
  steps[1].hard.assign true
  check simulator.nazoPuyo.puyoPuyo.steps == steps

  simulator.writeCell 2, true
  steps[2] = Step.init([0, 0, 0, 0, 0, 0], true)
  check simulator.nazoPuyo.puyoPuyo.steps == steps

  simulator.editCell = Purple
  simulator.writeCell 3, true
  steps[3] = Step.init PurplePurple
  check simulator.nazoPuyo.puyoPuyo.steps == steps

  simulator.editCell = Yellow
  simulator.writeCell 4, false
  steps.addLast Step.init YellowYellow
  check simulator.nazoPuyo.puyoPuyo.steps == steps

  simulator.editCross = false
  simulator.writeCell 2, true
  steps[2] = Step.init(cross = false)
  check simulator.nazoPuyo.puyoPuyo.steps == steps

  simulator.writeRotate(cross = false)
  steps[0] = Step.init(cross = false)
  check simulator.nazoPuyo.puyoPuyo.steps == steps

# ------------------------------------------------
# Edit - Shift / Flip
# ------------------------------------------------

block: # shiftFieldUp, shiftFieldDown, shiftFieldRight, shiftFieldLeft
  let nazoPuyo =
    """
ぷよ全て消すべし
======
[だいかいてん]
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
(0,1,2,3,4,5)
R""".parseNazoPuyo.unsafeValue
  var
    field = nazoPuyo.puyoPuyo.field
    steps = nazoPuyo.puyoPuyo.steps
    simulator = Simulator.init(nazoPuyo, EditEditor)

  simulator.shiftFieldUp
  field.shiftUp
  check simulator.nazoPuyo.puyoPuyo.field == field

  simulator.shiftFieldDown
  field.shiftDown
  check simulator.nazoPuyo.puyoPuyo.field == field

  simulator.shiftFieldRight
  field.shiftRight
  check simulator.nazoPuyo.puyoPuyo.field == field

  simulator.shiftFieldLeft
  field.shiftLeft
  check simulator.nazoPuyo.puyoPuyo.field == field

  simulator.flipFieldVertical
  field.flipVertical
  check simulator.nazoPuyo.puyoPuyo.field == field

  simulator.flipFieldHorizontal
  field.flipHorizontal
  check simulator.nazoPuyo.puyoPuyo.field == field

  simulator.flip
  field.flipHorizontal
  check simulator.nazoPuyo.puyoPuyo.field == field

  simulator.toggleFocus

  simulator.flip
  steps[0].pair.swap
  check simulator.nazoPuyo.puyoPuyo.steps == steps

  simulator.moveCursorDown
  simulator.flip
  steps[1].counts.reverse
  check simulator.nazoPuyo.puyoPuyo.steps == steps

  simulator.moveCursorDown
  simulator.moveCursorDown
  simulator.flip
  check simulator.nazoPuyo.puyoPuyo.steps == steps

# ------------------------------------------------
# Edit - Goal
# ------------------------------------------------

block:
  # normalizeGoal, `goalKindOpt=`, `goalColor=`, `goalVal=`, `goalOperator=`,
  # `goalClearColorOpt=`
  var simulator = Simulator.init(
    NazoPuyo.init(PuyoPuyo.init, Goal.init(Color, GoalColor.Red, 2, Exact)), EditEditor
  )
  simulator.normalizeGoal
  check simulator.nazoPuyo.goal == Goal.init(Color, 2, Exact)

  simulator.goalKindOpt = Opt[GoalKind].ok Chain
  check simulator.nazoPuyo.goal == Goal.init(Chain, 2, Exact)

  simulator.goalColor = GoalColor.Yellow
  check simulator.nazoPuyo.goal == Goal.init(Chain, 2, Exact)

  simulator.goalVal = 3
  check simulator.nazoPuyo.goal == Goal.init(Chain, 3, Exact)

  simulator.goalOperator = AtLeast
  check simulator.nazoPuyo.goal == Goal.init(Chain, 3, AtLeast)

  simulator.goalClearColorOpt = Opt[GoalColor].ok All
  check simulator.nazoPuyo.goal == Goal.init(Chain, 3, AtLeast, All)

  simulator.goalKindOpt = Opt[GoalKind].err
  check simulator.nazoPuyo.goal == Goal.init All

  simulator.goalColor = GoalColor.Red
  check simulator.nazoPuyo.goal == Goal.init All

  simulator.goalVal = 1
  check simulator.nazoPuyo.goal == Goal.init All

  simulator.goalOperator = AtLeast
  check simulator.nazoPuyo.goal == Goal.init All

  simulator.goalClearColorOpt = Opt[GoalColor].ok Colored
  check simulator.nazoPuyo.goal == Goal.init Colored

  simulator.goalClearColorOpt = Opt[GoalColor].err
  check simulator.nazoPuyo.goal == NoneGoal

# ------------------------------------------------
# Edit - Other
# ------------------------------------------------

block: # toggleFocus, toggleInsert
  var simulator = Simulator.init EditEditor

  simulator.toggleFocus
  check not simulator.editData.focusField

  simulator.toggleFocus
  check simulator.editData.focusField

  simulator.toggleInsert
  check simulator.editData.insert

  simulator.toggleInsert
  check not simulator.editData.insert

# ------------------------------------------------
# Play - Placement
# ------------------------------------------------

block:
  # movePlacementRight, movePlacementLeft, rotatePlacementRight, rotatePlacementLeft
  var
    simulator = Simulator.init
    placement = Up2

  check simulator.operatingPlacement == placement

  simulator.movePlacementRight
  placement.moveRight
  check simulator.operatingPlacement == placement

  simulator.movePlacementLeft
  placement.moveLeft
  check simulator.operatingPlacement == placement

  simulator.rotatePlacementRight
  placement.rotateRight
  check simulator.operatingPlacement == placement

  simulator.rotatePlacementLeft
  placement.rotateLeft
  check simulator.operatingPlacement == placement

# ------------------------------------------------
# Forward / Backward
# ------------------------------------------------

block: # forward, backward, reset
  block: # play
    let
      nazoPuyo0 =
        """
ちょうど3連鎖するべし
======
[だいかいてん]
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
rb|
R""".parseNazoPuyo.unsafeValue
      nazoPuyo0P =
        """
ちょうど3連鎖するべし
======
[だいかいてん]
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
rb|6N
R""".parseNazoPuyo.unsafeValue
      nazoPuyo1 =
        """
ちょうど3連鎖するべし
======
[だいかいてん]
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
rb|6N
R""".parseNazoPuyo.unsafeValue
      nazoPuyo2 =
        """
ちょうど3連鎖するべし
======
[だいかいてん]
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
rb|6N
R""".parseNazoPuyo.unsafeValue
      nazoPuyo3 =
        """
ちょうど3連鎖するべし
======
[だいかいてん]
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
rb|6N
R""".parseNazoPuyo.unsafeValue
      nazoPuyo4 =
        """
ちょうど3連鎖するべし
======
[だいかいてん]
......
bbogg.
..bgo.
...o..
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
rb|6N
R""".parseNazoPuyo.unsafeValue
      nazoPuyo5 =
        """
ちょうど3連鎖するべし
======
[だいかいてん]
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
...g..
..ogg.
bbboo.
------
rb|6N
R""".parseNazoPuyo.unsafeValue

      counts: array[Cell, int] = [0, 0, 2, 4, 0, 0, 0, 0]
      full: array[Cell, seq[int]] = [@[], @[], @[], @[4], @[], @[], @[], @[]]
      moveResult0 = MoveResult.init true
      moveResult1 = MoveResult.init true
      moveResult2 = MoveResult.init(1, counts, 0, @[counts], @[0], @[full])
      moveResult3 = moveResult2
      moveResult4 = MoveResult.init true
      moveResult5 = MoveResult.init true

    var simulator = Simulator.init nazoPuyo0
    check simulator.moveResult == moveResult0

    for _ in 1 .. 3:
      simulator.movePlacementRight
    simulator.forward
    check simulator.nazoPuyo == nazoPuyo1
    check simulator.moveResult == moveResult1

    simulator.forward
    check simulator.nazoPuyo == nazoPuyo2
    check simulator.moveResult == moveResult2

    simulator.forward
    check simulator.nazoPuyo == nazoPuyo3
    check simulator.moveResult == moveResult3

    simulator.forward
    check simulator.nazoPuyo == nazoPuyo4
    check simulator.moveResult == moveResult4

    simulator.forward
    check simulator.nazoPuyo == nazoPuyo5
    check simulator.moveResult == moveResult5

    simulator.forward
    check simulator.nazoPuyo == nazoPuyo5
    check simulator.moveResult == moveResult5

    simulator.forward(replay = true)
    check simulator.nazoPuyo == nazoPuyo5
    check simulator.moveResult == moveResult5

    simulator.forward(skip = true)
    check simulator.nazoPuyo == nazoPuyo5
    check simulator.moveResult == moveResult5

    simulator.backward
    check simulator.nazoPuyo == nazoPuyo3
    check simulator.moveResult == moveResult3

    simulator.backward(detail = true)
    check simulator.nazoPuyo == nazoPuyo2
    check simulator.moveResult == moveResult2

    simulator.backward(detail = true)
    check simulator.nazoPuyo == nazoPuyo1
    check simulator.moveResult == moveResult1

    simulator.backward(detail = true)
    check simulator.nazoPuyo == nazoPuyo0P
    check simulator.moveResult == moveResult0

    simulator.backward(detail = true)
    check simulator.nazoPuyo == nazoPuyo0P
    check simulator.moveResult == moveResult0

    simulator.backward
    check simulator.nazoPuyo == nazoPuyo0P
    check simulator.moveResult == moveResult0

    simulator.forward(replay = true)
    check simulator.nazoPuyo == nazoPuyo1
    check simulator.moveResult == moveResult1

    simulator.reset
    check simulator.nazoPuyo == nazoPuyo0P
    check simulator.moveResult == moveResult0

    simulator.forward(skip = true)
    check simulator.nazoPuyo == nazoPuyo0
    check simulator.moveResult == moveResult0

  block: # edit
    let nazoPuyo0 =
      """
ちょうど3連鎖するべし
======
[通]
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
rb|""".parseNazoPuyo.unsafeValue
    var
      field = nazoPuyo0.puyoPuyo.field
      simulator = Simulator.init(nazoPuyo0, EditEditor)
    let field0 = field
    check simulator.state == AfterEdit

    simulator.forward
    field.settle
    check simulator.state == WillPop
    check simulator.nazoPuyo.puyoPuyo.field == field

    simulator.forward
    discard field.pop
    check simulator.state == WillSettle
    check simulator.nazoPuyo.puyoPuyo.field == field

    simulator.backward
    check simulator.state == AfterEdit
    check simulator.nazoPuyo.puyoPuyo.field == field0

    for _ in 1 .. 3:
      simulator.forward
    simulator.reset
    check simulator.state == AfterEdit
    check simulator.nazoPuyo.puyoPuyo.field == field0

    simulator.forward
    simulator.forward

    simulator.writeCell Cell.Purple
    field[Row0, Col0] = Cell.Purple
    check simulator.state == AfterEdit
    check simulator.nazoPuyo.puyoPuyo.field == field

    simulator.forward
    field.settle
    check simulator.state == Stable
    check simulator.nazoPuyo.puyoPuyo.field == field

    simulator.forward
    check simulator.state == Stable
    check simulator.nazoPuyo.puyoPuyo.field == field

    simulator.writeCell Cell.Yellow
    field[Row0, Col0] = Cell.Yellow
    simulator.forward
    simulator.reset
    check simulator.state == AfterEdit
    check simulator.nazoPuyo.puyoPuyo.field == field

    simulator.backward
    check simulator.state == AfterEdit
    check simulator.nazoPuyo.puyoPuyo.field == field

# ------------------------------------------------
# Mark
# ------------------------------------------------

block: # mark
  let nazoPuyo =
    """
ちょうど1連鎖するべし
======
[通]
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
yy|""".parseNazoPuyo.unsafeValue
  var simulator = Simulator.init nazoPuyo
  check simulator.mark == Incorrect

  simulator.movePlacementRight
  simulator.movePlacementRight
  simulator.movePlacementRight
  simulator.forward
  while simulator.state != Stable:
    simulator.forward
  check simulator.mark == Incorrect

  simulator.forward
  while simulator.state != Stable:
    simulator.forward
  check simulator.mark == Correct

  simulator.backward
  check simulator.mark == Incorrect

  simulator.backward
  check simulator.mark == Incorrect

  simulator.movePlacementLeft
  simulator.forward
  while simulator.state != Stable:
    simulator.forward
  check simulator.mark == Correct

  simulator.forward
  while simulator.state != Stable:
    simulator.forward
  check simulator.mark == Correct

  simulator.backward
  check simulator.mark == Correct

  simulator.backward
  check simulator.mark == Incorrect

  check Simulator.init(PuyoPuyo.init).mark == NotSupport

# ------------------------------------------------
# Keyboard
# ------------------------------------------------

block: # operate
  let nazoPuyo =
    """
ちょうど1連鎖するべし
======
[通]
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
pp|23""".parseNazoPuyo.unsafeValue
  var
    simulator1 = Simulator.init nazoPuyo
    simulator2 = Simulator.init nazoPuyo
  check simulator1 == simulator2

  simulator1.rotatePlacementLeft
  check simulator2.operate KeyEventJ
  check simulator1 == simulator2

  simulator1.rotatePlacementRight
  check simulator2.operate KeyEventK
  check simulator1 == simulator2

  simulator1.movePlacementLeft
  check simulator2.operate KeyEventA
  check simulator1 == simulator2

  simulator1.movePlacementRight
  check simulator2.operate KeyEventD
  check simulator1 == simulator2

  simulator1.forward
  check simulator2.operate KeyEventS
  check simulator1 == simulator2

  simulator1.forward(replay = true)
  check simulator2.operate KeyEventC
  check simulator1 == simulator2

  simulator1.forward(skip = true)
  check simulator2.operate KeyEventSpace
  check simulator1 == simulator2

  simulator1.backward
  check simulator2.operate KeyEventW
  check simulator1 == simulator2

  simulator1.backward
  check simulator2.operate KeyEventX
  check simulator1 == simulator2

  simulator1.reset
  check simulator2.operate KeyEventZ
  check simulator1 == simulator2

  check not simulator2.operate KeyEventTab
  check simulator1 == simulator2

  simulator1.mode = EditViewer
  check simulator2.operate KeyEventT
  check simulator1 == simulator2

  simulator1.toggleInsert
  check simulator2.operate KeyEventG
  check simulator1 == simulator2

  simulator1.toggleFocus
  check simulator2.operate KeyEventTab
  check simulator1 == simulator2

  simulator1.moveCursorRight
  check simulator2.operate KeyEventD
  check simulator1 == simulator2

  simulator1.moveCursorLeft
  check simulator2.operate KeyEventA
  check simulator1 == simulator2

  simulator1.moveCursorUp
  check simulator2.operate KeyEventW
  check simulator1 == simulator2

  simulator1.moveCursorDown
  check simulator2.operate KeyEventS
  check simulator1 == simulator2

  simulator1.writeCell Cell.Red
  check simulator2.operate KeyEventH
  check simulator1 == simulator2

  simulator1.writeCell Cell.Green
  check simulator2.operate KeyEventJ
  check simulator1 == simulator2

  simulator1.writeCell Cell.Blue
  check simulator2.operate KeyEventK
  check simulator1 == simulator2

  simulator1.writeCell Cell.Yellow
  check simulator2.operate KeyEventL
  check simulator1 == simulator2

  simulator1.writeCell Cell.Purple
  check simulator2.operate KeyEventSemicolon
  check simulator1 == simulator2

  simulator1.writeCell Garbage
  check simulator2.operate KeyEventO
  check simulator1 == simulator2

  simulator1.writeCell Hard
  check simulator2.operate KeyEventP
  check simulator1 == simulator2

  simulator1.writeCell Cell.None
  check simulator2.operate KeyEventSpace
  check simulator1 == simulator2

  simulator1.writeRotate(cross = false)
  check simulator2.operate KeyEventN
  check simulator1 == simulator2

  simulator1.writeRotate(cross = true)
  check simulator2.operate KeyEventM
  check simulator1 == simulator2

  simulator1.shiftFieldRight
  check simulator2.operate KeyEventShiftD
  check simulator1 == simulator2

  simulator1.shiftFieldLeft
  check simulator2.operate KeyEventShiftA
  check simulator1 == simulator2

  simulator1.shiftFieldUp
  check simulator2.operate KeyEventShiftW
  check simulator1 == simulator2

  simulator1.shiftFieldDown
  check simulator2.operate KeyEventShiftS
  check simulator1 == simulator2

  simulator1.flip
  check simulator2.operate KeyEventF
  check simulator1 == simulator2

  simulator1.undo
  check simulator2.operate KeyEventShiftZ
  check simulator1 == simulator2

  simulator1.redo
  check simulator2.operate KeyEventShiftX
  check simulator1 == simulator2

  simulator1.forward
  check simulator2.operate KeyEventC
  check simulator1 == simulator2

  simulator1.backward
  check simulator2.operate KeyEventX
  check simulator1 == simulator2

  simulator1.reset
  check simulator2.operate KeyEventZ
  check simulator1 == simulator2

  check not simulator2.operate KeyEventV
  check simulator1 == simulator2

  simulator1.mode = PlayViewer
  check simulator2.operate KeyEventT
  check simulator1 == simulator2

  var
    simulator3 = Simulator.init(nazoPuyo, Replay)
    simulator4 = Simulator.init(nazoPuyo, Replay)
  check simulator3 == simulator4

  simulator3.forward(replay = true)
  check simulator4.operate KeyEventC
  check simulator3 == simulator4

  simulator3.reset
  check simulator4.operate KeyEventShiftW
  check simulator3 == simulator4

  simulator3.forward(replay = true)
  check simulator4.operate KeyEventS
  check simulator3 == simulator4

  simulator3.backward
  check simulator4.operate KeyEventW
  check simulator3 == simulator4

  simulator3.backward
  check simulator4.operate KeyEventX
  check simulator3 == simulator4

  simulator3.reset
  check simulator4.operate KeyEventZ
  check simulator3 == simulator4

  check not simulator4.operate KeyEventShiftZ
  check simulator3 == simulator4

  var
    simulator5 = Simulator.init(nazoPuyo, EditEditor)
    simulator6 = Simulator.init(nazoPuyo, EditEditor)
  check simulator5 == simulator6

  simulator5.rule = Water
  check simulator6.operate KeyEventE
  check simulator5 == simulator6

  simulator5.rule = Tsu
  check simulator6.operate KeyEventR
  check simulator5 == simulator6

  simulator5.toggleFocus
  check simulator6.operate KeyEventTab
  check simulator5 == simulator6

  simulator5.writeCell Garbage
  check simulator6.operate KeyEventO
  check simulator5 == simulator6

  for digit in 0 .. 9:
    simulator5.writeCount digit
    check simulator6.operate KeyEvent.init "Digit{digit}".fmt
    check simulator5 == simulator6

# ------------------------------------------------
# Simulator <-> URI
# ------------------------------------------------

block: # toUri, parseSimulator
  block: # Nazo Puyo
    let
      simulator = Simulator.init NazoPuyo.init(PuyoPuyo.init, Goal.init All)
      uriPon2 =
        "https://24ik.github.io/pon2/stable/studio/?mode=0&field=0_&steps&goal=_0".parseUri
      uriIshikawa = "https://ishikawapuyo.net/simu/pn.html?___200".parseUri
      uriIps = "https://ips.karou.jp/simu/pn.html?___200".parseUri
      uriPon22 =
        "https://24ik.github.io/pon2/stable/studio/?field=0_&steps&goal=_0".parseUri
      uriPon23 =
        "https://24ik.github.io/pon2/stable/studio/index.html?mode=0&field=0_&steps&goal=_0".parseUri
      uriIshikawa2 = "http://ishikawapuyo.net/simu/pn.html?___200".parseUri
      uriIshikawa3 = "http://ishikawapuyo.net/simu/pn.html?__200".parseUri
      uriIps2 = "http://ishikawapuyo.net/simu/pn.html?___200".parseUri

    check simulator.toUri(fqdn = Pon2) == Pon2Result[Uri].ok uriPon2
    check simulator.toUri(fqdn = IshikawaPuyo) == Pon2Result[Uri].ok uriIshikawa
    check simulator.toUri(fqdn = Ips) == Pon2Result[Uri].ok uriIps

    check uriPon2.parseSimulator == Pon2Result[Simulator].ok simulator
    check uriIshikawa.parseSimulator == Pon2Result[Simulator].ok simulator
    check uriIps.parseSimulator == Pon2Result[Simulator].ok simulator
    check uriPon22.parseSimulator == Pon2Result[Simulator].ok simulator
    check uriPon23.parseSimulator == Pon2Result[Simulator].ok simulator
    check uriIshikawa2.parseSimulator == Pon2Result[Simulator].ok simulator
    check uriIshikawa3.parseSimulator == Pon2Result[Simulator].ok simulator
    check uriIps2.parseSimulator == Pon2Result[Simulator].ok simulator

  block: # Puyo Puyo
    let
      simulator = Simulator.init PuyoPuyo.init
      uriPon2 =
        "https://24ik.github.io/pon2/stable/studio/?mode=0&field=0_&steps&goal=_".parseUri
      uriIshikawa = "https://ishikawapuyo.net/simu/ps.html?___".parseUri
      uriIps = "https://ips.karou.jp/simu/ps.html?___".parseUri
      uriPon22 =
        "https://24ik.github.io/pon2/stable/studio/?mode=0&field=0_&steps&goal=".parseUri
      uriPon23 =
        "https://24ik.github.io/pon2/stable/studio/?mode=0&field=0_&steps&goal".parseUri
      uriPon24 =
        "https://24ik.github.io/pon2/stable/studio/?mode=0&field=0_&steps".parseUri
      uriIshikawa2 = "https://ishikawapuyo.net/simu/ps.html?__".parseUri
      uriIshikawa3 = "https://ishikawapuyo.net/simu/ps.html?_".parseUri
      uriIshikawa4 = "https://ishikawapuyo.net/simu/ps.html?".parseUri
      uriIshikawa5 = "https://ishikawapuyo.net/simu/ps.html".parseUri
      uriIshikawa6 = "https://ishikawapuyo.net/simu/pn.html".parseUri

    check simulator.toUri(fqdn = Pon2) == Pon2Result[Uri].ok uriPon2
    check simulator.toUri(fqdn = IshikawaPuyo) == Pon2Result[Uri].ok uriIshikawa
    check simulator.toUri(fqdn = Ips) == Pon2Result[Uri].ok uriIps

    check uriPon2.parseSimulator == Pon2Result[Simulator].ok simulator
    check uriIshikawa.parseSimulator == Pon2Result[Simulator].ok simulator
    check uriIps.parseSimulator == Pon2Result[Simulator].ok simulator
    check uriPon22.parseSimulator == Pon2Result[Simulator].ok simulator
    check uriPon23.parseSimulator == Pon2Result[Simulator].ok simulator
    check uriPon24.parseSimulator == Pon2Result[Simulator].ok simulator
    check uriIshikawa2.parseSimulator == Pon2Result[Simulator].ok simulator
    check uriIshikawa3.parseSimulator == Pon2Result[Simulator].ok simulator
    check uriIshikawa4.parseSimulator == Pon2Result[Simulator].ok simulator
    check uriIshikawa5.parseSimulator == Pon2Result[Simulator].ok simulator
    check uriIshikawa6.parseSimulator == Pon2Result[Simulator].ok simulator

  block: # clearPlacements
    let nazoPuyo =
      """
ちょうど6連鎖するべし
======
[通]
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
gy|23""".parseNazoPuyo.unsafeValue

    check Simulator.init(nazoPuyo).toUri(clearPlacements = true) ==
      Pon2Result[Uri].ok "https://24ik.github.io/pon2/stable/studio/?mode=0&field=0_b..&steps=rbppgy&goal=0_0_6_0_".parseUri

block: # toExportUri
  # EditEditor
  block:
    var simulator = Simulator.init EditEditor
    simulator.moveCursorUp
    simulator.moveCursorUp
    simulator.moveCursorLeft
    simulator.writeCell Cell.Green
    simulator.forward

    check simulator.toUri ==
      Pon2Result[Uri].ok "https://24ik.github.io/pon2/stable/studio/?mode=3&field=0_g&steps&goal=_".parseUri
    check simulator.toExportUri ==
      Pon2Result[Uri].ok "https://24ik.github.io/pon2/stable/studio/?mode=0&field=0_g......&steps&goal=_".parseUri
    check simulator.toExportUri(viewer = false) ==
      Pon2Result[Uri].ok "https://24ik.github.io/pon2/stable/studio/?mode=1&field=0_g......&steps&goal=_".parseUri

  # EditViewer
  block:
    var simulator = Simulator.init EditViewer
    simulator.moveCursorUp
    simulator.moveCursorUp
    simulator.moveCursorLeft
    simulator.writeCell Cell.Green
    simulator.forward

    check simulator.toExportUri ==
      Pon2Result[Uri].ok "https://24ik.github.io/pon2/stable/studio/?mode=0&field=0_&steps&goal=_".parseUri

  # PlayViewer
  block:
    let nazoPuyo =
      """
ちょうど1連鎖するべし
======
[通]
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
rb|""".parseNazoPuyo.unsafeValue

    var simulator = Simulator.init nazoPuyo
    simulator.rotatePlacementRight
    simulator.forward

    check simulator.toUri ==
      Pon2Result[Uri].ok "https://24ik.github.io/pon2/stable/studio/?mode=0&field=0_rb..&steps=rb34&goal=0_0_1_0_".parseUri
    check simulator.toExportUri ==
      Pon2Result[Uri].ok "https://24ik.github.io/pon2/stable/studio/?mode=0&field=0_&steps=rb&goal=0_0_1_0_".parseUri
    check simulator.toExportUri(clearPlacements = false) ==
      Pon2Result[Uri].ok "https://24ik.github.io/pon2/stable/studio/?mode=0&field=0_&steps=rb34&goal=0_0_1_0_".parseUri

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strutils, unittest]
import ../../src/pon2/core/[cell, field, fieldtype, pair, pairposition, position, rule]

proc main*() =
  # ------------------------------------------------
  # Convert
  # ------------------------------------------------

  # toTsuField, toWaterField
  block:
    let
      str = "......\n".repeat(12) & "rgbypo"
      tsuField = parseField[TsuField](str)
      waterField = parseField[WaterField](str)

    check tsuField.toWaterField == waterField
    check waterField.toTsuField == tsuField

    check tsuField.toTsuField == tsuField
    check waterField.toWaterField == waterField

  # ------------------------------------------------
  # Indexer
  # ------------------------------------------------

  # [], []=
  block:
    var field = parseField[TsuField]("......\n".repeat(12) & "g.r...")
    check field[12, 1] == Cell.None
    check field[12, 2] == Red

    field[12, 2] = Yellow
    check field[12, 2] == Yellow

  # ------------------------------------------------
  # Insert / RemoveSqueeze
  # ------------------------------------------------

  # insert, removeSqueeze
  block:
    # tsu
    block:
      let
        field1 = parseField[TsuField]("......\n".repeat(12) & "o.....")
        field2 = parseField[TsuField]("......\n".repeat(11) & "r.....\no.....")
        field3 = parseField[TsuField]("......\n".repeat(10) & "r.....\ng.....\no.....")

      var field = field1
      field.insert 11, 0, Red
      check field == field2

      field.insert 11, 0, Green
      check field == field3

      field.removeSqueeze 11, 0
      check field == field2

      field.removeSqueeze 11, 0
      check field == field1

    # water
    block:
      let
        field1 = parseField[WaterField](
          "......\n".repeat(4) & "r.....\ng.....\n" & "......\n".repeat(7)[0 ..^ 2]
        )
        field2 = parseField[WaterField](
          "......\n".repeat(3) & "b.....\nr.....\ng.....\n" &
            "......\n".repeat(7)[0 ..^ 2]
        )
        field3 = parseField[WaterField](
          "......\n".repeat(2) & "b.....\ny.....\nr.....\ng.....\n" &
            "......\n".repeat(7)[0 ..^ 2]
        )
        field4 = parseField[WaterField](
          "......\n".repeat(2) & "b.....\ny.....\nr.....\ng.....\np.....\n" &
            "......\n".repeat(6)[0 ..^ 2]
        )
        field5 = parseField[WaterField](
          "......\n".repeat(2) & "b.....\ny.....\nr.....\ng.....\no.....\np.....\n" &
            "......\n".repeat(5)[0 ..^ 2]
        )

      var field = field1
      field.insert 3, 0, Blue
      check field == field2

      field.insert 3, 0, Yellow
      check field == field3

      field.insert 6, 0, Purple
      check field == field4

      field.insert 6, 0, Garbage
      check field == field5

      field.removeSqueeze 6, 0
      check field == field4

      field.removeSqueeze 6, 0
      check field == field3

      field.removeSqueeze 3, 0
      check field == field2

      field.removeSqueeze 3, 0
      check field == field1

  # ------------------------------------------------
  # Connect
  # ------------------------------------------------

  # connect2
  block:
    let
      fieldTop = "p.....\np.....\n" & "......\n".repeat 6
      fieldTopEmpty = "......\n".repeat 8
      fieldBottom =
        """
bbbrry
yggbgy
ygbbgg
yrbyyy
bbrggy"""
      two =
        """
...rry
.....y
......
......
bb.gg."""
      twoV =
        """
.....y
.....y
......
......
......"""
      twoH =
        """
...rr.
......
......
......
bb.gg."""

    let field = parseField[TsuField](fieldTop & fieldBottom)
    check field.connect2 == parseField[TsuField](fieldTopEmpty & two)
    check field.connect2V == parseField[TsuField](fieldTopEmpty & twoV)
    check field.connect2H == parseField[TsuField](fieldTopEmpty & twoH)

  # connect3
  block:
    let
      fieldTop = "pp....\np.....\n" & "......\n".repeat 6
      fieldTopEmpty = "......\n".repeat 8
      fieldBottom =
        """
bbbbrr
rggyyr
rgbbbr
ryyygb
ybybbb"""
      three =
        """
......
rgg...
rgbbb.
r.....
......"""
      threeV =
        """
......
r.....
r.....
r.....
......"""
      threeH =
        """
......
......
..bbb.
......
......"""
      threeL =
        """
......
.gg...
.g....
......
......"""

    let field = parseField[TsuField](fieldTop & fieldBottom)
    check field.connect3 == parseField[TsuField](fieldTopEmpty & three)
    check field.connect3V == parseField[TsuField](fieldTopEmpty & threeV)
    check field.connect3H == parseField[TsuField](fieldTopEmpty & threeH)
    check field.connect3L == parseField[TsuField](fieldTopEmpty & threeL)

  # ------------------------------------------------
  # Shift
  # ------------------------------------------------

  # shift
  block:
    var field1 = parseField[TsuField]("......\n".repeat(12) & "..o...")
    let field2 = parseField[TsuField]("......\n".repeat(12) & "...o..")
    let field3 = parseField[TsuField]("......\n".repeat(11) & "...o..\n......")

    check field2.shiftedLeft == field1
    check field1.shiftedRight == field2
    check field2.shiftedUp == field3
    check field3.shiftedDown == field2

    field1.shiftRight
    check field1 == field2

    field1.shiftUp
    check field1 == field3

  # ------------------------------------------------
  # Flip
  # ------------------------------------------------

  # flip
  block:
    let
      field1 = parseField[TsuField]("......\n".repeat(11) & "....rg\n.by...")
      field2 = parseField[TsuField](".by...\n....rg\n" & "......\n".repeat(11)[0 .. ^2])
      field3 = parseField[TsuField]("......\n".repeat(11) & "gr....\n...yb.")

    check field1.flippedV == field2
    check field1.flippedH == field3

    block:
      var field = field1
      field.flipV
      check field == field2
    block:
      var field = field1
      field.flipH
      check field == field3

  # ------------------------------------------------
  # Disappear
  # ------------------------------------------------

  # disappear
  block:
    var field = initField[TsuField]()
    field[0, 5] = Green
    field[1, 5] = Green
    field[2, 5] = Green
    field[3, 5] = Green
    field[0, 4] = Garbage
    field[1, 4] = Garbage
    check field.colorCount == 4
    check field.garbageCount == 2

    field.disappear
    check field.colorCount == 4
    check field.garbageCount == 2

    field[4, 5] = Green
    check field.colorCount == 5
    check field.garbageCount == 2

    field.disappear
    check field.colorCount == 1
    check field.garbageCount == 1

  # willDisappear
  block:
    var field = initField[TsuField]()
    field[0, 0] = Blue
    field[1, 0] = Blue
    field[2, 0] = Blue
    field[2, 1] = Blue
    check not field.willDisappear

    field[3, 1] = Blue
    check field.willDisappear

  # ------------------------------------------------
  # Operation
  # ------------------------------------------------

  # put
  block:
    # Tsu
    block:
      var field = initField[TsuField]()
      field.put RedGreen, Right1
      check field == parseField[TsuField]("......\n".repeat(12) & ".rg...")
      field.put BlueYellow, Left3
      check field == parseField[TsuField]("......\n".repeat(11) & "..y...\n.rgb..")
      field.put PairPosition(pair: RedPurple, position: Up3)
      check field ==
        parseField[TsuField]("......\n".repeat(10) & "...p..\n..yr..\n.rgb..")

    # ghost, row-14
    block:
      var field = parseField[TsuField](
        """
......
o.....
o.....
o.....
o.....
o.....
o.....
o.....
o.....
o.....
o.....
o.....
o....."""
      )
      field.put RedGreen, Up0
      check field ==
        parseField[TsuField](
          """
r.....
o.....
o.....
o.....
o.....
o.....
o.....
o.....
o.....
o.....
o.....
o.....
o....."""
        )

    # Water
    block:
      var field = parseField[WaterField](
        """
......
......
......
......
......
....o.
....o.
....o.
....o.
....o.
....o.
......
......"""
      )
      field.put RedGreen, Left4
      check field ==
        parseField[WaterField](
          """
......
......
......
......
......
...gr.
....o.
....o.
....o.
....o.
....o.
....o.
......"""
        )
      field.put BlueYellow, Down4
      check field ==
        parseField[WaterField](
          """
......
......
......
......
....b.
...gy.
....r.
....o.
....o.
....o.
....o.
....o.
....o."""
        )

  # drop
  block:
    # Tsu
    block:
      var field = parseField[TsuField](
        """
oo....
oo....
oo....
o.....
o.....
oo....
oo....
oo....
o.o...
oooo..
ooo...
ooo...
o.oo.."""
      )
      field.drop
      check field ==
        parseField[TsuField](
          """
o.....
o.....
o.....
o.....
oo....
oo....
oo....
oo....
ooo...
ooo...
ooo...
oooo..
oooo.."""
        )

    # Water
    block:
      var field = parseField[WaterField](
        """
....o.
....o.
...oo.
..o...
......
o...o.
oo.oo.
......
.o.oo.
....o.
.o..o.
......
....o."""
      )
      field.drop
      check field ==
        parseField[WaterField](
          """
......
......
......
......
....o.
ooooo.
oo.oo.
.o.oo.
....o.
....o.
....o.
....o.
....o."""
        )

  # ------------------------------------------------
  # Property
  # ------------------------------------------------

  # rule
  block:
    check initField[TsuField]().rule == Tsu
    check initField[WaterField]().rule == Water

  # isDead
  block:
    # Tsu
    block:
      var field = initField[TsuField]()
      field[1, 2] = Blue
      check field.isDead

      for row in Row.low .. Row.high:
        for col in Column.low .. Column.high:
          field[row, col] = Blue
      field[1, 2] = Cell.None
      check not field.isDead

    # Water
    block:
      var field = initField[WaterField]()
      field[WaterRow.low.pred, 3] = Blue
      check field.isDead

      field = initField[WaterField]()
      for row in Row.low .. Row.high:
        if row != WaterRow.low.pred:
          for col in Column.low .. Column.high:
            field[row, col] = Blue
      check not field.isDead

  # ------------------------------------------------
  # Count - None
  # ------------------------------------------------

  # noneCount
  block:
    var field = initField[TsuField]()
    check field.noneCount == Height * Width

    field[1, 3] = Blue
    field[2, 2] = Red
    field[3, 1] = Garbage
    check field.noneCount == Height * Width - 3

  # ------------------------------------------------
  # Position
  # ------------------------------------------------

  # invalidPositions, validPositions, validDoublePositions
  block:
    var field = initField[TsuField]()
    field[12, 1] = Red
    check field.invalidPositions.card == 0
    check field.validPositions == AllPositions
    check field.validDoublePositions == AllDoublePositions

    field[1, 1] = Red
    check field.invalidPositions ==
      {Up0, Right0, Down0, Up1, Right1, Down1, Left1, Left2}

    field[2, 5] = Red
    check field.invalidPositions == {Down1}

    field[2, 5] = Cell.None
    field[1, 3] = Red
    check field.invalidPositions == {Down1, Down3}

    field[0, 1] = Red
    check field.invalidPositions ==
      {Up0, Right0, Down0, Up1, Right1, Down1, Left1, Left2, Down3}

    field = initField[TsuField]()
    field[1, 1] = Red
    field[2, 2] = Red
    field[1, 3] = Red
    field[0, 4] = Red
    check field.invalidPositions ==
      {Down1, Right3, Down3, Up4, Right4, Down4, Left4, Up5, Down5, Left5}

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[setutils, strutils, unittest]
import ../../src/pon2pkg/corepkg/[cell, field {.all.}, misc, pair, position]

proc main* =
  # ------------------------------------------------
  # Convert
  # ------------------------------------------------

  # toTsuField, toWaterField
  block:
    let
      str = "......\n".repeat(12) & "rgbypo"
      tsuField = str.parseTsuField
      waterField = str.parseWaterField

    check tsuField.toWaterField == waterField
    check waterField.toTsuField == tsuField

  # ------------------------------------------------
  # Indexer
  # ------------------------------------------------

  # [], []=
  block:
    var field = parseTsuField "......\n".repeat(12) & "g.r..."
    check field[12, 1] == None
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
        field1 = parseTsuField "......\n".repeat(12) & "o....."
        field2 = parseTsuField "......\n".repeat(11) & "r.....\no....."
        field3 = parseTsuField "......\n".repeat(10) & "r.....\ng.....\no....."

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
        field1 = parseWaterField "......\n".repeat(4) & "r.....\ng.....\n" &
          "......\n".repeat(7)[0..^2]
        field2 = parseWaterField "......\n".repeat(3) &
          "b.....\nr.....\ng.....\n" & "......\n".repeat(7)[0..^2]
        field3 = parseWaterField "......\n".repeat(2) &
          "b.....\ny.....\nr.....\ng.....\n" & "......\n".repeat(7)[0..^2]
        field4 = parseWaterField "......\n".repeat(2) &
          "b.....\ny.....\nr.....\ng.....\np.....\n" &
          "......\n".repeat(6)[0..^2]
        field5 = parseWaterField "......\n".repeat(2) &
          "b.....\ny.....\nr.....\ng.....\no.....\np.....\n" &
          "......\n".repeat(5)[0..^2]

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

  # connect3
  block:
    let
      fieldTop = "......\n".repeat 8
      fieldBottom = """
bbbbrr
rggyyr
rgbbbr
ryyygb
ybybbb"""
      three = """
......
rgg...
rgbbb.
r.....
......"""
      threeV = """
......
r.....
r.....
r.....
......"""
      threeH = """
......
......
..bbb.
......
......"""
      threeL = """
......
.gg...
.g....
......
......"""

    let field = parseTsuField fieldTop & fieldBottom
    check field.connect3 == parseTsuField fieldTop & three
    check field.connect3V == parseTsuField fieldTop & threeV
    check field.connect3H == parseTsuField fieldTop & threeH
    check field.connect3L == parseTsuField fieldTop & threeL

  # ------------------------------------------------
  # Shift
  # ------------------------------------------------

  # shift
  block:
    var field1 = parseTsuField "......\n".repeat(12) & "..o..."
    let field2 = parseTsuField "......\n".repeat(12) & "...o.."
    let field3 = parseTsuField "......\n".repeat(11) & "...o..\n......"

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
      field1 = parseTsuField "......\n".repeat(11) & "....rg\n.by..."
      field2 = parseTsuField ".by...\n....rg\n" & "......\n".repeat(11)[0 .. ^2]
      field3 = parseTsuField "......\n".repeat(11) & "gr....\n...yb."

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

  # willDisappear
  block:
    var field = zeroTsuField()
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
      var field = zeroTsuField()
      field.put RedGreen, Right1
      check field == parseTsuField "......\n".repeat(12) & ".rg..."
      field.put BlueYellow, Left3
      check field == parseTsuField "......\n".repeat(11) & "..y...\n.rgb.."
      field.put RedPurple, Up3
      check field == parseTsuField "......\n".repeat(10) &
        "...p..\n..yr..\n.rgb.."

    # ghost, row-14
    block:
      var field = parseTsuField """
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
      field.put RedGreen, Up0
      check field == parseTsuField """
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

    # Water
    block:
      var field = parseWaterField """
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
      field.put RedGreen, Left4
      check field == parseWaterField """
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
      field.put BlueYellow, Down4
      check field == parseWaterField """
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

  # drop
  block:
    # Tsu
    block:
      var field = parseTsuField """
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
      field.drop
      check field == parseTsuField """
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

    # Water
    block:
      var field = parseWaterField """
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
      field.drop
      check field == parseWaterField """
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

  # ------------------------------------------------
  # Property
  # ------------------------------------------------

  # rule
  block:
    check zeroTsuField().rule == Tsu
    check zeroWaterField().rule == Water

  # isDead
  block:
    # Tsu
    block:
      var field = zeroTsuField()
      field[1, 2] = Blue
      check field.isDead

      for row in Row.low..Row.high:
        for col in Column.low..Column.high:
          field[row, col] = Blue
      field[1, 2] = None
      check not field.isDead

    # Water
    block:
      var field = zeroWaterField()
      field[WaterRow.low.pred, 3] = Blue
      check field.isDead

      field = zeroWaterField()
      for row in Row.low..Row.high:
        if row != WaterRow.low.pred:
          for col in Column.low..Column.high:
            field[row, col] = Blue
      check not field.isDead

  # ------------------------------------------------
  # Flatten
  # ------------------------------------------------

  # flattenAnd
  block:
    let
      str = "......\n".repeat(12) & "r....."
      tsuField = str.parseTsuField
      waterField = str.parseWaterField
    var fields = Fields(rule: Tsu, tsu: tsuField, water: waterField)

    fields.flattenAnd:
      check field.type is TsuField

    fields.rule = Water
    fields.flattenAnd:
      check field.type is WaterField

  # ------------------------------------------------
  # Count - None
  # ------------------------------------------------

  # noneCount
  block:
    var field = zeroTsuField()
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
    var field = zeroTsuField()
    field[12, 1] = Red
    check field.invalidPositions.card == 0
    check field.validPositions == Position.fullSet
    check field.validDoublePositions == DoublePositions

    field[1, 1] = Red
    check field.invalidPositions == {Up0, Right0, Down0, Up1, Right1, Down1,
                                     Left1, Left2}

    field[2, 5] = Red
    check field.invalidPositions == {Down1}

    field[2, 5] = None
    field[1, 3] = Red
    check field.invalidPositions == {Down1, Down3}

    field[0, 1] = Red
    check field.invalidPositions == {Up0, Right0, Down0, Up1, Right1, Down1,
                                     Left1, Left2, Down3}

    field = zeroField[TsuField]()
    field[1, 1] = Red
    field[2, 2] = Red
    field[1, 3] = Red
    field[0, 4] = Red
    check field.invalidPositions == {Down1, Right3, Down3, Up4, Right4, Down4,
                                     Left4, Up5, Down5, Left5}

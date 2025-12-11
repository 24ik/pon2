{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import
  ../../src/pon2/core/[
    cell, common, field, fqdn, moveresult, pair, placement, popresult, puyopuyo, rule,
    step,
  ]
import ../../src/pon2/private/[arrayutils, strutils]
import ../../src/pon2/private/core/[binaryfield]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

block: # init
  let
    fieldW = Field.init Rule.Water
    steps = [Step.init RedGreen].toDeque

  check PuyoPuyo.init(fieldW, steps) == PuyoPuyo(field: fieldW, steps: steps)
  check PuyoPuyo.init(CrossSpinner) == PuyoPuyo.init(
    Field.init CrossSpinner, Steps.init
  )
  check PuyoPuyo.init == PuyoPuyo.init Rule.Tsu

# ------------------------------------------------
# Count
# ------------------------------------------------

block: # cellCount, puyoCount, colorPuyoCount, nuisancePuyoCount
  let
    fieldT =
      """
[通]
rgo...
.go...
..o...
......
......
......
......
......
......
......
......
......
......""".parseField.unsafeValue
    fieldW =
      """
[すいちゅう]
......
......
......
......
......
~~~~~~
......
......
......
......
....hh
.....p
.....p
.....p""".parseField.unsafeValue
    steps = [
      Step.init RedGreen,
      Step.init(BlueBlue, Down3),
      Step.init([Col0: 2, 0, 0, 1, 0, 1], hard = true),
      Step.init [Col0: 0, 0, 0, 0, 1, 0],
      Step.init(cross = false),
      Step.init(cross = true),
    ].toDeque

    puyoT = PuyoPuyo.init(fieldT, steps)
    puyoW = PuyoPuyo.init(fieldW, steps)

  check puyoT.cellCount(Red) == 2
  check puyoT.cellCount(Garbage) == 4
  check puyoT.puyoCount == 15
  check puyoT.colorPuyoCount == 7
  check puyoT.nuisancePuyoCount == 8

  check puyoW.cellCount(Purple) == 3
  check puyoW.cellCount(Hard) == 6
  check puyoW.puyoCount == 14
  check puyoW.colorPuyoCount == 7
  check puyoW.nuisancePuyoCount == 7

# ------------------------------------------------
# Move
# ------------------------------------------------

block: # move
  let
    stepsBefore = [Step.init(BlueGreen, Right1)].toDeque
    stepsAfter = Steps.init
    fieldBefore =
      """
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
.b....
.b....
.bgrr.
hggoo.""".parseField.unsafeValue
    fieldAfter =
      """
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
....r.
o..ro.""".parseField.unsafeValue
  var puyoPuyo = PuyoPuyo.init(fieldBefore, stepsBefore)

  let
    moveResult = puyoPuyo.move(calcConnection = false)
    popCounts: array[Cell, int] = [0, 0, 1, 0, 4, 4, 0, 0]

  check puyoPuyo.field == fieldAfter
  check puyoPuyo.steps == stepsAfter
  check moveResult == MoveResult.init(1, popCounts, 1, @[popCounts], @[1])

  let moveResult2 = puyoPuyo.move
  check puyoPuyo.field == fieldAfter
  check puyoPuyo.steps == stepsAfter
  check moveResult2 == MoveResult.init(0, Cell.initArrayWith 0, 0, @[], @[], @[])

# ------------------------------------------------
# Puyo Puyo <-> string
# ------------------------------------------------

block: # `$`, parsePuyoPuyo
  block:
    let
      str =
        """
[クロスかいてん]
r.....
.g....
..b...
...y..
....p.
.....o
....h.
......
......
......
......
......
......
------
by|
(0,1,0,0,0,2)
rg|23
[3,0,0,0,4,0]
R
C
pp|4N"""
      puyoPuyo = str.parsePuyoPuyo.unsafeValue

    check $puyoPuyo == str

  block: # empty steps
    let
      str =
        """
[通]
r.....
.g....
..b...
...y..
....p.
.....o
....h.
......
......
......
......
......
......
------
"""
      puyoPuyo = str.parsePuyoPuyo.unsafeValue

    check $puyoPuyo == str

# ------------------------------------------------
# Puyo Puyo <-> URI
# ------------------------------------------------

block: # toUriQuery, parsePuyoPuyo
  block:
    let
      str =
        """
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
.op...
...yg.
...b.r
------
by|
(0,1,0,0,0,1)
rg|23"""
      puyoPuyo = str.parsePuyoPuyo.unsafeValue

      queryPon2 = "field=0_op......yg....b.r&steps=byo0_1_0_0_0_1org23"
      queryIshikawa = "6E004g031_E1ahce"

    check puyoPuyo.toUriQuery(Pon2) == Pon2Result[string].ok queryPon2
    check puyoPuyo.toUriQuery(IshikawaPuyo) == Pon2Result[string].ok queryIshikawa
    check puyoPuyo.toUriQuery(Ips) == Pon2Result[string].ok queryIshikawa

    check queryPon2.parsePuyoPuyo(Pon2) == Pon2Result[PuyoPuyo].ok puyoPuyo
    check queryIshikawa.parsePuyoPuyo(IshikawaPuyo) == Pon2Result[PuyoPuyo].ok puyoPuyo
    check queryIshikawa.parsePuyoPuyo(Ips) == Pon2Result[PuyoPuyo].ok puyoPuyo

  block: # empty steps
    let
      str =
        """
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
.....r
------
"""
      puyoPuyo = str.parsePuyoPuyo.unsafeValue

      queryPon2 = "field=0_r&steps"
      queryPon22 = "field=0_r&steps="
      queryPon23 = "field=0_r"
      queryIshikawa = "1"
      queryIshikawa2 = "1_"

    check puyoPuyo.toUriQuery(Pon2) == Pon2Result[string].ok queryPon2
    check puyoPuyo.toUriQuery(IshikawaPuyo) == Pon2Result[string].ok queryIshikawa
    check puyoPuyo.toUriQuery(Ips) == Pon2Result[string].ok queryIshikawa

    for query in [queryPon2, queryPon22, queryPon23]:
      check query.parsePuyoPuyo(Pon2) == Pon2Result[PuyoPuyo].ok puyoPuyo
    for query in [queryIshikawa, queryIshikawa2]:
      check query.parsePuyoPuyo(IshikawaPuyo) == Pon2Result[PuyoPuyo].ok puyoPuyo
      check query.parsePuyoPuyo(Ips) == Pon2Result[PuyoPuyo].ok puyoPuyo

  block: # empty field
    let
      puyoPuyo = PuyoPuyo.init(Field.init, [Step.init GreenBlue].toDeque)

      queryPon2 = "field=0_&steps=gb"
      queryPon22 = "steps=gb"
      queryIshikawa = "_q1"

    check puyoPuyo.toUriQuery(Pon2) == Pon2Result[string].ok queryPon2
    check puyoPuyo.toUriQuery(IshikawaPuyo) == Pon2Result[string].ok queryIshikawa
    check puyoPuyo.toUriQuery(Ips) == Pon2Result[string].ok queryIshikawa

    for query in [queryPon2, queryPon22]:
      check query.parsePuyoPuyo(Pon2) == Pon2Result[PuyoPuyo].ok puyoPuyo
    check queryIshikawa.parsePuyoPuyo(IshikawaPuyo) == Pon2Result[PuyoPuyo].ok puyoPuyo
    check queryIshikawa.parsePuyoPuyo(Ips) == Pon2Result[PuyoPuyo].ok puyoPuyo

  block: # empty field and steps
    let
      puyoPuyo = PuyoPuyo.init

      queryPon2 = "field=0_&steps"
      queryPon22 = "field=0_&steps="
      queryPon23 = "field=0_"
      queryPon24 = "steps"
      queryPon25 = "steps="
      queryPon26 = ""
      queryIshikawa = ""
      queryIshikawa2 = "_"

    check puyoPuyo.toUriQuery(Pon2) == Pon2Result[string].ok queryPon2
    check puyoPuyo.toUriQuery(IshikawaPuyo) == Pon2Result[string].ok queryIshikawa
    check puyoPuyo.toUriQuery(Ips) == Pon2Result[string].ok queryIshikawa

    for query in [queryPon2, queryPon22, queryPon23, queryPon24, queryPon25, queryPon26]:
      check query.parsePuyoPuyo(Pon2) == Pon2Result[PuyoPuyo].ok puyoPuyo
    for query in [queryIshikawa, queryIshikawa2]:
      check query.parsePuyoPuyo(IshikawaPuyo) == Pon2Result[PuyoPuyo].ok puyoPuyo
      check query.parsePuyoPuyo(Ips) == Pon2Result[PuyoPuyo].ok puyoPuyo

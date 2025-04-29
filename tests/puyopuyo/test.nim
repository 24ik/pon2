{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar, unittest]
import
  ../../src/pon2/core/[
    cell, common, field, fqdn, moveresult, pair, placement, popresult, puyopuyo, rule,
    step,
  ]
import ../../src/pon2/private/[assign3, arrayops2, results2, strutils2]
import ../../src/pon2/private/core/[binfield]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

block: # init
  let
    fieldT = TsuField.init
    fieldW = WaterField.init
    steps = [Step.init RedGreen].toDeque2

  check PuyoPuyo[TsuField].init(fieldT, steps) ==
    PuyoPuyo[TsuField](field: fieldT, steps: steps)
  check PuyoPuyo[WaterField].init(fieldW, steps) ==
    PuyoPuyo[WaterField](field: fieldW, steps: steps)

# ------------------------------------------------
# Count
# ------------------------------------------------

block: # cellCnt, puyoCnt, colorPuyoCnt, garbagesCnt
  let
    fieldT =
      """
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
......""".parseTsuField.expect
    fieldW =
      """
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
.....p""".parseWaterField.expect
    steps = [
      Step.init(RedGreen),
      Step.init(BlueBlue, Down3),
      Step.init([Col0: 2, 0, 0, 1, 0, 1], true),
      Step.init([Col0: 0, 0, 0, 0, 1, 0], false),
    ].toDeque2

    puyoT = PuyoPuyo[TsuField].init(fieldT, steps)
    puyoW = PuyoPuyo[WaterField].init(fieldW, steps)

  check puyoT.cellCnt(Red) == 2
  check puyoT.cellCnt(Garbage) == 4
  check puyoT.puyoCnt == 15
  check puyoT.colorPuyoCnt == 7
  check puyoT.garbagesCnt == 8

  check puyoW.cellCnt(Purple) == 3
  check puyoW.cellCnt(Hard) == 6
  check puyoW.puyoCnt == 14
  check puyoW.colorPuyoCnt == 7
  check puyoW.garbagesCnt == 7

# ------------------------------------------------
# Move
# ------------------------------------------------

block: # move
  let
    stepsBefore = [Step.init(BlueGreen, Right1)].toDeque2
    stepsAfter = Deque[Step].init
    fieldBefore =
      """
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
hggoo.""".parseTsuField.expect
    fieldAfter =
      """
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
o..ro.""".parseTsuField.expect
  var puyoPuyo = PuyoPuyo[TsuField].init(fieldBefore, stepsBefore)

  let
    moveRes = puyoPuyo.move false
    popCnts: array[Cell, int] = [0, 0, 1, 0, 4, 4, 0, 0]

  check puyoPuyo.field == fieldAfter
  check puyoPuyo.steps == stepsAfter
  check moveRes == MoveResult.init(1, popCnts, 1, @[popCnts], @[1])

  let moveRes2 = puyoPuyo.move true
  check puyoPuyo.field == fieldAfter
  check puyoPuyo.steps == stepsAfter
  check moveRes2 == MoveResult.init(0, initArrWith[Cell, int](0), 0, @[], @[])

# ------------------------------------------------
# Puyo Puyo <-> string
# ------------------------------------------------

block: # `$`, parsePuyoPuyo
  let
    str =
      """
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
pp|4N"""

    puyoPuyo = parsePuyoPuyo[TsuField](str).expect

  check $puyoPuyo == str

# ------------------------------------------------
# Puyo Puyo <-> URI
# ------------------------------------------------

block: # toUriQuery, parsePuyoPuyo
  let
    str =
      """
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
    puyoPuyo = parsePuyoPuyo[TsuField](str).expect

    queryPon2 = "field=t-op......yg....b.r&steps=byo0_1_0_0_0_1org23"
    queryIshikawa = "6E004g031_E1ahce"

  check puyoPuyo.toUriQuery(Pon2) == Res[string].ok queryPon2
  check puyoPuyo.toUriQuery(Ishikawa) == Res[string].ok queryIshikawa
  check puyoPuyo.toUriQuery(Ips) == Res[string].ok queryIshikawa

  check parsePuyoPuyo[TsuField](queryPon2, Pon2) == Res[PuyoPuyo[TsuField]].ok puyoPuyo
  check parsePuyoPuyo[TsuField](queryIshikawa, Ishikawa) ==
    Res[PuyoPuyo[TsuField]].ok puyoPuyo
  check parsePuyoPuyo[TsuField](queryIshikawa, Ips) ==
    Res[PuyoPuyo[TsuField]].ok puyoPuyo

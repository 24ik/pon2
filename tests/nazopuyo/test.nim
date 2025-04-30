{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar, unittest]
import ../../src/pon2/core/[common, field, fqdn, goal, nazopuyo, puyopuyo, rule, step]
import ../../src/pon2/private/[results2, strutils2]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

block: # init
  let
    puyoPuyoT = PuyoPuyo[TsuField].init
    puyoPuyoW = PuyoPuyo[WaterField].init
    goal = Goal.init(Cnt, Colors, 10)

  check NazoPuyo[TsuField].init(puyoPuyoT, goal) ==
    NazoPuyo[TsuField](puyoPuyo: puyoPuyoT, goal: goal)
  check NazoPuyo[WaterField].init(puyoPuyoW, goal) ==
    NazoPuyo[WaterField](puyoPuyo: puyoPuyoW, goal: goal)

  let defaultGoal = Goal.init(Clear, All)
  check NazoPuyo[TsuField].init ==
    NazoPuyo[TsuField](puyoPuyo: PuyoPuyo[TsuField].init, goal: defaultGoal)
  check NazoPuyo[WaterField].init ==
    NazoPuyo[WaterField](puyoPuyo: PuyoPuyo[WaterField].init, goal: defaultGoal)

# ------------------------------------------------
# Nazo Puyo <-> string
# ------------------------------------------------

block: # `$`, parseNazoPuyo
  let
    str =
      """
色ぷよ2連結以上で消すべし
======
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

    nazoPuyo = parseNazoPuyo[TsuField](str).expect

  check $nazoPuyo == str

# ------------------------------------------------
# Nazo Puyo <-> URI
# ------------------------------------------------

block: # toUriQuery, parseNazoPuyo
  let
    str =
      """
2連鎖するべし
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
.op...
...yg.
...b.r
------
by|
(0,1,0,0,0,1)
rg|23"""
    nazoPuyo = parseNazoPuyo[TsuField](str).expect

    queryPon2 = "field=t-op......yg....b.r&steps=byo0_1_0_0_0_1org23&goal=5__2"
    queryIshikawa = "6E004g031_E1ahce__u02"

  check nazoPuyo.toUriQuery(Pon2) == Res[string].ok queryPon2
  check nazoPuyo.toUriQuery(Ishikawa) == Res[string].ok queryIshikawa
  check nazoPuyo.toUriQuery(Ips) == Res[string].ok queryIshikawa

  check parseNazoPuyo[TsuField](queryPon2, Pon2) == Res[NazoPuyo[TsuField]].ok nazoPuyo
  check parseNazoPuyo[TsuField](queryIshikawa, Ishikawa) ==
    Res[NazoPuyo[TsuField]].ok nazoPuyo
  check parseNazoPuyo[TsuField](queryIshikawa, Ips) ==
    Res[NazoPuyo[TsuField]].ok nazoPuyo

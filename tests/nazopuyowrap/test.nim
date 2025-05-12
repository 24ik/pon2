{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/[core]
import ../../src/pon2/app/[nazopuyowrap]

# ------------------------------------------------
# Constructor / Operator
# ------------------------------------------------

block: # init, `==`
  check NazoPuyoWrap.init(NazoPuyo[TsuField].init) == NazoPuyoWrap.init

# ------------------------------------------------
# Internal Access
# ------------------------------------------------

block: # runIt
  var nazoWrap = NazoPuyoWrap.init
  nazoWrap.runIt:
    check it.puyoPuyo.field.rule == Tsu

    it.puyoPuyo.field[Row1, Col3] = Hard
    check it.puyoPuyo.garbagesCnt == 1

# ------------------------------------------------
# Convert
# ------------------------------------------------

block: # `rule=`
  let
    nazoT = NazoPuyo[TsuField].init
    nazoW = NazoPuyo[WaterField].init
    wrapT = NazoPuyoWrap.init nazoT
    wrapW = NazoPuyoWrap.init nazoW
  var nazoWrap = NazoPuyoWrap.init

  nazoWrap.rule = Tsu
  check nazoWrap == wrapT

  nazoWrap.rule = Water
  check nazoWrap == wrapW

  nazoWrap.rule = Water
  check nazoWrap == wrapW

  nazoWrap.rule = Tsu
  check nazoWrap == wrapT

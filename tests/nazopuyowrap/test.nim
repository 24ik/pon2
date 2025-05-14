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

  var wrap = NazoPuyoWrap.init NazoPuyo[WaterField].init
  wrap.optGoal.err
  check wrap == NazoPuyoWrap.init PuyoPuyo[WaterField].init

  check NazoPuyoWrap.init != NazoPuyoWrap.init NazoPuyo[WaterField].init
  check NazoPuyoWrap.init != NazoPuyoWrap.init PuyoPuyo[TsuField].init

# ------------------------------------------------
# Internal Access
# ------------------------------------------------

block: # runIt
  var nazoWrap = NazoPuyoWrap.init
  nazoWrap.runIt:
    check it.field.rule == Tsu

    it.field[Row1, Col3] = Hard
    check it.garbagesCnt == 1

    check itNazo.expect("Invalid Nazo Puyo").goal == Goal.init

  NazoPuyoWrap.init(PuyoPuyo[TsuField].init).runIt:
    check itNazo.isErr

# ------------------------------------------------
# Property
# ------------------------------------------------

block: # rule, `rule=`
  block: # nazo
    let
      nazoT = NazoPuyo[TsuField].init
      nazoW = NazoPuyo[WaterField].init
      wrapT = NazoPuyoWrap.init nazoT
      wrapW = NazoPuyoWrap.init nazoW

    check wrapT.rule == Tsu
    check wrapW.rule == Water

    var nazoWrap = NazoPuyoWrap.init nazoT
    check nazoWrap == wrapT

    nazoWrap.rule = Tsu
    check nazoWrap == wrapT

    nazoWrap.rule = Water
    check nazoWrap == wrapW

    nazoWrap.rule = Water
    check nazoWrap == wrapW

  block: # puyo
    let
      puyoT = PuyoPuyo[TsuField].init
      puyoW = PuyoPuyo[WaterField].init
      wrapT = NazoPuyoWrap.init puyoT
      wrapW = NazoPuyoWrap.init puyoW

    check wrapT.rule == Tsu
    check wrapW.rule == Water

    var nazoWrap = NazoPuyoWrap.init puyoW
    check nazoWrap.rule == Water

    nazoWrap.rule = Water
    check nazoWrap == wrapW

    nazoWrap.rule = Tsu
    check nazoWrap == wrapT

    nazoWrap.rule = Tsu
    check nazoWrap == wrapT

# ------------------------------------------------
# Nazo Puyo wrapper <-> URI
# ------------------------------------------------

block: # toUriQuery, parseNazoPuyoWrap
  let
    nazoT = NazoPuyo[TsuField].init
    puyoW = PuyoPuyo[WaterField].init
    wrapT = NazoPuyoWrap.init nazoT
    wrapW = NazoPuyoWrap.init puyoW

  for fqdn in SimulatorFqdn:
    check wrapT.toUriQuery(fqdn) == nazoT.toUriQuery fqdn
    check nazoT.toUriQuery(fqdn).expect("Invalid Nazo Puyo").parseNazoPuyoWrap(fqdn) ==
      Res[NazoPuyoWrap].ok wrapT

  check wrapW.toUriQuery(Pon2) == puyoW.toUriQuery Pon2
  check puyoW.toUriQuery(Pon2).expect("Invalid Puyo Puyo").parseNazoPuyoWrap(Pon2) ==
    Res[NazoPuyoWrap].ok wrapW

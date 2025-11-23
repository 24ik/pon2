{.push raises: [].}
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
  check NazoPuyoWrap.init(NazoPuyo[WaterField].init) ==
    NazoPuyoWrap.init PuyoPuyo[WaterField].init
  check NazoPuyoWrap.init != NazoPuyoWrap.init(NazoPuyo[WaterField].init)

# ------------------------------------------------
# Internal Access
# ------------------------------------------------

block: # unwrap
  var nazoWrap = NazoPuyoWrap.init
  nazoWrap.unwrap:
    check it.puyoPuyo.field.rule == Tsu

    it.puyoPuyo.field[Row1, Col3] = Hard
    check it.puyoPuyo.garbagesCount == 1

  let stepCount = nazoWrap.unwrap:
    it.puyoPuyo.steps.len
  check stepCount == 0

# ------------------------------------------------
# Rule
# ------------------------------------------------

block: # setRule
  let
    nazoWrapT = NazoPuyoWrap.init
    nazoWrapW = NazoPuyoWrap.init NazoPuyo[WaterField].init

  check nazoWrapT.setRule(Tsu) == nazoWrapT
  check nazoWrapT.setRule(Water) == nazoWrapW
  check nazoWrapW.setRule(Tsu) == nazoWrapT
  check nazoWrapW.setRule(Water) == nazoWrapW

# ------------------------------------------------
# Nazo Puyo wrapper <-> URI
# ------------------------------------------------

block: # toUriQuery, parseNazoPuyoWrap
  let
    nazo = NazoPuyo[TsuField].init
    wrap = NazoPuyoWrap.init nazo

  for fqdn in SimulatorFqdn:
    check wrap.toUriQuery(fqdn) == nazo.toUriQuery(fqdn)
    check nazo.toUriQuery(fqdn).unsafeValue.parseNazoPuyoWrap(fqdn) ==
      StrErrorResult[NazoPuyoWrap].ok wrap

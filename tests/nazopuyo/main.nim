{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques, options, unittest]
import
  ../../src/pon2/core/[field, fqdn, nazopuyo, pairposition, puyopuyo, requirement, rule]

proc moveCount(uriStr: string): int =
  parseNazoPuyo[TsuField](uriStr, Ishikawa).moveCount

proc main*() =
  # ------------------------------------------------
  # Constructor
  # ------------------------------------------------

  # initNazoPuyo
  block:
    let
      tsu = initNazoPuyo[TsuField]()
      water = initNazoPuyo[WaterField]()
      req = initRequirement(Clear, RequirementColor.All)

    check tsu.puyoPuyo.field == initField[TsuField]()
    check tsu.puyoPuyo.pairsPositions.len == 0
    check tsu.requirement == req

    check tsu.puyoPuyo.field == initField[TsuField]()
    check tsu.puyoPuyo.pairsPositions.len == 0
    check tsu.requirement == req

    check water.puyoPuyo.field == initField[WaterField]()
    check water.puyoPuyo.pairsPositions.len == 0
    check water.requirement == req

  # ------------------------------------------------
  # Convert
  # ------------------------------------------------

  # toTsuNazoPuyo, toWaterNazoPuyo
  block:
    let nazo = initNazoPuyo[TsuField]()
    check nazo.toWaterNazoPuyo.toWaterNazoPuyo.toTsuNazoPuyo.toTsuNazoPuyo == nazo

  # ------------------------------------------------
  # Property
  # ------------------------------------------------

  # rule
  block:
    check initNazoPuyo[TsuField]().rule == Tsu
    check initNazoPuyo[WaterField]().rule == Water

  # moveCount
  block:
    check initNazoPuyo[TsuField]().moveCount == 0
    check "109e9_01__200".moveCount == 1
    check "5004ABA_S1S1__u03".moveCount == 2
    check "3ww3so4zM_s1G1u1__u04".moveCount == 3

  # ------------------------------------------------
  # NazoPuyo <-> string / URI
  # ------------------------------------------------

  # $, parseNazoPuyo, toUriQuery
  block:
    let
      str =
        """
4連鎖するべし
======
......
......
......
......
......
......
......
......
..oo..
.bbb..
.ooo..
.bbbyy
yyyooy
------
yb|23
yb|"""
      nazo = parseNazoPuyo[TsuField](str)

    check $nazo == str

    let
      pon2Query =
        "field=t-oo...bbb...ooo...bbbyyyyyooy&pairs=yb23yb&req-kind=5&req-number=4"
      ishikawaQuery = "S03r06S03rAACQ_ueu1__u04"
      ipsQuery = "S03r06S03rAACQ_ueu1__u04"

    check nazo.toUriQuery(Pon2) == pon2Query
    check nazo.toUriQuery(Ishikawa) == ishikawaQuery
    check nazo.toUriQuery(Ips) == ipsQuery

    check parseNazoPuyo[TsuField](pon2Query, Pon2) == nazo
    check parseNazoPuyo[TsuField](ishikawaQuery, Ishikawa) == nazo
    check parseNazoPuyo[TsuField](ipsQuery, Ips) == nazo

{.experimental: "strictDefs".}

import std/[options, sequtils, strformat, unittest, uri]
import ../../src/pon2pkg/core/[field, environment, misc, pair, position]
import ../../src/pon2pkg/core/nazo/[nazoPuyo {.all.}]

func moveCount(uriStr: string): int =
  ## Returns the number of moves.
  parseTsuNazoPuyo(uriStr.parseUri).nazoPuyo.moveCount

proc main* =
  # ------------------------------------------------
  # Constructor
  # ------------------------------------------------

  # initNazoPuyo, initTsuNazoPuyo, initWaterNazoPuyo
  block:
    let
      tsu = initTsuNazoPuyo()
      tsu2 = initNazoPuyo[TsuField]()
      water = initWaterNazoPuyo()
      req = Requirement(
        kind: RequirementKind.low, color: some RequirementColor.All,
        number: none RequirementNumber)

    check tsu.environment.field == zeroTsuField()
    check tsu.environment.pairs.len == 0
    check tsu.requirement == req

    check tsu2.environment.field == zeroTsuField()
    check tsu2.environment.pairs.len == 0
    check tsu2.requirement == req

    check water.environment.field == zeroWaterField()
    check water.environment.pairs.len == 0
    check water.requirement == req

  # ------------------------------------------------
  # Convert
  # ------------------------------------------------

  # toTsuNazoPuyo, toWaterNazoPuyo
  block:
    let
      tsuNazo = initTsuNazoPuyo()
      waterNazo = initWaterNazoPuyo()

    check tsuNazo.toWaterNazoPuyo == waterNazo
    check waterNazo.toTsuNazoPuyo == tsuNazo

  # ------------------------------------------------
  # Property
  # ------------------------------------------------
  
  # moveCount
  block:
    check initTsuNazoPuyo().moveCount == 0
    check "https://ishikawapuyo.net/simu/pn.html?109e9_01__200".moveCount == 1
    check "https://ishikawapuyo.net/simu/pn.html?5004ABA_S1S1__u03".
      moveCount == 2
    check "https://ishikawapuyo.net/simu/pn.html?3ww3so4zM_s1G1u1__u04".
      moveCount == 3
    check "https://ishikawapuyo.net/simu/pn.html?z00R00Jw0Qw_G1s1G1Q1__u04".
      moveCount == 4

  # ------------------------------------------------
  # Requirement <-> string / URI
  # ------------------------------------------------

  # `$`, toUriQuery, parseRequirement
  block:
    # requirement w/ color
    block:
      let
        req = Requirement(kind: Clear, color: some RequirementColor.Garbage,
                          number: none RequirementNumber)
        str = "おじゃまぷよ全て消すべし"
        izumiyaUri = "req-kind=0&req-color=6"
        ishikawaUri = "260"

      check $req == str
      check req.toUriQuery(Izumiya) == izumiyaUri
      check req.toUriQuery(Ishikawa) == ishikawaUri
      check req.toUriQuery(IPS) == ishikawaUri
      check str.parseRequirement == req
      check izumiyaUri.parseRequirement(Izumiya) == req
      check ishikawaUri.parseRequirement(Ishikawa) == req

    # requirement w/ num
    block:
      let
        req = Requirement(kind: Chain, color: none RequirementColor,
                          number: some 5.RequirementNumber)
        str = "5連鎖するべし"
        izumiyaUri = "req-kind=5&req-number=5"
        ishikawaUri = "u05"

      check $req == str
      check req.toUriQuery(Izumiya) == izumiyaUri
      check req.toUriQuery(Ishikawa) == ishikawaUri
      check req.toUriQuery(Ips) == ishikawaUri
      check str.parseRequirement == req
      check izumiyaUri.parseRequirement(Izumiya) == req
      check ishikawaUri.parseRequirement(Ishikawa) == req

    # requirement w/ color and number
    block:
      let
        req = Requirement(kind: ChainMoreClear,
                          color: some RequirementColor.Red,
                          number: some 3.RequirementNumber)
        str = "3連鎖以上&赤ぷよ全て消すべし"
        izumiyaUri = "req-kind=8&req-color=1&req-number=3"
        ishikawaUri = "x13"

      check $req == str
      check req.toUriQuery(Izumiya) == izumiyaUri
      check req.toUriQuery(Ishikawa) == ishikawaUri
      check req.toUriQuery(Ips) == ishikawaUri
      check str.parseRequirement == req
      check izumiyaUri.parseRequirement(Izumiya) == req
      check ishikawaUri.parseRequirement(Ishikawa) == req

  # ------------------------------------------------
  # NazoPuyo <-> string / URI
  # ------------------------------------------------

  # $, toString, parseNazoPuyo, toUri
  block:
    let
      str = """
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
"""
      pairsStr = "yb\nyb"
      pairsPosStr = "yb|..\nyb|23"
      nazoStr = str & pairsStr
      nazoPosStr = str & pairsPosStr

      izumiyaMode = IzumiyaSimulatorMode.Edit
      ishikawaMode = IshikawaSimulatorMode.Edit
      izumiyaUri = parseUri "https://izumiya-keisuke.github.io" &
        "/puyo-simulator/playground/index.html?" &
        &"kind=n&" &
        &"mode={izumiyaMode}&" &
        "field=t-oo...bbb...ooo...bbbyyyyyooy&" &
        "pairs=ybyb&" &
        "req-kind=5&" &
        "req-number=4"
      izumiyaUriWithPos = parseUri "https://izumiya-keisuke.github.io" &
        "/puyo-simulator/playground/index.html?" &
        &"kind=n&" &
        &"mode={izumiyaMode}&" &
        "field=t-oo...bbb...ooo...bbbyyyyyooy&" &
        "pairs=ybyb&" &
        "positions=..23&" &
        "req-kind=5&" &
        "req-number=4"
      ishikawaUri = parseUri "https://ishikawapuyo.net" &
        &"/simu/p{ishikawaMode}.html?S03r06S03rAACQ_u1u1__u04"
      ipsUri = parseUri "http://ips.karou.jp" &
        &"/simu/p{ishikawaMode}.html?S03r06S03rAACQ_u1u1__u04"
      ishikawaUriWithPos = parseUri "https://ishikawapuyo.net" &
        &"/simu/p{ishikawaMode}.html?S03r06S03rAACQ_u1ue__u04"
      ipsUriWithPos = parseUri "http://ips.karou.jp" &
        &"/simu/p{ishikawaMode}.html?S03r06S03rAACQ_u1ue__u04"
      positions = @[none Position, some Right1]

      envUri = parseUri "https://ishikawapuyo.net" &
        &"/simu/p{ishikawaMode}.html?S03r06S03rAACQ_u1u1"
      nazo = NazoPuyo[TsuField](
        environment: parseTsuEnvironment(envUri).environment,
        requirement: "u04".parseRequirement(Ishikawa))

    # Nazo <-> string
    block:
      check $nazo == nazoStr
      check nazo.toString == nazoStr
      check nazo.toString(positions) == nazoPosStr

    # Nazo <-> URI
    block:
      check nazo.toUri(host = Izumiya, mode = izumiyaMode) == izumiyaUri
      check nazo.toUri(host = Ishikawa, mode = ishikawaMode) == ishikawaUri
      check nazo.toUri(host = Ips, mode = ishikawaMode) == ipsUri
      check nazo.toUri(positions, Izumiya, izumiyaMode) == izumiyaUriWithPos
      check nazo.toUri(positions, Ishikawa, ishikawaMode) == ishikawaUriWithPos
      check nazo.toUri(positions, Ips, ishikawaMode) == ipsUriWithPos

      check izumiyaUri.parseTsuNazoPuyo == (
        nazoPuyo: nazo,
        positions: none Positions,
        izumiyaMode: some izumiyaMode,
        ishikawaMode: none IshikawaSimulatorMode)
      check ishikawaUri.parseTsuNazoPuyo == (
        nazoPuyo: nazo,
        positions: some Position.none.repeat nazo.moveCount,
        izumiyaMode: none IzumiyaSimulatorMode,
        ishikawaMode: some ishikawaMode)
      check izumiyaUriWithPos.parseTsuNazoPuyo == (
        nazoPuyo: nazo,
        positions: some positions,
        izumiyaMode: some izumiyaMode,
        ishikawaMode: none IshikawaSimulatorMode)
      check ishikawaUriWithPos.parseTsuNazoPuyo == (
        nazoPuyo: nazo,
        positions: some positions,
        izumiyaMode: none IzumiyaSimulatorMode,
        ishikawaMode: some ishikawaMode)
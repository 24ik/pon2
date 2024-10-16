{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques, sequtils, strformat, strutils, unittest, uri]
import
  ../../src/pon2/core/
    [cell, field, fqdn, moveresult, pair, pairposition, position, puyopuyo, rule]

proc main*() =
  # ------------------------------------------------
  # Reset / Constructor
  # ------------------------------------------------

  # initPuyoPuyo
  block:
    let puyoPuyo = initPuyoPuyo[TsuField]()
    check puyoPuyo.field == initField[TsuField]()
    check puyoPuyo.pairsPositions.len == 0

  # ------------------------------------------------
  # Convert
  # ------------------------------------------------

  # toTsuPuyoPuyo, toWaterPuyoPuyo
  block:
    var puyoPuyo = initPuyoPuyo[TsuField]()
    puyoPuyo.field[0, 0] = Red
    puyoPuyo.pairsPositions.addLast PairPosition(pair: RedGreen, position: Up1)

    check puyoPuyo.toWaterPuyoPuyo.toWaterPuyoPuyo.toTsuPuyoPuyo.toTsuPuyoPuyo ==
      puyoPuyo

  # ------------------------------------------------
  # Property
  # ------------------------------------------------

  # rule
  block:
    check initPuyoPuyo[TsuField]().rule == Tsu
    check initPuyoPuyo[WaterField]().rule == Water

  # movingCompleted
  block:
    var puyoPuyo = initPuyoPuyo[TsuField]()
    puyoPuyo.pairsPositions.addLast PairPosition(pair: RedGreen, position: Up1)
    puyoPuyo.pairsPositions.addLast PairPosition(pair: BlueYellow, position: Up2)
    check not puyoPuyo.movingCompleted

    puyoPuyo.move
    check not puyoPuyo.movingCompleted

    puyoPuyo.move
    check puyoPuyo.movingCompleted

  # ------------------------------------------------
  # Count
  # ------------------------------------------------

  # puyoCount, colorCount, garbageCount
  block:
    let puyoPuyo = parsePuyoPuyo[TsuField](
      "......\n".repeat(11) & "rrb...\noogg..\n------\nry|\ngg|"
    )

    check puyoPuyo.puyoCount(Red) == 3
    check puyoPuyo.puyoCount(Blue) == 1
    check puyoPuyo.puyoCount(Purple) == 0
    check puyoPuyo.puyoCount == 11
    check puyoPuyo.colorCount == 9
    check puyoPuyo.garbageCount == 2

  # ------------------------------------------------
  # Move
  # ------------------------------------------------

  # move, move0, move1, move2
  block:
    # Tsu
    block:
      let
        puyoPuyoBefore = parsePuyoPuyo[TsuField](
          """
....g.
....g.
....pg
....rg
....gr
....go
....gp
....bg
....bp
...bgp
...bgr
...orb
...gbb
------
rb|4F
rg|"""
        )
        puyoPuyoAfter = parsePuyoPuyo[TsuField](
          "......\n".repeat(10) & ".....r\n.....b\n...gbb\n------\nrg|"
        )

      block:
        var puyoPuyo = puyoPuyoBefore
        puyoPuyo.move
        check puyoPuyo.field == puyoPuyoAfter.field
        check puyoPuyo.pairsPositions == puyoPuyoAfter.pairsPositions

      block:
        var puyoPuyo = puyoPuyoBefore
        discard puyoPuyo.move0
        check puyoPuyo.field == puyoPuyoAfter.field
        check puyoPuyo.pairsPositions == puyoPuyoAfter.pairsPositions

      block:
        var puyoPuyo = puyoPuyoBefore
        discard puyoPuyo.move1
        check puyoPuyo.field == puyoPuyoAfter.field
        check puyoPuyo.pairsPositions == puyoPuyoAfter.pairsPositions

      block:
        var puyoPuyo = puyoPuyoBefore
        discard puyoPuyo.move2
        check puyoPuyo.field == puyoPuyoAfter.field
        check puyoPuyo.pairsPositions == puyoPuyoAfter.pairsPositions

    # Water
    block:
      let
        puyoPuyoBefore = parsePuyoPuyo[WaterField](
          """
......
......
......
......
......
yggb..
roob..
rbb...
.gb...
.oo...
.og...
.yy...
..y...
------
rb|34
rg|"""
        )
        puyoPuyoAfter = parsePuyoPuyo[WaterField](
          """
......
......
......
......
......
yor...
ryy...
r.y...
......
......
......
......
......
------
rg|"""
        )

      var puyoPuyo = puyoPuyoBefore
      discard puyoPuyo.move2
      check puyoPuyo.field == puyoPuyoAfter.field
      check puyoPuyo.pairsPositions == puyoPuyoAfter.pairsPositions

  # ------------------------------------------------
  # Puyo Puyo <-> string / URI
  # ------------------------------------------------

  # `$`, parsePuyoPuyo, toUriQuery
  block:
    # Tsu
    block:
      let
        str = "......\n".repeat(12) & "rg.bo.\n------\nyy|\ngp|21"
        puyoPuyo = parsePuyoPuyo[TsuField](str)

      check $puyoPuyo == str

      let
        pon2Query = "field=t-rg.bo.&pairs=yygp21"
        ishikawaQuery = "a3M_G1OC"
        ipsQuery = "a3M_G1OC"

      check puyoPuyo.toUriQuery(Pon2) == pon2Query
      check puyoPuyo.toUriQuery(Ishikawa) == ishikawaQuery
      check puyoPuyo.toUriQuery(Ips) == ipsQuery

      check parsePuyoPuyo[TsuField](pon2Query, Pon2) == puyoPuyo
      check parsePuyoPuyo[TsuField](ishikawaQuery, Ishikawa) == puyoPuyo
      check parsePuyoPuyo[TsuField](ipsQuery, Ips) == puyoPuyo

    # Water
    block:
      let
        str =
          "......\n".repeat(4) & "rg....\n....by\n" & "......\n".repeat(7)[0 .. ^2] &
          "\n------\n"
        puyoPuyo = parsePuyoPuyo[WaterField](str)

      check $puyoPuyo == str

      let pon2Query = "field=w-rg....~....by&pairs"

      check puyoPuyo.toUriQuery(Pon2) == pon2Query
      check parsePuyoPuyo[WaterField](pon2Query, Pon2) == puyoPuyo

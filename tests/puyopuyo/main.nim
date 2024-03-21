{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, strformat, strutils, unittest, uri]
import
  ../../src/pon2pkg/core/
    [
      cell,
      field,
      host,
      moveresult,
      pair,
      pairposition,
      position,
      puyopuyo {.all.},
      rule,
    ]

proc main*() =
  # ------------------------------------------------
  # Reset / Constructor
  # ------------------------------------------------

  # reset, initPuyoPuyo
  block:
    var puyoPuyo = initPuyoPuyo[TsuField]()
    puyoPuyo.field[0, 0] = Red
    puyoPuyo.pairsPositions.add PairPosition(pair: RedGreen, position: Up1)

    puyoPuyo.reset
    check puyoPuyo == initPuyoPuyo[TsuField]()

  # ------------------------------------------------
  # Convert
  # ------------------------------------------------

  # toTsuPuyoPuyo, toWaterPuyoPuyo
  block:
    var puyoPuyo = initPuyoPuyo[TsuField]()
    puyoPuyo.field[0, 0] = Red
    puyoPuyo.pairsPositions.add PairPosition(pair: RedGreen, position: Up1)

    check puyoPuyo.toWaterPuyoPuyo.toWaterPuyoPuyo.toTsuPuyoPuyo.toTsuPuyoPuyo ==
      puyoPuyo

  # ------------------------------------------------
  # Property
  # ------------------------------------------------

  # rule
  block:
    check initPuyoPuyo[TsuField]().rule == Tsu
    check initPuyoPuyo[WaterField]().rule == Water

  # operatingIndex, incrementOperatingIndex, decrementOperatingIndex
  block:
    var puyoPuyo = initPuyoPuyo[TsuField]()
    puyoPuyo.pairsPositions.add PairPosition(pair: RedGreen, position: Up1)
    check puyoPuyo.operatingIndex == 0

    puyoPuyo.decrementOperatingIndex
    check puyoPuyo.operatingIndex == 0

    puyoPuyo.incrementOperatingIndex
    check puyoPuyo.operatingIndex == 1
    puyoPuyo.incrementOperatingIndex
    check puyoPuyo.operatingIndex == 1

    puyoPuyo.decrementOperatingIndex
    check puyoPuyo.operatingIndex == 0

  # movingCompleted, operatingPairPosition
  block:
    var puyoPuyo = initPuyoPuyo[TsuField]()
    puyoPuyo.pairsPositions.add PairPosition(pair: RedGreen, position: Up1)
    puyoPuyo.pairsPositions.add PairPosition(pair: BlueYellow, position: Up2)

    check not puyoPuyo.movingCompleted
    check puyoPuyo.operatingPairPosition == PairPosition(pair: RedGreen, position: Up1)

    puyoPuyo.move
    check not puyoPuyo.movingCompleted
    check puyoPuyo.operatingPairPosition == PairPosition(
      pair: BlueYellow, position: Up2
    )

    puyoPuyo.move
    check puyoPuyo.movingCompleted
    expect IndexDefect:
      discard puyoPuyo.operatingPairPosition

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
          "......\n".repeat(10) & ".....r\n.....b\n...gbb\n------\nrb|4F\nrg|"
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
rb|34
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
        izumiyaQuery = "field=t-rg.bo.&pairs=yygp21"
        ishikawaQuery = "a3M_G1OC"
        ipsQuery = "a3M_G1OC"

      check puyoPuyo.toUriQuery(Izumiya) == izumiyaQuery
      check puyoPuyo.toUriQuery(Ishikawa) == ishikawaQuery
      check puyoPuyo.toUriQuery(Ips) == ipsQuery

      check parsePuyoPuyo[TsuField](izumiyaQuery, Izumiya) == puyoPuyo
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

      let izumiyaQuery = "field=w-rg....~....by&pairs"

      check puyoPuyo.toUriQuery(Izumiya) == izumiyaQuery
      check parsePuyoPuyo[WaterField](izumiyaQuery, Izumiya) == puyoPuyo

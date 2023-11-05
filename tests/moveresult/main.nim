{.experimental: "strictDefs".}

import std/[unittest]
import ../../src/pon2pkg/corepkg/[cell, environment, moveresult {.all.},
                                  position]

proc main* =
  # ------------------------------------------------
  # Count, Score
  # ------------------------------------------------

  # chainCount, puyoCount[s], colorCount[s], garbageCount[s], colors[Seq],
  # colorPlaces, colorConnects, score
  block:
    var env = parseTsuEnvironment("""
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
rb
rg""").environment

    let
      fullRes = env.moveWithFullTracking(Down3, false)
      detailRes: DetailMoveResult = fullRes
      roughRes: RoughMoveResult = detailRes
      moveRes: MoveResult = roughRes

    # chainCount
    block:
      let chain = 3

      check fullRes.chainCount == chain
      check detailRes.chainCount == chain
      check roughRes.chainCount == chain
      check moveRes.chainCount == chain

    # puyoCount
    block:
      let
        red = 4
        puyo = 25

      check fullRes.puyoCount(Red) == red
      check detailRes.puyoCount(Red) == red
      check roughRes.puyoCount(Red) == red
      expect NotSupportDefect:
        discard moveRes.puyoCount(Red)

      check fullRes.puyoCount == puyo
      check detailRes.puyoCount == puyo
      check roughRes.puyoCount == puyo
      expect NotSupportDefect:
        discard moveRes.puyoCount

    # colorCount
    block:
      let color = 23

      check fullRes.colorCount == color
      check detailRes.colorCount == color
      check roughRes.colorCount == color
      expect NotSupportDefect:
        discard moveRes.colorCount

    # garbageCount
    block:
      let garbage = 2

      check fullRes.garbageCount == garbage
      check detailRes.garbageCount == garbage
      check roughRes.garbageCount == garbage
      expect NotSupportDefect:
        discard moveRes.garbageCount

    # puyoCounts
    block:
      let
        red = @[0, 0, 4]
        puyo = @[6, 10, 9]

      check fullRes.puyoCounts(Red) == red
      check detailRes.puyoCounts(Red) == red
      expect NotSupportDefect:
        discard roughRes.puyoCounts(Red)
      expect NotSupportDefect:
        discard moveRes.puyoCount(Red)

      check fullRes.puyoCounts == puyo
      check detailRes.puyoCounts == puyo
      expect NotSupportDefect:
        discard roughRes.puyoCounts
      expect NotSupportDefect:
        discard moveRes.puyoCounts

    # colorCounts
    block:
      let color = @[5, 10, 8]

      check fullRes.colorCounts == color
      check detailRes.colorCounts == color
      expect NotSupportDefect:
        discard roughRes.colorCounts
      expect NotSupportDefect:
        discard moveRes.colorCounts

    # garbageCounts
    block:
      let garbage = @[1, 0, 1]

      check fullRes.garbageCounts == garbage
      check detailRes.garbageCounts == garbage
      expect NotSupportDefect:
        discard roughRes.garbageCounts
      expect NotSupportDefect:
        discard moveRes.garbageCounts

    # colors
    block:
      let colors = {Red.ColorPuyo, Green, Blue, Purple}

      check fullRes.colors == colors
      check detailRes.colors == colors
      check roughRes.colors == colors
      expect NotSupportDefect:
        discard moveRes.colors

    # colorsSeq
    block:
      let colorsSeq = @[{Blue.ColorPuyo}, {Green}, {Red, Purple}]
      
      check fullRes.colorsSeq == colorsSeq
      check detailRes.colorsSeq == colorsSeq
      expect NotSupportDefect:
        discard roughRes.colorsSeq
      expect NotSupportDefect:
        discard moveRes.colorsSeq

    # colorPlaces
    block:
      let
        red = @[0, 0, 1]
        color = @[1, 2, 2]

      check fullRes.colorPlaces(Red) == red
      expect NotSupportDefect:
        discard detailRes.colorPlaces(Red)
      expect NotSupportDefect:
        discard roughRes.colorPlaces(Red)
      expect NotSupportDefect:
        discard moveRes.colorPlaces(Red)

      check fullRes.colorPlaces == color
      expect NotSupportDefect:
        discard detailRes.colorPlaces
      expect NotSupportDefect:
        discard roughRes.colorPlaces
      expect NotSupportDefect:
        discard moveRes.colorPlaces

    # colorConnects
    block:
      let
        red = @[4]
        color = @[5, 4, 6, 4, 4]

      check fullRes.colorConnects(Red) == red
      expect NotSupportDefect:
        discard detailRes.colorConnects(Red)
      expect NotSupportDefect:
        discard roughRes.colorConnects(Red)
      expect NotSupportDefect:
        discard moveRes.colorConnects(Red)

      check fullRes.colorConnects == color
      expect NotSupportDefect:
        discard detailRes.colorConnects
      expect NotSupportDefect:
        discard roughRes.colorConnects
      expect NotSupportDefect:
        discard moveRes.colorConnects
      
    # score
    block:
      let score = 2720

      check fullRes.score == score
      expect NotSupportDefect:
        discard detailRes.score
      expect NotSupportDefect:
        discard roughRes.score
      expect NotSupportDefect:
        discard moveRes.score

{.experimental: "strictDefs".}

import std/[options, unittest]
import ../../src/pon2pkg/corepkg/[cell, environment, moveresult {.all.},
                                  position]

proc main* =
  # ------------------------------------------------
  # Count, Score
  # ------------------------------------------------

  # chainCount, puyoCount[s], colorCount[s], garbageCount[s], colors[Seq],
  # colorPlaces, colorConnects, score
  block:
    let env = parseTsuEnvironment("""
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
      moveRes, roughRes, detailRes, fullRes: MoveResult
      pos = Down3
    block:
      var env2 = env
      moveRes = env2.move(pos, false)
    block:
      var env2 = env
      roughRes = env2.moveWithRoughTracking(pos, false)
    block:
      var env2 = env
      detailRes = env2.moveWithDetailTracking(pos, false)
    block:
      var env2 = env
      fullRes = env2.moveWithFullTracking(pos, false)

    # chainCount
    block:
      let chain = 3

      check moveRes.chainCount == chain
      check roughRes.chainCount == chain
      check detailRes.chainCount == chain
      check fullRes.chainCount == chain

    # puyoCount
    block:
      let
        red = 4
        puyo = 25

      expect UnpackDefect:
        discard moveRes.puyoCount(Red)
      check roughRes.puyoCount(Red) == red
      check detailRes.puyoCount(Red) == red
      check fullRes.puyoCount(Red) == red

      expect UnpackDefect:
        discard moveRes.puyoCount
      check roughRes.puyoCount == puyo
      check detailRes.puyoCount == puyo
      check fullRes.puyoCount == puyo

    # colorCount
    block:
      let color = 23

      expect UnpackDefect:
        discard moveRes.colorCount
      check roughRes.colorCount == color
      check detailRes.colorCount == color
      check fullRes.colorCount == color

    # garbageCount
    block:
      let garbage = 2

      expect UnpackDefect:
        discard moveRes.garbageCount
      check roughRes.garbageCount == garbage
      check detailRes.garbageCount == garbage
      check fullRes.garbageCount == garbage

    # puyoCounts
    block:
      let
        red = @[0, 0, 4]
        puyo = @[6, 10, 9]

      expect UnpackDefect:
        discard moveRes.puyoCount(Red)
      expect UnpackDefect:
        discard roughRes.puyoCounts(Red)
      check detailRes.puyoCounts(Red) == red
      check fullRes.puyoCounts(Red) == red

      expect UnpackDefect:
        discard moveRes.puyoCounts
      expect UnpackDefect:
        discard roughRes.puyoCounts
      check detailRes.puyoCounts == puyo
      check fullRes.puyoCounts == puyo

    # colorCounts
    block:
      let color = @[5, 10, 8]

      expect UnpackDefect:
        discard moveRes.colorCounts
      expect UnpackDefect:
        discard roughRes.colorCounts
      check detailRes.colorCounts == color
      check fullRes.colorCounts == color

    # garbageCounts
    block:
      let garbage = @[1, 0, 1]

      expect UnpackDefect:
        discard moveRes.garbageCounts
      expect UnpackDefect:
        discard roughRes.garbageCounts
      check detailRes.garbageCounts == garbage
      check fullRes.garbageCounts == garbage

    # colors
    block:
      let colors = {Red.ColorPuyo, Green, Blue, Purple}

      expect UnpackDefect:
        discard moveRes.colors
      check roughRes.colors == colors
      check detailRes.colors == colors
      check fullRes.colors == colors

    # colorsSeq
    block:
      let colorsSeq = @[{Blue.ColorPuyo}, {Green}, {Red, Purple}]
      
      expect UnpackDefect:
        discard moveRes.colorsSeq
      expect UnpackDefect:
        discard roughRes.colorsSeq
      check detailRes.colorsSeq == colorsSeq
      check fullRes.colorsSeq == colorsSeq

    # colorPlaces
    block:
      let
        red = @[0, 0, 1]
        color = @[1, 2, 2]

      expect UnpackDefect:
        discard moveRes.colorPlaces(Red)
      expect UnpackDefect:
        discard roughRes.colorPlaces(Red)
      expect UnpackDefect:
        discard detailRes.colorPlaces(Red)
      check fullRes.colorPlaces(Red) == red

      expect UnpackDefect:
        discard moveRes.colorPlaces
      expect UnpackDefect:
        discard roughRes.colorPlaces
      expect UnpackDefect:
        discard detailRes.colorPlaces
      check fullRes.colorPlaces == color

    # colorConnects
    block:
      let
        red = @[4]
        color = @[5, 4, 6, 4, 4]

      expect UnpackDefect:
        discard moveRes.colorConnects(Red)
      expect UnpackDefect:
        discard roughRes.colorConnects(Red)
      expect UnpackDefect:
        discard detailRes.colorConnects(Red)
      check fullRes.colorConnects(Red) == red

      expect UnpackDefect:
        discard moveRes.colorConnects
      expect UnpackDefect:
        discard roughRes.colorConnects
      expect UnpackDefect:
        discard detailRes.colorConnects
      check fullRes.colorConnects == color
      
    # score
    block:
      let score = 2720

      expect UnpackDefect:
        discard moveRes.score
      expect UnpackDefect:
        discard roughRes.score
      expect UnpackDefect:
        discard detailRes.score
      check fullRes.score == score

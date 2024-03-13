{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2pkg/core/[cell, field, moveresult {.all.}, position, puyopuyo]

proc main*() =
  # ------------------------------------------------
  # Count, Score
  # ------------------------------------------------

  # chainCount, puyoCount[s], colorCount[s], garbageCount[s], colors[Seq],
  # colorPlaces, colorConnects, score
  block:
    let puyoPuyo = parsePuyoPuyo[TsuField](
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

    let res0, res1, res2: MoveResult
    block:
      var puyoPuyo2 = puyoPuyo
      res0 = puyoPuyo2.move0
    block:
      var puyoPuyo2 = puyoPuyo
      res1 = puyoPuyo2.move1
    block:
      var puyoPuyo2 = puyoPuyo
      res2 = puyoPuyo2.move2

    # chainCount
    block:
      let chain = 3

      check res0.chainCount == chain
      check res1.chainCount == chain
      check res2.chainCount == chain

    # puyoCount
    block:
      let
        red = 4
        puyo = 25

      check res0.puyoCount(Red) == red
      check res1.puyoCount(Red) == red
      check res2.puyoCount(Red) == red

      check res0.puyoCount == puyo
      check res1.puyoCount == puyo
      check res2.puyoCount == puyo

    # colorCount
    block:
      let color = 23

      check res0.colorCount == color
      check res1.colorCount == color
      check res2.colorCount == color

    # garbageCount
    block:
      let garbage = 2

      check res0.garbageCount == garbage
      check res1.garbageCount == garbage
      check res2.garbageCount == garbage

    # puyoCounts
    block:
      let
        red = @[0, 0, 4]
        puyo = @[6, 10, 9]

      expect FieldDefect:
        discard res0.puyoCounts(Red)
      check res1.puyoCounts(Red) == red
      check res2.puyoCounts(Red) == red

      expect FieldDefect:
        discard res0.puyoCounts
      check res1.puyoCounts == puyo
      check res2.puyoCounts == puyo

    # colorCounts
    block:
      let color = @[5, 10, 8]

      expect FieldDefect:
        discard res0.colorCounts
      check res1.colorCounts == color
      check res2.colorCounts == color

    # garbageCounts
    block:
      let garbage = @[1, 0, 1]

      expect FieldDefect:
        discard res0.garbageCounts
      check res1.garbageCounts == garbage
      check res2.garbageCounts == garbage

    # colors
    block:
      let colors = {Red.ColorPuyo, Green, Blue, Purple}

      check res0.colors == colors
      check res1.colors == colors
      check res2.colors == colors

    # colorsSeq
    block:
      let colorsSeq = @[{Blue.ColorPuyo}, {Green}, {Red, Purple}]

      expect FieldDefect:
        discard res0.colorsSeq
      check res1.colorsSeq == colorsSeq
      check res2.colorsSeq == colorsSeq

    # colorPlaces
    block:
      let
        red = @[0, 0, 1]
        color = @[1, 2, 2]

      expect FieldDefect:
        discard res0.colorPlaces(Red)
      expect FieldDefect:
        discard res1.colorPlaces(Red)
      check res2.colorPlaces(Red) == red

      expect FieldDefect:
        discard res0.colorPlaces
      expect FieldDefect:
        discard res1.colorPlaces
      check res2.colorPlaces == color

    # colorConnects
    block:
      let
        red = @[4]
        color = @[5, 4, 6, 4, 4]

      expect FieldDefect:
        discard res0.colorConnects(Red)
      expect FieldDefect:
        discard res1.colorConnects(Red)
      check res2.colorConnects(Red) == red

      expect FieldDefect:
        discard res0.colorConnects
      expect FieldDefect:
        discard res1.colorConnects
      check res2.colorConnects == color

    # score
    block:
      let score = 2720

      expect FieldDefect:
        discard res0.score
      expect FieldDefect:
        discard res1.score
      check res2.score == score

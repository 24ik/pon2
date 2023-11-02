{.experimental: "strictDefs".}

import std/[unittest]
import ../../src/pon2pkg/core/[cell, environment, field, moveResult {.all.},
                               position]

proc main* =
  # ------------------------------------------------
  # Count, Score
  # ------------------------------------------------

  # cellCount[s], puyoCount[s], colorCount[s], score
  block:
    let envBefore = parseTsuEnvironment("""
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

    block:
      var env = envBefore
      let res = env.moveWithDetailTracking Down3
      check res.cellCount(Red) == 4
      check res.cellCount == 25
      check res.puyoCount == 25
      check res.colorCount == 23
      check res.cellCounts(Red) == @[0, 0, 4]
      check res.cellCounts == @[6, 10, 9]
      check res.puyoCounts == @[6, 10, 9]
      check res.colorCounts == @[5, 10, 8]

    block:
      var env = envBefore
      let res = env.moveWithFullTracking Down3
      check res.score == 2720

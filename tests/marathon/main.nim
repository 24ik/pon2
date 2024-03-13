{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strutils, unittest]
import ../../src/pon2pkg/app/[marathon {.all.}, nazopuyo, simulator]
import ../../src/pon2pkg/core/[cell, pair, pairposition]
import ../../src/pon2pkg/private/app/marathon/[common]

proc main*() =
  # ------------------------------------------------
  # Edit - Other
  # ------------------------------------------------

  # toggleFocus
  block:
    var marathon = initMarathon()
    check not marathon.focusSimulator

    marathon.toggleFocus
    check marathon.focusSimulator

  # ------------------------------------------------
  # Table Page
  # ------------------------------------------------

  # nextResultPage, prevResultPage
  block:
    var marathon = initMarathon()
    marathon.match("rrgy")
    doAssert marathon.matchPairsStrsSeq.len > 1
    check marathon.matchResultPageIdx == 0

    marathon.nextResultPage
    check marathon.matchResultPageIdx == 1

    marathon.prevResultPage
    check marathon.matchResultPageIdx == 0

    marathon.prevResultPage
    check marathon.matchResultPageIdx == marathon.matchResultPageCount.pred

    marathon.nextResultPage
    check marathon.matchResultPageIdx == 0

  # ------------------------------------------------
  # Match
  # ------------------------------------------------

  # match
  block:
    var marathon = initMarathon()

    # specify colors
    block:
      var count = 0
      for color in ColorPuyo:
        marathon.match($color)
        count.inc marathon.matchPairsStrsSeq.len

      check count == AllPairsCount

    # specify abstract pattern
    block:
      var count = 0
      for pattern in ["aa", "ab"]:
        marathon.match(pattern)
        count.inc marathon.matchPairsStrsSeq.len

      check count == AllPairsCount

  # ------------------------------------------------
  # Play
  # ------------------------------------------------

  # play
  block:
    var marathon = initMarathon()

    marathon.simulator[].nazoPuyoWrap.get:
      doAssert wrappedNazoPuyo.puyoPuyo.pairsPositions.len == 0

      marathon.play(onlyMatched = false)
      check wrappedNazoPuyo.puyoPuyo.pairsPositions.len > 0

      marathon.match("rg")
      marathon.play
      check wrappedNazoPuyo.puyoPuyo.pairsPositions[0].pair == RedGreen

      marathon.play 0
      check wrappedNazoPuyo.puyoPuyo.pairsPositions[0].pair == RedGreen
      check marathon.matchPairsStrsSeq[0].startsWith "rg"

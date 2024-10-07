{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strutils, unittest]
import ../../src/pon2/app/[marathon, nazopuyo, simulator]
import ../../src/pon2/core/[cell, pair, pairposition]
import ../../src/pon2/private/app/marathon/[common]

proc main*() =
  # ------------------------------------------------
  # Edit - Other
  # ------------------------------------------------

  # toggleFocus
  block:
    var marathon = newMarathon()
    check not marathon.focusSimulator

    marathon.toggleFocus
    check marathon.focusSimulator

  # ------------------------------------------------
  # Table Page
  # ------------------------------------------------

  # nextResultPage, prevResultPage
  block:
    var marathon = newMarathon()
    marathon.match("rrgy")
    doAssert marathon.matchResult.strings.len > 1
    check marathon.matchResult.pageIndex == 0

    marathon.nextResultPage
    check marathon.matchResult.pageIndex == 1

    marathon.prevResultPage
    check marathon.matchResult.pageIndex == 0

    marathon.prevResultPage
    check marathon.matchResult.pageIndex == marathon.matchResult.pageCount.pred

    marathon.nextResultPage
    check marathon.matchResult.pageIndex == 0

  # ------------------------------------------------
  # Match
  # ------------------------------------------------

  # match
  block:
    var marathon = newMarathon()

    # specify colors
    block:
      var count = 0
      for color in ColorPuyo:
        marathon.match $color
        count.inc marathon.matchResult.strings.len

      check count == AllPairsCount

    # specify abstract pattern
    block:
      var count = 0
      for pattern in ["aa", "ab"]:
        marathon.match pattern
        count.inc marathon.matchResult.strings.len

      check count == AllPairsCount

  # ------------------------------------------------
  # Play
  # ------------------------------------------------

  # play
  block:
    var marathon = newMarathon()

    marathon.simulator[].nazoPuyoWrap.get:
      doAssert wrappedNazoPuyo.puyoPuyo.pairsPositions.len == 0

      marathon.play(onlyMatched = false)
      check wrappedNazoPuyo.puyoPuyo.pairsPositions.len > 0

      marathon.match "rg"
      marathon.play
      check wrappedNazoPuyo.puyoPuyo.pairsPositions[0].pair == GreenRed

      marathon.play 0
      check wrappedNazoPuyo.puyoPuyo.pairsPositions[0].pair == GreenRed
      check marathon.matchResult.strings[0].startsWith "rg"

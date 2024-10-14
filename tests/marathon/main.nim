{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques, strutils, unittest]
import ../../src/pon2/app/[marathon {.all.}, nazopuyo, simulator]
import ../../src/pon2/core/[cell, pair, pairposition]
import ../../src/pon2/private/app/marathon/[common]

when defined(js):
  import std/[os]
  import ../../src/pon2/private/app/[misc]

  const SwapPairsTxt = staticRead NativeAssetsDir / "pairs" / "swap.txt"

  proc loadData(self: Marathon) {.inline.} =
    ## Loads pairs' data.
    self.loadData SwapPairsTxt

proc main*() =
  # ------------------------------------------------
  # Edit - Other
  # ------------------------------------------------

  # toggleFocus
  block:
    let marathon = newMarathon()
    marathon.loadData
    check not marathon.focusSimulator

    marathon.toggleFocus
    check marathon.focusSimulator

  # ------------------------------------------------
  # Table Page
  # ------------------------------------------------

  # nextResultPage, prevResultPage
  block:
    let marathon = newMarathon()
    marathon.loadData
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
    let marathon = newMarathon()
    marathon.loadData

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
    let marathon = newMarathon()
    marathon.loadData

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

import options
import sequtils
import unittest
import uri

import nazopuyo_core
import puyo_core

import ../../src/pon2pkg/core/permute

proc main* =
  # ------------------------------------------------
  # Permute
  # ------------------------------------------------

  # permute
  block:
    let
      query = "https://ishikawapuyo.net/simu/pn.html?S00r0Mm6iOi_g1g1__u03".parseUri.toNazoPuyo.get.nazoPuyo

      result1gbgb = ("gb\ngb".toPairs.get, "12\n12".toPositions.get)
      result1gbbg = ("gb\nbg".toPairs.get, "12\n21".toPositions.get)
      result1bgbg = ("bg\nbg".toPairs.get, "21\n21".toPositions.get)
      result2 = ("gg\nbb".toPairs.get, "1N\n2N".toPositions.get)

    # allow double
    # w/o fixMoves
    check query.permute(newSeq[Positive](0), true, true, true).toSeq == @[result2, result1gbgb]
    check query.permute(newSeq[Positive](0), true, true, false).toSeq == @[result2, result1gbgb]
    # w/ fixMoves
    check query.permute(@[2.Positive], true, true, true).toSeq == @[result1gbbg]
    check query.permute(@[2.Positive], true, true, false).toSeq == @[result1gbbg]
    check query.permute(@[1.Positive, 2.Positive], true, true, true).toSeq == @[result1bgbg]
    check query.permute(@[1.Positive, 2.Positive], true, true, false).toSeq == @[result1bgbg]

    # not allow last double
    check query.permute(newSeq[Positive](0), true, false, true).toSeq == @[result1gbgb]

    # not allow double
    check query.permute(newSeq[Positive](0), false, false, true).toSeq == @[result1gbgb]

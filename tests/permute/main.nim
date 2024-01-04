{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options, sequtils, unittest, uri]
import ../../src/pon2pkg/nazopuyopkg/[nazopuyo, permute]
import ../../src/pon2pkg/corepkg/[pair, position]

proc main* =
  # ------------------------------------------------
  # Permute
  # ------------------------------------------------

  # permute
  block:
    let
      nazo = "https://ishikawapuyo.net/simu/pn.html?S00r0Mm6iOi_g1g1__u03".
        parseUri.parseTsuNazoPuyo.nazoPuyo

      result1gbgb = ("gb\ngb".parsePairs, "12\n12".parsePositions)
      result1gbbg = ("gb\nbg".parsePairs, "12\n21".parsePositions)
      result1bgbg = ("bg\nbg".parsePairs, "21\n21".parsePositions)
      result2 = ("gg\nbb".parsePairs, "1N\n2N".parsePositions)

    # allow double
    # w/o fixMoves
    check nazo.permute(newSeq[Positive](0), true, true, 1).toSeq == @[
      result2, result1gbgb]
    # w/ fixMoves
    check nazo.permute(@[2.Positive], true, true, 1).toSeq == @[
      result1gbbg]
    check nazo.permute(@[1.Positive, 2.Positive], true, true, 1).toSeq == @[
      result1bgbg]

    # not allow last double
    check nazo.permute(newSeq[Positive](0), true, false, 1).toSeq == @[
      result1gbgb]

    # not allow double
    check nazo.permute(newSeq[Positive](0), false, false, 1).toSeq == @[
      result1gbgb]

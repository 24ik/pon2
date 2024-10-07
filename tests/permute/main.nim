{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, unittest, uri]
import ../../src/pon2/app/[permute]
import ../../src/pon2/core/[field, fqdn, nazopuyo, pairposition]

proc main*() =
  # ------------------------------------------------
  # Permute
  # ------------------------------------------------

  # permute
  block:
    let
      nazo = parseNazoPuyo[TsuField]("S00r0Mm6iOi_g1g1__u03", Ishikawa)

      result1gbgb = "gb12gb12".parsePairsPositions Pon2
      result1gbbg = "gb12bg21".parsePairsPositions Pon2
      result1bgbg = "bg21bg21".parsePairsPositions Pon2
      result2 = "gg1Nbb2N".parsePairsPositions Pon2

    # allow double
    # w/o fixMoves
    check nazo.permute(newSeq[Positive](0), allowDouble = true, allowLastDouble = true).toSeq ==
      @[result2, result1gbgb]
    # w/ fixMoves
    check nazo.permute(@[2.Positive], allowDouble = true, allowLastDouble = true).toSeq ==
      @[result1gbbg]
    check nazo.permute(
      @[1.Positive, 2.Positive], allowDouble = true, allowLastDouble = true
    ).toSeq == @[result1bgbg]

    # not allow last double
    check nazo.permute(newSeq[Positive](0), allowDouble = true, allowLastDouble = false).toSeq ==
      @[result1gbgb]

    # not allow double
    check nazo.permute(
      newSeq[Positive](0), allowDouble = false, allowLastDouble = false
    ).toSeq == @[result1gbgb]

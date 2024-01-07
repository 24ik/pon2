{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2pkg/corepkg/[cell, pair {.all.}]

proc main* =
  # ------------------------------------------------
  # Constructor
  # ------------------------------------------------

  # initPair
  block:
    check initPair(Yellow, Green) == YellowGreen
    check initPair(Purple, Purple) == PurplePurple

  # initPairs
  block:
    check initPairs([BlueRed, YellowPurple]) == [BlueRed, YellowPurple].toDeque
    check initPairs(BlueRed, YellowPurple) == [BlueRed, YellowPurple].toDeque

  # ------------------------------------------------
  # Property
  # ------------------------------------------------

  # axis, child
  block:
    check BlueRed.axis == Blue
    check BlueRed.child == Red

  # isDouble
  block:
    check not PurpleRed.isDouble
    check YellowYellow.isDouble

  # ------------------------------------------------
  # Operator
  # ------------------------------------------------

  # axis=, child=
  block:
    var pair = RedRed
    pair.axis = Blue
    check pair == BlueRed
    pair.child = Green
    check pair == BlueGreen

  # ==
  block:
    let
      pairsSeq = [RedRed, PurpleGreen]
      pairs1 = initPairs(pairsSeq)
    var pairs2 = initPairs()
    pairs2.addLast pairsSeq[0]
    pairs2.addLast pairsSeq[1]
    check pairs1 == pairs2

  # ------------------------------------------------
  # Swap
  # ------------------------------------------------

  # swapped, swap
  block:
    check YellowBlue.swapped == BlueYellow
    check RedRed.swapped == RedRed

    var pair = GreenPurple
    pair.swap
    check pair == PurpleGreen

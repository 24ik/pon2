{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2pkg/core/[cell, host, pair {.all.}]

proc main*() =
  # ------------------------------------------------
  # Constructor
  # ------------------------------------------------

  # initPair
  block:
    check initPair(Yellow, Green) == YellowGreen
    check initPair(Purple, Purple) == PurplePurple

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

  # ------------------------------------------------
  # Count
  # ------------------------------------------------

  # puyoCount, colorCount, garbageCount
  block:
    check YellowGreen.puyoCount(Yellow) == 1
    check YellowGreen.puyoCount(Green) == 1
    check YellowGreen.puyoCount(Purple) == 0
    check YellowGreen.puyoCount == 2
    check YellowGreen.colorCount == 2
    check YellowGreen.garbageCount == 0

  # ------------------------------------------------
  # Pair <-> string / URI
  # ------------------------------------------------

  # parsePair, toUriQuery
  block:
    check $RedGreen == "rg"
    check "rg".parsePair == RedGreen

    check RedGreen.toUriQuery(Izumiya) == "rg"
    check RedGreen.toUriQuery(Ishikawa) == "c"
    check RedGreen.toUriQuery(Ips) == "c"

    check "rg".parsePair(Izumiya) == RedGreen
    check "c".parsePair(Ishikawa) == RedGreen
    check "c".parsePair(Ips) == RedGreen

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/core/[cell, fqdn, pair]
import ../../src/pon2/private/[results2]

proc main*() =
  # ------------------------------------------------
  # Constructor
  # ------------------------------------------------

  # init
  block:
    check Pair.init(Yellow, Green) == YellowGreen
    check Pair.init(Purple, Purple) == PurplePurple

  # ------------------------------------------------
  # Property
  # ------------------------------------------------

  # pivot, rotor
  block:
    check BlueRed.pivot == Blue
    check BlueRed.rotor == Red

  # isDbl
  block:
    check not PurpleRed.isDbl
    check YellowYellow.isDbl

  # ------------------------------------------------
  # Operator
  # ------------------------------------------------

  # pivot=, rotor=
  block:
    var pair = RedRed
    pair.pivot = Blue
    check pair == BlueRed
    pair.rotor = Green
    check pair == BlueGreen

    pair.pivot = None
    check pair == BlueGreen
    pair.rotor = Garbage
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

  # cellCnt, colorCnt, garbageCnt
  block:
    check YellowGreen.cellCnt(Yellow) == 1
    check YellowGreen.cellCnt(Green) == 1
    check YellowGreen.cellCnt(Purple) == 0
    check YellowGreen.cellCnt == 2
    check YellowGreen.colorCnt == 2
    check YellowGreen.garbageCnt == 0

  # ------------------------------------------------
  # Pair <-> string / URI
  # ------------------------------------------------

  # Pair <-> string
  block:
    check $RedGreen == "rg"

    let pairRes = "rg".parsePair
    check pairRes == Res[Pair].ok RedGreen

    check "RG".parsePair.isErr

  # Pair <-> URI
  block:
    check RedGreen.toUriQuery(Pon2) == "rg"
    for fqdn in [Ishikawa, Ips]:
      check RedGreen.toUriQuery(fqdn) == "c"

    let pairRes = "rg".parsePair(Pon2)
    check pairRes == Res[Pair].ok RedGreen

    for fqdn in [Ishikawa, Ips]:
      let pairRes2 = "c".parsePair(fqdn)
      check pairRes2 == Res[Pair].ok RedGreen

    check "c".parsePair(Pon2).isErr
    check "rg".parsePair(Ishikawa).isErr
    check "rg".parsePair(Ips).isErr

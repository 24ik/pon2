{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar, unittest]
import ../../src/pon2/core/[cell, fqdn, pair]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

block: # init
  check Pair.init(Yellow, Green) == YellowGreen
  check Pair.init(Purple, Purple) == PurplePurple

  check Pair.init == Pair.low

# ------------------------------------------------
# Property
# ------------------------------------------------

block: # pivot, rotor
  check BlueRed.pivot == Blue
  check BlueRed.rotor == Red

block: # isDouble
  check not PurpleRed.isDouble
  check YellowYellow.isDouble

# ------------------------------------------------
# Operator
# ------------------------------------------------

block: # pivot=, rotor=
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

block: # swapped, swap
  check YellowBlue.swapped == BlueYellow
  check RedRed.swapped == RedRed
  check GreenPurple.dup(swap) == PurpleGreen

# ------------------------------------------------
# Count
# ------------------------------------------------

block: # cellCount, puyoCount, colorPuyoCount, garbagesCount
  check YellowGreen.cellCount(Yellow) == 1
  check YellowGreen.cellCount(Green) == 1
  check YellowGreen.cellCount(Purple) == 0
  check YellowGreen.puyoCount == 2
  check YellowGreen.colorPuyoCount == 2
  check YellowGreen.garbagesCount == 0

# ------------------------------------------------
# Pair <-> string / URI
# ------------------------------------------------

block: # Pair <-> string
  check $RedGreen == "rg"

  let pairRes = "rg".parsePair
  check pairRes == Pon2Result[Pair].ok RedGreen

  check "RG".parsePair.isErr
  check "".parsePair.isErr
  check "oo".parsePair.isErr

block: # Pair <-> URI
  check RedGreen.toUriQuery(Pon2) == "rg"
  for fqdn in [Ishikawa, Ips]:
    check RedGreen.toUriQuery(fqdn) == "c"

  let pairRes = "rg".parsePair(Pon2)
  check pairRes == Pon2Result[Pair].ok RedGreen

  for fqdn in [Ishikawa, Ips]:
    let pairRes2 = "c".parsePair(fqdn)
    check pairRes2 == Pon2Result[Pair].ok RedGreen

  check "c".parsePair(Pon2).isErr
  check "rg".parsePair(Ishikawa).isErr
  check "rg".parsePair(Ips).isErr

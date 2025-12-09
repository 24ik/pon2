{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar, unittest]
import ../../src/pon2/core/[fqdn, placement]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

block: # init
  check Placement.init(Col5, Left) == Left5
  check Placement.init == None

# ------------------------------------------------
# Property
# ------------------------------------------------

block: # pivotCol, rotorCol, rotorDir
  check Right2.pivotCol == Col2
  check Right2.rotorCol == Col3
  check Right2.rotorDir == Right

# ------------------------------------------------
# Move
# ------------------------------------------------

block: # movedRight, movedLeft, moveRight, moveLeft
  for (placement, answer) in [(Right2, Right3), (Left5, Left5), (None, None)]:
    check placement.movedRight == answer
    check placement.dup(moveRight) == answer

  for (placement, answer) in [(Down3, Down2), (Up0, Up0), (None, None)]:
    check placement.movedLeft == answer
    check placement.dup(moveLeft) == answer

# ------------------------------------------------
# Rotate
# ------------------------------------------------

block: # rotatedRight, rotatedLeft, rotateRight, rotateLeft
  for (placement, answer) in [(Left4, Up4), (Up5, Right4), (None, None)]:
    check placement.rotatedRight == answer
    check placement.dup(rotateRight) == answer

  for (placement, answer) in [(Down4, Right4), (Up0, Left1), (None, None)]:
    check placement.rotatedLeft == answer
    check placement.dup(rotateLeft) == answer

# ------------------------------------------------
# Placement <-> string / URI
# ------------------------------------------------

block: # Placement <-> string
  check $Right2 == "34"
  check "34".parsePlacement == Pon2Result[Placement].ok Right2

  check $None == ""
  check "".parsePlacement == Pon2Result[Placement].ok None

  check "33".parsePlacement.isErr

block: # Placement <-> URI
  check Right2.toUriQuery(Pon2) == "34"
  check "34".parsePlacement(Pon2) == Pon2Result[Placement].ok Right2
  check None.toUriQuery(Pon2) == ""
  check "".parsePlacement(Pon2) == Pon2Result[Placement].ok None

  for fqdn in [Ishikawa, Ips]:
    check Right2.toUriQuery(fqdn) == "g"
    check "g".parsePlacement(fqdn) == Pon2Result[Placement].ok Right2
    check None.toUriQuery(fqdn) == "1"
    check "1".parsePlacement(fqdn) == Pon2Result[Placement].ok None

  check "g".parsePlacement(Pon2).isErr
  check "34".parsePlacement(Ishikawa).isErr
  check "".parsePlacement(Ips).isErr

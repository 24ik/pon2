{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar, unittest]
import ../../src/pon2/core/[common, fqdn, placement]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

block: # init
  check Placement.init(Col5, Left) == Left5

  let dir = Down
  check Placement.init(Col2, dir) == Down2

  check Placement.init == Placement.low

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
  for (plcmt, answer) in [(Right2, Right3), (Left5, Left5)]:
    check plcmt.movedRight == answer
    check plcmt.dup(moveRight) == answer

  for (plcmt, answer) in [(Down3, Down2), (Up0, Up0)]:
    check plcmt.movedLeft == answer
    check plcmt.dup(moveLeft) == answer

# ------------------------------------------------
# Rotate
# ------------------------------------------------

block: # rotatedRight, rotatedLeft, rotateRight, rotateLeft
  for (plcmt, answer) in [(Left4, Up4), (Up5, Right4)]:
    check plcmt.rotatedRight == answer
    check plcmt.dup(rotateRight) == answer

  for (plcmt, answer) in [(Down4, Right4), (Up0, Left1)]:
    check plcmt.rotatedLeft == answer
    check plcmt.dup(rotateLeft) == answer

# ------------------------------------------------
# Placement <-> string / URI
# ------------------------------------------------

block: # Placement <-> string
  check $Right2 == "34"

  let plcmtRes = "34".parsePlacement
  check plcmtRes == Res[Placement].ok Right2

  check "".parsePlacement.isErr
  check "33".parsePlacement.isErr

block: # OptPlacement <-> string
  check $OptPlacement.ok(Down5) == "6S"
  check $NonePlacement == ""

  let optPlcmtRes = "6S".parseOptPlacement
  check optPlcmtRes == Res[OptPlacement].ok OptPlacement.ok Down5

  let optPlcmtRes2 = "".parseOptPlacement
  check optPlcmtRes2 == Res[OptPlacement].ok NonePlacement

  check "6s".parseOptPlacement.isErr

block: # Placement <-> URI
  check Right2.toUriQuery(Pon2) == "34"
  for fqdn in [Ishikawa, Ips]:
    check Right2.toUriQuery(fqdn) == "g"

  let plcmtRes = "34".parsePlacement Pon2
  check plcmtRes == Res[Placement].ok Right2
  for fqdn in [Ishikawa, Ips]:
    let plcmtRes2 = "g".parsePlacement(fqdn)
    check plcmtRes2 == Res[Placement].ok Right2

  check "g".parsePlacement(Pon2).isErr
  check "34".parsePlacement(Ishikawa).isErr
  check "34".parsePlacement(Ips).isErr

block: # OptPlacement <-> URI
  check OptPlacement.ok(Right2).toUriQuery(Pon2) == "34"
  check NonePlacement.toUriQuery(Pon2) == ""
  for fqdn in [Ishikawa, Ips]:
    check OptPlacement.ok(Right2).toUriQuery(fqdn) == "g"
    check NonePlacement.toUriQuery(fqdn) == "1"

  let
    optPlcmtRes = "34".parseOptPlacement Pon2
    optPlcmtRes2 = "".parseOptPlacement Pon2
  check optPlcmtRes == Res[OptPlacement].ok OptPlacement.ok Right2
  check optPlcmtRes2 == Res[OptPlacement].ok NonePlacement
  for fqdn in [Ishikawa, Ips]:
    let
      optPlcmtRes3 = "g".parseOptPlacement fqdn
      optPlcmtRes4 = "1".parseOptPlacement fqdn
    check optPlcmtRes3 == Res[OptPlacement].ok OptPlacement.ok Right2
    check optPlcmtRes4 == Res[OptPlacement].ok NonePlacement

  check "1".parseOptPlacement(Pon2).isErr
  check "".parseOptPlacement(Ishikawa).isErr
  check "".parseOptPlacement(Ips).isErr

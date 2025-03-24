{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar, unittest]
import results
import ../../src/pon2/core/[common, fqdn, placement]

proc main*() =
  # ------------------------------------------------
  # Constructor
  # ------------------------------------------------

  # init
  block:
    check Placement.init(Col5, Left) == Left5

  # ------------------------------------------------
  # Property
  # ------------------------------------------------

  # pivotCol, rotorCol, rotorDir
  block:
    check Right2.pivotCol == Col2
    check Right2.rotorCol == Col3
    check Right2.rotorDir == Right

  # ------------------------------------------------
  # Move
  # ------------------------------------------------

  # movedRight, movedLeft, moveRight, moveLeft
  block:
    for (plcmt, answer) in [(Right2, Right3), (Left5, Left5)]:
      check plcmt.movedRight == answer
      check plcmt.dup(moveRight) == answer

    for (plcmt, answer) in [(Down3, Down2), (Up0, Up0)]:
      check plcmt.movedLeft == answer
      check plcmt.dup(moveLeft) == answer

  # ------------------------------------------------
  # Rotate
  # ------------------------------------------------

  # rotatedRight, rotatedLeft, rotateRight, rotateLeft
  block:
    for (plcmt, answer) in [(Left4, Up4), (Up5, Right4)]:
      check plcmt.rotatedRight == answer
      check plcmt.dup(rotateRight) == answer

    for (plcmt, answer) in [(Down4, Right4), (Up0, Left1)]:
      check plcmt.rotatedLeft == answer
      check plcmt.dup(rotateLeft) == answer

  # ------------------------------------------------
  # Placement <-> string / URI
  # ------------------------------------------------

  # Placement <-> string
  block:
    check $Right2 == "34"

    let plcmtRes = "34".parsePlacement
    check plcmtRes.isOk and plcmtRes.value == Right2

    check "".parsePlacement.isErr
    check "33".parsePlacement.isErr

  # Opt[Placement] <-> string
  block:
    check $Opt[Placement].ok(Down5) == "6S"
    check $NonePlacement == ""

    let optPlcmtRes = "6S".parseOptPlacement
    check optPlcmtRes.isOk and optPlcmtRes.value == Opt[Placement].ok(Down5)

    let optPlcmtRes2 = "".parseOptPlacement
    check optPlcmtRes2.isOk and optPlcmtRes2.value == NonePlacement

    check "6s".parseOptPlacement.isErr

  # Placement <-> URI
  block:
    check Right2.toUriQuery(Pon2) == "34"
    for fqdn in [Ishikawa, Ips]:
      check Right2.toUriQuery(fqdn) == "g"

    let plcmtRes = "34".parsePlacement(Pon2)
    check plcmtRes.isOk and plcmtRes.value == Right2
    for fqdn in [Ishikawa, Ips]:
      let plcmtRes2 = "g".parsePlacement(fqdn)
      check plcmtRes2.isOk and plcmtRes2.value == Right2

    check "g".parsePlacement(Pon2).isErr
    check "34".parsePlacement(Ishikawa).isErr
    check "34".parsePlacement(Ips).isErr

  # Opt[Placement] <-> URI
  block:
    check Opt[Placement].ok(Right2).toUriQuery(Pon2) == "34"
    check NonePlacement.toUriQuery(Pon2) == ""
    for fqdn in [Ishikawa, Ips]:
      check Opt[Placement].ok(Right2).toUriQuery(fqdn) == "g"
      check NonePlacement.toUriQuery(fqdn) == "1"

    let
      optPlcmtRes = "34".parseOptPlacement(Pon2)
      optPlcmtRes2 = "".parseOptPlacement(Pon2)
    check optPlcmtRes.isOk and optPlcmtRes.value == Opt[Placement].ok(Right2)
    check optPlcmtRes2.isOk and optPlcmtRes2.value == NonePlacement
    for fqdn in [Ishikawa, Ips]:
      let
        optPlcmtRes3 = "g".parseOptPlacement(fqdn)
        optPlcmtRes4 = "1".parseOptPlacement(fqdn)
      check optPlcmtRes3.isOk and optPlcmtRes3.value == Opt[Placement].ok(Right2)
      check optPlcmtRes4.isOk and optPlcmtRes4.value == NonePlacement

    check "1".parseOptPlacement(Pon2).isErr
    check "".parseOptPlacement(Ishikawa).isErr
    check "".parseOptPlacement(Ips).isErr

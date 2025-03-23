{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import results
import ../../src/pon2/core/[common, fqdn, pos]

proc main*() =
  # ------------------------------------------------
  # Constructor
  # ------------------------------------------------

  # init
  block:
    check Pos.init(Col5, Left) == Left5

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
    for (pos, answer) in [(Right2, Right3), (Left5, Left5)]:
      check pos.movedRight == answer

      var pos2 = pos
      pos2.moveRight
      check pos2 == answer

    for (pos, answer) in [(Down3, Down2), (Up0, Up0)]:
      check pos.movedLeft == answer

      var pos2 = pos
      pos2.moveLeft
      check pos2 == answer

  # ------------------------------------------------
  # Rotate
  # ------------------------------------------------

  # rotatedRight, rotatedLeft, rotateRight, rotateLeft
  block:
    for (pos, answer) in [(Left4, Up4), (Up5, Right4)]:
      check pos.rotatedRight == answer

      var pos2 = pos
      pos2.rotateRight
      check pos2 == answer

    for (pos, answer) in [(Down4, Right4), (Up0, Left1)]:
      check pos.rotatedLeft == answer

      var pos2 = pos
      pos2.rotateLeft
      check pos2 == answer

  # ------------------------------------------------
  # Pos <-> string / URI
  # ------------------------------------------------

  # Pos <-> string
  block:
    check $Right2 == "34"

    let posRes = "34".parsePos
    check posRes.isOk and posRes.value == Right2

    check "".parsePos.isErr
    check "33".parsePos.isErr

  # OptPos <-> string
  block:
    check $OptPos.ok(Down5) == "6S"
    check $NonePos == ""

    let optPosRes = "6S".parseOptPos
    check optPosRes.isOk and optPosRes.value == OptPos.ok(Down5)

    let optPosRes2 = "".parseOptPos
    check optPosRes2.isOk and optPosRes2.value == NonePos

    check "6s".parseOptPos.isErr

  # Pos <-> URI
  block:
    check Right2.toUriQuery(Pon2) == "34"
    for fqdn in [Ishikawa, Ips]:
      check Right2.toUriQuery(fqdn) == "g"

    let posRes = "34".parsePos(Pon2)
    check posRes.isOk and posRes.value == Right2
    for fqdn in [Ishikawa, Ips]:
      let posRes2 = "g".parsePos(fqdn)
      check posRes2.isOk and posRes2.value == Right2

    check "g".parsePos(Pon2).isErr
    check "34".parsePos(Ishikawa).isErr
    check "34".parsePos(Ips).isErr

  # OptPos <-> URI
  block:
    check OptPos.ok(Right2).toUriQuery(Pon2) == "34"
    check NonePos.toUriQuery(Pon2) == ""
    for fqdn in [Ishikawa, Ips]:
      check OptPos.ok(Right2).toUriQuery(fqdn) == "g"
      check NonePos.toUriQuery(fqdn) == "1"

    let
      optPosRes = "34".parseOptPos(Pon2)
      optPosRes2 = "".parseOptPos(Pon2)
    check optPosRes.isOk and optPosRes.value == OptPos.ok(Right2)
    check optPosRes2.isOk and optPosRes2.value == NonePos
    for fqdn in [Ishikawa, Ips]:
      let
        optPosRes3 = "g".parseOptPos(fqdn)
        optPosRes4 = "1".parseOptPos(fqdn)
      check optPosRes3.isOk and optPosRes3.value == OptPos.ok(Right2)
      check optPosRes4.isOk and optPosRes4.value == NonePos

    check "1".parseOptPos(Pon2).isErr
    check "".parseOptPos(Ishikawa).isErr
    check "".parseOptPos(Ips).isErr

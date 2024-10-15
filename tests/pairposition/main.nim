{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques, unittest]
import ../../src/pon2/core/[cell, fqdn, pair, pairposition, position]

proc main*() =
  # ------------------------------------------------
  # Property
  # ------------------------------------------------

  # `positions=`
  block:
    var pairsPositions = [
      PairPosition(pair: RedGreen, position: Position.None),
      PairPosition(pair: YellowYellow, position: Right3),
      PairPosition(pair: BluePurple, position: Left2),
    ].toDeque
    pairsPositions.positions = [Up0, Position.None].toDeque
    check pairsPositions == [
      PairPosition(pair: RedGreen, position: Up0),
      PairPosition(pair: YellowYellow, position: Position.None),
      PairPosition(pair: BluePurple, position: Position.None),
    ].toDeque

  # ------------------------------------------------
  # Count
  # ------------------------------------------------

  # puyoCount, colorCount, garbageCount
  block:
    let pairsPositions = [
      PairPosition(pair: RedGreen, position: Position.None),
      PairPosition(pair: YellowYellow, position: Position.None),
    ].toDeque
    check pairsPositions.puyoCount(Red) == 1
    check pairsPositions.puyoCount(Yellow) == 2
    check pairsPositions.puyoCount(Purple) == 0
    check pairsPositions.puyoCount == 4
    check pairsPositions.colorCount == 4
    check pairsPositions.garbageCount == 0

  # ------------------------------------------------
  # Pair&Position <-> string / URI
  # ------------------------------------------------

  # `$`, parsePairPosition, toUriQuery
  block:
    let pairPos = PairPosition(pair: BluePurple, position: Left3)

    check $pairPos == "bp|43"
    check "bp|43".parsePairPosition == pairPos

    check pairPos.toUriQuery(Pon2) == "bp43"
    check pairPos.toUriQuery(Ishikawa) == "QG"
    check pairPos.toUriQuery(Ips) == "QG"

    check "bp43".parsePairPosition(Pon2) == pairPos
    check "QG".parsePairPosition(Ishikawa) == pairPos
    check "QG".parsePairPosition(Ips) == pairPos

  # ------------------------------------------------
  # Pairs&Positions <-> string / URI
  # ------------------------------------------------

  # `$`, parsePairPosition, toUriQuery
  block:
    let pairsPositions = [
      PairPosition(pair: RedGreen, position: Position.None),
      PairPosition(pair: YellowYellow, position: Up2),
    ].toDeque

    check $pairsPositions == "rg|\nyy|3N"
    check "rg|\nyy|3N".parsePairsPositions == pairsPositions

    check pairsPositions.toUriQuery(Pon2) == "rgyy3N"
    check pairsPositions.toUriQuery(Ishikawa) == "c1G4"
    check pairsPositions.toUriQuery(Ips) == "c1G4"

    check "rgyy3N".parsePairsPositions(Pon2) == pairsPositions
    check "c1G4".parsePairsPositions(Ishikawa) == pairsPositions
    check "c1G4".parsePairsPositions(Ips) == pairsPositions

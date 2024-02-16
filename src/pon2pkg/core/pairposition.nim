## This module implements pairs with positions.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, strformat, strutils, sugar]
import ./[host, pair, position]
import ../private/[misc]

type
  PairPosition* = object ## Pair and position.
    pair*: Pair
    position*: Position

  PairsPositions* = seq[PairPosition] ## Pairs and Positions.

# ------------------------------------------------
# Count
# ------------------------------------------------

func puyoCount*(pairsPositions: PairsPositions, puyo: Puyo): int {.inline.} =
  ## Returns the number of `puyo` in the pairs.
  sum2 pairsPositions.mapIt it.pair.puyoCount puyo

func puyoCount*(pairsPositions: PairsPositions): int {.inline.} =
  ## Returns the number of puyos in the pairs.
  sum2 pairsPositions.mapIt it.pair.puyoCount

func colorCount*(pairsPositions: PairsPositions): int {.inline.} =
  ## Returns the number of color puyos in the pairs.
  sum2 pairsPositions.mapIt it.pair.colorCount

func garbageCount*(pairsPositions: PairsPositions): int {.inline.} =
  ## Returns the number of garbage puyos in the pairs.
  sum2 pairsPositions.mapIt it.pair.garbageCount

# ------------------------------------------------
# PairPosition <-> string
# ------------------------------------------------

const PairPosSep = '|'

func `$`*(pairPosition: PairPosition): string {.inline.} =
  &"{self.pair}{PairPosSep}{self.position}"

func parsePairPosition*(str: string): PairPosition {.inline.} =
  ## Returns the pair&position converted from the string representation.
  ## If the string is invalid, `ValueError` is raised.
  let strs = str.split PairPosSep
  if strs.len != 2:
    raise newException(ValueError, "Invalid pair&position: " & str)

  result.pair = strs[0].parsePair
  result.position = strs[1].parsePosition

# ------------------------------------------------
# PairsPositions <-> string
# ------------------------------------------------

const PairsPositionsSep = "\n"

func `$`*(pairsPositions: PairsPositions): string {.inline.} =
  let strs = collect:
    for pairPos in pairsPositions:
      $pairPos

  result = strs.join PairsPositionsSep

func parsePairsPositions*(str: string): PairsPositions {.inline.} =
  ## Returns the pairs&positions converted from the string representation.
  ## If the string is invalid, `ValueError` is raised.
  if str == "":
    newSeq[PairPosition](0)
  else:
    str.split(PairsPositionsSep).mapIt it.parsePairPosition

# ------------------------------------------------
# PairPosition <-> URI
# ------------------------------------------------

func toUriQuery*(pairPosition: PairPosition, host: SimulatorHost): string {.inline.} =
  ## Returns the URI query converted from the pair&position.
  &"{self.pair.toUriQuery host}{self.position.toUriQuery host}"

func parsePairPosition*(query: string, host: SimulatorHost): PairPosition {.inline.} =
  ## Returns the pair&position converted from the URI query.
  ## If the query is invalid, `ValueError` is raised.
  # NOTE: this function is not robust; dependent on the current URI format
  case host
  of Izumiya:
    result.pair = query[0 ..< 2].parsePair host
    result.position = query[2 ..^ 1].parsePosition host
  of Ishikawa, Ips:
    result.pair = query[0 .. 0].parsePair host
    result.position = query[1 ..^ 1].parsePosition host

# ------------------------------------------------
# PairsPositions <-> URI
# ------------------------------------------------

func toUriQuery*(pairsPositions: PairsPositions, host: SimulatorHost): string {.inline.} =
  ## Returns the URI query converted from the pairs&positions.
  let strs = collect:
    for pairPos in pairsPositions:
      pairPos.toUriQuery host

  result = strs.join

func parsePairsPositions*(query: string, host: SimulatorHost): PairsPosition {.inline.} =
  ## Returns the pairs&positions converted from the URI query.
  ## If the query is invalid, `ValueError` is raised.
  # NOTE: this function is not robust; dependent on the current URI format
  if query.len mod 2 != 0:
    raise newException(ValueError, "Invalid pairs&positions: ", query)

  result = newSeqOfCap[PairPosition](query.len div 2)

  case host
  of Izumiya:
    var idx = 0
    while idx < query.len:
      try:
        if idx.succ(4) >= query.len:
          raise newException(ValueError, "This exception cannot occur.")

        result.add query[idx ..< idx.succ 4].parsePairPosition host
        idx.inc 4
      except ValueError:
        result.add query[idx ..< idx.succ 2].parsePairPosition host
        idx.inc 2
  of Ishikawa, Ips:
    for i in countup(0, query.len, 2):
      result.add query[idx .. idx.succ].parsePairPosition host

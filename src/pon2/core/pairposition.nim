## This module implements pairs with positions.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques, sequtils, strformat, strutils, sugar]
import ./[cell, fqdn, pair, position]
import ../private/[misc]

export deques.`==` # NOTE: need to be exported otherwise system.`==` is used

type
  PairPosition* = object ## Pair and position.
    pair*: Pair
    position*: Position

  PairsPositions* = Deque[PairPosition] ## Pairs and Positions.

# ------------------------------------------------
# Copy
# ------------------------------------------------

func copy*(pairsPositions: PairsPositions): PairsPositions {.inline.} =
  ## Returns a copy of the pairs&positions.
  misc.copy pairsPositions

# ------------------------------------------------
# Property
# ------------------------------------------------

func `positions=`*(
    pairsPositions: var PairsPositions, positions: Deque[Position]
) {.inline.} =
  ## Sets the positions.
  ## If `positions` is shorter than `pairsPositions`, the rest of the positions
  ## are filled with `Position.None`.
  assert positions.len <= pairsPositions.len

  for pairIdx, pos in positions:
    pairsPositions[pairIdx].position = pos
  for pairIdx in positions.len ..< pairsPositions.len:
    pairsPositions[pairIdx].position = Position.None

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
  &"{pairPosition.pair}{PairPosSep}{pairPosition.position}"

func parsePairPosition*(str: string): PairPosition {.inline.} =
  ## Returns the pair&position converted from the string representation.
  ## If the string is invalid, `ValueError` is raised.
  let strs = str.split PairPosSep
  if strs.len != 2:
    raise newException(ValueError, "Invalid pair&position: " & str)

  result = PairPosition(pair: strs[0].parsePair, position: strs[1].parsePosition)

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
  {.push warning[Uninit]: off.}
  result =
    if str == "":
      initDeque[PairPosition]()
    else:
      str.split(PairsPositionsSep).mapIt(it.parsePairPosition).toDeque
  {.pop.}

# ------------------------------------------------
# PairPosition <-> URI
# ------------------------------------------------

func toUriQuery*(pairPosition: PairPosition, fqdn = Pon2): string {.inline.} =
  ## Returns the URI query converted from the pair&position.
  &"{pairPosition.pair.toUriQuery fqdn}{pairPosition.position.toUriQuery fqdn}"

func parsePairPosition*(query: string, fqdn: IdeFqdn): PairPosition {.inline.} =
  ## Returns the pair&position converted from the URI query.
  ## If the query is invalid, `ValueError` is raised.
  case fqdn
  of Pon2:
    PairPosition(
      pair: query[0 ..< 2].parsePair fqdn, position: query[2 ..^ 1].parsePosition fqdn
    )
  of Ishikawa, Ips:
    PairPosition(
      pair: query[0 .. 0].parsePair fqdn, position: query[1 ..^ 1].parsePosition fqdn
    )

# ------------------------------------------------
# PairsPositions <-> URI
# ------------------------------------------------

func toUriQuery*(pairsPositions: PairsPositions, fqdn = Pon2): string {.inline.} =
  ## Returns the URI query converted from the pairs&positions.
  let strs = collect:
    for pairPos in pairsPositions:
      pairPos.toUriQuery fqdn

  result = strs.join

func parsePairsPositions*(query: string, fqdn: IdeFqdn): PairsPositions {.inline.} =
  ## Returns the pairs&positions converted from the URI query.
  ## If the query is invalid, `ValueError` is raised.
  if query.len mod 2 != 0:
    raise newException(ValueError, "Invalid pairs&positions: " & query)

  result = initDeque(query.len div 2)

  case fqdn
  of Pon2:
    var idx = 0
    while idx < query.len:
      try:
        if idx.succ(4) > query.len:
          raise newException(ValueError, "This exception should be caught.")

        result.addLast query[idx ..< idx.succ 4].parsePairPosition fqdn
        idx.inc 4
      except ValueError:
        result.addLast query[idx ..< idx.succ 2].parsePairPosition fqdn
        idx.inc 2
  of Ishikawa, Ips:
    for i in countup(0, query.len.pred, 2):
      result.addLast query[i .. i.succ].parsePairPosition fqdn

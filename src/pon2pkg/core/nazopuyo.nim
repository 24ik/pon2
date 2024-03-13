## This module implements Nazo Puyos.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, strutils, tables, uri]
import ./[field, host, pairposition, puyopuyo, requirement, rule]

type NazoPuyo*[F: TsuField or WaterField] = object ## Nazo Puyo.
  puyoPuyo*: PuyoPuyo[F]
  requirement*: Requirement

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const DefaultRequirement = Requirement(kind: Clear, color: All, number: 0)

func initNazoPuyo*[F: TsuField or WaterField](): NazoPuyo[F] {.inline.} =
  ## Returns the initial nazo puyo.
  result.puyoPuyo = initPuyoPuyo[F]()
  result.requirement = DefaultRequirement

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `==`*(self: NazoPuyo[TsuField], puyoPuyo: NazoPuyo[WaterField]): bool {.inline.} =
  false

func `==`*(self: NazoPuyo[WaterField], field: NazoPuyo[TsuField]): bool {.inline.} =
  false

# ------------------------------------------------
# Property
# ------------------------------------------------

func rule*[F: TsuField or WaterField](self: NazoPuyo[F]): Rule {.inline.} =
  ## Returns the rule.
  self.puyoPuyo.rule

func moveCount*[F: TsuField or WaterField](self: NazoPuyo[F]): int {.inline.} =
  ## Returns the number of moves of the nazo puyo.
  self.puyoPuyo.pairsPositions.len

# ------------------------------------------------
# Nazo Puyo <-> string
# ------------------------------------------------

const ReqPuyoPuyoSep = "\n======\n"

func `$`*[F: TsuField or WaterField](self: NazoPuyo[F]): string {.inline.} =
  # HACK: cannot `strformat` here due to inlining error
  $self.requirement & ReqPuyoPuyoSep & $self.puyoPuyo

func parseNazoPuyo*[F: TsuField or WaterField](str: string): NazoPuyo[F] {.inline.} =
  ## Returns the Nazo Puyo converted from the string representation.
  ## If the string is invalid, `ValueError` is raised.
  let strs = str.split ReqPuyoPuyoSep
  if strs.len != 2:
    raise newException(ValueError, "Invalid Nazo Puyo: " & str)

  result.requirement = strs[0].parseRequirement
  result.puyoPuyo = parsePuyoPuyo[F](strs[1])

# ------------------------------------------------
# Nazo Puyo <-> URI
# ------------------------------------------------

func toUriQuery*[F: TsuField or WaterField](
    self: NazoPuyo[F], host: SimulatorHost
): string {.inline.} =
  ## Returns the URI query converted from the Nazo Puyo.
  let sep =
    case host
    of Izumiya: "&"
    of Ishikawa, Ips: "__"

  result = &"{self.puyoPuyo.toUriQuery host}{sep}{self.requirement.toUriQuery host}"

func parseNazoPuyo*[F: TsuField or WaterField](
    query: string, host: SimulatorHost
): NazoPuyo[F] {.inline.} =
  ## Returns the Nazo Puyo converted from the URI query.
  ## If the query is invalid, `ValueError` is raised.
  case host
  of Izumiya:
    var
      puyoPuyoKeyVals = newSeq[(string, string)](0)
      reqKeyVals = newSeq[(string, string)](0)
    for (key, val) in query.decodeQuery:
      if key in RequirementQueryKeys:
        reqKeyVals.add (key, val)
      else:
        puyoPuyoKeyVals.add (key, val)

    result.puyoPuyo = parsePuyoPuyo[F](puyoPuyoKeyVals.encodeQuery, host)
    result.requirement = reqKeyVals.encodeQuery.parseRequirement host
  of Ishikawa, Ips:
    let queries = query.split "__"
    case queries.len
    of 2:
      result.puyoPuyo = parsePuyoPuyo[F](queries[0], host)
      result.requirement = queries[1].parseRequirement host
    else:
      raise newException(ValueError, "Invalid Nazo Puyo: " & query)

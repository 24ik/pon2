## This module implements Nazo Puyos.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options, strformat, strutils, tables, uri]
import ./[field, fqdn, puyopuyo, requirement, rule]

type NazoPuyo*[F: TsuField or WaterField] = object ## Nazo Puyo.
  puyoPuyo*: PuyoPuyo[F]
  requirement*: Requirement

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const DefaultRequirement = initRequirement(Clear, All)

func initNazoPuyo*[F: TsuField or WaterField](): NazoPuyo[F] {.inline.} =
  ## Returns the initial nazo puyo.
  NazoPuyo[F](puyoPuyo: initPuyoPuyo[F](), requirement: DefaultRequirement)

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `==`*(nazo1: NazoPuyo[TsuField], nazo2: NazoPuyo[WaterField]): bool {.inline.} =
  false

func `==`*(nazo1: NazoPuyo[WaterField], nazo2: NazoPuyo[TsuField]): bool {.inline.} =
  false

# ------------------------------------------------
# Convert
# ------------------------------------------------

func toTsuNazoPuyo*[F: TsuField or WaterField](
    self: NazoPuyo[F]
): NazoPuyo[TsuField] {.inline.} =
  ## Returns the Tsu Nazo Puyo converted from the given Nazo Puyo.
  NazoPuyo[TsuField](
    puyoPuyo: self.puyoPuyo.toTsuPuyoPuyo, requirement: self.requirement
  )

func toWaterNazoPuyo*[F: TsuField or WaterField](
    self: NazoPuyo[F]
): NazoPuyo[WaterField] {.inline.} =
  ## Returns the Water Nazo Puyo converted from the given Nazo Puyo.
  NazoPuyo[WaterField](
    puyoPuyo: self.puyoPuyo.toWaterPuyoPuyo, requirement: self.requirement
  )

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

  result = NazoPuyo[F](
    puyoPuyo: parsePuyoPuyo[F](strs[1]), requirement: strs[0].parseRequirement
  )

# ------------------------------------------------
# Nazo Puyo <-> URI
# ------------------------------------------------

func toUriQuery*[F: TsuField or WaterField](
    self: NazoPuyo[F], fqdn = Pon2
): string {.inline.} =
  ## Returns the URI query converted from the Nazo Puyo.
  let sep =
    case fqdn
    of Pon2: "&"
    of Ishikawa, Ips: "__"

  result = &"{self.puyoPuyo.toUriQuery fqdn}{sep}{self.requirement.toUriQuery fqdn}"

func parseNazoPuyo*[F: TsuField or WaterField](
    query: string, fqdn: IdeFqdn
): NazoPuyo[F] {.inline.} =
  ## Returns the Nazo Puyo converted from the URI query.
  ## If the query is invalid, `ValueError` is raised.
  case fqdn
  of Pon2:
    var
      puyoPuyoKeyVals = newSeq[(string, string)](0)
      reqKeyVals = newSeq[(string, string)](0)
    for (key, val) in query.decodeQuery:
      if key in RequirementQueryKeys:
        reqKeyVals.add (key, val)
      else:
        puyoPuyoKeyVals.add (key, val)

    result = NazoPuyo[F](
      puyoPuyo: parsePuyoPuyo[F](puyoPuyoKeyVals.encodeQuery, fqdn),
      requirement: reqKeyVals.encodeQuery.parseRequirement fqdn,
    )
  of Ishikawa, Ips:
    let queries = query.split "__"
    case queries.len
    of 2:
      result = NazoPuyo[F](
        puyoPuyo: parsePuyoPuyo[F](queries[0], fqdn),
        requirement: queries[1].parseRequirement fqdn,
      )
    else:
      raise newException(ValueError, "Invalid Nazo Puyo: " & query)

## This module implements Nazo Puyo wrappers.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat]
import ../[core]
import ../private/[assign, macros, results2, strutils]

export core, results2

type NazoPuyoWrap* = object ## Nazo puyo wrapper.
  case rule*: Rule
  of Tsu:
    tsu: NazoPuyo[TsuField]
  of Water:
    water: NazoPuyo[WaterField]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type NazoPuyoWrap, nazo: NazoPuyo[TsuField]): T =
  T(rule: Tsu, tsu: nazo)

func init*(T: type NazoPuyoWrap, nazo: NazoPuyo[WaterField]): T =
  T(rule: Water, water: nazo)

func init*[F: TsuField or WaterField](T: type NazoPuyoWrap, puyoPuyo: PuyoPuyo[F]): T =
  T.init NazoPuyo[F].init(puyoPuyo, Goal.init)

func init*(T: type NazoPuyoWrap): T =
  T.init NazoPuyo[TsuField].init

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `==`*(field1: TsuField, field2: WaterField): bool =
  # NOTE: this function may be needed in `unwrap`.
  false

func `==`*(field1: WaterField, field2: TsuField): bool =
  # NOTE: this function may be needed in `unwrap`.
  false

func `==`*(wrap1, wrap2: NazoPuyoWrap): bool =
  if wrap1.rule != wrap2.rule:
    return false

  case wrap1.rule
  of Tsu:
    wrap1.tsu == wrap2.tsu
  of Water:
    wrap1.water == wrap2.water

# ------------------------------------------------
# Internal Access
# ------------------------------------------------

macro unwrap*(self: untyped, body: untyped): untyped =
  ## Runs `body` with `it` (internal `NazoPuyo`) exposed.
  ## Note that this macro may be incompatible with "method-like" calling.
  let
    nazoT = quote:
      `self`.tsu
    nazoW = quote:
      `self`.water

    bodyT = body.replaced("it".ident, nazoT)
    bodyW = body.replaced("it".ident, nazoW)

  quote:
    case `self`.rule
    of Tsu: `bodyT`
    of Water: `bodyW`

# ------------------------------------------------
# Rule
# ------------------------------------------------

func setRule*(self: NazoPuyoWrap, rule: Rule): NazoPuyoWrap {.inline, noinit.} =
  ## Returns the Nazo Puyo wrapper with the specified rule set.
  if rule == self.rule:
    return self

  self.unwrap:
    case rule
    of Tsu:
      NazoPuyoWrap.init NazoPuyo[TsuField].init(
        PuyoPuyo[TsuField].init(it.puyoPuyo.field.toTsuField, it.puyoPuyo.steps),
        it.goal,
      )
    of Water:
      NazoPuyoWrap.init NazoPuyo[WaterField].init(
        PuyoPuyo[WaterField].init(it.puyoPuyo.field.toWaterField, it.puyoPuyo.steps),
        it.goal,
      )

# ------------------------------------------------
# Nazo Puyo wrapper <-> URI
# ------------------------------------------------

func toUriQuery*(self: NazoPuyoWrap, fqdn: SimulatorFqdn): StrErrorResult[string] =
  ## Returns the URI query converted from the Nazo Puyo wrapper.
  self.unwrap:
    it.toUriQuery(fqdn).context "Invalid Nazo Puyo wrapper"

func parseNazoPuyoWrap*(
    query: string, fqdn: SimulatorFqdn
): StrErrorResult[NazoPuyoWrap] =
  ## Returns the Nazo Puyo wrapper converted from the URI query.
  let errorMsg = "Invalid Nazo Puyo wrapper: {query}".fmt

  case fqdn
  of Pon2:
    if "field={Water}_".fmt in query:
      ok NazoPuyoWrap.init ?parseNazoPuyo[WaterField](query, fqdn).context errorMsg
    else:
      ok NazoPuyoWrap.init ?parseNazoPuyo[TsuField](query, fqdn).context errorMsg
  of Ishikawa, Ips:
    if "__" in query:
      ok NazoPuyoWrap.init ?parseNazoPuyo[TsuField](query, fqdn).context errorMsg
    else:
      ok NazoPuyoWrap.init ?parsePuyoPuyo[TsuField](query, fqdn).context errorMsg

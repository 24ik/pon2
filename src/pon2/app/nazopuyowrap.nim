## This module implements Nazo Puyo wrappers.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat]
import ../[core]
import ../private/[assign3, macros2, results2, strutils2]

export results2

type NazoPuyoWrap* = object ## Nazo puyo wrapper.
  optGoal*: Opt[Goal]
  case rule: Rule
  of Tsu:
    tsu: PuyoPuyo[TsuField]
  of Water:
    water: PuyoPuyo[WaterField]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init(T: type NazoPuyoWrap, optGoal: Opt[Goal], puyoPuyo: PuyoPuyo[TsuField]): T =
  T(optGoal: optGoal, rule: Tsu, tsu: puyoPuyo)

func init(T: type NazoPuyoWrap, optGoal: Opt[Goal], puyoPuyo: PuyoPuyo[WaterField]): T =
  T(optGoal: optGoal, rule: Water, water: puyoPuyo)

func init*[F: TsuField or WaterField](T: type NazoPuyoWrap, nazo: NazoPuyo[F]): T =
  T.init(Opt[Goal].ok nazo.goal, nazo.puyoPuyo)

func init*[F: TsuField or WaterField](T: type NazoPuyoWrap, puyoPuyo: PuyoPuyo[F]): T =
  T.init(Opt[Goal].err, puyoPuyo)

func init*(T: type NazoPuyoWrap): T =
  T.init NazoPuyo[TsuField].init

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `==`*(field1: TsuField, field2: WaterField): bool =
  # NOTE: this function may be needed in `unwrapNazoPuyo`.
  false

func `==`*(field1: WaterField, field2: TsuField): bool =
  # NOTE: this function may be needed in `unwrapNazoPuyo`.
  false

func `==`*(wrap1, wrap2: NazoPuyoWrap): bool =
  if wrap1.optGoal != wrap2.optGoal or wrap1.rule != wrap2.rule:
    return false

  case wrap1.rule
  of Tsu:
    wrap1.tsu == wrap2.tsu
  of Water:
    wrap1.water == wrap2.water

# ------------------------------------------------
# Internal Access
# ------------------------------------------------

macro unwrapNazoPuyo*(self: untyped, body: untyped): untyped =
  ## Runs `body` with `it` (internal `PuyoPuyo`) and `itNazo`
  ## (internal `NazoPuyo` constructor calling) exposed.
  ## If `self` has no goal, the behavior of `itNazo` is undefined.
  ## Note that this macro may be incompatible with "method-like" calling.
  let
    puyoT = quote:
      `self`.tsu
    puyoW = quote:
      `self`.water
    goal = quote:
      `self`.optGoal.unsafeValue

    nazoT = quote:
      NazoPuyo[TsuField].init(`puyoT`, `goal`)
    nazoW = quote:
      NazoPuyo[WaterField].init(`puyoW`, `goal`)

    bodyT = body.replaced("it".ident, puyoT).replaced("itNazo".ident, nazoT)
    bodyW = body.replaced("it".ident, puyoW).replaced("itNazo".ident, nazoW)

  quote:
    case `self`.rule
    of Tsu: `bodyT`
    of Water: `bodyW`

# ------------------------------------------------
# Property
# ------------------------------------------------

func rule*(self: NazoPuyoWrap): Rule =
  ## Returns the rule.
  self.rule

func `rule=`*(self: var NazoPuyoWrap, rule: Rule) =
  ## Sets the rule.
  if rule == self.rule:
    return

  self.unwrapNazoPuyo:
    case rule
    of Tsu:
      self.assign NazoPuyoWrap.init(
        self.optGoal, PuyoPuyo[TsuField].init(it.field.toTsuField, it.steps)
      )
    of Water:
      self.assign NazoPuyoWrap.init(
        self.optGoal, PuyoPuyo[WaterField].init(it.field.toWaterField, it.steps)
      )

# ------------------------------------------------
# Nazo Puyo wrapper <-> URI
# ------------------------------------------------

func toUriQuery*(self: NazoPuyoWrap, fqdn: SimulatorFqdn): Res[string] =
  ## Returns the URI query converted from the Nazo Puyo wrapper.
  const ErrMsg = "Invalid Nazo Puyo wrapper"

  if self.optGoal.isOk:
    self.unwrapNazoPuyo:
      itNazo.toUriQuery(fqdn).context ErrMsg
  else:
    self.unwrapNazoPuyo:
      it.toUriQuery(fqdn).context ErrMsg

func parseNazoPuyoWrap*(query: string, fqdn: SimulatorFqdn): Res[NazoPuyoWrap] =
  ## Returns the Nazo Puyo wrapper converted from the URI query.
  let errMsg = "Invalid Nazo Puyo wrapper: {query}".fmt

  case fqdn
  of Pon2:
    let
      isNazo = "goal" in query
      isWater = "field={Water}_".fmt in query

    if isWater:
      if isNazo:
        ok NazoPuyoWrap.init ?parseNazoPuyo[WaterField](query, fqdn).context errMsg
      else:
        ok NazoPuyoWrap.init ?parsePuyoPuyo[WaterField](query, fqdn).context errMsg
    else:
      if isNazo:
        ok NazoPuyoWrap.init ?parseNazoPuyo[TsuField](query, fqdn).context errMsg
      else:
        ok NazoPuyoWrap.init ?parsePuyoPuyo[TsuField](query, fqdn).context errMsg
  of Ishikawa, Ips:
    if "__" in query:
      ok NazoPuyoWrap.init ?parseNazoPuyo[TsuField](query, fqdn).context errMsg
    else:
      ok NazoPuyoWrap.init ?parsePuyoPuyo[TsuField](query, fqdn).context errMsg

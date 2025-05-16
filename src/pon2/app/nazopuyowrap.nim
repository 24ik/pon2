## This module implements Nazo Puyo wrappers.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat]
import ../[core]
import ../private/[assign3, results2, strutils2]

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

func init(
    T: type NazoPuyoWrap, optGoal: Opt[Goal], puyoPuyo: PuyoPuyo[TsuField]
): T {.inline.} =
  T(optGoal: optGoal, rule: Tsu, tsu: puyoPuyo)

func init(
    T: type NazoPuyoWrap, optGoal: Opt[Goal], puyoPuyo: PuyoPuyo[WaterField]
): T {.inline.} =
  T(optGoal: optGoal, rule: Water, water: puyoPuyo)

func init*[F: TsuField or WaterField](
    T: type NazoPuyoWrap, nazo: NazoPuyo[F]
): T {.inline.} =
  T.init(Opt[Goal].ok nazo.goal, nazo.puyoPuyo)

func init*[F: TsuField or WaterField](
    T: type NazoPuyoWrap, puyoPuyo: PuyoPuyo[F]
): T {.inline.} =
  T.init(Opt[Goal].err, puyoPuyo)

func init*(T: type NazoPuyoWrap): T {.inline.} =
  T.init NazoPuyo[TsuField].init

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `==`*(field1: TsuField, field2: WaterField): bool {.inline.} =
  # NOTE: this may be used in `runIt`.
  false

func `==`*(field1: WaterField, field2: TsuField): bool {.inline.} =
  # NOTE: this may be used in `runIt`.
  false

func `==`*(wrap1, wrap2: NazoPuyoWrap): bool {.inline.} =
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

template runIt*(self: NazoPuyoWrap, body: untyped): untyped =
  ## Runs `body` with `it` (internal `PuyoPuyo`) exposed.
  case self.rule
  of Tsu:
    template it(): auto =
      self.tsu

    body
  of Water:
    template it(): auto =
      self.water

    body

# ------------------------------------------------
# Property
# ------------------------------------------------

func rule*(self: NazoPuyoWrap): Rule {.inline.} =
  ## Returns the rule.
  self.rule

func `rule=`*(self: var NazoPuyoWrap, rule: Rule) {.inline.} =
  ## Sets the rule.
  if rule == self.rule:
    return

  self.runIt:
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

func toUriQuery*(self: NazoPuyoWrap, fqdn: SimulatorFqdn): Res[string] {.inline.} =
  ## Returns the URI query converted from the Nazo Puyo wrapper.
  const ErrMsg = "Invalid Nazo Puyo wrapper"

  if self.optGoal.isOk:
    case self.rule
    of Tsu:
      NazoPuyo[TsuField]
      .init(self.tsu, self.optGoal.unsafeValue)
      .toUriQuery(fqdn).context ErrMsg
    of Water:
      NazoPuyo[WaterField]
      .init(self.water, self.optGoal.unsafeValue)
      .toUriQuery(fqdn).context ErrMsg
  else:
    self.runIt:
      it.toUriQuery(fqdn).context ErrMsg

func parseNazoPuyoWrap*(
    query: string, fqdn: SimulatorFqdn
): Res[NazoPuyoWrap] {.inline.} =
  ## Returns the Nazo Puyo wrapper converted from the URI query.
  let errMsg = "Invalid Nazo Puyo wrapper: {query}".fmt

  case fqdn
  of Pon2:
    let
      isNazo = "goal=" in query
      isTsu = "field={Tsu}_".fmt in query

    if isTsu:
      if isNazo:
        ok NazoPuyoWrap.init ?parseNazoPuyo[TsuField](query, fqdn).context errMsg
      else:
        ok NazoPuyoWrap.init ?parsePuyoPuyo[TsuField](query, fqdn).context errMsg
    else:
      if isNazo:
        ok NazoPuyoWrap.init ?parseNazoPuyo[WaterField](query, fqdn).context errMsg
      else:
        ok NazoPuyoWrap.init ?parsePuyoPuyo[WaterField](query, fqdn).context errMsg
  of Ishikawa, Ips:
    if "__" in query:
      ok NazoPuyoWrap.init ?parseNazoPuyo[TsuField](query, fqdn).context errMsg
    else:
      ok NazoPuyoWrap.init ?parsePuyoPuyo[TsuField](query, fqdn).context errMsg

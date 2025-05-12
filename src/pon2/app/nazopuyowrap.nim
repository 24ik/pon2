## This module implements Nazo Puyo wrappers.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ../[core]
import ../private/[assign3]

type NazoPuyoWrap* = object ## Nazo puyo wrapper.
  case rule: Rule
  of Tsu:
    tsu*: NazoPuyo[TsuField]
  of Water:
    water*: NazoPuyo[WaterField]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type NazoPuyoWrap, nazo: NazoPuyo[TsuField]): T {.inline.} =
  T(rule: Tsu, tsu: nazo)

func init*(T: type NazoPuyoWrap, nazo: NazoPuyo[WaterField]): T {.inline.} =
  T(rule: Water, water: nazo)

func init*(T: type NazoPuyoWrap): T {.inline.} =
  T.init(NazoPuyo[TsuField].init)

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `==`*(wrap1, wrap2: NazoPuyoWrap): bool {.inline.} =
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

template runIt*(self: NazoPuyoWrap, body: untyped): untyped =
  ## Runs `body` with `it` (internal `NazoPuyo`) exposed.
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
      self.assign NazoPuyoWrap.init NazoPuyo[TsuField].init(
        PuyoPuyo[TsuField].init(it.puyoPuyo.field.toTsuField, it.puyoPuyo.steps),
        it.goal,
      )
    of Water:
      self.assign NazoPuyoWrap.init NazoPuyo[WaterField].init(
        PuyoPuyo[WaterField].init(it.puyoPuyo.field.toWaterField, it.puyoPuyo.steps),
        it.goal,
      )

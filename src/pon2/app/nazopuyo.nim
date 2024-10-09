## This module implements Nazo Puyo wrap for all rules.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options]
import ../core/[field, nazopuyo, pairposition, puyopuyo, requirement, rule]

type NazoPuyoWrap* = object ## Nazo puyo type that accepts all rules.
  rule: Rule
  tsu: Option[NazoPuyo[TsuField]]
  water: Option[NazoPuyo[WaterField]]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func initNazoPuyoWrap*[F: TsuField or WaterField](
    nazo: NazoPuyo[F]
): NazoPuyoWrap {.inline.} =
  ## Returns a new nazo puyo wrap.
  when F is TsuField:
    NazoPuyoWrap(rule: Tsu, tsu: some nazo, water: none NazoPuyo[WaterField])
  else:
    NazoPuyoWrap(rule: Water, tsu: none NazoPuyo[TsuField], water: some nazo)

# ------------------------------------------------
# Property
# ------------------------------------------------

template get*(self: NazoPuyoWrap, body: untyped): untyped =
  ## Runs `body` with `wrappedNazoPuyo` exposed.
  case self.rule
  of Tsu:
    template wrappedNazoPuyo(): auto =
      self.tsu.get

    body
  of Water:
    template wrappedNazoPuyo(): auto =
      self.water.get

    body

func rule*(self: NazoPuyoWrap): Rule {.inline.} =
  ## Returns the rule.
  self.rule

func `rule=`*(self: var NazoPuyoWrap, rule: Rule) {.inline.} =
  ## Sets the rule.
  case self.rule
  of Tsu:
    case rule
    of Tsu:
      return
    of Water:
      self.water = some self.tsu.get.toWaterNazoPuyo
      self.tsu = none NazoPuyo[TsuField]

      self.rule = rule
  of Water:
    case rule
    of Tsu:
      self.tsu = some self.water.get.toTsuNazoPuyo
      self.water = none NazoPuyo[WaterField]

      self.rule = rule
    of Water:
      return

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `==`*(nazo1, nazo2: NazoPuyoWrap): bool {.inline.} =
  case nazo1.rule
  of Tsu:
    nazo1.tsu == nazo2.tsu
  of Water:
    nazo1.water == nazo2.water

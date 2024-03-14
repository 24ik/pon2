## This module implements Nazo Puyo wrap for all rules.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ../core/[field, nazopuyo, pairposition, puyopuyo, requirement, rule]

type NazoPuyoWrap* = object ## Nazo puyo type that accepts all rules.
  case rule: Rule
  of Tsu: tsu: NazoPuyo[TsuField]
  of Water: water: NazoPuyo[WaterField]

using
  self: NazoPuyoWrap
  mSelf: var NazoPuyoWrap

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func initNazoPuyoWrap*[F: TsuField or WaterField](
    nazo: NazoPuyo[F]
): NazoPuyoWrap {.inline.} =
  ## Returns a new nazo puyo wrap.
  when F is TsuField:
    NazoPuyoWrap(rule: Tsu, tsu: nazo)
  else:
    NazoPuyoWrap(rule: Water, water: nazo)

# ------------------------------------------------
# Property
# ------------------------------------------------

template get*(self; body: untyped): untyped =
  ## Runs `body` with `wrappedNazoPuyo` exposed.
  case self.rule
  of Tsu:
    template wrappedNazoPuyo(): auto {.redefine.} =
      self.tsu

    body
  of Water:
    template wrappedNazoPuyo(): auto {.redefine.} =
      self.water

    body

func rule*(self): Rule {.inline.} =
  self.rule

func `rule=`*(mSelf; rule: Rule) {.inline.} =
  if rule == mSelf.rule:
    return

  mSelf.get:
    case rule
    of Tsu:
      mSelf = wrappedNazoPuyo.toTsuNazoPuyo.initNazoPuyoWrap
    of Water:
      mSelf = wrappedNazoPuyo.toWaterNazoPuyo.initNazoPuyoWrap

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `==`*(self; nazoPuyoWrap: NazoPuyoWrap): bool {.inline.} =
  case self.rule
  of Tsu:
    result = nazoPuyoWrap.get:
      self.tsu == wrappedNazoPuyo
  of Water:
    result = nazoPuyoWrap.get:
      self.water == wrappedNazoPuyo

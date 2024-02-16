## This module implements Nazo Puyo wrap for all rules.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ../core/[field, nazopuyo, rule]

type NazoPuyoWrap* = object ## Nazo puyo type that accepts all rules.
  rule*: Rule
  tsu*: NazoPuyo[TsuField]
  water*: NazoPuyo[WaterField]

using
  self: NazoPuyoWrap
  mSelf: var NazoPuyoWrap

# ------------------------------------------------
# Flatten
# ------------------------------------------------

template flattenAnd*(self; body: untyped): untyped =
  ## Runs `body` with `nazoPuyo` exposed.
  case self.rule
  of Tsu:
    let nazoPuyo {.inject.} = self.tsu
    body
  of Water:
    let nazoPuyo {.inject.} = self.water
    body

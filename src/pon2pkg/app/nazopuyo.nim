## This module implements Nazo Puyo wrap for all rules.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ../core/[field, nazopuyo, pairposition, requirement, rule]

type NazoPuyoWrap* = object ## Nazo puyo type that accepts all rules.
  tsu*: NazoPuyo[TsuField]
  water*: NazoPuyo[WaterField]
  rule: Rule

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
    result.tsu = nazo
    result.water = initNazoPuyo[WaterField]()
    result.rule = Tsu
  else:
    result.tsu = initNazoPuyo[TsuField]()
    result.water = nazo
    result.rule = Water

# ------------------------------------------------
# Property - Nazo Puyo / Puyo Puyo / Field
# ------------------------------------------------

template flattenAnd*(self; body: untyped): untyped =
  ## Runs `body` with `nazoPuyo` exposed.
  {.push hint[XDeclaredButNotUsed]: off.}
  case self.rule
  of Tsu:
    let
      nazoPuyo {.inject.} = self.tsu
      puyoPuyo {.inject.} = self.tsu.puyoPuyo
      field {.inject.} = self.tsu.puyoPuyo.field

    body
  of Water:
    let
      nazoPuyo {.inject.} = self.water
      puyoPuyo {.inject.} = self.water.puyoPuyo
      field {.inject.} = self.water.puyoPuyo.field

    body
  {.pop.}

# ------------------------------------------------
# Property - Pairs&Positions
# ------------------------------------------------

func pairsPositions*(self): PairsPositions {.inline.} =
  self.flattenAnd:
    result = puyoPuyo.pairsPositions

func pairsPositions*(mSelf): var PairsPositions {.inline.} =
  case mSelf.rule
  of Tsu:
    result = mSelf.tsu.puyoPuyo.pairsPositions
  of Water:
    result = mSelf.water.puyoPuyo.pairsPositions

func `pairsPositions=`*(mSelf; pairsPositions: PairsPositions) {.inline.} =
  case mSelf.rule
  of Tsu:
    mSelf.tsu.puyoPuyo.pairsPositions = pairsPositions
  of Water:
    mSelf.water.puyoPuyo.pairsPositions = pairsPositions

# ------------------------------------------------
# Property - Requirement
# ------------------------------------------------

func requirement*(self): Requirement {.inline.} =
  self.flattenAnd:
    result = nazoPuyo.requirement

func requirement*(mSelf): var Requirement {.inline.} =
  case mSelf.rule
  of Tsu:
    result = mSelf.tsu.requirement
  of Water:
    result = mSelf.water.requirement

func `requirement=`*(mSelf; req: Requirement) {.inline.} =
  case mSelf.rule
  of Tsu:
    mSelf.tsu.requirement = req
  of Water:
    mSelf.water.requirement = req

# ------------------------------------------------
# Property - Rule
# ------------------------------------------------

func rule*(self): Rule {.inline.} =
  self.rule

func `rule=`*(mSelf; rule: Rule) {.inline.} =
  if rule == mSelf.rule:
    return

  mSelf.rule = rule
  case rule
  of Tsu:
    mSelf.tsu.puyoPuyo.field = mSelf.water.puyoPuyo.field.toTsuField
  of Water:
    mSelf.water.puyoPuyo.field = mSelf.tsu.puyoPuyo.field.toWaterField

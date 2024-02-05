## This modules implements pairs.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[setutils, sugar, tables]
import ./[cell, host]

type Pair* {.pure.} = enum
  ## The pair of two color puyos.
  RedRed = $Red & $Red
  RedGreen = $Red & $Green
  RedBlue = $Red & $Blue
  RedYellow = $Red & $Yellow
  RedPurple = $Red & $Purple

  GreenRed = $Green & $Red
  GreenGreen = $Green & $Green
  GreenBlue = $Green & $Blue
  GreenYellow = $Green & $Yellow
  GreenPurple = $Green & $Purple

  BlueRed = $Blue & $Red
  BlueGreen = $Blue & $Green
  BlueBlue = $Blue & $Blue
  BlueYellow = $Blue & $Yellow
  BluePurple = $Blue & $Purple

  YellowRed = $Yellow & $Red
  YellowGreen = $Yellow & $Green
  YellowBlue = $Yellow & $Blue
  YellowYellow = $Yellow & $Yellow
  YellowPurple = $Yellow & $Purple

  PurpleRed = $Purple & $Red
  PurpleGreen = $Purple & $Green
  PurpleBlue = $Purple & $Blue
  PurpleYellow = $Purple & $Yellow
  PurplePurple = $Purple & $Purple

using
  self: Pair
  mSelf: var Pair

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const FirstPairs: array[ColorPuyo, Pair] = [
  RedRed, GreenRed, BlueRed, YellowRed, PurpleRed]

func initPair*(axis, child: ColorPuyo): Pair {.inline.} =
  ## Returns a new Pair.
  FirstPairs[axis].succ child.ord - ColorPuyo.low.ord

# ------------------------------------------------
# Property
# ------------------------------------------------

func initPairToAxis: array[Pair, Cell] {.inline.} =
  ## Returns `PairToAxis`.
  result[Pair.low] = Cell.low # HACK: dummy to suppress warning
  for pair in Pair:
    result[pair] = ColorPuyo.low.succ pair.ord div ColorPuyo.fullSet.card

func initPairToChild: array[Pair, Cell] {.inline.} =
  ## Returns `PairToChild`.
  result[Pair.low] = Cell.low # HACK: dummy to suppress warning
  for pair in Pair:
    result[pair] = ColorPuyo.low.succ pair.ord mod ColorPuyo.fullSet.card

const
  PairToAxis = initPairToAxis()
  PairToChild = initPairToChild()

func axis*(self): Cell {.inline.} = PairToAxis[self] ## Returns the axis-puyo.

func child*(self): Cell {.inline.} = PairToChild[self]
  ## Returns the child-puyo.

func isDouble*(self): bool {.inline.} =
  ## Returns `true` if the pair is double (monochromatic).
  self in {RedRed, GreenGreen, BlueBlue, YellowYellow, PurplePurple}

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `axis=`*(mSelf; color: ColorPuyo) {.inline.} =
  ## Sets the axis-puyo.
  mSelf.inc (color.ord - mSelf.axis.ord) * ColorPuyo.fullSet.card

func `child=`*(mSelf; color: ColorPuyo) {.inline.} =
  ## Sets the child-puyo.
  mSelf.inc color.ord - mSelf.child.ord

# ------------------------------------------------
# Swap
# ------------------------------------------------

func initPairToSwapPair: array[Pair, Pair] {.inline.} =
  ## Returns `PairToSwapPair`.
  result[Pair.low] = Pair.low # HACK: dummy to suppress warning
  for pair in Pair:
    result[pair] = initPair(pair.child, pair.axis)

const PairToSwapPair = initPairToSwapPair()

func swapped*(self): Pair {.inline.} = PairToSwapPair[self]
  ## Returns the pair with axis-puyo and child-puyo swapped.

func swap*(mSelf) {.inline.} = mSelf = mSelf.swapped
  ## Swaps the axis-puyo and child-puyo.

# ------------------------------------------------
# Count
# ------------------------------------------------

func puyoCount*(self; puyo: Puyo): int {.inline.} =
  ## Returns the number of `puyo` in the pair.
  (self.axis == puyo).int + (self.child == puyo).int

func puyoCount*(self): int {.inline.} = 2
  ## Returns the number of puyos in the pair.

func colorCount*(self): int {.inline.} = self.puyoCount
  ## Returns the number of color puyos in the pair.

func garbageCount*(self): int {.inline.} = 0
  ## Returns the number of garbage puyos in the pair.

# ------------------------------------------------
# Pair <-> string
# ------------------------------------------------

const StrToPair = collect:
  for pair in Pair:
    {$pair: pair}

func parsePair*(str: string): Pair {.inline.} =
  ## Returns the pair converted from the string representation.
  ## If the string is invalid, `ValueError` is raised.
  try:
    result = StrToPair[str]
  except KeyError:
    result = Pair.low # HACK: dummy to suppress warning
    raise newException(ValueError, "Invalid pair: " & str)

# ------------------------------------------------
# Pair <-> URI
# ------------------------------------------------

const
  PairToIshikawaUri = "0coAM2eqCO4gsEQ6iuGS8kwIU"
  IshikawaUriToPair = collect:
    for pair in Pair:
      {$PairToIshikawaUri[pair.ord]: pair}

func toUriQuery*(self; host: SimulatorHost): string {.inline.} =
  ## Returns the URI query converted from the pair.
  case host
  of Izumiya: $self
  of Ishikawa, Ips: $PairToIshikawaUri[self.ord]

func parsePair*(query: string; host: SimulatorHost): Pair {.inline.} =
  ## Returns the pair converted from the URI query.
  ## If the query is invalid, `ValueError` is raised.
  case host
  of Izumiya:
    result = query.parsePair
  of Ishikawa, Ips:
    try:
      result = IshikawaUriToPair[query]
    except KeyError:
      result = Pair.low # HACK: dummy to suppress warning
      raise newException(ValueError, "Invalid pair: " & query)

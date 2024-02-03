## This modules implements pairs.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, setutils, strutils, sugar, tables]
import ./[cell, misc]
import ../private/[misc]

type
  Pair* {.pure.} = enum
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

  Pairs* = seq[Pair]

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
# Count - Puyo
# ------------------------------------------------

func puyoCount*(self; puyo: Puyo): int {.inline.} =
  ## Returns the number of `puyo` in the pair.
  (self.axis == puyo).int + (self.child == puyo).int

func puyoCount*(self): int {.inline.} = 2
  ## Returns the number of puyos in the pair.

func puyoCount*(pairs: Pairs; puyo: Puyo): int {.inline.} =
  ## Returns the number of `puyo` in the pairs.
  sum2 pairs.mapIt it.puyoCount puyo

func puyoCount*(pairs: Pairs): int {.inline.} = pairs.len * 2
  ## Returns the number of puyos in the pairs.

# ------------------------------------------------
# Count - Color
# ------------------------------------------------

func colorCount*(self): int {.inline.} = self.puyoCount
  ## Returns the number of color puyos in the pair.

func colorCount*(pairs: Pairs): int {.inline.} = pairs.puyoCount
  ## Returns the number of color puyos in the pairs.

# ------------------------------------------------
# Count - Garbage
# ------------------------------------------------

func garbageCount*(self): int {.inline.} = 0
  ## Returns the number of garbage puyos in the pair.

func garbageCount*(pairs: Pairs): int {.inline.} = 0
  ## Returns the number of garbage puyos in the pairs.

# ------------------------------------------------
# Pair <-> string
# ------------------------------------------------

const StrToPair = collect:
  for pair in Pair:
    {$pair: pair}

func parsePair*(str: string): Pair {.inline.} =
  ## Converts the string representation to the pair.
  ## If `str` is not a valid representation, `ValueError` is raised.
  try:
    result = StrToPair[str]
  except KeyError:
    result = Pair.low # HACK: dummy to suppress warning
    raise newException(ValueError, "Invalid pair: " & str)

# ------------------------------------------------
# Pairs <-> string
# ------------------------------------------------

const PairsSep = "\n"

func `$`*(pairs: Pairs): string {.inline.} =
  let strs = collect:
    for pair in pairs:
      $pair

  result = strs.join PairsSep

func parsePairs*(str: string): Pairs {.inline.} =
  ## Converts the string representation to the pairs.
  ## If `str` is not a valid representation, `ValueError` is raised.
  if str == "": newSeq[Pair](0)
  else: str.split(PairsSep).mapIt it.parsePair

# ------------------------------------------------
# Pair <-> URI
# ------------------------------------------------

const
  PairToIshikawaUri = "0coAM2eqCO4gsEQ6iuGS8kwIU"
  IshikawaUriToPair = collect:
    for pair in Pair:
      {$PairToIshikawaUri[pair.ord]: pair}

func toUriQuery*(self; host: SimulatorHost): string {.inline.} =
  ## Converts the pair to the URI query.
  case host
  of Izumiya: $self
  of Ishikawa, Ips: $PairToIshikawaUri[self.ord]

func parsePair*(query: string; host: SimulatorHost): Pair {.inline.} =
  ## Converts the URI query to the pair.
  ## If `query` is not a valid URI, `ValueError` is raised.
  case host
  of Izumiya:
    result = query.parsePair
  of Ishikawa, Ips:
    try:
      result = IshikawaUriToPair[query]
    except KeyError:
      result = Pair.low # HACK: dummy to suppress warning
      raise newException(ValueError, "Invalid pair: " & query)

# ------------------------------------------------
# Pairs <-> URI
# ------------------------------------------------

func toUriQuery*(pairs: Pairs; host: SimulatorHost): string {.inline.} =
  ## Converts the pairs to the URI query.
  join pairs.mapIt it.toUriQuery host

func parsePairs*(query: string; host: SimulatorHost): Pairs {.inline.} =
  ## Converts the URI query to the pairs.
  ## If `query` is not a valid URI, `ValueError` is raised.
  case host
  of Izumiya:
    if query.len mod 2 != 0:
      raise newException(ValueError, "Invalid pairs: " & query)

    result = collect:
      for i in countup(0, query.len.pred, 2):
        query[i..i.succ].parsePair host
  of Ishikawa, Ips:
    result = collect:
      for c in query:
        ($c).parsePair host

# ------------------------------------------------
# Pair <-> array
# ------------------------------------------------

func toArray*(self): array[2, Cell] {.inline.} = [self.axis, self.child]
  ## Converts the pair to the array.

func parsePair*(arr: array[2, ColorPuyo]): Pair {.inline.} =
  ## Converts the array to the pair.
  initPair(arr[0], arr[1])

# ------------------------------------------------
# Pairs <-> array
# ------------------------------------------------

func toArray*(pairs: Pairs): seq[array[2, Cell]] {.inline.} =
  ## Converts the pairs to the array.
  collect:
    for pair in pairs:
      pair.toArray

func parsePairs*(arr: openArray[array[2, ColorPuyo]]): Pairs {.inline.} =
  ## Converts the array to the pairs.
  collect:
    for pairArray in arr:
      pairArray.parsePair

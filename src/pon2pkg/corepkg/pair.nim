## This modules implements pairs.
##

{.experimental: "strictDefs".}

import std/[deques, sequtils, setutils, strutils, sugar, tables]
import ./[cell, misc]
import ../private/[misc]

export deques.Deque, deques.`[]`, deques.`[]=`, deques.addFirst, deques.addLast,
  deques.clear, deques.contains, deques.len, deques.peekFirst, deques.peekLast,
  deques.popFirst, deques.popLast, deques.shrink, deques.items, deques.mitems,
  deques.pairs

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

  Pairs* = Deque[Pair]

using
  pair: Pair
  pairs: Pairs
  mPair: var Pair
  mPairs: var Pairs

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func initPair*(axis, child: ColorPuyo): Pair {.inline.} =
  ## Constructor of `Pair`.
  Pair.low.succ (axis.ord - ColorPuyo.low.ord) * ColorPuyo.fullSet.card +
    (child.ord - ColorPuyo.low.ord)

func initPairs*(pairs: varargs[Pair]): Pairs {.inline.} = pairs.toDeque
  ## Constructor of `Pairs`.

# ------------------------------------------------
# Property
# ------------------------------------------------

func initPairToAxis: array[Pair, Cell] {.inline.} =
  ## Constructor of `PairToAxis`.
  result[Pair.low] = Cell.low # dummy to remove warning
  for pair in Pair:
    result[pair] = ColorPuyo.low.succ pair.ord div ColorPuyo.fullSet.card

func initPairToChild: array[Pair, Cell] {.inline.} =
  ## Constructor of `PairToChild`.
  result[Pair.low] = Cell.low # dummy to remove warning
  for pair in Pair:
    result[pair] = ColorPuyo.low.succ pair.ord mod ColorPuyo.fullSet.card

const
  PairToAxis = initPairToAxis()
  PairToChild = initPairToChild()

func axis*(pair): Cell {.inline.} = PairToAxis[pair] ## Returns the axis-puyo.
func child*(pair): Cell {.inline.} = PairToChild[pair]
  ## Returns the child-puyo.

func isDouble*(pair): bool {.inline.} =
  ## Returns `true` if the pair is double (monochromatic).
  pair in {RedRed, GreenGreen, BlueBlue, YellowYellow, PurplePurple}

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `axis=`*(mPair; color: ColorPuyo) {.inline.} =
  ## Sets the axis-puyo.
  mPair.inc (color.ord - mPair.axis.ord) * ColorPuyo.fullSet.card

func `child=`*(mPair; color: ColorPuyo) {.inline.} =
  ## Sets the child-puyo.
  mPair.inc (color.ord - mPair.child.ord)

func `==`*(pairs1, pairs2: Pairs): bool {.inline.} =
  pairs1.toSeq == pairs2.toSeq

# ------------------------------------------------
# Swap
# ------------------------------------------------

func initPairToSwapPair: array[Pair, Pair] {.inline.} =
  ## Constructor of `PairToSwapPair`.
  result[Pair.low] = Pair.low # dummy to remove warning
  for pair in Pair:
    result[pair] = initPair(pair.child, pair.axis)

const PairToSwapPair = initPairToSwapPair()

func swapped*(pair): Pair {.inline.} = PairToSwapPair[pair]
  ## Returns the pair with axis-puyo and child-puyo swapped.

func swap*(mPair) {.inline.} = mPair = mPair.swapped
  ## Swaps the axis-puyo and child-puyo.

# ------------------------------------------------
# Count - Puyo
# ------------------------------------------------

func puyoCount*(pair; puyo: Puyo): int {.inline.} =
  ## Returns the number of `puyo` in the pair.
  (pair.axis == puyo).int + (pair.child == puyo).int

func puyoCount*(pair): int {.inline.} = 2
  ## Returns the number of puyos in the pair.

func puyoCount*(pairs; puyo: Puyo): int {.inline.} =
  ## Returns the number of `puyo` in the pairs.
  sum pairs.mapIt it.puyoCount puyo

func puyoCount*(pairs): int {.inline.} = pairs.len * 2
  ## Returns the number of puyos in the pairs.
  
# ------------------------------------------------
# Count - Color
# ------------------------------------------------

func colorCount*(pair): int {.inline.} = pair.puyoCount
  ## Returns the number of color puyos in the pair.

func colorCount*(pairs): int {.inline.} = pairs.puyoCount
  ## Returns the number of color puyos in the pairs.

# ------------------------------------------------
# Count - Garbage
# ------------------------------------------------

func garbageCount*(pair): int {.inline.} = 0
  ## Returns the number of garbage puyos in the pair.

func garbageCount*(pairs): int {.inline.} = 0
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
  if str notin StrToPair:
    raise newException(ValueError, "Invalid pair: " & str)

  result = StrToPair[str]

# ------------------------------------------------
# Pairs <-> string
# ------------------------------------------------

const PairsSep = "\n"

func `$`*(pairs): string {.inline.} =
  let strs = collect:
    for pair in pairs:
      $pair

  result = strs.join PairsSep

func parsePairs*(str: string): Pairs {.inline.} =
  ## Converts the string representation to the pairs.
  ## If `str` is not a valid representation, `ValueError` is raised.
  if str == "":
    return initDeque[Pair]()

  result = str.split(PairsSep).mapIt(it.parsePair).toDeque

# ------------------------------------------------
# Pair <-> URI
# ------------------------------------------------

const
  PairToIshikawaUri = "0coAM2eqCO4gsEQ6iuGS8kwIU"
  IshikawaUriToPair = collect:
    for i, url in PairToIshikawaUri:
      {$url: i.Pair}

func toUriQuery*(pair; host: SimulatorHost): string {.inline.} =
  ## Converts the pair to the URI query.
  case host
  of Izumiya: $pair
  of Ishikawa, Ips: $PairToIshikawaUri[pair.ord]

func parsePair*(query: string, host: SimulatorHost): Pair {.inline.} =
  ## Converts the URI query to the pair.
  ## If `query` is not a valid URI, `ValueError` is raised.
  case host
  of Izumiya:
    query.parsePair
  of Ishikawa, Ips:
    if query notin IshikawaUriToPair:
      raise newException(ValueError, "Invalid pair: " & query)

    IshikawaUriToPair[query]

# ------------------------------------------------
# Pairs <-> URI
# ------------------------------------------------

func toUriQuery*(pairs; host: SimulatorHost): string {.inline.} =
  ## Converts the pairs to the URI query.
  join pairs.mapIt it.toUriQuery host

func parsePairs*(query: string, host: SimulatorHost): Pairs {.inline.} =
  ## Converts the URI query to the pairs.
  ## If `query` is not a valid URI, `ValueError` is raised.
  let pairsSeq = case host
  of Izumiya:
    if query.len mod 2 != 0:
      raise newException(ValueError, "Invalid pairs: " & query)

    collect:
      for i in 0..<query.len div 2:
        query[2 * i ..< 2 * i.succ].parsePair host
  of Ishikawa, Ips:
    collect:
      for c in query:
        ($c).parsePair host

  result = pairsSeq.toDeque

# ------------------------------------------------
# Pair <-> array
# ------------------------------------------------

func toArray*(pair): array[2, Cell] {.inline.} = [pair.axis, pair.child]
  ## Converts the pair to the array.

func parsePair*(arr: array[2, ColorPuyo]): Pair {.inline.} =
  ## Converts the array to the pair.
  Pair.low.succ (arr[0].ord - ColorPuyo.low.ord) * ColorPuyo.fullSet.card +
    (arr[1].ord - ColorPuyo.low.ord)

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
  let pairsSeq = collect:
    for pairArray in arr:
      pairArray.parsePair

  result = pairsSeq.toDeque

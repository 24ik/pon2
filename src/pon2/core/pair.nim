## This modules implements pairs.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[setutils, strformat, sugar, tables]
import results
import ./[cell, fqdn]
import ../private/[misc]

type Pair* {.pure.} = enum
  ## The pair of two color puyos.
  # axis: Red
  RedRed = $Red & $Red
  RedGreen = $Red & $Green
  RedBlue = $Red & $Blue
  RedYellow = $Red & $Yellow
  RedPurple = $Red & $Purple
  # axis: Green
  GreenRed = $Green & $Red
  GreenGreen = $Green & $Green
  GreenBlue = $Green & $Blue
  GreenYellow = $Green & $Yellow
  GreenPurple = $Green & $Purple
  # axis: Blue
  BlueRed = $Blue & $Red
  BlueGreen = $Blue & $Green
  BlueBlue = $Blue & $Blue
  BlueYellow = $Blue & $Yellow
  BluePurple = $Blue & $Purple
  # axis: Yellow
  YellowRed = $Yellow & $Red
  YellowGreen = $Yellow & $Green
  YellowBlue = $Yellow & $Blue
  YellowYellow = $Yellow & $Yellow
  YellowPurple = $Yellow & $Purple
  # axis: Purple
  PurpleRed = $Purple & $Red
  PurpleGreen = $Purple & $Green
  PurpleBlue = $Purple & $Blue
  PurpleYellow = $Purple & $Yellow
  PurplePurple = $Purple & $Purple

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const
  DummyPair = RedRed
  FirstPairs: array[Cell, Pair] =
    [DummyPair, DummyPair, DummyPair, RedRed, GreenRed, BlueRed, YellowRed, PurpleRed]

func init*(T: type Pair, axis, child: Cell): T {.inline.} =
  FirstPairs[axis].succ child.ord - Red.ord

# ------------------------------------------------
# Property
# ------------------------------------------------

func initPairToAxis(): array[Pair, Cell] {.inline.} =
  ## Returns `PairToAxis`.
  var pairToAxis = initArrWith[Pair, Cell](Cell.low)
  for pair in Pair:
    pairToAxis[pair] = Red.succ pair.ord div ColorPuyos.card

  pairToAxis

func initPairToChild(): array[Pair, Cell] {.inline.} =
  ## Returns `PairToChild`.
  var pairToChild = initArrWith[Pair, Cell](Cell.low)
  for pair in Pair:
    pairToChild[pair] = Red.succ pair.ord mod ColorPuyos.card

  pairToChild

const
  PairToAxis = initPairToAxis()
  PairToChild = initPairToChild()

func axis*(self: Pair): Cell {.inline.} = ## Returns the axis-puyo.
  PairToAxis[self]

func child*(self: Pair): Cell {.inline.} = ## Returns the child-puyo.
  PairToChild[self]

func isDouble*(self: Pair): bool {.inline.} =
  ## Returns `true` if the pair is double (monochromatic).
  self in {RedRed, GreenGreen, BlueBlue, YellowYellow, PurplePurple}

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `axis=`*(self: var Pair, colorPuyo: Cell): Result[void, string] {.inline.} =
  ## Sets the axis-puyo.
  if colorPuyo notin ColorPuyos:
    return Result[void, string].err "Invalid color puyo: {colorPuyo}".fmt

  self.inc (colorPuyo.ord - self.axis.ord) * ColorPuyos.card

  Result[void, string].ok

func `child=`*(self: var Pair, colorPuyo: Cell): Result[void, string] {.inline.} =
  ## Sets the child-puyo.
  if colorPuyo notin ColorPuyos:
    return Result[void, string].err "Invalid color puyo: {colorPuyo}".fmt

  self.inc colorPuyo.ord - self.axis.ord

  Result[void, string].ok

# ------------------------------------------------
# Swap
# ------------------------------------------------

func initPairToSwapPair(): array[Pair, Pair] {.inline.} =
  ## Returns `PairToSwapPair`.
  var pairToPair = initArrWith[Pair, Pair](Pair.low)
  for pair in Pair:
    pairToPair[pair] = Pair.init(pair.child, pair.axis)

  pairToPair

const PairToSwapPair = initPairToSwapPair()

func swapped*(self: Pair): Pair {.inline.} =
  ## Returns the pair with axis-puyo and child-puyo swapped.
  PairToSwapPair[self]

func swap*(self: var Pair) {.inline.} = ## Swaps the axis-puyo and child-puyo.
  self = self.swapped

# ------------------------------------------------
# Count
# ------------------------------------------------

func cellCnt*(self: Pair, cell: Cell): int {.inline.} =
  ## Returns the number of `cell` in the pair.
  (self.axis == cell).int + (self.child == cell).int

func cellCnt*(self: Pair): int {.inline.} =
  ## Returns the number of cells in the pair.
  2

func colorCnt*(self: Pair): int {.inline.} =
  ## Returns the number of color puyos in the pair.
  2

func garbageCnt*(self: Pair): int {.inline.} =
  ## Returns the number of garbage puyos in the pair.
  0

# ------------------------------------------------
# Pair <-> string
# ------------------------------------------------

const StrToPair = collect:
  for pair in Pair:
    {$pair: pair}

func parsePair*(str: string): Result[Pair, string] {.inline.} =
  ## Returns the pair converted from the string representation.
  if str in StrToPair:
    Result[Pair, string].ok StrToPair[str]
  else:
    Result[Pair, string].err "Invalid pair: {str}".fmt

# ------------------------------------------------
# Pair <-> URI
# ------------------------------------------------

const
  PairToIshikawaUri = "0coAM2eqCO4gsEQ6iuGS8kwIU"
  IshikawaUriToPair = collect:
    for pair in Pair:
      {$PairToIshikawaUri[pair.ord]: pair}

func toUriQuery*(self: Pair, fqdn = Pon2): string {.inline.} =
  ## Returns the URI query converted from the pair.
  case fqdn
  of Pon2:
    $self
  of Ishikawa, Ips:
    $PairToIshikawaUri[self.ord]

func parsePair*(query: string, fqdn: IdeFqdn): Result[Pair, string] {.inline.} =
  ## Returns the pair converted from the URI query.
  case fqdn
  of Pon2:
    query.parsePair
  of Ishikawa, Ips:
    if query in IshikawaUriToPair:
      Result[Pair, string].ok IshikawaUriToPair[query]
    else:
      Result[Pair, string].ok "Invalid pair: {query}".fmt

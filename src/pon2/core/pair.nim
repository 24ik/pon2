## This modules implements pairs.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[setutils, strformat, sugar]
import results
import stew/[assign2]
import stew/shims/[tables]
import ./[cell, fqdn]

type Pair* {.pure.} = enum
  ## The pair of two color puyos.
  # pivot: Red
  RedRed = $Red & $Red
  RedGreen = $Red & $Green
  RedBlue = $Red & $Blue
  RedYellow = $Red & $Yellow
  RedPurple = $Red & $Purple
  # pivot: Green
  GreenRed = $Green & $Red
  GreenGreen = $Green & $Green
  GreenBlue = $Green & $Blue
  GreenYellow = $Green & $Yellow
  GreenPurple = $Green & $Purple
  # pivot: Blue
  BlueRed = $Blue & $Red
  BlueGreen = $Blue & $Green
  BlueBlue = $Blue & $Blue
  BlueYellow = $Blue & $Yellow
  BluePurple = $Blue & $Purple
  # pivot: Yellow
  YellowRed = $Yellow & $Red
  YellowGreen = $Yellow & $Green
  YellowBlue = $Yellow & $Blue
  YellowYellow = $Yellow & $Yellow
  YellowPurple = $Yellow & $Purple
  # pivot: Purple
  PurpleRed = $Purple & $Red
  PurpleGreen = $Purple & $Green
  PurpleBlue = $Purple & $Blue
  PurpleYellow = $Purple & $Yellow
  PurplePurple = $Purple & $Purple

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const
  DummyPair = Pair.low
  FirstPairs: array[Cell, Pair] =
    [DummyPair, DummyPair, DummyPair, RedRed, GreenRed, BlueRed, YellowRed, PurpleRed]

func init*(T: type Pair, pivot, rotor: Cell): T {.inline.} =
  FirstPairs[pivot].succ rotor.ord - Red.ord

# ------------------------------------------------
# Property
# ------------------------------------------------

func initPivots(): array[Pair, Cell] {.inline.} =
  ## Returns `Pivots`.
  var pivots {.noinit.}: array[Pair, Cell]
  for pair in Pair:
    pivots[pair] = Red.succ pair.ord div ColorPuyos.card

  pivots

func initRotors(): array[Pair, Cell] {.inline.} =
  ## Returns `Rotors`.
  var rotors {.noinit.}: array[Pair, Cell]
  for pair in Pair:
    rotors[pair] = Red.succ pair.ord mod ColorPuyos.card

  rotors

const
  Pivots = initPivots()
  Rotors = initRotors()

func pivot*(self: Pair): Cell {.inline.} = ## Returns the pivot-puyo.
  Pivots[self]

func rotor*(self: Pair): Cell {.inline.} = ## Returns the rotor-puyo.
  Rotors[self]

func isDbl*(self: Pair): bool {.inline.} =
  ## Returns `true` if the pair is double (monochromatic).
  self in {RedRed, GreenGreen, BlueBlue, YellowYellow, PurplePurple}

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `pivot=`*(self: var Pair, colorPuyo: Cell): Result[void, string] {.inline.} =
  ## Sets the pivot-puyo.
  if colorPuyo notin ColorPuyos:
    return Result[void, string].err "Invalid color puyo: {colorPuyo}".fmt

  self.inc (colorPuyo.ord - self.pivot.ord) * ColorPuyos.card

  Result[void, string].ok

func `rotor=`*(self: var Pair, colorPuyo: Cell): Result[void, string] {.inline.} =
  ## Sets the rotor-puyo.
  if colorPuyo notin ColorPuyos:
    return Result[void, string].err "Invalid color puyo: {colorPuyo}".fmt

  self.inc colorPuyo.ord - self.pivot.ord

  Result[void, string].ok

# ------------------------------------------------
# Swap
# ------------------------------------------------

func initSwapPairs(): array[Pair, Pair] {.inline.} =
  ## Returns `SwapPairs`.
  var swapPairs {.noinit.}: array[Pair, Pair]
  for pair in Pair:
    swapPairs[pair] = Pair.init(pair.rotor, pair.pivot)

  swapPairs

const SwapPairs = initSwapPairs()

func swapped*(self: Pair): Pair {.inline.} =
  ## Returns the pair with pivot-puyo and rotor-puyo swapped.
  SwapPairs[self]

func swap*(self: var Pair) {.inline.} = ## Swaps the axis-puyo and child-puyo.
  self.assign self.swapped

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

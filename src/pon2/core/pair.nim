## This modules implements pairs.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar]
import ./[cell, fqdn]
import ../private/[assign3, results2, tables2]

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

func init*(T: type Pair, pivot, rotor: Cell): T {.inline.} =
  ## Note that the result is undefined if the pivot or rotor is no-color.
  # no-color cell is treated as Red
  let
    pivotVal = max(pivot.ord - Red.ord, 0)
    rotorVal = max(rotor.ord - Red.ord, 0)

  T pivotVal * ColorPuyos.card + rotorVal

func init*(T: type Pair): T {.inline.} =
  T.low

# ------------------------------------------------
# Property
# ------------------------------------------------

func pivot*(self: Pair): Cell {.inline.} = ## Returns the pivot-puyo.
  Red.succ self.ord div ColorPuyos.card

func rotor*(self: Pair): Cell {.inline.} = ## Returns the rotor-puyo.
  Red.succ self.ord mod ColorPuyos.card

func isDbl*(self: Pair): bool {.inline.} =
  ## Returns `true` if the pair is double (monochromatic).
  self in {RedRed, GreenGreen, BlueBlue, YellowYellow, PurplePurple}

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `pivot=`*(self: var Pair, colorPuyo: Cell) {.inline.} =
  ## Sets the pivot-puyo.
  ## If the `colorPuyo` is not color puyo, does nothing.
  if colorPuyo in ColorPuyos:
    self.inc (colorPuyo.ord - self.pivot.ord) * ColorPuyos.card

func `rotor=`*(self: var Pair, colorPuyo: Cell) {.inline.} =
  ## Sets the rotor-puyo.
  ## If the `colorPuyo` is not color puyo, does nothing.
  if colorPuyo in ColorPuyos:
    self.inc colorPuyo.ord - self.rotor.ord

# ------------------------------------------------
# Swap
# ------------------------------------------------

func swapped*(self: Pair): Pair {.inline.} =
  ## Returns the pair with pivot-puyo and rotor-puyo swapped.
  Pair.init(self.rotor, self.pivot)

func swap*(self: var Pair) {.inline.} = ## Swaps the pivot-puyo and rotor-puyo.
  self.assign self.swapped

# ------------------------------------------------
# Count
# ------------------------------------------------

func cellCnt*(self: Pair, cell: Cell): int {.inline.} =
  ## Returns the number of `cell` in the pair.
  (self.pivot == cell).int + (self.rotor == cell).int

func puyoCnt*(self: Pair): int {.inline.} =
  ## Returns the number of puyos in the pair.
  2

func colorPuyoCnt*(self: Pair): int {.inline.} =
  ## Returns the number of color puyos in the pair.
  2

func garbagesCnt*(self: Pair): int {.inline.} =
  ## Returns the number of hard and garbage puyos in the pair.
  0

# ------------------------------------------------
# Pair <-> string
# ------------------------------------------------

const StrToPair = collect:
  for pair in Pair:
    {$pair: pair}

func parsePair*(str: string): Res[Pair] {.inline.} =
  ## Returns the pair converted from the string representation.
  StrToPair.getRes(str).context "Invalid pair: {str}".fmt

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

func parsePair*(query: string, fqdn: IdeFqdn): Res[Pair] {.inline.} =
  ## Returns the pair converted from the URI query.
  case fqdn
  of Pon2:
    query.parsePair
  of Ishikawa, Ips:
    IshikawaUriToPair.getRes(query).context "Invalid pair: {query}".fmt

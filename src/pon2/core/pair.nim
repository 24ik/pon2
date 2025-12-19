## This modules implements pairs.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat]
import ./[cell, fqdn]
import ../[utils]
import ../private/[assign]

export cell, utils

type Pair* {.pure.} = enum
  ## The pair of two colored puyos.
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

func init*(T: type Pair, pivot, rotor: Cell): T {.inline, noinit.} =
  ## Note that the result is undefined if the pivot or rotor are not colored puyos.
  # no-colored cells are treated as Red
  let
    pivotVal = max(pivot.ord - Red.ord, 0)
    rotorVal = max(rotor.ord - Red.ord, 0)

  (pivotVal * ColoredPuyos.card + rotorVal).T

func init*(T: type Pair): T {.inline, noinit.} =
  T.low

# ------------------------------------------------
# Property
# ------------------------------------------------

func pivot*(self: Pair): Cell {.inline, noinit.} = ## Returns the pivot-puyo.
  Red.succ self.ord div ColoredPuyos.card

func rotor*(self: Pair): Cell {.inline, noinit.} = ## Returns the rotor-puyo.
  Red.succ self.ord mod ColoredPuyos.card

func isDouble*(self: Pair): bool {.inline, noinit.} =
  ## Returns `true` if the pair is double (monochromatic).
  self in {RedRed, GreenGreen, BlueBlue, YellowYellow, PurplePurple}

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `pivot=`*(self: var Pair, colorPuyo: Cell) {.inline, noinit.} =
  ## Sets the pivot-puyo.
  ## If the `colorPuyo` is not color puyo, does nothing.
  if colorPuyo in ColoredPuyos:
    self.inc (colorPuyo.ord - self.pivot.ord) * ColoredPuyos.card

func `rotor=`*(self: var Pair, colorPuyo: Cell) {.inline, noinit.} =
  ## Sets the rotor-puyo.
  ## If the `colorPuyo` is not color puyo, does nothing.
  if colorPuyo in ColoredPuyos:
    self.inc colorPuyo.ord - self.rotor.ord

# ------------------------------------------------
# Swap
# ------------------------------------------------

func swapped*(self: Pair): Pair {.inline, noinit.} =
  ## Returns the pair with pivot-puyo and rotor-puyo swapped.
  Pair.init(self.rotor, self.pivot)

func swap*(self: var Pair) {.inline, noinit.} = ## Swaps the pivot-puyo and rotor-puyo.
  self.assign self.swapped

# ------------------------------------------------
# Count
# ------------------------------------------------

func cellCount*(self: Pair, cell: Cell): int {.inline, noinit.} =
  ## Returns the number of `cell` in the pair.
  (self.pivot == cell).int + (self.rotor == cell).int

func puyoCount*(self: Pair): int {.inline, noinit.} =
  ## Returns the number of puyos in the pair.
  2

func coloredPuyoCount*(self: Pair): int {.inline, noinit.} =
  ## Returns the number of colored puyos in the pair.
  2

func nuisancePuyoCount*(self: Pair): int {.inline, noinit.} =
  ## Returns the number of nuisance puyos in the pair.
  0

# ------------------------------------------------
# Pair <-> string
# ------------------------------------------------

func parsePair*(str: string): Pon2Result[Pair] {.inline, noinit.} =
  ## Returns the pair converted from the string representation.
  let errorMsg = "Invalid pair: {str}".fmt

  if str.len != 2:
    return err errorMsg

  let pivot = ?str[0 .. 0].parseCell.context errorMsg
  if pivot notin ColoredPuyos:
    return err errorMsg

  let rotor = ?str[1 .. 1].parseCell.context errorMsg
  if rotor notin ColoredPuyos:
    return err errorMsg

  ok Pair.init(pivot, rotor)

# ------------------------------------------------
# Pair <-> URI
# ------------------------------------------------

const PairToIshikawaUri = "0coAM2eqCO4gsEQ6iuGS8kwIU"

func toUriQuery*(self: Pair, fqdn = Pon2): string {.inline, noinit.} =
  ## Returns the URI query converted from the pair.
  case fqdn
  of Pon2:
    $self
  of IshikawaPuyo, Ips:
    $PairToIshikawaUri[self.ord]

func parsePair*(
    query: string, fqdn: SimulatorFqdn
): Pon2Result[Pair] {.inline, noinit.} =
  ## Returns the pair converted from the URI query.
  case fqdn
  of Pon2:
    query.parsePair
  of IshikawaPuyo, Ips:
    let errorMsg = "Invalid pair: {query}".fmt

    if query.len != 1:
      return err errorMsg

    let index = PairToIshikawaUri.find query[0]
    if index >= 0:
      ok index.Pair
    else:
      err errorMsg

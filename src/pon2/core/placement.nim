## This module implements placements.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar]
import ./[common, fqdn]
import ../[utils]
import ../private/[setutils]

export common, utils

type
  Dir* {.pure.} = enum
    ## Rotor-puyo's direction seen from the pivot-puyo.
    Up
    Right
    Down
    Left

  Placement* {.pure.} = enum
    ## The location where a pair is put.
    None = ""
    Up0 = "1N"
    Up1 = "2N"
    Up2 = "3N"
    Up3 = "4N"
    Up4 = "5N"
    Up5 = "6N"
    Right0 = "12"
    Right1 = "23"
    Right2 = "34"
    Right3 = "45"
    Right4 = "56"
    Down0 = "1S"
    Down1 = "2S"
    Down2 = "3S"
    Down3 = "4S"
    Down4 = "5S"
    Down5 = "6S"
    Left1 = "21"
    Left2 = "32"
    Left3 = "43"
    Left4 = "54"
    Left5 = "65"

const
  ActualPlacements* = Placement.fullSet - {None}
  DoublePlacements* = {Up0 .. Right4}

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type Placement, pivotCol: Col, rotorDir: Dir): T {.inline, noinit.} =
  case rotorDir
  of Up:
    Up0.succ pivotCol.ord
  of Right:
    Right0.succ pivotCol.ord
  of Down:
    Down0.succ pivotCol.ord
  of Left:
    Down5.succ pivotCol.ord

func init*(T: type Placement): T {.inline, noinit.} =
  None

# ------------------------------------------------
# Property
# ------------------------------------------------

func pivotCol*(self: Placement): Col {.inline, noinit.} =
  ## Returns the pivot-puyo's column.
  ## If the placement is None, returns the undefined column.
  case self
  of None, Up0, Right0, Down0: Col0
  of Up1, Right1, Down1, Left1: Col1
  of Up2, Right2, Down2, Left2: Col2
  of Up3, Right3, Down3, Left3: Col3
  of Up4, Right4, Down4, Left4: Col4
  of Up5, Down5, Left5: Col5

func rotorCol*(self: Placement): Col {.inline, noinit.} =
  ## Returns the rotor-puyo's column.
  ## If the placement is None, returns the undefined column.
  case self
  of None, Up0, Down0, Left1: Col0
  of Up1, Right0, Down1, Left2: Col1
  of Up2, Right1, Down2, Left3: Col2
  of Up3, Right2, Down3, Left4: Col3
  of Up4, Right3, Down4, Left5: Col4
  of Up5, Right4, Down5: Col5

func rotorDir*(self: Placement): Dir {.inline, noinit.} =
  ## Returns the rotor-puyo's direction.
  ## If the placement is None, returns the undefined direction.
  case self
  of None, Up0 .. Up5: Up
  of Right0 .. Right4: Right
  of Down0 .. Down5: Down
  of Left1 .. Left5: Left

# ------------------------------------------------
# Move
# ------------------------------------------------

func moveRight*(self: var Placement) {.inline, noinit.} =
  ## Moves the placement rightward.
  case self
  of None, Up5, Right4, Down5, Left5: discard
  else: self.inc

func moveLeft*(self: var Placement) {.inline, noinit.} =
  ## Moves the placement leftward.
  case self
  of None, Up0, Right0, Down0, Left1: discard
  else: self.dec

func movedRight*(self: Placement): Placement {.inline, noinit.} =
  ## Returns the placement moved rightward.
  self.dup moveRight

func movedLeft*(self: Placement): Placement {.inline, noinit.} =
  ## Returns the placement moved leftward.
  self.dup moveLeft

# ------------------------------------------------
# Rotate
# ------------------------------------------------

func rotateRight*(self: var Placement) {.inline, noinit.} =
  ## Rotates the placement right (clockwise).
  case self
  of None:
    discard
  of Up0 .. Up4, Down0:
    self.inc 6
  of Up5, Right0 .. Right4, Down1 .. Down5:
    self.inc 5
  of Left1 .. Left5:
    self.dec 16

func rotateLeft*(self: var Placement) {.inline, noinit.} =
  ## Rotates the placement left (counterclockwise).
  case self
  of None:
    discard
  of Up0:
    self.inc 17
  of Up1 .. Up5:
    self.inc 16
  of Right0 .. Right4, Down5:
    self.dec 6
  of Down0 .. Down4, Left1 .. Left5:
    self.dec 5

func rotatedRight*(self: Placement): Placement {.inline, noinit.} =
  ## Returns the placement rotated right (clockwise).
  self.dup rotateRight

func rotatedLeft*(self: Placement): Placement {.inline, noinit.} =
  ## Returns the placement rotated left (counterclockwise).
  self.dup rotateLeft

# ------------------------------------------------
# Placement <-> string
# ------------------------------------------------

func parsePlacement*(str: string): Pon2Result[Placement] {.inline, noinit.} =
  ## Returns the placement converted from the string representation.
  for placement in Placement:
    if $placement == str:
      return ok placement

  err "Invalid placement: {str}".fmt

# ------------------------------------------------
# Placement <-> URI
# ------------------------------------------------

const PlacementToIshikawaUri = "102468acegikoqsuwyCEGIK"

func toUriQuery*(self: Placement, fqdn = Pon2): string {.inline, noinit.} =
  ## Returns the URI query converted from the placement.
  case fqdn
  of Pon2:
    $self
  of IshikawaPuyo, Ips:
    $PlacementToIshikawaUri[self.ord]

func parsePlacement*(
    query: string, fqdn: SimulatorFqdn
): Pon2Result[Placement] {.inline, noinit.} =
  ## Returns the placement converted from the URI query.
  case fqdn
  of Pon2:
    query.parsePlacement
  of IshikawaPuyo, Ips:
    let errorMsg = "Invalid placement: {query}".fmt

    if query.len != 1:
      return err errorMsg

    let index = PlacementToIshikawaUri.find query[0]
    if index >= 0:
      ok index.Placement
    else:
      err errorMsg

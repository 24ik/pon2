## This module implements placements.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar]
import ./[common, fqdn]
import ../private/[results2, tables2]

type
  Dir* {.pure.} = enum
    ## Rotor-puyo's direction seen from the pivot-puyo.
    Up = "^"
    Right = ">"
    Down = "v"
    Left = "<"

  Placement* {.pure.} = enum
    ## The location where a pair is put.
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

  OptPlacement* = Opt[Placement]

const
  NonePlacement* = OptPlacement.err
  DblPlacements* = {Up0 .. Right4}

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type Placement, pivotCol: Col, rotorDir: static Dir): T {.inline.} =
  when rotorDir == Up:
    Up0.succ pivotCol.ord
  elif rotorDir == Up:
    Right0.succ pivotCol.ord
  elif rotorDir == Down:
    Down0.succ pivotCol.ord
  else:
    Down5.succ pivotCol.ord

func init*(T: type Placement, pivotCol: Col, rotorDir: Dir): T {.inline.} =
  case rotorDir
  of Up:
    Up0.succ pivotCol.ord
  of Right:
    Right0.succ pivotCol.ord
  of Down:
    Down0.succ pivotCol.ord
  of Left:
    Down5.succ pivotCol.ord

func init*(T: type Placement): T {.inline.} =
  T.low

# ------------------------------------------------
# Property
# ------------------------------------------------

func pivotCol*(self: Placement): Col {.inline.} = ## Returns the pivot-puyo's column.
  case self
  of Up0, Right0, Down0: Col0
  of Up1, Right1, Down1, Left1: Col1
  of Up2, Right2, Down2, Left2: Col2
  of Up3, Right3, Down3, Left3: Col3
  of Up4, Right4, Down4, Left4: Col4
  of Up5, Down5, Left5: Col5

func rotorCol*(self: Placement): Col {.inline.} =
  ## Returns the rotor-puyo's column.
  case self
  of Up0, Down0, Left1: Col0
  of Up1, Right0, Down1, Left2: Col1
  of Up2, Right1, Down2, Left3: Col2
  of Up3, Right2, Down3, Left4: Col3
  of Up4, Right3, Down4, Left5: Col4
  of Up5, Right4, Down5: Col5

func rotorDir*(self: Placement): Dir {.inline.} =
  ## Returns the rotor-puyo's direction.
  case self
  of Up0 .. Up5: Up
  of Right0 .. Right4: Right
  of Down0 .. Down5: Down
  of Left1 .. Left5: Left

# ------------------------------------------------
# Move
# ------------------------------------------------

func moveRight*(self: var Placement) {.inline.} =
  ## Moves the placement rightward.
  case self
  of Up5, Right4, Down5, Left5: discard
  else: self.inc

func moveLeft*(self: var Placement) {.inline.} =
  ## Moves the placement leftward.
  case self
  of Up0, Right0, Down0, Left1: discard
  else: self.dec

func movedRight*(self: Placement): Placement {.inline.} =
  ## Returns the placement moved rightward.
  self.dup moveRight

func movedLeft*(self: Placement): Placement {.inline.} =
  ## Returns the placement moved leftward.
  self.dup moveLeft

# ------------------------------------------------
# Rotate
# ------------------------------------------------

func rotateRight*(self: var Placement) {.inline.} =
  ## Rotates the placement right (clockwise).
  case self
  of Up0 .. Up4, Down0:
    self.inc 6
  of Up5, Right0 .. Right4, Down1 .. Down5:
    self.inc 5
  of Left1 .. Left5:
    self.dec 16

func rotateLeft*(self: var Placement) {.inline.} =
  ## Rotates the placement left (counterclockwise).
  case self
  of Up0:
    self.inc 17
  of Up1 .. Up5:
    self.inc 16
  of Right0 .. Right4, Down5:
    self.dec 6
  of Down0 .. Down4, Left1 .. Left5:
    self.dec 5

func rotatedRight*(self: Placement): Placement {.inline.} =
  ## Returns the placement rotated right (clockwise).
  self.dup rotateRight

func rotatedLeft*(self: Placement): Placement {.inline.} =
  ## Returns the placement rotated left (counterclockwise).
  self.dup rotateLeft

# ------------------------------------------------
# Placement <-> string
# ------------------------------------------------

const
  NonePlcmtStr = ""
  StrToPlcmt = collect:
    for plcmt in Placement:
      {$plcmt: plcmt}

func `$`*(self: OptPlacement): string {.inline.} =
  if self.isOk:
    $self.expect
  else:
    NonePlcmtStr

func parsePlacement*(str: string): Res[Placement] {.inline.} =
  ## Returns the placement converted from the string representation.
  StrToPlcmt.getRes(str).context "Invalid placement: {str}".fmt

func parseOptPlacement*(str: string): Res[OptPlacement] {.inline.} =
  ## Returns the optional placement converted from the string representation.
  if str == NonePlcmtStr:
    ok NonePlacement
  else:
    ok OptPlacement.ok ?str.parsePlacement

# ------------------------------------------------
# Placement <-> URI
# ------------------------------------------------

const
  PlcmtToIshikawaUri = "02468acegikoqsuwyCEGIK"
  NonePlcmtIshikawaUri = "1"
  IshikawaUriToPlcmt = collect:
    for plcmt in Placement:
      {$PlcmtToIshikawaUri[plcmt.ord]: plcmt}

func toUriQuery*(self: Placement, fqdn = Pon2): string {.inline.} =
  ## Returns the URI query converted from the placement.
  case fqdn
  of Pon2:
    $self
  of Ishikawa, Ips:
    $PlcmtToIshikawaUri[self.ord]

func toUriQuery*(self: OptPlacement, fqdn = Pon2): string {.inline.} =
  ## Returns the URI query converted from the optional placement.
  case fqdn
  of Pon2:
    $self
  of Ishikawa, Ips:
    if self.isOk:
      $PlcmtToIshikawaUri[self.value.ord]
    else:
      NonePlcmtIshikawaUri

func parsePlacement*(query: string, fqdn: IdeFqdn): Res[Placement] {.inline.} =
  ## Returns the placement converted from the URI query.
  case fqdn
  of Pon2:
    query.parsePlacement
  of Ishikawa, Ips:
    IshikawaUriToPlcmt.getRes(query).context "Invalid placement: {query}".fmt

func parseOptPlacement*(query: string, fqdn: IdeFqdn): Res[OptPlacement] {.inline.} =
  ## Returns the optional placement converted from the URI query.
  case fqdn
  of Pon2:
    query.parseOptPlacement
  of Ishikawa, Ips:
    if query == NonePlcmtIshikawaUri:
      ok NonePlacement
    else:
      ok OptPlacement.ok ?query.parsePlacement fqdn

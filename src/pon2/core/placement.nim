## This module implements placements.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar, tables]
import results
import ./[common, fqdn]
import ../private/[assign2, misc]

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

const
  NonePlacement* = Opt[Placement].err
  AllDblPlacements* = {Up0 .. Right4}

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const
  StartPlacements: array[Dir, Placement] = [Up0, Right0, Down0, Left1]
  StartCols: array[Dir, Col] = [Col0, Col0, Col0, Col1]

func init*(T: type Placement, pivotCol: Col, rotorDir: Dir): T {.inline.} =
  StartPlacements[rotorDir].succ pivotCol.ord - StartCols[rotorDir].ord

# ------------------------------------------------
# Property
# ------------------------------------------------

func initPivotCols(): array[Placement, Col] {.inline.} =
  ## Returns `PivotCols`.
  var pivotCols {.noinit.}: array[Placement, Col]
  for plcmt in Up0 .. Up5:
    pivotCols[plcmt].assign StartCols[Up].succ plcmt.ord - StartPlacements[Up].ord
  for plcmt in Right0 .. Right4:
    pivotCols[plcmt].assign StartCols[Right].succ plcmt.ord - StartPlacements[Right].ord
  for plcmt in Down0 .. Down5:
    pivotCols[plcmt].assign StartCols[Down].succ plcmt.ord - StartPlacements[Down].ord
  for plcmt in Left1 .. Left5:
    pivotCols[plcmt].assign StartCols[Left].succ plcmt.ord - StartPlacements[Left].ord

  pivotCols

const PivotCols = initPivotCols()

func initRotorCols(): array[Placement, Col] {.inline.} =
  ## Returns `RotorCols`.
  var rotorCols {.noinit.}: array[Placement, Col]
  for plcmt in Up0 .. Up5:
    rotorCols[plcmt].assign PivotCols[plcmt]
  for plcmt in Right0 .. Right4:
    rotorCols[plcmt].assign PivotCols[plcmt].succ
  for plcmt in Down0 .. Down5:
    rotorCols[plcmt].assign PivotCols[plcmt]
  for plcmt in Left1 .. Left5:
    rotorCols[plcmt].assign PivotCols[plcmt].pred

  rotorCols

func initRotorDirs(): array[Placement, Dir] {.inline.} =
  ## Returns `RotorDirs`.
  var rotorDirs {.noinit.}: array[Placement, Dir]
  for plcmt in Up0 .. Up5:
    rotorDirs[plcmt].assign Up
  for plcmt in Right0 .. Right4:
    rotorDirs[plcmt].assign Right
  for plcmt in Down0 .. Down5:
    rotorDirs[plcmt].assign Down
  for plcmt in Left1 .. Left5:
    rotorDirs[plcmt].assign Left

  rotorDirs

const
  RotorCols = initRotorCols()
  RotorDirs = initRotorDirs()

func pivotCol*(self: Placement): Col {.inline.} = ## Returns the pivot-puyo's column.
  PivotCols[self]

func rotorCol*(self: Placement): Col {.inline.} =
  ## Returns the rotor-puyo's column.
  RotorCols[self]

func rotorDir*(self: Placement): Dir {.inline.} =
  ## Returns the rotor-puyo's direction.
  RotorDirs[self]

# ------------------------------------------------
# Move
# ------------------------------------------------

func initRightPlacements(): array[Placement, Placement] {.inline.} =
  ## Returns `RightPlacements`.
  var rightPlacements {.noinit.}: array[Placement, Placement]
  for plcmt in Placement:
    let
      pivotCol = plcmt.pivotCol
      newPivotCol = if pivotCol == Col.high: Col.high else: pivotCol.succ

    rightPlacements[plcmt].assign Placement.init(newPivotCol, plcmt.rotorDir)

  rightPlacements

func initLeftPlacements(): array[Placement, Placement] {.inline.} =
  ## Returns `LeftPlacements`.
  var leftPlacements {.noinit.}: array[Placement, Placement]
  for plcmt in Placement:
    let
      pivotCol = plcmt.pivotCol
      newPivotCol = if pivotCol == Col.low: Col.low else: pivotCol.pred

    leftPlacements[plcmt].assign Placement.init(newPivotCol, plcmt.rotorDir)

  leftPlacements

const
  RightPlacements = initRightPlacements()
  LeftPlacements = initLeftPlacements()

func movedRight*(self: Placement): Placement {.inline.} =
  ## Returns the placement moved rightward.
  RightPlacements[self]

func movedLeft*(self: Placement): Placement {.inline.} =
  ## Returns the placement moved leftward.
  LeftPlacements[self]

func moveRight*(self: var Placement) {.inline.} = ## Moves the placement rightward.
  self.assign self.movedRight

func moveLeft*(self: var Placement) {.inline.} = ## Moves the placement leftward.
  self.assign self.movedLeft

# ------------------------------------------------
# Rotate
# ------------------------------------------------

func initRightRotatePlacements(): array[Placement, Placement] {.inline.} =
  ## Returns `RightRotatePlacements`.
  var rightRotatePlacements {.noinit.}: array[Placement, Placement]
  for plcmt in Placement:
    let
      pivotCol = plcmt.pivotCol
      rotorDir = plcmt.rotorDir
      newPivotCol =
        if pivotCol == Col.high and rotorDir == Up:
          pivotCol.pred
        elif pivotCol == Col.low and rotorDir == Down:
          pivotCol.succ
        else:
          pivotCol
      newRotorDir = if rotorDir == Dir.high: Dir.low else: rotorDir.succ

    rightRotatePlacements[plcmt].assign Placement.init(newPivotCol, newRotorDir)

  rightRotatePlacements

func initLeftRotatePlacements(): array[Placement, Placement] {.inline.} =
  ## Returns `LeftRotatePlacements`.
  var leftRotatePlacements {.noinit.}: array[Placement, Placement]
  for plcmt in Placement:
    let
      pivotCol = plcmt.pivotCol
      rotorDir = plcmt.rotorDir
      newPivotCol =
        if pivotCol == Col.high and rotorDir == Down:
          pivotCol.pred
        elif pivotCol == Col.low and rotorDir == Up:
          pivotCol.succ
        else:
          pivotCol
      newRotorDir = if rotorDir == Dir.low: Dir.high else: rotorDir.pred

    leftRotatePlacements[plcmt].assign Placement.init(newPivotCol, newRotorDir)

  leftRotatePlacements

const
  RightRotatePlacements = initRightRotatePlacements()
  LeftRotatePlacements = initLeftRotatePlacements()

func rotatedRight*(self: Placement): Placement {.inline.} =
  ## Returns the placement rotated right (clockwise).
  RightRotatePlacements[self]

func rotatedLeft*(self: Placement): Placement {.inline.} =
  ## Returns the placement rotated left (counterclockwise).
  LeftRotatePlacements[self]

func rotateRight*(self: var Placement) {.inline.} =
  ## Rotates the placement right (clockwise).
  self.assign self.rotatedRight

func rotateLeft*(self: var Placement) {.inline.} =
  ## Rotates the placement left (counterclockwise).
  self.assign self.rotatedLeft

# ------------------------------------------------
# Placement <-> string
# ------------------------------------------------

const
  NonePlcmtStr = ""
  StrToPlcmt = collect:
    for plcmt in Placement:
      {$plcmt: plcmt}

func `$`*(self: Opt[Placement]): string {.inline.} =
  if self.isOk:
    $self.value
  else:
    NonePlcmtStr

func parsePlacement*(str: string): Result[Placement, string] {.inline.} =
  ## Returns the placement converted from the string representation.
  let plcmtRes = StrToPlcmt.getRes str
  if plcmtRes.isOk:
    Result[Placement, string].ok plcmtRes.value
  else:
    Result[Placement, string].err "Invalid placement: {str}".fmt

func parseOptPlacement*(str: string): Result[Opt[Placement], string] {.inline.} =
  ## Returns the optional placement converted from the string representation.
  if str == NonePlcmtStr:
    Result[Opt[Placement], string].ok NonePlacement
  else:
    Result[Opt[Placement], string].ok Opt[Placement].ok ?str.parsePlacement

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

func toUriQuery*(self: Opt[Placement], fqdn = Pon2): string {.inline.} =
  ## Returns the URI query converted from the optional placement.
  case fqdn
  of Pon2:
    $self
  of Ishikawa, Ips:
    if self.isOk:
      $PlcmtToIshikawaUri[self.value.ord]
    else:
      NonePlcmtIshikawaUri

func parsePlacement*(
    query: string, fqdn: IdeFqdn
): Result[Placement, string] {.inline.} =
  ## Returns the placement converted from the URI query.
  case fqdn
  of Pon2:
    query.parsePlacement
  of Ishikawa, Ips:
    let plcmtRes = IshikawaUriToPlcmt.getRes query
    if plcmtRes.isOk:
      Result[Placement, string].ok plcmtRes.value
    else:
      Result[Placement, string].err "Invalid placement: {query}".fmt

func parseOptPlacement*(
    query: string, fqdn: IdeFqdn
): Result[Opt[Placement], string] {.inline.} =
  ## Returns the optional placement converted from the URI query.
  case fqdn
  of Pon2:
    query.parseOptPlacement
  of Ishikawa, Ips:
    if query == NonePlcmtIshikawaUri:
      Result[Opt[Placement], string].ok NonePlacement
    else:
      Result[Opt[Placement], string].ok Opt[Placement].ok ?query.parsePlacement fqdn

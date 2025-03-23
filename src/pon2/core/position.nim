## This module implements positions.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar]
import results
import stew/[assign2]
import stew/shims/[tables]
import ./[common, fqdn]

type
  Dir* {.pure.} = enum
    ## Rotor-puyo's direction seen from the pivot-puyo.
    Up = "^"
    Right = ">"
    Down = "v"
    Left = "<"

  Pos* {.pure.} = enum
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

  OptPos* = Opt[Pos]

const
  NonePos* = Opt[Pos].err()
  AllDblPoses* = {Up0 .. Right4}

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const
  StartPoses: array[Dir, Pos] = [Up0, Right0, Down0, Left1]
  StartCols: array[Dir, Col] = [Col0, Col0, Col0, Col1]

func init*(T: type Pos, pivotCol: Col, rotorDir: Dir): T {.inline.} =
  StartPoses[rotorDir].succ pivotCol.ord - StartCols[rotorDir].ord

# ------------------------------------------------
# Property
# ------------------------------------------------

func initPivotCols(): array[Pos, Col] {.inline.} =
  ## Returns `PivotCols`.
  var pivotCols {.noinit.}: array[Pos, Col]
  for pos in Up0 .. Up5:
    pivotCols[pos] = StartCols[Up].succ pos.ord - StartPoses[Up].ord
  for pos in Right0 .. Right4:
    pivotCols[pos] = StartCols[Right].succ pos.ord - StartPoses[Right].ord
  for pos in Down0 .. Down5:
    pivotCols[pos] = StartCols[Down].succ pos.ord - StartPoses[Down].ord
  for pos in Left1 .. Left5:
    pivotCols[pos] = StartCols[Left].succ pos.ord - StartPoses[Left].ord

  pivotCols

const PivotCols = initPivotCols()

func initRotorCols(): array[Pos, Col] {.inline.} =
  ## Returns `RotorCols`.
  var rotorCols {.noinit.}: array[Pos, Col]
  for pos in Up0 .. Up5:
    rotorCols[pos] = PivotCols[pos]
  for pos in Right0 .. Right4:
    rotorCols[pos] = PivotCols[pos].succ
  for pos in Down0 .. Down5:
    rotorCols[pos] = PivotCols[pos]
  for pos in Left1 .. Left5:
    rotorCols[pos] = PivotCols[pos].pred

  rotorCols

func initRotorDirs(): array[Pos, Dir] {.inline.} =
  ## Returns `RotorDirs`.
  var rotorDirs {.noinit.}: array[Pos, Dir]
  for pos in Up0 .. Up5:
    rotorDirs[pos] = Up
  for pos in Right0 .. Right4:
    rotorDirs[pos] = Right
  for pos in Down0 .. Down5:
    rotorDirs[pos] = Down
  for pos in Left1 .. Left5:
    rotorDirs[pos] = Left

  rotorDirs

const
  RotorCols = initRotorCols()
  RotorDirs = initRotorDirs()

func pivotCol*(self: Pos): Col {.inline.} = ## Returns the pivot-puyo's column.
  PivotCols[self]

func rotorCol*(self: Pos): Col {.inline.} =
  ## Returns the rotor-puyo's column.
  RotorCols[self]

func rotorDir*(self: Pos): Dir {.inline.} =
  ## Returns the rotor-puyo's direction.
  RotorDirs[self]

# ------------------------------------------------
# Move
# ------------------------------------------------

func initRightPoses(): array[Pos, Pos] {.inline.} =
  ## Returns `RightPoses`.
  var rightPoses {.noinit.}: array[Pos, Pos]
  for pos in Pos:
    let
      pivotCol = pos.pivotCol
      newPivotCol = if pivotCol == Col.high: Col.high else: pivotCol.succ

    rightPoses[pos] = Pos.init(newPivotCol, pos.rotorDir)

  rightPoses

func initLeftPoses(): array[Pos, Pos] {.inline.} =
  ## Returns `LeftPoses`.
  var leftPoses {.noinit.}: array[Pos, Pos]
  for pos in Pos:
    let
      pivotCol = pos.pivotCol
      newPivotCol = if pivotCol == Col.low: Col.low else: pivotCol.pred

    leftPoses[pos] = Pos.init(newPivotCol, pos.rotorDir)

  leftPoses

const
  RightPoses = initRightPoses()
  LeftPoses = initLeftPoses()

func movedRight*(self: Pos): Pos {.inline.} =
  ## Returns the position moved rightward.
  RightPoses[self]

func movedLeft*(self: Pos): Pos {.inline.} =
  ## Returns the position moved leftward.
  LeftPoses[self]

func moveRight*(self: var Pos) {.inline.} = ## Moves the position rightward.
  self.assign self.movedRight

func moveLeft*(self: var Pos) {.inline.} = ## Moves the position leftward.
  self.assign self.movedLeft

# ------------------------------------------------
# Rotate
# ------------------------------------------------

func initRightRotatePoses(): array[Pos, Pos] {.inline.} =
  ## Returns `RightRotatePoses`.
  var rightRotatePoses {.noinit.}: array[Pos, Pos]
  for pos in Pos:
    let
      pivotCol = pos.pivotCol
      rotorDir = pos.rotorDir
      newPivotCol =
        if pivotCol == Col.high and rotorDir == Up:
          pivotCol.pred
        elif pivotCol == Col.low and rotorDir == Down:
          pivotCol.succ
        else:
          pivotCol
      newRotorDir = if rotorDir == Dir.high: Dir.low else: rotorDir.succ

    rightRotatePoses[pos] = Pos.init(newPivotCol, newRotorDir)

  rightRotatePoses

func initLeftRotatePoses(): array[Pos, Pos] {.inline.} =
  ## Returns `LeftRotatePoses`.
  var leftRotatePoses {.noinit.}: array[Pos, Pos]
  for pos in Pos:
    let
      pivotCol = pos.pivotCol
      rotorDir = pos.rotorDir
      newPivotCol =
        if pivotCol == Col.high and rotorDir == Down:
          pivotCol.pred
        elif pivotCol == Col.low and rotorDir == Up:
          pivotCol.succ
        else:
          pivotCol
      newRotorDir = if rotorDir == Dir.low: Dir.high else: rotorDir.pred

    leftRotatePoses[pos] = Pos.init(newPivotCol, newRotorDir)

  leftRotatePoses

const
  RightRotatePoses = initRightRotatePoses()
  LeftRotatePoses = initLeftRotatePoses()

func rotatedRight*(self: Pos): Pos {.inline.} =
  ## Returns the position rotated right (clockwise).
  RightRotatePoses[self]

func rotatedLeft*(self: Pos): Pos {.inline.} =
  ## Returns the position rotated left (counterclockwise).
  LeftRotatePoses[self]

func rotateRight*(self: var Pos) {.inline.} =
  ## Rotates the position right (clockwise).
  self.assign self.rotatedRight

func rotateLeft*(self: var Pos) {.inline.} =
  ## Rotates the position left (counterclockwise).
  self.assign self.rotatedLeft

# ------------------------------------------------
# Position <-> string
# ------------------------------------------------

const
  NonePosStr = ""
  StrToPos = collect:
    for pos in Pos:
      {$pos: pos}

func `$`*(self: OptPos): string {.inline.} =
  if self.isOk:
    $self.value
  else:
    NonePosStr

func parsePos*(str: string): Result[Pos, string] {.inline.} =
  ## Returns the position converted from the string representation.
  if str in StrToPos:
    Result[Pos, string].ok StrToPos[str]
  else:
    Result[Pos, string].err "Invalid pos: {str}".fmt

func parseOptPos*(str: string): Result[OptPos, string] {.inline.} =
  ## Returns the optional position converted from the string representation.
  if str == NonePosStr:
    Result[OptPos, string].ok NonePos
  else:
    Result[OptPos, string].ok OptPos.ok ?str.parsePos

# ------------------------------------------------
# Position <-> URI
# ------------------------------------------------

const
  PosToIshikawaUri = "02468acegikoqsuwyCEGIK"
  NonePosIshikawaUri = "1"
  IshikawaUriToPos = collect:
    for pos in Pos:
      {$PosToIshikawaUri[pos.ord]: pos}

func toUriQuery*(self: Pos, fqdn = Pon2): string {.inline.} =
  ## Returns the URI query converted from the position.
  case fqdn
  of Pon2:
    $self
  of Ishikawa, Ips:
    $PosToIshikawaUri[self.ord]

func toUriQuery*(self: OptPos, fqdn = Pon2): string {.inline.} =
  ## Returns the URI query converted from the optional position.
  case fqdn
  of Pon2:
    $self
  of Ishikawa, Ips:
    if self.isOk:
      $PosToIshikawaUri[self.value.ord]
    else:
      NonePosIshikawaUri

func parsePos*(query: string, fqdn: IdeFqdn): Result[Pos, string] {.inline.} =
  ## Returns the position converted from the URI query.
  case fqdn
  of Pon2:
    query.parsePos
  of Ishikawa, Ips:
    if query in IshikawaUriToPos:
      Result[Pos, string].ok IshikawaUriToPos[query]
    else:
      Result[Pos, string].err "Invalid pos: {query}".fmt

func parseOptPos*(query: string, fqdn: IdeFqdn): Result[OptPos, string] {.inline.} =
  ## Returns the optional position converted from the URI query.
  case fqdn
  of Pon2:
    query.parseOptPos
  of Ishikawa, Ips:
    if query == NonePosIshikawaUri:
      Result[OptPos, string].ok NonePos
    else:
      Result[OptPos, string].ok ?query.parsePos fqdn

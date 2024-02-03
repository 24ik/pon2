## This module implements positions.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, strutils, sugar, tables]
import ./[fieldtype, misc]

type
  Direction* {.pure.} = enum
    ## Child-puyo's direction seen from the axis-puyo.
    Up = "^"
    Right = ">"
    Down = "v"
    Left = "<"

  Position* {.pure.} = enum
    ## The location where a pair is put.
    None = ".."

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

    Down0 = "1F"
    Down1 = "2F"
    Down2 = "3F"
    Down3 = "4F"
    Down4 = "5F"
    Down5 = "6F"

    Left1 = "21"
    Left2 = "32"
    Left3 = "43"
    Left4 = "54"
    Left5 = "65"

  Positions* = seq[Position]

const
  AllPositions* = {Up0..Left5}
  AllDoublePositions* = {Up0..Right4}

using
  self: Position
  mSelf: var Position

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const
  StartPositions: array[Direction, Position] = [Up0, Right0, Down0, Left1]
  StartColumns: array[Direction, Column] = [0, 0, 0, 1]

func initPosition*(axisCol: Column, childDir: Direction): Position {.inline.} =
  ## Returns a new position.
  StartPositions[childDir].succ axisCol - StartColumns[childDir]

# ------------------------------------------------
# Property
# ------------------------------------------------

func initPosToAxisCol: array[Position, Column] {.inline.} =
  ## Returns `PosToAxisCol`.
  result[None] = Column.low
  for pos in Up0..Up5:
    result[pos] = StartColumns[Up].succ pos.ord - StartPositions[Up].ord
  for pos in Right0..Right4:
    result[pos] = StartColumns[Right].succ pos.ord - StartPositions[Right].ord
  for pos in Down0..Down5:
    result[pos] = StartColumns[Down].succ pos.ord - StartPositions[Down].ord
  for pos in Left1..Left5:
    result[pos] = StartColumns[Left].succ pos.ord - StartPositions[Left].ord

const PosToAxisCol = initPosToAxisCol()

func initPosToChildCol: array[Position, Column] {.inline.} =
  ## Returns `PosToChildCol`.
  result[None] = Column.low
  for pos in Up0..Up5: result[pos] = PosToAxisCol[pos]
  for pos in Right0..Right4: result[pos] = PosToAxisCol[pos].succ
  for pos in Down0..Down5: result[pos] = PosToAxisCol[pos]
  for pos in Left1..Left5: result[pos] = PosToAxisCol[pos].pred

const PosToChildCol = initPosToChildCol()

func initPosToChildDir: array[Position, Direction] {.inline.} =
  ## Returns `PosToChildDir`.
  result[None] = Direction.low
  for pos in Up0..Up5: result[pos] = Up
  for pos in Right0..Right4: result[pos] = Right
  for pos in Down0..Down5: result[pos] = Down
  for pos in Left1..Left5: result[pos] = Left

const PosToChildDir = initPosToChildDir()

func axisColumn*(self): Column {.inline.} = PosToAxisCol[self]
  ## Returns the axis-puyo's column.

func childColumn*(self): Column {.inline.} = PosToChildCol[self]
  ## Returns the child-puyo's column.

func childDirection*(self): Direction {.inline.} = PosToChildDir[self]
  ## Returns the child-puyo's direction.

# ------------------------------------------------
# Move
# ------------------------------------------------

const
  RightPositions: array[Position, Position] = [
    None,
    Up1, Up2, Up3, Up4, Up5, Up5,
    Right1, Right2, Right3, Right4, Right4,
    Down1, Down2, Down3, Down4, Down5, Down5,
    Left2, Left3, Left4, Left5, Left5]
  LeftPositions: array[Position, Position] = [
    None,
    Up0, Up0, Up1, Up2, Up3, Up4,
    Right0, Right0, Right1, Right2, Right3,
    Down0, Down0, Down1, Down2, Down3, Down4,
    Left1, Left1, Left2, Left3, Left4]

func movedRight*(self): Position {.inline.} = RightPositions[self]
  ## Returns the position moved rightward.

func movedLeft*(self): Position {.inline.} = LeftPositions[self]
  ## Returns the position moved leftward.

func moveRight*(mSelf) {.inline.} = mSelf = mSelf.movedRight
  ## Moves the position rightward.

func moveLeft*(mSelf) {.inline.} = mSelf = mSelf.movedLeft
  ## Moves the position leftward.

# ------------------------------------------------
# Rotate
# ------------------------------------------------

const
  RightRotatePositions: array[Position, Position] = [
    None,
    Right0, Right1, Right2, Right3, Right4, Right4,
    Down0, Down1, Down2, Down3, Down4,
    Left1, Left1, Left2, Left3, Left4, Left5,
    Up1, Up2, Up3, Up4, Up5]
  LeftRotatePositions: array[Position, Position] = [
    None,
    Left1, Left1, Left2, Left3, Left4, Left5,
    Up0, Up1, Up2, Up3, Up4,
    Right0, Right1, Right2, Right3, Right4, Right4,
    Down1, Down2, Down3, Down4, Down5]

func rotatedRight*(self): Position {.inline.} = RightRotatePositions[self]
  ## Returns the position rotated right (clockwise).

func rotatedLeft*(self): Position {.inline.} = LeftRotatePositions[self]
  ## Returns the position rotated left (counterclockwise).

func rotateRight*(mSelf) {.inline.} = mSelf = mSelf.rotatedRight
  ## Rotates the position right.

func rotateLeft*(mSelf) {.inline.} = mSelf = mSelf.rotatedLeft
  ## Rotates the position left.

# ------------------------------------------------
# Position <-> string
# ------------------------------------------------

const StrToPos = collect:
  for pos in Position:
    {$pos: pos}

func parsePosition*(str: string): Position {.inline.} =
  ## Converts the string representation to a position.
  ## If `str` is not a valid representation, `ValueError` is raised.
  try:
    result = StrToPos[str]
  except KeyError:
    result = Position.low # HACK: dummy to suppress warning
    raise newException(ValueError, "Invalid position: " & str)

# ------------------------------------------------
# Positions <-> string
# ------------------------------------------------

const PositionsSep = "\n"

func `$`*(positions: Positions): string {.inline.} =
  let strs = collect:
    for pos in positions:
      $pos

  result = strs.join PositionsSep

func parsePositions*(str: string): Positions {.inline.} =
  ## Converts the string representation to positions.
  ## If `str` is not a valid representation, `ValueError` is raised.
  if str == "": newSeq[Position](0)
  else: str.split(PositionsSep).mapIt it.parsePosition

# ------------------------------------------------
# Position <-> URI
# ------------------------------------------------

const
  PosToIshikawaUri = "102468acegikoqsuwyCEGIK"
  IshikawaUriToPos = collect:
    for pos in Position:
      {$PosToIshikawaUri[pos.ord]: pos}

func toUriQuery*(self; host: SimulatorHost): string {.inline.} =
  ## Converts the position to a URI query.
  case host
  of Izumiya: $self
  of Ishikawa, Ips: $PosToIshikawaUri[self.ord]

func parsePosition*(query: string, host: SimulatorHost): Position {.inline.} =
  ## Converts the URI query to a position.
  ## If `query` is not a vaid URI, `ValueError` is raised.
  case host
  of Izumiya: query.parsePosition
  of Ishikawa, Ips: IshikawaUriToPos[query]

# ------------------------------------------------
# Positions <-> URI
# ------------------------------------------------

func toUriQuery*(positions: Positions, host: SimulatorHost): string {.inline.} =
  ## Converts the positions to a URI query.
  join positions.mapIt it.toUriQuery host

func parsePositions*(query: string, host: SimulatorHost): Positions {.inline.} =
  ## Converts the URI query to positions.
  ## If `query` is not a vaid URI, `ValueError` is raised.
  case host
  of Izumiya:
    if query.len mod 2 != 0:
      raise newException(ValueError, "Invalid positions: " & query)

    result = collect:
      for i in countup(0, query.len.pred, 2):
        query[i..i.succ].parsePosition host
  of Ishikawa, Ips:
    result = collect:
      for c in query:
        ($c).parsePosition host

## This module implements positions.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar, tables]
import ./[fieldtype, fqdn]

type
  Direction* {.pure.} = enum
    ## Child-puyo's direction seen from the axis-puyo.
    Up = "^"
    Right = ">"
    Down = "v"
    Left = "<"

  Position* {.pure.} = enum
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

const
  AllPositions* = {Up0 .. Left5}
  AllDoublePositions* = {Up0 .. Right4}

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

func initPosToAxisCol(): array[Position, Column] {.inline.} =
  ## Returns `PosToAxisCol`.
  result[None] = Column.low
  for pos in Up0 .. Up5:
    result[pos] = StartColumns[Up].succ pos.ord - StartPositions[Up].ord
  for pos in Right0 .. Right4:
    result[pos] = StartColumns[Right].succ pos.ord - StartPositions[Right].ord
  for pos in Down0 .. Down5:
    result[pos] = StartColumns[Down].succ pos.ord - StartPositions[Down].ord
  for pos in Left1 .. Left5:
    result[pos] = StartColumns[Left].succ pos.ord - StartPositions[Left].ord

const PosToAxisCol = initPosToAxisCol()

func initPosToChildCol(): array[Position, Column] {.inline.} =
  ## Returns `PosToChildCol`.
  result[None] = Column.low
  for pos in Up0 .. Up5:
    result[pos] = PosToAxisCol[pos]
  for pos in Right0 .. Right4:
    result[pos] = PosToAxisCol[pos].succ
  for pos in Down0 .. Down5:
    result[pos] = PosToAxisCol[pos]
  for pos in Left1 .. Left5:
    result[pos] = PosToAxisCol[pos].pred

const PosToChildCol = initPosToChildCol()

func initPosToChildDir(): array[Position, Direction] {.inline.} =
  ## Returns `PosToChildDir`.
  result[None] = Direction.low
  for pos in Up0 .. Up5:
    result[pos] = Up
  for pos in Right0 .. Right4:
    result[pos] = Right
  for pos in Down0 .. Down5:
    result[pos] = Down
  for pos in Left1 .. Left5:
    result[pos] = Left

const PosToChildDir = initPosToChildDir()

func axisColumn*(self: Position): Column {.inline.} = ## Returns the axis-puyo's column.
  PosToAxisCol[self]

func childColumn*(self: Position): Column {.inline.} =
  ## Returns the child-puyo's column.
  PosToChildCol[self]

func childDirection*(self: Position): Direction {.inline.} =
  ## Returns the child-puyo's direction.
  PosToChildDir[self]

# ------------------------------------------------
# Move
# ------------------------------------------------

const
  RightPositions: array[Position, Position] = [
    None, Up1, Up2, Up3, Up4, Up5, Up5, Right1, Right2, Right3, Right4, Right4, Down1,
    Down2, Down3, Down4, Down5, Down5, Left2, Left3, Left4, Left5, Left5,
  ]
  LeftPositions: array[Position, Position] = [
    None, Up0, Up0, Up1, Up2, Up3, Up4, Right0, Right0, Right1, Right2, Right3, Down0,
    Down0, Down1, Down2, Down3, Down4, Left1, Left1, Left2, Left3, Left4,
  ]

func movedRight*(self: Position): Position {.inline.} =
  ## Returns the position moved rightward.
  RightPositions[self]

func movedLeft*(self: Position): Position {.inline.} =
  ## Returns the position moved leftward.
  LeftPositions[self]

func moveRight*(self: var Position) {.inline.} = ## Moves the position rightward.
  self = self.movedRight

func moveLeft*(self: var Position) {.inline.} = ## Moves the position leftward.
  self = self.movedLeft

# ------------------------------------------------
# Rotate
# ------------------------------------------------

const
  RightRotatePositions: array[Position, Position] = [
    None, Right0, Right1, Right2, Right3, Right4, Right4, Down0, Down1, Down2, Down3,
    Down4, Left1, Left1, Left2, Left3, Left4, Left5, Up1, Up2, Up3, Up4, Up5,
  ]
  LeftRotatePositions: array[Position, Position] = [
    None, Left1, Left1, Left2, Left3, Left4, Left5, Up0, Up1, Up2, Up3, Up4, Right0,
    Right1, Right2, Right3, Right4, Right4, Down1, Down2, Down3, Down4, Down5,
  ]

func rotatedRight*(self: Position): Position {.inline.} =
  ## Returns the position rotated right (clockwise).
  RightRotatePositions[self]

func rotatedLeft*(self: Position): Position {.inline.} =
  ## Returns the position rotated left (counterclockwise).
  LeftRotatePositions[self]

func rotateRight*(self: var Position) {.inline.} = ## Rotates the position right.
  self = self.rotatedRight

func rotateLeft*(self: var Position) {.inline.} = ## Rotates the position left.
  self = self.rotatedLeft

# ------------------------------------------------
# Position <-> string
# ------------------------------------------------

const StrToPos = collect:
  for pos in Position:
    {$pos: pos}

func parsePosition*(str: string): Position {.inline.} =
  ## Returns the position converted from the string representation.
  ## If the string is invalid, `ValueError` is raised.
  try:
    result = StrToPos[str]
  except KeyError:
    result = Position.low # HACK: dummy to suppress warning
    raise newException(ValueError, "Invalid position: " & str)

# ------------------------------------------------
# Position <-> URI
# ------------------------------------------------

const
  PosToIshikawaUri = "102468acegikoqsuwyCEGIK"
  IshikawaUriToPos = collect:
    for pos in Position:
      {$PosToIshikawaUri[pos.ord]: pos}

func toUriQuery*(self: Position, fqdn = Pon2): string {.inline.} =
  ## Returns the URI query converted from the position.
  case fqdn
  of Pon2:
    $self
  of Ishikawa, Ips:
    $PosToIshikawaUri[self.ord]

func parsePosition*(query: string, fqdn: IdeFqdn): Position {.inline.} =
  ## Returns the position converted from the URI query.
  ## If the query is invalid, `ValueError` is raised.
  case fqdn
  of Pon2:
    result = query.parsePosition
  of Ishikawa, Ips:
    try:
      result = IshikawaUriToPos[query]
    except KeyError:
      result = Position.low # HACK: dummy to suppress warning
      raise newException(ValueError, "Invalid position: " & query)

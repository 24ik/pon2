## This module implements positions.
##

{.experimental: "strictDefs".}

import std/[options, sequtils, strutils, sugar, tables]
import ./[misc]

type
  Direction* {.pure.} = enum
    ## Child-puyo's direction seen from the axis-puyo.
    Up = "^"
    Right = ">"
    Down = "v"
    Left = "<"

  Position* {.pure.} = enum
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

  Positions* = seq[Option[Position]]
    ## The position sequence. `none(Position)` means no-position.

const DoublePositions* = {Up0 .. Right4}
  ## All positions for double pairs; deduplicated.

using
  pos: Position
  optPos: Option[Position]
  positions: Positions
  mPos: var Position
  mPositions: var Positions

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const
  StartPositions: array[Direction, Position] = [Up0, Right0, Down0, Left1]
  StartColumns: array[Direction, Column] = [0, 0, 0, 1]

func initPosition*(axisCol: Column, childDir: Direction): Position {.inline.} =
  ## Position constructor.
  StartPositions[childDir].succ axisCol - StartColumns[childDir]

# ------------------------------------------------
# Property
# ------------------------------------------------

func initPosToAxisCol: array[Position, Column] {.inline.} =
  ## Constructor of `PosToAxisCol`.
  result[Position.low] = Column.low # dummy to remove warning
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
  ## Constructor of `PosToChildCol`.
  result[Position.low] = Column.low # dummy to remove warning
  for pos in Up0..Up5: result[pos] = PosToAxisCol[pos]
  for pos in Right0..Right4: result[pos] = PosToAxisCol[pos].succ
  for pos in Down0..Down5: result[pos] = PosToAxisCol[pos]
  for pos in Left1..Left5: result[pos] = PosToAxisCol[pos].pred

const PosToChildCol = initPosToChildCol()

func initPosToChildDir: array[Position, Direction] {.inline.} =
  ## Constructor of `PosToChildDir`.
  result[Position.low] = Direction.low # dummy to remove warning
  for pos in Up0..Up5: result[pos] = Up
  for pos in Right0..Right4: result[pos] = Right
  for pos in Down0..Down5: result[pos] = Down
  for pos in Left1..Left5: result[pos] = Left

const PosToChildDir = initPosToChildDir()

func axisColumn*(pos): Column {.inline.} = PosToAxisCol[pos]
  ## Returns the axis-puyo's column.

func childColumn*(pos): Column {.inline.} = PosToChildCol[pos]
  ## Returns the child-puyo's column.

func childDirection*(pos): Direction {.inline.} = PosToChildDir[pos]
  ## Returns the child-puyo's direction.

# ------------------------------------------------
# Move
# ------------------------------------------------

const
  RightPositions: array[Position, Position] = [
    Up1, Up2, Up3, Up4, Up5, Up5,
    Right1, Right2, Right3, Right4, Right4,
    Down1, Down2, Down3, Down4, Down5, Down5,
    Left2, Left3, Left4, Left5, Left5]
  LeftPositions: array[Position, Position] = [
    Up0, Up0, Up1, Up2, Up3, Up4,
    Right0, Right0, Right1, Right2, Right3,
    Down0, Down0, Down1, Down2, Down3, Down4,
    Left1, Left1, Left2, Left3, Left4]

func movedRight*(pos): Position {.inline.} = RightPositions[pos]
  ## Returns the position moved rightward.

func movedLeft*(pos): Position {.inline.} = LeftPositions[pos]
  ## Returns the position moved leftward.

func moveRight*(mPos) {.inline.} = mPos = mPos.movedRight
  ## Moves the position rightward.

func moveLeft*(mPos) {.inline.} = mPos = mPos.movedLeft
  ## Moves the position leftward.

# ------------------------------------------------
# Rotate
# ------------------------------------------------

const
  RightRotatePositions: array[Position, Position] = [
    Right0, Right1, Right2, Right3, Right4, Right4,
    Down0, Down1, Down2, Down3, Down4,
    Left1, Left1, Left2, Left3, Left4, Left5,
    Up1, Up2, Up3, Up4, Up5]
  LeftRotatePositions: array[Position, Position] = [
    Left1, Left1, Left2, Left3, Left4, Left5,
    Up0, Up1, Up2, Up3, Up4,
    Right0, Right1, Right2, Right3, Right4, Right4,
    Down1, Down2, Down3, Down4, Down5]

func rotatedRight*(pos): Position {.inline.} =
  ## Returns the position rotated right (clockwise).
  RightRotatePositions[pos]

func rotatedLeft*(pos): Position {.inline.} =
  ## Returns the position rotated left (counterclockwise).
  LeftRotatePositions[pos]

func rotateRight*(mPos: var Position) {.inline.} = mPos = mPos.rotatedRight
  ## Rotates the position right.

func rotateLeft*(mPos: var Position) {.inline.} = mPos = mPos.rotatedLeft
  ## Rotates the position left.

# ------------------------------------------------
# Position <-> string
# ------------------------------------------------

const
  NoPosStr = ".."
  StrToOptPos = collect:
    for pos in Position:
      {$pos: some pos}

func `$`*(optPos): string {.inline.} =
  if optPos.isSome: $optPos.get else: NoPosStr

func parsePosition*(str: string): Option[Position] {.inline.} =
  ## Converts the string representation to the position.
  ## If `str` is not a valid representation, `ValueError` is raised.
  ## If `str` means no-position, returns `none(Position)`.
  if str == NoPosStr:
    {.push warning[ProveInit]:off.}
    return none Position
    {.pop.}

  if str notin StrToOptPos:
    raise newException(ValueError, "Invalid position: " & str)

  result = StrToOptPos[str]

# ------------------------------------------------
# Positions <-> string
# ------------------------------------------------

const PositionsSep = "\n"

func `$`*(positions): string {.inline.} =
  let strs = collect:
    for pos in positions:
      $pos

  result = strs.join PositionsSep

func parsePositions*(str: string): Positions {.inline.} =
  ## Converts the string representation to the positions.
  ## If `str` is not a valid representation, `ValueError` is raised.
  if str == "":
    return newSeq[Option[Position]] 0

  result = str.split(PositionsSep).mapIt(it.parsePosition)

# ------------------------------------------------
# Position <-> URI
# ------------------------------------------------

const
  PosToIshikawaUri = "02468acegikoqsuwyCEGIK"
  NoPosIshikawaUri = "1"
  IshikawaUriToOptPos = collect:
    for i, url in PosToIshikawaUri:
      {$url: some i.Position}

func toUriQuery*(optPos; host: SimulatorHost): string {.inline.} =
  ## Converts the position to the URI query.
  case host
  of Izumiya: $optPos
  of Ishikawa, Ips:
    if optPos.isSome: $PosToIshikawaUri[optPos.get.ord] else: NoPosIshikawaUri

func parsePosition*(query: string, host: SimulatorHost): Option[Position]
                   {.inline.} =
  ## Converts the URI query to the position.
  ## If `query` is not a vaid URI, `ValueError` is raised.
  ## If `query` means no-position, returns `none(Position)`.
  case host
  of Izumiya: query.parsePosition
  of Ishikawa, Ips:
    if query == NoPosIshikawaUri: none Position
    elif query notin IshikawaUriToOptPos:
      raise newException(ValueError, "Invalid position: " & query)
    else: IshikawaUriToOptPos[query]

# ------------------------------------------------
# Positions <-> URI
# ------------------------------------------------

func toUriQuery*(positions; host: SimulatorHost): string {.inline.} =
  ## Converts the positions to the URI query.
  join positions.mapIt it.toUriQuery host

func parsePositions*(query: string, host: SimulatorHost): Positions {.inline.} =
  ## Converts the URI query to the positions.
  ## If `query` is not a vaid URI, `ValueError` is raised.
  case host
  of Izumiya:
    if query.len mod 2 != 0:
      raise newException(ValueError, "Invalid positions: " & query)

    collect:
      for i in 0..<query.len div 2:
        query[2 * i ..< 2 * i.succ].parsePosition host
  of Ishikawa, Ips:
    collect:
      for c in query:
        ($c).parsePosition host

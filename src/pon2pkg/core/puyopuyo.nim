## This module implements Puyo Puyo.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, strutils, tables, uri]
import ./[cell, field, host, moveresult, pair, pairposition, position]

type PuyoPuyo*[F: TsuField or WaterField] = object ## Puyo Puyo game.
  field*: F
  pairsPositions*: PairsPositions

  nextIdx: Natural

# ------------------------------------------------
# Reset
# ------------------------------------------------

func reset*[F: TsuField or WaterField](mSelf: var PuyoPuyo[F]) {.inline.} =
  ## Resets the Puyo Puyo game.
  mSelf.field = zeroField[F]()
  mSelf.pairsPositions.setLen 0
  mSelf.nextIdx = 0

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func initPuyoPuyo*[F: TsuField or WaterField](): PuyoPuyo[F] {.inline.} =
  ## Returns a new Puyo Puyo game.
  result = default PuyoPuyo[F] # HACK: dummy to suppress warning
  result.reset

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `==`*(self: PuyoPuyo[TsuField], puyoPuyo: PuyoPuyo[WaterField]): bool {.inline.} =
  false

func `==`*(self: PuyoPuyo[WaterField], field: PuyoPuyo[TsuField]): bool {.inline.} =
  false

# ------------------------------------------------
# Property
# ------------------------------------------------

func movingCompleted*[F: TsuField or WaterField](self: PuyoPuyo[F]): bool {.inline.} =
  ## Returns `true` if all pairs in the Puyo Puyo game are put (or skipped).
  self.nextIdx >= self.pairsPositions.len

# ------------------------------------------------
# Count
# ------------------------------------------------

func puyoCount*[F: TsuField or WaterField](
    self: PuyoPuyo[F], puyo: Puyo
): int {.inline.} =
  ## Returns the number of `puyo` in the Puyo Puyo game.
  self.field.puyoCount(puyo) + self.pairsPositions.puyoCount(puyo)

func puyoCount*[F: TsuField or WaterField](self: PuyoPuyo[F]): int {.inline.} =
  ## Returns the number of puyos in the Puyo Puyo game.
  self.field.puyoCount + self.pairsPositions.puyoCount

func colorCount*[F: TsuField or WaterField](self: PuyoPuyo[F]): int {.inline.} =
  ## Returns the number of color puyos in the Puyo Puyo game.
  self.field.colorCount + self.pairsPositions.colorCount

func garbageCount*[F: TsuField or WaterField](self: PuyoPuyo[F]): int {.inline.} =
  ## Returns the number of garbage puyos in the Puyo Puyo game.
  self.field.garbageCount + self.pairsPositions.garbageCount

# ------------------------------------------------
# Move - Vanilla
# ------------------------------------------------

func move[F: TsuField or WaterField](
    mSelf: var PuyoPuyo[F], pos: Position, overwritePos: static bool
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks the followings:
  ## - Number of chains
  if mSelf.movingCompleted:
    return 0.initMoveResult

  when overwritePos:
    mSelf.pairsPositions[mSelf.nextIdx].position = pos

  let pairPos = mSelf.pairsPositions[mSelf.nextIdx]
  result = mSelf.field.move(pairPos.pair, pairPos.position)
  mSelf.nextIdx.inc

func move*[F: TsuField or WaterField](
    mSelf: var PuyoPuyo[F]
): MoveResult {.inline, discardable.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks the followings:
  ## - Number of chains
  mSelf.move(Position.low, false)

func move*[F: TsuField or WaterField](
    mSelf: var PuyoPuyo[F], pos: Position
): MoveResult {.inline, discardable.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks the followings:
  ## - Number of chains
  mSelf.move(pos, true)

# ------------------------------------------------
# Move - Rough
# ------------------------------------------------

func moveWithRoughTracking[F: TsuField or WaterField](
    mSelf: var PuyoPuyo[F], pos: Position, overwritePos: static bool
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks the followings:
  ## - Number of chains
  ## - Number of puyos that disappeared
  if mSelf.movingCompleted:
    return initMoveResult(0, [0, 0, 0, 0, 0, 0, 0])

  when overwritePos:
    mSelf.pairsPositions[mSelf.nextIdx].position = pos

  let pairPos = mSelf.pairsPositions[mSelf.nextIdx]
  result = mSelf.field.moveWithRoughTracking(pairPos.pair, pairPos.position)
  mSelf.nextIdx.inc

func moveWithRoughTracking*[F: TsuField or WaterField](
    mSelf: var PuyoPuyo[F]
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks the followings:
  ## - Number of chains
  ## - Number of puyos that disappeared
  mSelf.moveWithRoughTracking(Position.low, false)

func moveWithRoughTracking*[F: TsuField or WaterField](
    mSelf: var PuyoPuyo[F], pos: Position
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks the followings:
  ## - Number of chains
  ## - Number of puyos that disappeared
  mSelf.moveWithRoughTracking(pos, true)

# ------------------------------------------------
# Move - Detail
# ------------------------------------------------

func moveWithDetailTracking[F: TsuField or WaterField](
    mSelf: var PuyoPuyo[F], pos: Position, overwritePos: static bool
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks the followings:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  if mSelf.movingCompleted:
    return initMoveResult(0, [0, 0, 0, 0, 0, 0, 0], @[])

  when overwritePos:
    mSelf.pairsPositions[mSelf.nextIdx].position = pos

  let pairPos = mSelf.pairsPositions[mSelf.nextIdx]
  result = mSelf.field.moveWithDetailTracking(pairPos.pair, pairPos.position)
  mSelf.nextIdx.inc

func moveWithDetailTracking*[F: TsuField or WaterField](
    mSelf: var PuyoPuyo[F]
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks the followings:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  mSelf.moveWithDetailTracking(Position.low, false)

func moveWithDetailTracking*[F: TsuField or WaterField](
    mSelf: var PuyoPuyo[F], pos: Position
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks the followings:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  mSelf.moveWithDetailTracking(pos, true)

# ------------------------------------------------
# Move - Full
# ------------------------------------------------

func moveWithFullTracking[F: TsuField or WaterField](
    mSelf: var PuyoPuyo[F], pos: Position, overwritePos: static bool
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks the followings:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  ## - Number of color puyos in each connected component that disappeared \
  ## in each chain
  if mSelf.movingCompleted:
    return initMoveResult(0, [0, 0, 0, 0, 0, 0, 0], @[], @[])

  when overwritePos:
    mSelf.pairsPositions[mSelf.nextIdx].position = pos

  let pairPos = mSelf.pairsPositions[mSelf.nextIdx]
  result = mSelf.field.moveWithFullTracking(pairPos.pair, pairPos.position)
  mSelf.nextIdx.inc

func moveWithFullTracking*[F: TsuField or WaterField](
    mSelf: var PuyoPuyo[F]
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks the followings:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  ## - Number of color puyos in each connected component that disappeared \
  ## in each chain
  mSelf.moveWithFullTracking(Position.low, false)

func moveWithFullTracking*[F: TsuField or WaterField](
    mSelf: var PuyoPuyo[F], pos: Position
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks the followings:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  ## - Number of color puyos in each connected component that disappeared \
  ## in each chain
  mSelf.moveWithFullTracking(pos, true)

# ------------------------------------------------
# Puyo Puyo Game <-> string
# ------------------------------------------------

const FieldPairsPositionsSep = "\n------\n"

func `$`*[F: TsuField or WaterField](self: PuyoPuyo[F]): string {.inline.} =
  # HACK: cannot `strformat` here due to inlining error
  $self.field & FieldPairsPositionsSep & $self.pairsPositions

func parsePuyoPuyo*[F: TsuField or WaterField](str: string): PuyoPuyo[F] {.inline.} =
  ## Returns the Puyo Puyo game converted from the string representation.
  ## If the string is invalid, `ValueError` is raised.
  let strs = str.split FieldPairsPositionsSep
  if strs.len != 2:
    raise newException(ValueError, "Invalid Puyo Puyo game: " & str)

  result.reset

  result.field = parseField[F](strs[0])
  result.pairsPositions = strs[1].parsePairsPositions
  result.nextIdx = 0

# ------------------------------------------------
# Puyo Puyo Game <-> URI
# ------------------------------------------------

const
  FieldKey = "field"
  PairsPositionsKey = "pairs"

func toUriQuery*[F: TsuField or WaterField](
    self: PuyoPuyo[F], host: SimulatorHost
): string {.inline.} =
  ## Returns the URI query converted from the Puyo Puyo game.
  case host
  of Izumiya:
    encodeQuery [
      (FieldKey, self.field.toUriQuery host),
      (PairsPositionsKey, self.pairsPositions.toUriQuery host)
    ]
  of Ishikawa, Ips:
    &"{self.field.toUriQuery host}_{self.pairsPositions.toUriQuery host}"

func parsePuyoPuyo*[F: TsuField or WaterField](
    query: string, host: SimulatorHost
): PuyoPuyo[F] {.inline.} =
  ## Returns the Puyo Puyo game converted from the URI query.
  ## If the query is invalid, `ValueError` is raised.
  result.nextIdx = 0

  case host
  of Izumiya:
    var
      fieldSet = false
      pairsPositionsSet = false

    for (key, val) in query.decodeQuery:
      case key
      of FieldKey:
        result.field = parseField[F](val, host)
        fieldSet = true
      of PairsPositionsKey:
        result.pairsPositions = val.parsePairsPositions host
        pairsPositionsSet = true
      else:
        raise newException(ValueError, "Invalid Puyo Puyo game: " & query)

    if not fieldSet or not pairsPositionsSet:
      raise newException(ValueError, "Invalid Puyo Puyo game: " & query)
  of Ishikawa, Ips:
    let queries = query.split '_'
    case queries.len
    of 1:
      result.pairsPositions.setLen 0
    of 2:
      result.pairsPositions = queries[1].parsePairsPositions host
    else:
      raise newException(ValueError, "Invalid Puyo Puyo game: " & query)

    result.field = parseField[F](queries[0], host)

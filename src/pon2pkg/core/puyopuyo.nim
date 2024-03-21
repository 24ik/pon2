## This module implements Puyo Puyo.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, strutils, tables, uri]
import ./[cell, field, host, moveresult, pair, pairposition, position, rule]

type PuyoPuyo*[F: TsuField or WaterField] = object ## Puyo Puyo game.
  field*: F
  pairsPositions*: PairsPositions

  nowIdx: Natural

# ------------------------------------------------
# Reset
# ------------------------------------------------

func reset*[F: TsuField or WaterField](mSelf: var PuyoPuyo[F]) {.inline.} =
  ## Resets the Puyo Puyo game.
  mSelf.field = initField[F]()
  mSelf.pairsPositions.setLen 0
  mSelf.nowIdx = 0

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
# Convert
# ------------------------------------------------

func toTsuPuyoPuyo*[F: TsuField or WaterField](
    self: PuyoPuyo[F]
): PuyoPuyo[TsuField] {.inline.} =
  ## Returns the Tsu Puyo Puyo converted from the given Puyo Puyo.
  result.field = self.field.toTsuField
  result.pairsPositions = self.pairsPositions
  result.nowIdx = self.nowIdx

func toWaterPuyoPuyo*[F: TsuField or WaterField](
    self: PuyoPuyo[F]
): PuyoPuyo[WaterField] {.inline.} =
  ## Returns the Water Puyo Puyo converted from the given Puyo Puyo.
  result.field = self.field.toWaterField
  result.pairsPositions = self.pairsPositions
  result.nowIdx = self.nowIdx

# ------------------------------------------------
# Property
# ------------------------------------------------

func rule*[F: TsuField or WaterField](self: PuyoPuyo[F]): Rule {.inline.} =
  ## Returns the rule.
  self.field.rule

func nowIndex*[F: TsuField or WaterField](self: PuyoPuyo[F]): int {.inline.} =
  ## Returns the index of pair being operated.
  self.nowIdx

func incrementNowIndex*[F: TsuField or WaterField](mSelf: var PuyoPuyo[F]) {.inline.} =
  ## Increments the index of pair being operated.
  ## The result is clipped.
  if mSelf.nowIdx >= mSelf.pairsPositions.len:
    return

  mSelf.nowIdx.inc

func decrementNowIndex*[F: TsuField or WaterField](mSelf: var PuyoPuyo[F]) {.inline.} =
  ## Decrements the index of pair being operated.
  ## The result is clipped.
  if mSelf.nowIdx <= 0:
    return

  mSelf.nowIdx.dec

func movingCompleted*[F: TsuField or WaterField](self: PuyoPuyo[F]): bool {.inline.} =
  ## Returns `true` if all pairs in the Puyo Puyo game are put (or skipped).
  self.nowIdx >= self.pairsPositions.len

func nowPairPosition*[F: TsuField or WaterField](
    self: PuyoPuyo[F]
): PairPosition {.inline.} =
  ## Returns the pair&position being operated.
  ## If no pairs left, `IndexDefect` is raised.
  self.pairsPositions[self.nowIdx]

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
# Move - Level0
# ------------------------------------------------

func move[F: TsuField or WaterField](
    mSelf: var PuyoPuyo[F], pos: Position, overwritePos: static bool
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  if mSelf.movingCompleted:
    return initMoveResult(0, [0, 0, 0, 0, 0, 0, 0])

  when overwritePos:
    mSelf.pairsPositions[mSelf.nowIdx].position = pos

  result = mSelf.field.move mSelf.nowPairPosition
  mSelf.nowIdx.inc

func move*[F: TsuField or WaterField](
    mSelf: var PuyoPuyo[F]
): MoveResult {.inline, discardable.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  mSelf.move(Position.low, false)

func move*[F: TsuField or WaterField](
    mSelf: var PuyoPuyo[F], pos: Position
): MoveResult {.inline, discardable.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  mSelf.move(pos, true)

func move0*[F: TsuField or WaterField](mSelf: var PuyoPuyo[F]): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  result = mSelf.move

func move0*[F: TsuField or WaterField](
    mSelf: var PuyoPuyo[F], pos: Position
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  result = mSelf.move pos

# ------------------------------------------------
# Move - Level1
# ------------------------------------------------

func move1[F: TsuField or WaterField](
    mSelf: var PuyoPuyo[F], pos: Position, overwritePos: static bool
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  if mSelf.movingCompleted:
    return initMoveResult(0, [0, 0, 0, 0, 0, 0, 0], newSeq[array[Puyo, int]](0))

  when overwritePos:
    mSelf.pairsPositions[mSelf.nowIdx].position = pos

  result = mSelf.field.move1 mSelf.nowPairPosition
  mSelf.nowIdx.inc

func move1*[F: TsuField or WaterField](mSelf: var PuyoPuyo[F]): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  mSelf.move1(Position.low, false)

func move1*[F: TsuField or WaterField](
    mSelf: var PuyoPuyo[F], pos: Position
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  mSelf.move1(pos, true)

# ------------------------------------------------
# Move - Level2
# ------------------------------------------------

func move2[F: TsuField or WaterField](
    mSelf: var PuyoPuyo[F], pos: Position, overwritePos: static bool
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  ## - Number of color puyos in each connected component that disappeared in each chain
  if mSelf.movingCompleted:
    return
      initMoveResult(0, [0, 0, 0, 0, 0, 0, 0], newSeq[array[ColorPuyo, seq[int]]](0))

  when overwritePos:
    mSelf.pairsPositions[mSelf.nowIdx].position = pos

  result = mSelf.field.move2 mSelf.nowPairPosition
  mSelf.nowIdx.inc

func move2*[F: TsuField or WaterField](mSelf: var PuyoPuyo[F]): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  ## - Number of color puyos in each connected component that disappeared in each chain
  mSelf.move2(Position.low, false)

func move2*[F: TsuField or WaterField](
    mSelf: var PuyoPuyo[F], pos: Position
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  ## - Number of color puyos in each connected component that disappeared in each chain
  mSelf.move2(pos, true)

# ------------------------------------------------
# Puyo Puyo <-> string
# ------------------------------------------------

const FieldPairsPositionsSep = "\n------\n"

func `$`*[F: TsuField or WaterField](self: PuyoPuyo[F]): string {.inline.} =
  # HACK: cannot `strformat` here due to inlining error
  $self.field & FieldPairsPositionsSep & $self.pairsPositions

func parsePuyoPuyo*[F: TsuField or WaterField](str: string): PuyoPuyo[F] {.inline.} =
  ## Returns the Puyo Puyo converted from the string representation.
  ## If the string is invalid, `ValueError` is raised.
  let strs = str.split FieldPairsPositionsSep
  if strs.len != 2:
    raise newException(ValueError, "Invalid Puyo Puyo: " & str)

  result.reset

  result.field = parseField[F](strs[0])
  result.pairsPositions = strs[1].parsePairsPositions
  result.nowIdx = 0

# ------------------------------------------------
# Puyo Puyo Game <-> URI
# ------------------------------------------------

const
  FieldKey = "field"
  PairsPositionsKey = "pairs"

func toUriQuery*[F: TsuField or WaterField](
    self: PuyoPuyo[F], host: SimulatorHost
): string {.inline.} =
  ## Returns the URI query converted from the Puyo Puyo.
  case host
  of Izumiya:
    encodeQuery [
      (FieldKey, self.field.toUriQuery host),
      (PairsPositionsKey, self.pairsPositions.toUriQuery host),
    ]
  of Ishikawa, Ips:
    &"{self.field.toUriQuery host}_{self.pairsPositions.toUriQuery host}"

func parsePuyoPuyo*[F: TsuField or WaterField](
    query: string, host: SimulatorHost
): PuyoPuyo[F] {.inline.} =
  ## Returns the Puyo Puyo converted from the URI query.
  ## If the query is invalid, `ValueError` is raised.
  result.nowIdx = 0

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
        raise newException(ValueError, "Invalid Puyo Puyo: " & query)

    if not fieldSet or not pairsPositionsSet:
      raise newException(ValueError, "Invalid Puyo Puyo: " & query)
  of Ishikawa, Ips:
    let queries = query.split '_'
    case queries.len
    of 1:
      result.pairsPositions.setLen 0
    of 2:
      result.pairsPositions = queries[1].parsePairsPositions host
    else:
      raise newException(ValueError, "Invalid Puyo Puyo: " & query)

    result.field = parseField[F](queries[0], host)

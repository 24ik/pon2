## This module implements Puyo Puyo.
##
#[
- env->puyopuyo
- envにposition追加
- env.toUriはfull-URIじゃなくてqueryだけでいい気がする
- simulatorはreqを必ず持つ
- appとcoreの二本立て
  - coreにnazopuyoも入れる
  - appとcoreはrename可能性あり
- editorpermuterはrenameする
- defineプラグマをpon2.waterheightみたいに指定できるように
- corepkg -> core
]#

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options, os, random, sequtils, setutils, strutils, sugar, tables, uri]
import ./[cell, field, fieldtype, misc, moveresult, pair, pairposition,
          position, rule]

type PuyoPuyo*[F: TsuField or WaterField] = object
  ## Puyo Puyo game.
  field*: F
  pairsPositions*: PairsPositions

  pairPositionIdx: Natural

# ------------------------------------------------
# Reset
# ------------------------------------------------

func reset*[F: TsuField or WaterField](mSelf: var PuyoPuyo[F]) {.inline.} =
  ## Resets the Puyo Puyo game.
  mSelf.field = zeroField[F]()
  mSelf.pairsPositions.setLen 0
  mSelf.pairPositionIdx = 0

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func initPuyoPuyo*[F: TsuField or WaterField]: PuyoPuyo[F] {.inline.} =
  ## Returns a new Puyo Puyo game.
  result.reset

# ------------------------------------------------
# Count
# ------------------------------------------------

func puyoCount*[F: TsuField or WaterField](self: PuyoPuyo[F], puyo: Puyo): int
               {.inline.} =
  ## Returns the number of `puyo` in the Puyo Puyo game.
  self.field.puyoCount(puyo) + self.pairsPositions.puyoCount(puyo)

func puyoCount*[F: TsuField or WaterField](self: PuyoPuyo[F]): int {.inline.} =
  ## Returns the number of puyos in the Puyo Puyo game.
  self.field.puyoCount + self.pairsPositions.puyoCount

func colorCount*[F: TsuField or WaterField](self: PuyoPuyo[F]): int {.inline.} =
  ## Returns the number of color puyos in the Puyo Puyo game.
  self.field.colorCount + self.pairsPositions.colorCount

func garbageCount*[F: TsuField or WaterField](self: PuyoPuyo[F]): int
                  {.inline.} =
  ## Returns the number of garbage puyos in the Puyo Puyo game.
  self.field.garbageCount + self.pairsPositions.garbageCount

# ------------------------------------------------
# Move
# ------------------------------------------------

func move*[F: TsuField or WaterField](mSelf: var PuyoPuyo[F]): MoveResult
    {.inline, discardable.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks the followings:
  ## - Number of chains
  if mSelf.pairPositionIdx >= mSelf.pairsPositions.len:
    return 0.initMoveResult

  let pairPos = mSelf.pairsPositions[mSelf.pairPositionIdx]
  result = mSelf.field.move(pairPos.pair, pairPos.position)
  mSelf.pairPositionIdx.inc

func move*[F: TsuField or WaterField](mSelf: var PuyoPuyo[F], pos: Position):
    MoveResult {.inline, discardable.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks the followings:
  ## - Number of chains
  mSelf.pairsPositions[mSelf.pairPositionIdx].position = pos
  result = mSelf.move

func moveWithRoughTracking*[F: TsuField or WaterField](
    mSelf: var PuyoPuyo[F]): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks the followings:
  ## - Number of chains
  ## - Number of puyos that disappeared
  if mSelf.pairPositionIdx >= mSelf.pairsPositions.len:
    return 0.initMoveResult

  let pairPos = mSelf.pairsPositions[mSelf.pairPositionIdx]
  result = mSelf.field.moveWithRoughTracking(pairPos.pair, pairPos.position)
  mSelf.pairPositionIdx.inc

func moveWithRoughTracking*[F: TsuField or WaterField](
    mSelf: var PuyoPuyo[F], pos: Position): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks the followings:
  ## - Number of chains
  ## - Number of puyos that disappeared
  mSelf.pairsPositions[mSelf.pairPositionIdx].position = pos
  result = mSelf.moveWithRoughTracking

func moveWithDetailTracking*[F: TsuField or WaterField](
    mSelf: var PuyoPuyo[F]): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks the followings:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  if mSelf.pairPositionIdx >= mSelf.pairsPositions.len:
    return 0.initMoveResult

  let pairPos = mSelf.pairsPositions[mSelf.pairPositionIdx]
  result = mSelf.field.moveWithDetailTracking(pairPos.pair, pairPos.position)
  mSelf.pairPositionIdx.inc

func moveWithDetailTracking*[F: TsuField or WaterField](
    mSelf: var PuyoPuyo[F], pos: Position): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks the followings:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  mSelf.pairsPositions[mSelf.pairPositionIdx].position = pos
  result = mSelf.moveWithDetailTracking

func moveWithFullTracking*[F: TsuField or WaterField](
    mSelf: var Environment[F]): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks the followings:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  ## - Number of color puyos in each connected component that disappeared \
  ## in each chain
  if mSelf.pairPositionIdx >= mSelf.pairsPositions.len:
    return 0.initMoveResult

  let pairPos = mSelf.pairsPositions[mSelf.pairPositionIdx]
  result = mSelf.field.moveWithFullTracking(pairPos.pair, pairPos.position)
  mSelf.pairPositionIdx.inc

func moveWithFullTracking*[F: TsuField or WaterField](
    mSelf: var Environment[F]): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks the followings:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  ## - Number of color puyos in each connected component that disappeared \
  ## in each chain
  mSelf.pairsPositions[mSelf.pairPositionIdx].position = pos
  result = mSelf.moveWithFullTracking

# ------------------------------------------------
# Puyo Puyo Game <-> string
# ------------------------------------------------

const FieldPairsPositionsSep = "\n------\n"

func `$`*[F: TsuField or WaterField](self: PuyoPuyo[F]): string {.inline.} =
  &"{self.field}{FieldPairsPositionsSep}{self.pairsPositions}"

func parsePuyoPuyo*[F: TsuField or WaterField](str: string): PuyoPuyo[F]
                   {.inline.} =
  ## Returns the Puyo Puyo game converted from the string representation.
  ## If the string is invalid, `ValueError` is raised.
  let strs = str.split FieldPairsPositionsSep
  if strs.len != 2:
    raise newException(ValueError, "Invalid Puyo Puyo game: " & str)

  result.reset

  result.field = strs[0].parseField[:F]
  result.pairsPositions = strs[1].parsePairsPositions
  result.pairPositionIdx = 0

# ------------------------------------------------
# Puyo Puyo Game <-> URI
# ------------------------------------------------

const
  FieldKey = "field"
  PairsPositionsKey = "pairs"

func toUriQuery*[F: TsuField or WaterField](
    self: PuyoPuyo[F], host: SimulatorHost): string {.inline.} =
  ## Returns the URI query converted from the Puyo Puyo game.
  case host
  of Izumiya:
    encodeQuery [(FieldKey, self.field.toUriQuery host),
                 (PairsPositionsKey, self.pairsPositions.toUriQuery host)]
  of Ishikawa, Ips:
    &"{self.field.toUriQuery host}_{self.pairsPositions.toUriQuery host}"

func parsePuyoPuyo*[F: TsuField or WaterField](
    query: string, host: SimulatorHost): PuyoPuyo[F] {.inline.} =
  ## Returns the Puyo Puyo game converted from the URI query.
  ## If the query is invalid, `ValueError` is raised.
  result.pairPositionIdx = 0

  case host
  of Izumiya:
    var
      fieldSet = false
      pairsPositionsSet = false

    for (key, val) in query.decodeQuery:
      case key
      of FieldKey:
        result.field = val.parseField[:F](host)
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

    result.field = queries[0].parseField host

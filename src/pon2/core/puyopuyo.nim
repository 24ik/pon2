## This module implements Puyo Puyo.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques, strformat, strutils, tables, uri]
import ./[cell, field, fqdn, moveresult, pair, pairposition, position, rule]

type PuyoPuyo*[F: TsuField or WaterField] = object ## Puyo Puyo game.
  field*: F
  pairsPositions*: PairsPositions

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func initPuyoPuyo*[F: TsuField or WaterField](): PuyoPuyo[F] {.inline.} =
  ## Returns a new Puyo Puyo game.
  result = PuyoPuyo[F](field: initField[F](), pairsPositions: initDeque[PairPosition]())

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
  PuyoPuyo[TsuField](field: self.field.toTsuField, pairsPositions: self.pairsPositions)

func toWaterPuyoPuyo*[F: TsuField or WaterField](
    self: PuyoPuyo[F]
): PuyoPuyo[WaterField] {.inline.} =
  ## Returns the Water Puyo Puyo converted from the given Puyo Puyo.
  PuyoPuyo[WaterField](
    field: self.field.toWaterField, pairsPositions: self.pairsPositions
  )

# ------------------------------------------------
# Property
# ------------------------------------------------

func rule*[F: TsuField or WaterField](self: PuyoPuyo[F]): Rule {.inline.} =
  ## Returns the rule.
  self.field.rule

func movingCompleted*[F: TsuField or WaterField](self: PuyoPuyo[F]): bool {.inline.} =
  ## Returns `true` if all pairs in the Puyo Puyo game are put (or skipped).
  self.pairsPositions.len == 0

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
    self: var PuyoPuyo[F], pos: Position, overwritePos: static bool
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  if self.movingCompleted:
    return initMoveResult(0, [0, 0, 0, 0, 0, 0, 0])

  when overwritePos:
    self.pairsPositions.peekFirst.position = pos

  result = self.field.move self.pairsPositions.popFirst

func move*[F: TsuField or WaterField](
    self: var PuyoPuyo[F]
): MoveResult {.inline, discardable.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  self.move(Position.low, false)

func move*[F: TsuField or WaterField](
    self: var PuyoPuyo[F], pos: Position
): MoveResult {.inline, discardable.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  self.move(pos, true)

func move0*[F: TsuField or WaterField](self: var PuyoPuyo[F]): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  self.move

func move0*[F: TsuField or WaterField](
    self: var PuyoPuyo[F], pos: Position
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  self.move pos

# ------------------------------------------------
# Move - Level1
# ------------------------------------------------

func move1[F: TsuField or WaterField](
    self: var PuyoPuyo[F], pos: Position, overwritePos: static bool
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  if self.movingCompleted:
    return initMoveResult(0, [0, 0, 0, 0, 0, 0, 0], @[])

  when overwritePos:
    self.pairsPositions.peekFirst.position = pos

  result = self.field.move1 self.pairsPositions.popFirst

func move1*[F: TsuField or WaterField](self: var PuyoPuyo[F]): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  self.move1(Position.low, false)

func move1*[F: TsuField or WaterField](
    self: var PuyoPuyo[F], pos: Position
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  self.move1(pos, true)

# ------------------------------------------------
# Move - Level2
# ------------------------------------------------

func move2[F: TsuField or WaterField](
    self: var PuyoPuyo[F], pos: Position, overwritePos: static bool
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  ## - Number of color puyos in each connected component that disappeared in each chain
  if self.movingCompleted:
    return initMoveResult(0, [0, 0, 0, 0, 0, 0, 0], @[], @[])

  when overwritePos:
    self.pairsPositions.peekFirst.position = pos

  result = self.field.move2 self.pairsPositions.popFirst

func move2*[F: TsuField or WaterField](self: var PuyoPuyo[F]): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  ## - Number of color puyos in each connected component that disappeared in each chain
  self.move2(Position.low, false)

func move2*[F: TsuField or WaterField](
    self: var PuyoPuyo[F], pos: Position
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  ## - Number of color puyos in each connected component that disappeared in each chain
  self.move2(pos, true)

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

  result = PuyoPuyo[F](
    field: parseField[F](strs[0]), pairsPositions: strs[1].parsePairsPositions
  )

# ------------------------------------------------
# Puyo Puyo Game <-> URI
# ------------------------------------------------

const
  FieldKey = "field"
  PairsPositionsKey = "pairs"

func toUriQuery*[F: TsuField or WaterField](
    self: PuyoPuyo[F], fqdn = Pon2
): string {.inline.} =
  ## Returns the URI query converted from the Puyo Puyo.
  case fqdn
  of Pon2:
    encodeQuery [
      (FieldKey, self.field.toUriQuery fqdn),
      (PairsPositionsKey, self.pairsPositions.toUriQuery fqdn),
    ]
  of Ishikawa, Ips:
    &"{self.field.toUriQuery fqdn}_{self.pairsPositions.toUriQuery fqdn}"

func parsePuyoPuyo*[F: TsuField or WaterField](
    query: string, fqdn: IdeFqdn
): PuyoPuyo[F] {.inline.} =
  ## Returns the Puyo Puyo converted from the URI query.
  ## If the query is invalid, `ValueError` is raised.
  result = initPuyoPuyo[F]()

  case fqdn
  of Pon2:
    var
      fieldSet = false
      pairsPositionsSet = false

    for (key, val) in query.decodeQuery:
      case key
      of FieldKey:
        if fieldSet:
          raise newException(ValueError, "Invalid Puyo Puyo: " & query)

        result.field = parseField[F](val, fqdn)
        fieldSet = true
      of PairsPositionsKey:
        if pairsPositionsSet:
          raise newException(ValueError, "Invalid Puyo Puyo: " & query)

        result.pairsPositions = val.parsePairsPositions fqdn
        pairsPositionsSet = true
      else:
        raise newException(ValueError, "Invalid Puyo Puyo: " & query)

    if not fieldSet or not pairsPositionsSet:
      raise newException(ValueError, "Invalid Puyo Puyo: " & query)
  of Ishikawa, Ips:
    let queries = query.split '_'
    case queries.len
    of 1:
      discard
    of 2:
      result.pairsPositions = queries[1].parsePairsPositions fqdn
    else:
      raise newException(ValueError, "Invalid Puyo Puyo: " & query)

    result.field = parseField[F](queries[0], fqdn)

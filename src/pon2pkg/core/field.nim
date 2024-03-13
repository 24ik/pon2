## This module implements fields.
## The following implementations are supported:
## - Bitboard with AVX2
## - Bitboard with primitive types
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, setutils, strutils, sugar, tables]
import ./[cell, fieldtype, host, moveresult, pair, pairposition, position, rule]
import ../private/[intrinsic]
import ../private/core/field/[binary]

when UseAvx2:
  import ../private/core/field/avx2/[disappearresult, main]
  export main.`==`
else:
  import ../private/core/field/primitive/[disappearresult, main]

export
  main.TsuField, main.WaterField, main.initField, main.toTsuField, main.toWaterField,
  main.`[]`, main.`[]=`, main.insert, main.removeSqueeze, main.puyoCount,
  main.colorCount, main.garbageCount, main.connect3, main.connect3V, main.connect3H,
  main.connect3L, main.shiftedUp, main.shiftedDown, main.shiftedRight, main.shiftedLeft,
  main.flippedV, main.flippedH, main.disappear, main.willDisappear, main.put, main.drop,
  main.toArray, main.parseField

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `==`*(self: TsuField, field: WaterField): bool {.inline.} =
  false

func `==`*(self: WaterField, field: TsuField): bool {.inline.} =
  false

# ------------------------------------------------
# Convert
# ------------------------------------------------

func toTsuField*(self: TsuField): TsuField {.inline.} =
  ## Returns the Tsu field converted from the given field.
  result = self

func toWaterField*(self: WaterField): WaterField {.inline.} =
  ## Returns the Water field converted from the given field.
  result = self

# ------------------------------------------------
# Property
# ------------------------------------------------

func rule*[F: TsuField or WaterField](self: F): Rule {.inline.} =
  ## Returns the rule.
  when F is TsuField: Tsu else: Water

func isDead*(self: TsuField or WaterField): bool {.inline.} =
  ## Returns `true` if the field is in a defeated state.
  self.exist.isDead self.rule

# ------------------------------------------------
# Count
# ------------------------------------------------

func noneCount*(self: TsuField or WaterField): int {.inline.} =
  ## Returns the number of `None` in the field.
  Height * Width - self.puyoCount

# ------------------------------------------------
# Position
# ------------------------------------------------

func invalidPositions*(self: TsuField or WaterField): set[Position] {.inline.} =
  ## Returns the invalid positions.
  ## `Position.None` is not included.
  self.exist.invalidPositions

func validPositions*(self: TsuField or WaterField): set[Position] {.inline.} =
  ## Returns the valid positions.
  ## `Position.None` is not included.
  self.exist.validPositions

func validDoublePositions*(self: TsuField or WaterField): set[Position] {.inline.} =
  ## Returns the valid positions for a double pair.
  ## `Position.None` is not included.
  self.exist.validDoublePositions

# ------------------------------------------------
# Shift
# ------------------------------------------------

func shiftUp*(mSelf: var (TsuField or WaterField)) {.inline.} =
  ## Shifts the field upward.
  mSelf = mSelf.shiftedUp

func shiftDown*(mSelf: var (TsuField or WaterField)) {.inline.} =
  ## Shifts the field downward.
  mSelf = mSelf.shiftedDown

func shiftRight*(mSelf: var (TsuField or WaterField)) {.inline.} =
  ## Shifts the field rightward.
  mSelf = mSelf.shiftedRight

func shiftLeft*(mSelf: var (TsuField or WaterField)) {.inline.} =
  ## Shifts the field leftward.
  mSelf = mSelf.shiftedLeft

# ------------------------------------------------
# Flip
# ------------------------------------------------

func flipV*(mSelf: var (TsuField or WaterField)) {.inline.} =
  ## Flips the field vertically.
  mSelf = mSelf.flippedV

func flipH*(mSelf: var (TsuField or WaterField)) {.inline.} =
  ## Flips the field horizontally.
  mSelf = mSelf.flippedH

# ------------------------------------------------
# Move - Level0
# ------------------------------------------------

func move*(
    mSelf: var (TsuField or WaterField), pair: Pair, pos: Position
): MoveResult {.inline, discardable.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  var
    chainCount = 0
    disappearCounts: array[Puyo, int] = [0, 0, 0, 0, 0, 0, 0]

  mSelf.put pair, pos

  while true:
    let disappearResult = mSelf.disappear
    if disappearResult.notDisappeared:
      return initMoveResult(chainCount, disappearCounts)

    mSelf.drop

    chainCount.inc
    for puyo in Puyo:
      disappearCounts[puyo].inc disappearResult.puyoCount puyo

  result = initMoveResult(chainCount, disappearCounts) # HACK: dummy to suppress warning

func move*(
    mSelf: var (TsuField or WaterField), pairPos: PairPosition
): MoveResult {.inline, discardable.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  result = mSelf.move(pairPos.pair, pairPos.position)

func move0*(
    mSelf: var (TsuField or WaterField), pair: Pair, pos: Position
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  result = mSelf.move(pair, pos)

func move0*(
    mSelf: var (TsuField or WaterField), pairPos: PairPosition
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  result = mSelf.move pairPos

# ------------------------------------------------
# Move - Level1
# ------------------------------------------------

func move1*(
    mSelf: var (TsuField or WaterField), pair: Pair, pos: Position
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  var
    chainCount = 0
    disappearCounts: array[Puyo, int] = [0, 0, 0, 0, 0, 0, 0]
    detailDisappearCounts: seq[array[Puyo, int]] = @[]

  mSelf.put pair, pos

  while true:
    let disappearResult = mSelf.disappear
    if disappearResult.notDisappeared:
      return initMoveResult(chainCount, disappearCounts, detailDisappearCounts)

    mSelf.drop

    chainCount.inc

    var counts: array[Puyo, int]
    counts[Puyo.low] = Natural.low # HACK: dummy to suppress warning
    for puyo in Puyo.low .. Puyo.high:
      let count = disappearResult.puyoCount puyo
      counts[puyo] = count
      disappearCounts[puyo].inc count
    detailDisappearCounts.add counts

  # HACK: dummy to suppress warning
  result = initMoveResult(chainCount, disappearCounts, detailDisappearCounts)

func move1*(
    mSelf: var (TsuField or WaterField), pairPos: PairPosition
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  result = mSelf.move1(pairPos.pair, pairPos.position)

# ------------------------------------------------
# Move - Level2
# ------------------------------------------------

func move2*(
    mSelf: var (TsuField or WaterField), pair: Pair, pos: Position
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  ## - Number of color puyos in each connected component that disappeared in each chain
  var
    chainCount = 0
    disappearCounts: array[Puyo, int] = [0, 0, 0, 0, 0, 0, 0]
    fullDisappearCounts: seq[array[ColorPuyo, seq[int]]] = @[]

  mSelf.put pair, pos

  while true:
    let disappearResult = mSelf.disappear
    if disappearResult.notDisappeared:
      return initMoveResult(chainCount, disappearCounts, fullDisappearCounts)

    mSelf.drop

    chainCount.inc

    for puyo in Puyo.low .. Puyo.high:
      let count = disappearResult.puyoCount puyo
      disappearCounts[puyo].inc count
    fullDisappearCounts.add disappearResult.connectionCounts

  # HACK: dummy to suppress warning
  result = initMoveResult(chainCount, disappearCounts, fullDisappearCounts)

func move2*(
    mSelf: var (TsuField or WaterField), pairPos: PairPosition
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  ## - Number of color puyos in each connected component that disappeared in each chain
  result = mSelf.move2(pairPos.pair, pairPos.position)

# ------------------------------------------------
# Field <-> string
# ------------------------------------------------

func `$`*(self: TsuField): string {.inline.} =
  # NOTE: using generics for `$` raises error
  let
    arr = self.toArray
    lines = collect:
      for row in Row.low .. Row.high:
        join arr[row].mapIt $it

  result = lines.join "\n"

func `$`*(self: WaterField): string {.inline.} =
  # NOTE: using generics for `$` raises error
  let
    arr = self.toArray
    lines = collect:
      for row in Row.low .. Row.high:
        join arr[row].mapIt $it

  result = lines.join "\n"

func parseField*[F: TsuField or WaterField](str: string): F {.inline.} =
  ## Returns the field converted from the string representation.
  ## If the string is invalid, `ValueError` is raised.
  let lines = str.split '\n'
  if lines.len != Height or lines.anyIt it.len != Width:
    raise newException(ValueError, "Invalid field: " & str)

  var arr: array[Row, array[Column, Cell]]
  arr[Row.low][Column.low] = Cell.low # dummy to remove warning
  for row in Row.low .. Row.high:
    for col in Column.low .. Column.high:
      arr[row][col] = ($lines[row][col]).parseCell

  result = parseField[F](arr)

# ------------------------------------------------
# Field <-> URI
# ------------------------------------------------

const
  IzumiyaUriRuleFieldSep = "-"
  IzumiyaUriAirWaterSep = "~"

  IzumiyaUriToRule = collect:
    for rule in Rule:
      {$rule: rule}

  IshikawaUriChars = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-"
  IshikawaUriCharToIdx = collect:
    for i, c in IshikawaUriChars:
      {c: i}
  CellToIshikawaIdx: array[Cell, int] = [0, -1, 6, 1, 2, 3, 4, 5]
  IshikawaIdxToCell = collect:
    for cell, idx in CellToIshikawaIdx:
      {idx: cell}

func toUriQuery*(self: TsuField or WaterField, host: SimulatorHost): string {.inline.} =
  ## Returns the URI query converted from the field.
  let arr = self.toArray

  case host
  of Izumiya:
    let cellsStr =
      case self.rule
      of Tsu:
        let cellChars = collect:
          for line in arr:
            for cell in line:
              $cell

        cellChars.join.strip(trailing = false, chars = {($None)[0]})
      of Water:
        let
          underWaterChars = collect:
            for row in WaterRow.low .. WaterRow.high:
              for cell in arr[row]:
                $cell
          airChars = collect:
            for row in Row.low .. WaterRow.low.pred:
              for cell in arr[row]:
                $cell

        airChars.join.strip(trailing = false, chars = {($None)[0]}) &
          IzumiyaUriAirWaterSep &
          underWaterChars.join.strip(leading = false, chars = {($None)[0]})

    result = $self.rule & IzumiyaUriRuleFieldSep & cellsStr
  of Ishikawa, Ips:
    var lines = newSeqOfCap[string](Height)
    for row in Row.low .. Row.high:
      var chars = newSeqOfCap[char](Height div 2)
      for i in 0 ..< Width div 2:
        let
          col = Column 2 * i
          cell1 = arr[row][col]
          cell2 = arr[row][col.succ]

        chars.add IshikawaUriChars[
          CellToIshikawaIdx[cell1] * Cell.fullSet.card + CellToIshikawaIdx[cell2]
        ]

      lines.add chars.join

    result = lines.join.strip(trailing = false, chars = {'0'})

func parseField*[F: TsuField or WaterField](
    query: string, host: SimulatorHost
): F {.inline.} =
  ## Returns the field converted from the query.
  ## If the query is invalid, `ValueError` is raised.
  var arr: array[Row, array[Column, Cell]]
  arr[Row.low][Column.low] = Cell.low # dummy to remove warning

  case host
  of Izumiya:
    let strs = query.split IzumiyaUriRuleFieldSep
    if strs.len != 2 or strs[0] notin IzumiyaUriToRule:
      raise newException(ValueError, "Invalid field: " & query)

    if strs[0] notin IzumiyaUriToRule:
      raise newException(ValueError, "Invalid field: " & query)
    let rule = IzumiyaUriToRule[strs[0]]

    when F is TsuField:
      if rule != Tsu:
        raise newException(ValueError, "Incompatible generics type: " & $F)
    else:
      if rule != Water:
        raise newException(ValueError, "Incompatible generics type: " & $F)

    case rule
    of Tsu:
      if strs[1].len > Height * Width:
        raise newException(ValueError, "Invalid field: " & query)

      let cellsStr = ($None).repeat(Height * Width - strs[1].len) & strs[1]
      for row in Row.low .. Row.high:
        for col in Column.low .. Column.high:
          arr[row][col] = parseCell $cellsStr[row * Width + col]
    of Water:
      let cellsStrs = strs[1].split IzumiyaUriAirWaterSep
      if cellsStrs.len != 2 or cellsStrs[0].len > AirHeight * Width or
          cellsStrs[1].len > WaterHeight * Width:
        raise newException(ValueError, "Invalid field: " & query)

      let airCellsStr =
        ($None).repeat(AirHeight * Width - cellsStrs[0].len) & cellsStrs[0]
      for row in AirRow.low .. AirRow.high:
        for col in Column.low .. Column.high:
          arr[row][col] = parseCell $airCellsStr[row * Width + col]

      let waterCellsStr =
        cellsStrs[1] & ($None).repeat(WaterHeight * Width - cellsStrs[1].len)
      for row in WaterRow.low .. WaterRow.high:
        for col in Column.low .. Column.high:
          arr[row][col] = parseCell $waterCellsStr[(row - WaterRow.low) * Width + col]
  of Ishikawa, Ips:
    if query.len > Height * Width div 2:
      raise newException(ValueError, "Invalid field: " & query)

    for i, c in '0'.repeat(Height * Width div 2 - query.len) & query:
      if c notin IshikawaUriCharToIdx:
        raise newException(ValueError, "Invalid field: " & query)

      let
        idx = IshikawaUriCharToIdx[c]
        cell1 = IshikawaIdxToCell[idx div Cell.fullSet.card]
        cell2 = IshikawaIdxToCell[idx mod Cell.fullSet.card]
        row = Row i div (Width div 2)
        col = Column i mod (Width div 2) * 2

      arr[row][col] = cell1
      arr[row][col.succ] = cell2

  result = parseField[F](arr)

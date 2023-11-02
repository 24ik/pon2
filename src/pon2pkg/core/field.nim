## This module implements fields.
## The following implementations are supported:
## - Bitboard with AVX2
## - Bitboard with primitive types
## 

{.experimental: "strictDefs".}

import std/[sequtils, setutils, strutils, sugar, tables]
import ./[cell, misc, moveResult, pair, position]
import ../private/core/[intrinsic]
import ../private/core/field/[binary]

when UseAvx2:
  import ../private/core/field/avx2/[disappearResult, main]
  export main.`==`
else:
  import ../private/core/field/primitive/[disappearResult, main]

export UseAvx2, main.TsuField, main.WaterField, main.zeroField,
  main.zeroTsuField, main.zeroWaterField, main.toTsuField,
  main.toWaterField, main.`[]`, main.`[]=`, main.insert, main.removeSqueeze,
  main.cellCount, main.puyoCount, main.colorCount, main.garbageCount,
  main.connect3, main.connect3V, main.connect3H, main.connect3L, main.shiftedUp,
  main.shiftedDown, main.shiftedRight, main.shiftedLeft, main.flippedV,
  main.flippedH, main.disappear, main.willDisappear, main.put, main.drop,
  main.toArray, main.parseField

type Fields* = object
  ## Field type that accepts all rules.
  rule*: Rule
  tsu*: TsuField
  water*: WaterField

# ------------------------------------------------
# Property
# ------------------------------------------------

func rule*[F: TsuField or WaterField](self: F): Rule {.inline.} =
  ## Returns the rule.
  when F is TsuField: Tsu else: Water

func isDead*[F: TsuField or WaterField](self: F): bool {.inline.} =
  ## Returns `true` if the field is in a defeated state.
  self.exist.isDead self.rule

# ------------------------------------------------
# Template
# ------------------------------------------------

template flatten*(fields: Fields, body: untyped) =
  ## Runs `body` with exported `field`.
  case fields.rule
  of Tsu:
    let field {.inject.} = fields.tsu
    body
  of Water:
    let field {.inject.} = fields.water
    body

# ------------------------------------------------
# Position
# ------------------------------------------------

func invalidPositions*[F: TsuField or WaterField](self: F): set[Position]
                                                 {.inline.} =
  ## Returns the invalid positions.
  self.exist.invalidPositions

func validPositions*[F: TsuField or WaterField](self: F): set[Position]
                                               {.inline.} =
  ## Returns the valid positions.
  self.exist.validPositions

func validDoublePositions*[F: TsuField or WaterField](self: F): set[Position]
                                                     {.inline.} =
  ## Returns the valid positions for a double pair.
  self.exist.validDoublePositions

# ------------------------------------------------
# Shift
# ------------------------------------------------

func shiftUp*[F: TsuField or WaterField](mSelf: var F) {.inline.} =
  ## Shifts the field upward.
  mSelf = mSelf.shiftedUp

func shiftDown*[F: TsuField or WaterField](mSelf: var F) {.inline.} =
  ## Shifts the field downward.
  mSelf = mSelf.shiftedDown

func shiftRight*[F: TsuField or WaterField](mSelf: var F) {.inline.} =
  ## Shifts the field rightward.
  mSelf = mSelf.shiftedRight

func shiftLeft*[F: TsuField or WaterField](mSelf: var F) {.inline.} =
  ## Shifts the field leftward.
  mSelf = mSelf.shiftedLeft

# ------------------------------------------------
# Flip
# ------------------------------------------------

func flipV*[F: TsuField or WaterField](mSelf: var F) {.inline.} =
  ## Flips the field vertically.
  mSelf = mSelf.flippedV

func flipH*[F: TsuField or WaterField](mSelf: var F) {.inline.} =
  ## Flips the field horizontally.
  mSelf = mSelf.flippedH

# ------------------------------------------------
# Move
# ------------------------------------------------

func move*[F: TsuField or WaterField](mSelf: var F, pair: Pair, pos: Position):
    MoveResult {.inline, discardable.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  result.chainCount = 0

  mSelf.put pair, pos

  while true:
    if mSelf.disappear.notDisappeared:
      return

    mSelf.drop

    result.chainCount.inc

func moveWithRoughTracking*[F: TsuField or WaterField](
  mSelf: var F, pair: Pair, pos: Position): RoughMoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  result.chainCount = 0
  result.totalDisappearCounts = [0, 0, 0, 0, 0, 0, 0]

  mSelf.put pair, pos

  while true:
    let disappearResult = mSelf.disappear
    if disappearResult.notDisappeared:
      return

    mSelf.drop

    result.chainCount.inc
    for puyo in Puyo:
      result.totalDisappearCounts[puyo].inc disappearResult.puyoCount puyo

func moveWithDetailTracking*[F: TsuField or WaterField](
  mSelf: var F, pair: Pair, pos: Position): DetailMoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  result.chainCount = 0
  result.totalDisappearCounts = [0, 0, 0, 0, 0, 0, 0]
  result.disappearCounts = @[]

  mSelf.put pair, pos

  while true:
    let disappearResult = mSelf.disappear
    if disappearResult.notDisappeared:
      return 

    mSelf.drop

    result.chainCount.inc

    var counts: array[Puyo, Natural]
    counts[Puyo.low] = Natural.low # dummy to remove warning
    for puyo in Puyo.low..Puyo.high:
      let count = disappearResult.puyoCount puyo
      counts[puyo] = count
      result.totalDisappearCounts[puyo].inc count
    result.disappearCounts.add counts

func moveWithFullTracking*[F: TsuField or WaterField](
  mSelf: var F, pair: Pair, pos: Position): FullMoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  ## - Number of color puyos in each connected component that disappeared
  ## in each chain
  result.chainCount = 0
  result.totalDisappearCounts = [0, 0, 0, 0, 0, 0, 0]
  result.disappearCounts = @[]
  result.detailDisappearCounts = @[]

  mSelf.put pair, pos

  while true:
    let disappearResult = mSelf.disappear
    if disappearResult.notDisappeared:
      return 

    mSelf.drop

    result.chainCount.inc

    var counts: array[Puyo, Natural]
    counts[Puyo.low] = Natural.low # dummy to remove warning
    for puyo in Puyo.low..Puyo.high:
      let count = disappearResult.puyoCount puyo
      counts[puyo] = count
      result.totalDisappearCounts[puyo].inc count
    result.disappearCounts.add counts
    result.detailDisappearCounts.add disappearResult.connectionCounts

# ------------------------------------------------
# Field <-> array
# ------------------------------------------------

func parseTsuField*(arr: array[Row, array[Column, Cell]]): TsuField {.inline.} =
  ## Converts the array to the Tsu field.
  parseField[TsuField] arr

func parseWaterField*(arr: array[Row, array[Column, Cell]]): WaterField
                     {.inline.} =
  ## Converts the array to the Water field.
  parseField[WaterField] arr

# ------------------------------------------------
# Field <-> string
# ------------------------------------------------

func `$`*(self: TsuField): string {.inline.} =
  # NOTE: using generics for `$` raises error
  let
    arr = self.toArray
    lines = collect:
      for row in Row.low..Row.high:
        join arr[row].mapIt $it

  result = lines.join "\n"

func `$`*(self: WaterField): string {.inline.} =
  # NOTE: using generics for `$` raises error
  let
    arr = self.toArray
    lines = collect:
      for row in Row.low..Row.high:
        join arr[row].mapIt $it

  result = lines.join "\n"

func parseField*[F: TsuField or WaterField](str: string): F {.inline.} =
  ## Converts the string representation to the field.
  ## If `str` is not a valid representation, `ValueError` is raised.
  let lines = str.split '\n'
  if lines.len != Height or lines.anyIt it.len != Width: 
    raise newException(ValueError, "Invalid field: " & str)

  var arr: array[Row, array[Column, Cell]]
  arr[Row.low][Column.low] = Cell.low # dummy to remove warning
  for row in Row.low..Row.high:
    for col in Column.low..Column.high:
      arr[row][col] = ($lines[row][col]).parseCell

  result = parseField[F] arr

func parseTsuField*(str: string): TsuField {.inline.} = parseField[TsuField] str
  ## Converts the string representation to the Tsu field.
  ## If `str` is not a valid representation, `ValueError` is raised.

func parseWaterField*(str: string): WaterField {.inline.} =
  ## Converts the string representation to the Water field.
  ## If `str` is not a valid representation, `ValueError` is raised.
  parseField[WaterField] str

# ------------------------------------------------
# Field <-> URI
# ------------------------------------------------

const
  IzumiyaUriRuleFieldSep = "-"
  IzumiyaUriAirWaterSep = "~"

  IzumiyaUriToRule = collect:
    for rule in Rule:
      {$rule: rule}

  IshikawaUriChars =
    "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-"
  IshikawaUriCharToIdx = collect:
    for i, c in IshikawaUriChars:
      {c: i}
  CellToIshikawaIdx: array[Cell, int] = [0, -1, 6, 1, 2, 3, 4, 5]
  IshikawaIdxToCell = collect:
    for cell, idx in CellToIshikawaIdx:
      {idx: cell}

func toUriQuery*[F: TsuField or WaterField](self: F, host: SimulatorHost):
    string {.inline.} =
  ## Converts the field to the URI query.
  let arr = self.toArray

  case host
  of Izumiya:
    let cellsStr = case self.rule
    of Tsu:
      let cellChars = collect:
        for line in arr:
          for cell in line:
            $cell

      cellChars.join.strip(trailing = false, chars = {($None)[0]})
    of Water:
      let
        underWaterChars = collect:
          for row in WaterRow.low..WaterRow.high:
            for cell in arr[row]:
              $cell
        airChars = collect:
          for row in Row.low..WaterRow.low.pred:
            for cell in arr[row]:
              $cell

      airChars.join.strip(trailing = false, chars = {($None)[0]}) &
      IzumiyaUriAirWaterSep &
      underWaterChars.join.strip(leading = false, chars = {($None)[0]})

    result = $self.rule & IzumiyaUriRuleFieldSep & cellsStr
  of Ishikawa, Ips:
    var lines = newSeqOfCap[string] Height
    for row in Row.low..Row.high:
      var chars = newSeqOfCap[char] Height div 2
      for i in 0 ..< Width div 2:
        let
          col = Column 2 * i
          cell1 = arr[row][col]
          cell2 = arr[row][col.succ]

        chars.add IshikawaUriChars[
          CellToIshikawaIdx[cell1] * Cell.fullSet.card +
          CellToIshikawaIdx[cell2]]

      lines.add chars.join

    result = lines.join.strip(trailing = false, chars = {'0'})

func parseField*[F: TsuField or WaterField](
    query: string, host: SimulatorHost): F {.inline.} =
  ## Converts the URI query to the field.
  ## If `query` is not a valid URI, `ValueError` is raised.
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
      for row in Row.low..Row.high:
        for col in Column.low..Column.high:
          arr[row][col] = parseCell $cellsStr[row * Width + col]
    of Water:
      let cellsStrs = strs[1].split IzumiyaUriAirWaterSep
      if cellsStrs.len != 2 or cellsStrs[0].len > AirHeight * Width or
          cellsStrs[1].len > WaterHeight * Width:
        raise newException(ValueError, "Invalid field: " & query)

      let airCellsStr =
        ($None).repeat(AirHeight * Width - cellsStrs[0].len) & cellsStrs[0]
      for row in AirRow.low..AirRow.high:
        for col in Column.low..Column.high:
          arr[row][col] = parseCell $airCellsStr[row * Width + col]

      let waterCellsStr =
        cellsStrs[1] & ($None).repeat(WaterHeight * Width - cellsStrs[1].len)
      for row in WaterRow.low..WaterRow.high:
        for col in Column.low..Column.high:
          arr[row][col] =
            parseCell $waterCellsStr[(row - WaterRow.low) * Width + col]
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

  result = parseField[F] arr

func parseTsuField*(query: string, host: SimulatorHost): TsuField {.inline.} =
  ## Converts the URI query to the Tsu field.
  ## If `query` is not a valid URI, `ValueError` is raised.
  parseField[TsuField](query, host)

func parseWaterField*(query: string, host: SimulatorHost): WaterField {.inline.} =
  ## Converts the URI query to the Water field.
  ## If `query` is not a valid URI, `ValueError` is raised.
  parseField[WaterField](query, host)

func parseFields*(query: string, host: SimulatorHost): Fields {.inline.} =
  ## Converts the URI query to the fields.
  ## If `query` is not a valid URI, `ValueError` is raised.
  try:
    result.tsu = query.parseTsuField host
    result.rule = Tsu
  except ValueError:
    result.water = query.parseWaterField host
    result.rule = Water
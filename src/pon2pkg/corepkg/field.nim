## This module implements fields.
## The following implementations are supported:
## - Bitboard with AVX2
## - Bitboard with primitive types
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, setutils, strutils, sugar, tables]
import ./[cell, fieldtype, misc, moveresult, pair, position, rule]
import ../private/[intrinsic]
import ../private/core/field/[binary]

when UseAvx2:
  import ../private/core/field/avx2/[disappearresult, main]
  export main.`==`
else:
  import ../private/core/field/primitive/[disappearresult, main]

export UseAvx2, main.TsuField, main.WaterField, main.zeroField,
  main.zeroTsuField, main.zeroWaterField, main.toTsuField,
  main.toWaterField, main.`[]`, main.`[]=`, main.insert, main.removeSqueeze,
  main.puyoCount, main.colorCount, main.garbageCount, main.connect3,
  main.connect3V, main.connect3H, main.connect3L, main.shiftedUp,
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

func isDead*(self: TsuField or WaterField): bool {.inline.} =
  ## Returns `true` if the field is in a defeated state.
  self.exist.isDead self.rule

# ------------------------------------------------
# Flatten
# ------------------------------------------------

template flattenAnd*(fields: Fields, body: untyped): untyped =
  ## Runs `body` with `field` exposed.
  case fields.rule
  of Tsu:
    let field {.inject.} = fields.tsu
    body
  of Water:
    let field {.inject.} = fields.water
    body

# ------------------------------------------------
# Count - None
# ------------------------------------------------

func noneCount*(self: TsuField or WaterField): int {.inline.} =
  ## Returns the number of `None` in the field.
  Height * Width - self.puyoCount

# ------------------------------------------------
# Position
# ------------------------------------------------

func invalidPositions*(self: TsuField or WaterField): set[Position] {.inline.} =
  ## Returns the invalid positions.
  self.exist.invalidPositions

func validPositions*(self: TsuField or WaterField): set[Position] {.inline.} =
  ## Returns the valid positions.
  self.exist.validPositions

func validDoublePositions*(self: TsuField or WaterField): set[Position]
                          {.inline.} =
  ## Returns the valid positions for a double pair.
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
# Move
# ------------------------------------------------

func move*(mSelf: var (TsuField or WaterField), pair: Pair, pos: Position):
    MoveResult {.inline, discardable.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  var chainCount = 0

  mSelf.put pair, pos

  while true:
    if mSelf.disappear.notDisappeared:
      return initMoveResult(chainCount)

    mSelf.drop

    chainCount.inc

  result = 0.initMoveResult # HACK: dummy to remove warning

func moveWithRoughTracking*(
    mSelf: var (TsuField or WaterField), pair: Pair, pos: Position): MoveResult
    {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  var
    chainCount = 0
    totalDisappearCounts: array[Puyo, int] = [0, 0, 0, 0, 0, 0, 0]

  mSelf.put pair, pos

  while true:
    let disappearResult = mSelf.disappear
    if disappearResult.notDisappeared:
      return initMoveResult(chainCount, totalDisappearCounts)

    mSelf.drop

    chainCount.inc
    for puyo in Puyo:
      totalDisappearCounts[puyo].inc disappearResult.puyoCount puyo

  result = 0.initMoveResult # HACK: dummy to remove warning

func moveWithDetailTracking*(
    mSelf: var (TsuField or WaterField), pair: Pair, pos: Position): MoveResult
    {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  var
    chainCount = 0
    totalDisappearCounts: array[Puyo, int] = [0, 0, 0, 0, 0, 0, 0]
    disappearCounts: seq[array[Puyo, int]] = @[]

  mSelf.put pair, pos

  while true:
    let disappearResult = mSelf.disappear
    if disappearResult.notDisappeared:
      return initMoveResult(chainCount, totalDisappearCounts, disappearCounts)

    mSelf.drop

    chainCount.inc

    var counts: array[Puyo, int]
    counts[Puyo.low] = Natural.low # dummy to remove warning
    for puyo in Puyo.low..Puyo.high:
      let count = disappearResult.puyoCount puyo
      counts[puyo] = count
      totalDisappearCounts[puyo].inc count
    disappearCounts.add counts

  result = 0.initMoveResult # HACK: dummy to remove warning

func moveWithFullTracking*(
    mSelf: var (TsuField or WaterField), pair: Pair, pos: Position): MoveResult
    {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  ## - Number of color puyos in each connected component that disappeared \
  ## in each chain
  var
    chainCount = 0
    totalDisappearCounts: array[Puyo, int] = [0, 0, 0, 0, 0, 0, 0]
    disappearCounts: seq[array[Puyo, int]] = @[]
    detailDisappearCounts: seq[array[ColorPuyo, seq[int]]] = @[]

  mSelf.put pair, pos

  while true:
    let disappearResult = mSelf.disappear
    if disappearResult.notDisappeared:
      return initMoveResult(chainCount, totalDisappearCounts, disappearCounts,
                            detailDisappearCounts)

    mSelf.drop

    chainCount.inc

    var counts: array[Puyo, int]
    counts[Puyo.low] = Natural.low # dummy to remove warning
    for puyo in Puyo.low..Puyo.high:
      let count = disappearResult.puyoCount puyo
      counts[puyo] = count
      totalDisappearCounts[puyo].inc count
    disappearCounts.add counts
    detailDisappearCounts.add disappearResult.connectionCounts

  result = 0.initMoveResult # HACK: dummy to remove warning

# ------------------------------------------------
# Field <-> array
# ------------------------------------------------

func parseTsuField*(arr: array[Row, array[Column, Cell]]): TsuField {.inline.} =
  ## Converts the array to the Tsu field.
  arr.parseField[:TsuField]

func parseWaterField*(arr: array[Row, array[Column, Cell]]): WaterField
                     {.inline.} =
  ## Converts the array to the Water field.
  arr.parseField[:WaterField]

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

  result = arr.parseField[:F]

func parseTsuField*(str: string): TsuField {.inline.} =
  ## Converts the string representation to the Tsu field.
  ## If `str` is not a valid representation, `ValueError` is raised.
  str.parseField[:TsuField]

func parseWaterField*(str: string): WaterField {.inline.} =
  ## Converts the string representation to the Water field.
  ## If `str` is not a valid representation, `ValueError` is raised.
  str.parseField[:WaterField]

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

func toUriQuery*(self: TsuField or WaterField, host: SimulatorHost):
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
    var lines = newSeqOfCap[string](Height)
    for row in Row.low..Row.high:
      var chars = newSeqOfCap[char](Height div 2)
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

  result = arr.parseField[:F]

func parseTsuField*(query: string, host: SimulatorHost): TsuField {.inline.} =
  ## Converts the URI query to the Tsu field.
  ## If `query` is not a valid URI, `ValueError` is raised.
  query.parseField[:TsuField](host)

func parseWaterField*(query: string, host: SimulatorHost): WaterField {.inline.} =
  ## Converts the URI query to the Water field.
  ## If `query` is not a valid URI, `ValueError` is raised.
  query.parseField[:WaterField](host)

func parseFields*(query: string, host: SimulatorHost): Fields {.inline.} =
  ## Converts the URI query to the fields.
  ## If `query` is not a valid URI, `ValueError` is raised.
  try:
    result.tsu = query.parseTsuField host
    result.rule = Tsu
  except ValueError:
    result.water = query.parseWaterField host
    result.rule = Water

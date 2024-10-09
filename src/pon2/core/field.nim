## This module implements fields.
## The following implementations are supported:
## - Bitboard with AVX2
## - Bitboard with primitive types
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, setutils, strutils, sugar, tables]
import ./[cell, fieldtype, fqdn, moveresult, pair, pairposition, position, rule]
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
  main.colorCount, main.garbageCount, main.connect2, main.connect2V, main.connect2H,
  main.connect3, main.connect3V, main.connect3H, main.connect3L, main.shiftedUp,
  main.shiftedDown, main.shiftedRight, main.shiftedLeft, main.flippedV, main.flippedH,
  main.disappear, main.willDisappear, main.put, main.drop, main.toArray, main.parseField

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `==`*(field1: TsuField, field2: WaterField): bool {.inline.} =
  false

func `==`*(field1: WaterField, field2: TsuField): bool {.inline.} =
  false

# ------------------------------------------------
# Convert
# ------------------------------------------------

func toTsuField*(self: TsuField): TsuField {.inline.} =
  ## Returns the Tsu field converted from the given field.
  self

func toWaterField*(self: WaterField): WaterField {.inline.} =
  ## Returns the Water field converted from the given field.
  self

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

func shiftUp*(self: var (TsuField or WaterField)) {.inline.} =
  ## Shifts the field upward.
  self = self.shiftedUp

func shiftDown*(self: var (TsuField or WaterField)) {.inline.} =
  ## Shifts the field downward.
  self = self.shiftedDown

func shiftRight*(self: var (TsuField or WaterField)) {.inline.} =
  ## Shifts the field rightward.
  self = self.shiftedRight

func shiftLeft*(self: var (TsuField or WaterField)) {.inline.} =
  ## Shifts the field leftward.
  self = self.shiftedLeft

# ------------------------------------------------
# Flip
# ------------------------------------------------

func flipV*(self: var (TsuField or WaterField)) {.inline.} =
  ## Flips the field vertically.
  self = self.flippedV

func flipH*(self: var (TsuField or WaterField)) {.inline.} =
  ## Flips the field horizontally.
  self = self.flippedH

# ------------------------------------------------
# Operate
# ------------------------------------------------

func put*(self: var (TsuField or WaterField), pairPos: PairPosition) {.inline.} =
  ## Puts the pair.
  self.put pairPos.pair, pairPos.position

func willDrop*(self: TsuField or WaterField): bool {.inline.} =
  ## Returns `true` if the field will drop.
  ## Note that this function calls `drop` internally.
  var field = self
  field.drop

  result = field != self

# ------------------------------------------------
# Move - Level0
# ------------------------------------------------

func move*(
    self: var (TsuField or WaterField), pair: Pair, pos: Position
): MoveResult {.inline, discardable.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  var
    chainCount = 0
    disappearCounts: array[Puyo, int] = [0, 0, 0, 0, 0, 0, 0]

  self.put pair, pos

  while true:
    let disappearResult = self.disappear
    if disappearResult.notDisappeared:
      return initMoveResult(chainCount, disappearCounts)

    self.drop

    chainCount.inc
    for puyo in Puyo:
      disappearCounts[puyo].inc disappearResult.puyoCount puyo

  result = initMoveResult(0, [0, 0, 0, 0, 0, 0, 0]) # HACK: dummy to suppress warning

func move*(
    self: var (TsuField or WaterField), pairPos: PairPosition
): MoveResult {.inline, discardable.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  self.move(pairPos.pair, pairPos.position)

func move0*(
    self: var (TsuField or WaterField), pair: Pair, pos: Position
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  self.move(pair, pos)

func move0*(
    self: var (TsuField or WaterField), pairPos: PairPosition
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  self.move pairPos

# ------------------------------------------------
# Move - Level1
# ------------------------------------------------

func move1*(
    self: var (TsuField or WaterField), pair: Pair, pos: Position
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  var
    chainCount = 0
    disappearCounts: array[Puyo, int] = [0, 0, 0, 0, 0, 0, 0]
    detailDisappearCounts = newSeq[array[Puyo, int]](0)

  self.put pair, pos

  while true:
    let disappearResult = self.disappear
    if disappearResult.notDisappeared:
      return initMoveResult(chainCount, disappearCounts, detailDisappearCounts)

    self.drop

    chainCount.inc

    var counts: array[Puyo, int]
    counts[Puyo.low] = int.low # HACK: dummy to suppress warning
    for puyo in Puyo.low .. Puyo.high:
      let count = disappearResult.puyoCount puyo
      counts[puyo] = count
      disappearCounts[puyo].inc count
    detailDisappearCounts.add counts

  result = initMoveResult(0, [0, 0, 0, 0, 0, 0, 0]) # HACK: dummy to suppress warning

func move1*(
    self: var (TsuField or WaterField), pairPos: PairPosition
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  self.move1(pairPos.pair, pairPos.position)

# ------------------------------------------------
# Move - Level2
# ------------------------------------------------

func move2*(
    self: var (TsuField or WaterField), pair: Pair, pos: Position
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
    detailDisappearCounts = newSeq[array[Puyo, int]](0)
    fullDisappearCounts = newSeq[array[ColorPuyo, seq[int]]](0)

  self.put pair, pos

  while true:
    let disappearResult = self.disappear
    if disappearResult.notDisappeared:
      return initMoveResult(
        chainCount, disappearCounts, detailDisappearCounts, fullDisappearCounts
      )

    self.drop

    chainCount.inc

    var counts: array[Puyo, int]
    counts[Puyo.low] = int.low # HACK: dummy to suppress warning
    for puyo in Puyo.low .. Puyo.high:
      let count = disappearResult.puyoCount puyo
      counts[puyo] = count
      disappearCounts[puyo].inc count
    detailDisappearCounts.add counts
    fullDisappearCounts.add disappearResult.connectionCounts

  result = initMoveResult(0, [0, 0, 0, 0, 0, 0, 0]) # HACK: dummy to suppress warning

func move2*(
    self: var (TsuField or WaterField), pairPos: PairPosition
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  ## This function tracks:
  ## - Number of chains
  ## - Number of puyos that disappeared
  ## - Number of puyos that disappeared in each chain
  ## - Number of color puyos in each connected component that disappeared in each chain
  self.move2(pairPos.pair, pairPos.position)

# ------------------------------------------------
# Field <-> string
# ------------------------------------------------

func `$`*(self: TsuField or WaterField): string {.inline.} =
  # NOTE: using explicit generics for `$` does not work
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
  arr[Row.low][Column.low] = Cell.low # HACK: dummy to suppress warning
  for row in Row.low .. Row.high:
    for col in Column.low .. Column.high:
      arr[row][col] = ($lines[row][col]).parseCell

  result = parseField[F](arr)

# ------------------------------------------------
# Field <-> URI
# ------------------------------------------------

const
  Pon2UriRuleFieldSep = "-"
  Pon2UriAirWaterSep = "~"

  Pon2UriToRule = collect:
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

func toUriQuery*(self: TsuField or WaterField, fqdn = Pon2): string {.inline.} =
  ## Returns the URI query converted from the field.
  let arr = self.toArray

  case fqdn
  of Pon2:
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

        airChars.join.strip(trailing = false, chars = {($None)[0]}) & Pon2UriAirWaterSep &
          underWaterChars.join.strip(leading = false, chars = {($None)[0]})

    result = $self.rule & Pon2UriRuleFieldSep & cellsStr
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
    query: string, fqdn: IdeFqdn
): F {.inline.} =
  ## Returns the field converted from the query.
  ## If the query is invalid, `ValueError` is raised.
  var arr: array[Row, array[Column, Cell]]
  arr[Row.low][Column.low] = Cell.low # HAKC: dummy to suppress warning

  case fqdn
  of Pon2:
    let strs = query.split Pon2UriRuleFieldSep
    if strs.len != 2 or strs[0] notin Pon2UriToRule:
      raise newException(ValueError, "Invalid field: " & query)

    if strs[0] notin Pon2UriToRule:
      raise newException(ValueError, "Invalid field: " & query)
    let rule = Pon2UriToRule[strs[0]]

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
      let cellsStrs = strs[1].split Pon2UriAirWaterSep
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

## This module implements fields.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[bitops, sequtils, strformat, sugar, typetraits]
import ./[cell, common, fqdn, moveresult, pair, placement, popresult, rule]
import
  ../private/
    [arrayops2, assign3, macros2, math2, results2, staticfor2, strutils2, tables2]
import ../private/core/[binfield]

type
  TsuField* = object ## Puyo Puyo field for Tsu rule.
    bit2: BinField
    bit1: BinField
    bit0: BinField

  WaterField* = object ## Puyo Puyo field for Water rule.
    bit2: BinField
    bit1: BinField
    bit0: BinField

# ------------------------------------------------
# Macro
# ------------------------------------------------

macro expand(identsAndBody: varargs[untyped]): untyped =
  ## Runs the body (the last argument) three times with specified identifiers
  ## (the rest arguments) replaced by `{ident}2`, `{ident}1`, and `{ident}0`.
  ## Underscore in the body is replaced by the integer literal 2, 1, and 0.
  let
    body = identsAndBody[^1]
    idents = identsAndBody[0 ..^ 2]
    stmts = nnkStmtList.newNimNode body

  var body2 = body.replaced("_".ident, 2.newLit)
  for id in idents:
    body2 = body2.replaced(id, (id.strVal & '2').ident)
  stmts.add body2

  var body1 = body.replaced("_".ident, 1.newLit)
  for id in idents:
    body1 = body1.replaced(id, (id.strVal & '1').ident)
  stmts.add body1

  var body0 = body.replaced("_".ident, 0.newLit)
  for id in idents:
    body0 = body0.replaced(id, (id.strVal & '0').ident)
  stmts.add body0

  stmts

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init[F: TsuField or WaterField](
    T: type F, bit2, bit1, bit0: BinField
): F {.inline.} =
  F(bit2: bit2, bit1: bit1, bit0: bit0)

func init*[F: TsuField or WaterField](T: type F): F {.inline.} =
  T.init(BinField.init, BinField.init, BinField.init)

# ------------------------------------------------
# Convert
# ------------------------------------------------

func toTsuField*(self: TsuField): TsuField {.inline.} =
  ## Returns the copy of the field.
  self

func toTsuField*(self: WaterField): TsuField {.inline.} =
  ## Returns the Tsu field converted from the field.
  TsuField.init(self.bit2, self.bit1, self.bit0)

func toWaterField*(self: TsuField): WaterField {.inline.} =
  ## Returns the Water field converted from the field.
  WaterField.init(self.bit2, self.bit1, self.bit0)

func toWaterField*(self: WaterField): WaterField {.inline.} =
  ## Returns the copy of the field.
  self

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `*`[F: TsuField or WaterField](self: F, binField: BinField): F {.inline.} =
  F.init(self.bit2 * binField, self.bit1 * binField, self.bit0 * binField)

# ------------------------------------------------
# Property
# ------------------------------------------------

func rule*(self: TsuField): Rule {.inline.} =
  ## Returns the rule.
  Tsu

func rule*(self: WaterField): Rule {.inline.} =
  ## Returns the rule.
  Water

func exist[F: TsuField or WaterField](self: F): BinField {.inline.} =
  ## Returns the binary field where puyos exist.
  sum(self.bit2, self.bit1, self.bit0)

func isDead*[F: TsuField or WaterField](self: F): bool {.inline.} =
  ## Returns `true` if the field is in a defeated state.
  const FieldRule = when F is TsuField: Tsu else: Water

  self.exist.isDead FieldRule

# ------------------------------------------------
# Placement
# ------------------------------------------------

func invalidPlacements*[F: TsuField or WaterField](self: F): set[Placement] {.inline.} =
  ## Returns the invalid placements.
  self.exist.invalidPlacements

func validPlacements*[F: TsuField or WaterField](self: F): set[Placement] {.inline.} =
  ## Returns the valid placements.
  self.exist.validPlacements

func validDblPlacements*[F: TsuField or WaterField](
    self: F
): set[Placement] {.inline.} =
  ## Returns the valid placements for double pairs.
  self.exist.validDblPlacements

# ------------------------------------------------
# Indexer
# ------------------------------------------------

func toCell(bit2, bit1, bit0: bool): Cell {.inline.} =
  ## Returns the cell converted from the bits.
  (bit2.int shl 2 + (bit1.int shl 1 + bit0.int)).Cell

func `[]`*[F: TsuField or WaterField](self: F, row: Row, col: Col): Cell {.inline.} =
  toCell(self.bit2[row, col], self.bit1[row, col], self.bit0[row, col])

template withBits(cell: Cell, body: untyped): untyped =
  ## Runs `body` with `bit2`, `bit1`, and `bit0` exposed.
  block:
    let c = cell.ord

    expand bit:
      let bit {.inject.} = c.testBit _

    body

func `[]=`*[F: TsuField or WaterField](
    self: var F, row: Row, col: Col, cell: Cell
) {.inline.} =
  cell.withBits:
    expand bit:
      self.bit[row, col] = bit

# ------------------------------------------------
# Insert / Delete
# ------------------------------------------------

func insert*[F: TsuField or WaterField](
    self: var F, row: Row, col: Col, cell: Cell
) {.inline.} =
  ## Inserts the cell and shifts the field.
  ## If (row, col) is in the air, shifts the field upward above where inserted.
  ## If it is in the water, shifts the field downward below where inserted.
  const FieldRule = when F is TsuField: Tsu else: Water

  cell.withBits:
    expand bit:
      self.bit.insert row, col, bit, FieldRule

func delete*[F: TsuField or WaterField](self: var F, row: Row, col: Col) {.inline.} =
  ## Deletes the cell and shifts the field.
  ## If (row, col) is in the air, shifts the field downward above where deleted.
  ## If it is in the water, shifts the field upward below where deleted.
  const FieldRule = when F is TsuField: Tsu else: Water

  expand bit:
    self.bit.delete row, col, FieldRule

# ------------------------------------------------
# Puyo Extract
# ------------------------------------------------

func hard[F: TsuField or WaterField](self: F): BinField {.inline.} =
  ## Returns the binary field where hard puyos exist.
  self.bit0 - (self.bit2 + self.bit1)

func garbage[F: TsuField or WaterField](self: F): BinField {.inline.} =
  ## Returns the binary field where garbage puyos exist.
  self.bit1 - (self.bit2 + self.bit0)

func red[F: TsuField or WaterField](self: F): BinField {.inline.} =
  ## Returns the binary field where red puyos exist.
  self.bit1 * self.bit0 - self.bit2

func green[F: TsuField or WaterField](self: F): BinField {.inline.} =
  ## Returns the binary field where green puyos exist.
  self.bit2 - (self.bit1 + self.bit0)

func blue[F: TsuField or WaterField](self: F): BinField {.inline.} =
  ## Returns the binary field where blue puyos exist.
  self.bit2 * self.bit0 - self.bit1

func yellow[F: TsuField or WaterField](self: F): BinField {.inline.} =
  ## Returns the binary field where yellow puyos exist.
  self.bit2 * self.bit1 - self.bit0

func purple[F: TsuField or WaterField](self: F): BinField {.inline.} =
  ## Returns the binary field where purple puyos exist.
  prod(self.bit2, self.bit1, self.bit0)

# ------------------------------------------------
# Count
# ------------------------------------------------

func cellCnt*[F: TsuField or WaterField](self: F, cell: Cell): int {.inline.} =
  ## Returns the number of `cell` in the field.
  case cell
  of None:
    Height * Width - sum(self.bit2, self.bit1, self.bit0).popcnt
  of Hard:
    self.hard.popcnt
  of Garbage:
    self.garbage.popcnt
  of Red:
    self.red.popcnt
  of Green:
    self.green.popcnt
  of Blue:
    self.blue.popcnt
  of Yellow:
    self.yellow.popcnt
  of Purple:
    self.purple.popcnt

func puyoCnt*[F: TsuField or WaterField](self: F): int {.inline.} =
  ## Returns the number of puyos in the field.
  self.exist.popcnt

func colorPuyoCnt*[F: TsuField or WaterField](self: F): int {.inline.} =
  ## Returns the number of color puyos in the field.
  (self.bit2 + self.red).popcnt

func garbagesCnt*[F: TsuField or WaterField](self: F): int {.inline.} =
  ## Returns the number of hard and garbage puyos in the field.
  (self.bit0 xor self.bit1 - self.bit2).popcnt

# ------------------------------------------------
# Connect - 2
# ------------------------------------------------

func conn2*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field where exactly two color puyos are connected.
  self *
    sum(
      self.red.conn2, self.green.conn2, self.blue.conn2, self.yellow.conn2,
      self.purple.conn2,
    )

func conn2Vertical*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field where exactly two color puyos are connected vertically.
  self *
    sum(
      self.red.conn2Vertical, self.green.conn2Vertical, self.blue.conn2Vertical,
      self.yellow.conn2Vertical, self.purple.conn2Vertical,
    )

func conn2Horizontal*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field where exactly two color puyos are connected horizontally.
  self *
    sum(
      self.red.conn2Horizontal, self.green.conn2Horizontal, self.blue.conn2Horizontal,
      self.yellow.conn2Horizontal, self.purple.conn2Horizontal,
    )

# ------------------------------------------------
# Connect - 3
# ------------------------------------------------

func conn3*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field where exactly three color puyos are connected.
  self *
    sum(
      self.red.conn3, self.green.conn3, self.blue.conn3, self.yellow.conn3,
      self.purple.conn3,
    )

func conn3Vertical*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field where exactly three color puyos are connected vertically.
  self *
    sum(
      self.red.conn3Vertical, self.green.conn3Vertical, self.blue.conn3Vertical,
      self.yellow.conn3Vertical, self.purple.conn3Vertical,
    )

func conn3Horizontal*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field where exactly three color puyos are connected horizontally.
  self *
    sum(
      self.red.conn3Horizontal, self.green.conn3Horizontal, self.blue.conn3Horizontal,
      self.yellow.conn3Horizontal, self.purple.conn3Horizontal,
    )

func conn3LShape*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field where exactly three color puyos are connected by L-shape.
  self *
    sum(
      self.red.conn3LShape, self.green.conn3LShape, self.blue.conn3LShape,
      self.yellow.conn3LShape, self.purple.conn3LShape,
    )

# ------------------------------------------------
# Shift
# ------------------------------------------------

func shiftUp*[F: TsuField or WaterField](self: var F) {.inline.} =
  ## Shifts the field upward.
  expand bit:
    self.bit.shiftUp

func shiftDown*[F: TsuField or WaterField](self: var F) {.inline.} =
  ## Shifts the field downward.
  expand bit:
    self.bit.shiftDown

func shiftRight*[F: TsuField or WaterField](self: var F) {.inline.} =
  ## Shifts the field rightward.
  expand bit:
    self.bit.shiftRight

func shiftLeft*[F: TsuField or WaterField](self: var F) {.inline.} =
  ## Shifts the field leftward.
  expand bit:
    self.bit.shiftLeft

# ------------------------------------------------
# Flip
# ------------------------------------------------

func flipVertical*[F: TsuField or WaterField](self: var F) {.inline.} =
  ## Flips the field vertically.
  expand bit:
    self.bit.flipVertical

func flipHorizontal*[F: TsuField or WaterField](self: var F) {.inline.} =
  ## Flips the field horizontally.
  expand bit:
    self.bit.flipHorizontal

# ------------------------------------------------
# Pop
# ------------------------------------------------

func pop*[F: TsuField or WaterField](self: var F): PopResult {.inline.} =
  ## Removes puyos that should pop.
  let
    poppedR = self.red.extractedPop
    poppedG = self.green.extractedPop
    poppedB = self.blue.extractedPop
    poppedY = self.yellow.extractedPop
    poppedP = self.purple.extractedPop
    poppedColor = sum(poppedR, poppedG, poppedB, poppedY, poppedP)

    colorU = poppedColor.shiftedUpRaw
    colorD = poppedColor.shiftedDownRaw
    colorR = poppedColor.shiftedRightRaw
    colorL = poppedColor.shiftedLeftRaw

    colorUorD = colorU + colorD
    colorRorL = colorR + colorL
    onlyU = colorU - (colorD + colorRorL)
    onlyD = colorD - (colorU + colorRorL)
    onlyR = colorR - (colorL + colorUorD)
    onlyL = colorL - (colorR + colorUorD)

    touch1 = sum(onlyU, onlyD, onlyR, onlyL)
    touch1More = sum(colorU, colorD, colorR, colorL)
    touch2More = touch1More - touch1

    visibleHard = self.hard.keptVisible
    hardToGarbage = visibleHard * touch1
    poppedHard = visibleHard * touch2More

    poppedGarbage = self.garbage.keptVisible * touch1More

    popped = poppedColor + poppedHard + poppedGarbage

  self.bit2 -= popped
  self.bit1.assign self.bit1 - popped + hardToGarbage
  self.bit0 -= popped + hardToGarbage

  PopResult.init(
    poppedR, poppedG, poppedB, poppedY, poppedP, poppedHard, hardToGarbage,
    poppedGarbage, poppedColor,
  )

func willPop*[F: TsuField or WaterField](self: F): bool {.inline.} =
  ## Returns `true` if any puyos will pop.
  self.red.willPop or self.green.willPop or self.blue.willPop or self.yellow.willPop or
    self.purple.willPop

# ------------------------------------------------
# Put
# ------------------------------------------------

template withFills(cell: Cell, body: untyped): untyped =
  ## Runs `body` with `fill2`, `fill1`, and `fill0` exposed.
  block:
    let c = cell.ord

    expand fill:
      let fill {.inject.} = if c.testBit _: BinField.initOne else: BinField.init

    body

func put*(self: var TsuField, pair: Pair, plcmt: Placement) {.inline.} =
  ## Puts the pair.
  let
    existField = self.exist
    nextPutMask = existField xor (existField + BinField.initFloor).shiftedUp
    pivotMask = (if plcmt in Down0 .. Down5: nextPutMask.shiftedUp else: nextPutMask).kept plcmt.pivotCol
    rotorMask = (if plcmt in Up0 .. Up5: nextPutMask.shiftedUp else: nextPutMask).kept plcmt.rotorCol

  let pivot2, pivot1, pivot0: BinField
  pair.pivot.withFills:
    expand pivot, fill:
      pivot = fill * pivotMask

  let rotor2, rotor1, rotor0: BinField
  pair.rotor.withFills:
    expand rotor, fill:
      rotor = fill * rotorMask

  expand bit, pivot, rotor:
    self.bit += pivot + rotor

func put*(self: var WaterField, pair: Pair, plcmt: Placement) {.inline.} =
  ## Puts the pair.
  let
    pCol = plcmt.pivotCol
    rCol = plcmt.rotorCol

    existField = self.exist
    nextPutMask =
      (existField xor (existField + BinField.initUpperWater).shiftedUpRaw).keptAir
    pivotMask =
      (if plcmt in Down0 .. Down5: nextPutMask.shiftedUp else: nextPutMask).kept pCol
    rotorMask =
      (if plcmt in Up0 .. Up5: nextPutMask.shiftedUp else: nextPutMask).kept rCol

  let pivot2, pivot1, pivot0: BinField
  pair.pivot.withFills:
    expand pivot, fill:
      pivot = fill * pivotMask

  let rotor2, rotor1, rotor0: BinField
  pair.rotor.withFills:
    expand rotor, fill:
      rotor = fill * rotorMask

  expand bit, pivot, rotor:
    self.bit += pivot + rotor

  if not existField[Row.high, pCol]:
    expand bit:
      self.bit.replace pCol, self.bit.shiftedDownRaw

  if not self.exist[Row.high, rCol]:
    expand bit:
      self.bit.replace rCol, self.bit.shiftedDownRaw

# ------------------------------------------------
# Drop
# ------------------------------------------------

func drop*[F: TsuField or WaterField](self: var F) {.inline.} =
  ## Falling floating cells.
  const FieldRule = when F is TsuField: Tsu else: Water

  let dropMask = self.exist.toDropMask

  expand bit:
    self.bit.drop dropMask, FieldRule

func willDrop*[F: TsuField or WaterField](self: F): bool {.inline.} =
  ## Returns `true` if any cell will drop.
  self != self.dup(drop)

# ------------------------------------------------
# Move
# ------------------------------------------------

func move*[F: TsuField or WaterField](
    self: var F, pair: Pair, plcmt: Placement, calcConn: static bool
): MoveResult {.inline.} =
  ## Puts the pair and advance the field until chains end.
  const MaxChainCnt = Height * Width div 4

  var
    chainCnt = 0
    popCnts = initArrWith[Cell, int](0)
    hardToGarbageCnt = 0
    detailPopCnts = newSeqOfCap[array[Cell, int]](MaxChainCnt)
    detailHardToGarbageCnt = newSeqOfCap[int](MaxChainCnt)

  when calcConn:
    var fullPopCnts = newSeqOfCap[array[Cell, seq[int]]](MaxChainCnt)

  self.put pair, plcmt

  while true:
    let popRes = self.pop
    if not popRes.isPopped:
      when calcConn:
        return MoveResult.init(
          chainCnt, popCnts, hardToGarbageCnt, detailPopCnts, detailHardToGarbageCnt,
          fullPopCnts,
        )
      else:
        return MoveResult.init(
          chainCnt, popCnts, hardToGarbageCnt, detailPopCnts, detailHardToGarbageCnt
        )

    chainCnt.inc

    self.drop

    var cellCnts {.noinit.}: array[Cell, int]
    cellCnts[None].assign 0
    staticFor(cell2, Hard .. Purple):
      let cellCnt = popRes.cellCnt cell2
      cellCnts[cell2].assign cellCnt
      popCnts[cell2].inc cellCnt
    detailPopCnts.add cellCnts

    let h2g = popRes.hardToGarbageCnt
    hardToGarbageCnt.inc h2g
    detailHardToGarbageCnt.add h2g

    when calcConn:
      fullPopCnts.add popRes.connCnts

  # NOTE: dummy to suppress warning
  MoveResult.init(0, initArrWith[Cell, int](0), 0, @[], @[])

# ------------------------------------------------
# Field <-> array
# ------------------------------------------------

func toArr*[F: TsuField or WaterField](
    self: F
): array[Row, array[Col, Cell]] {.inline.} =
  ## Returns the array converted from the field.
  expand arr, bit:
    let arr = self.bit.toArr

  var arr {.noinit.}: array[Row, array[Col, Cell]]
  staticFor(row, Row):
    staticFor(col, Col):
      {.push warning[Uninit]: off.}
      arr[row][col].assign toCell(arr2[row][col], arr1[row][col], arr0[row][col])
      {.pop.}

  arr

func toField[F: TsuField or WaterField](
    arr: array[Row, array[Col, Cell]]
): F {.inline.} =
  ## Returns the field converted from the array.
  var arr2 {.noinit.}, arr1 {.noinit.}, arr0 {.noinit.}: array[Row, array[Col, bool]]

  staticFor(row, Row):
    staticFor(col, Col):
      arr[row][col].withBits:
        {.push warning[Uninit]: off.}
        expand arr, bit:
          arr[row][col].assign bit
        {.pop.}

  F.init(arr2.toBinField, arr1.toBinField, arr0.toBinField)

func toTsuField*(arr: array[Row, array[Col, Cell]]): TsuField {.inline.} =
  ## Returns the Tsu field converted from the array.
  toField[TsuField](arr)

func toWaterField*(arr: array[Row, array[Col, Cell]]): WaterField {.inline.} =
  ## Returns the Water field converted from the array.
  toField[WaterField](arr)

# ------------------------------------------------
# Field <-> string
# ------------------------------------------------

const
  WaterSep = "~~~~~~"
  LowerAirRow = AirHeight.pred.Row

func toStrImpl[F: TsuField or WaterField](self: F): string {.inline.} =
  ## Returns the string representation.
  # NOTE: generics `$` does not work
  let arr = self.toArr
  var lines = collect:
    for row in Row:
      join arr[row].mapIt $it

  when F is WaterField:
    lines.insert WaterSep, AirHeight

  lines.join "\n"

func `$`*(self: TsuField): string {.inline.} =
  self.toStrImpl

func `$`*(self: WaterField): string {.inline.} =
  self.toStrImpl

func parseField[F: TsuField or WaterField](str: string): Res[F] {.inline.} =
  ## Returns the field converted from the string representation.
  var lines = str.split '\n'
  if lines.len != (when F is TsuField: Height else: Height.succ):
    return err "Invalid field: {str}".fmt

  when F is WaterField:
    if lines[AirHeight] != WaterSep:
      return err "Invalid field: {str}".fmt

    lines.delete AirHeight

  if lines.anyIt it.len != Width:
    return err "Invalid field: {str}".fmt

  var arr {.noinit.}: array[Row, array[Col, Cell]]
  for row in Row:
    staticFor(col, Col):
      {.push warning[Uninit]: off.}
      arr[row][col].assign ?($lines[row.ord][col.ord]).parseCell.context(
        "Invalid field: {str}".fmt
      )
      {.pop.}

  ok toField[F](arr)

func parseTsuField*(str: string): Res[TsuField] {.inline.} =
  ## Returns the Tsu field converted from the string representation.
  parseField[TsuField](str)

func parseWaterField*(str: string): Res[WaterField] {.inline.} =
  ## Returns the Water field converted from the string representation.
  parseField[WaterField](str)

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

  TildeIshikawaPrefix = '~'
  TildeIshikawaLf = '.'
  CellToTildeIshikawaStr: array[Cell, string] = ["0", "9", "6", "1", "2", "3", "4", "5"]
  TildeIshikawaCharToCell = collect:
    for cell, str in CellToTildeIshikawaStr:
      {str[0]: cell}

func toUriQueryPon2[F: TsuField or WaterField](self: F): Res[string] {.inline.} =
  ## Returns the URI query converted from the field.
  const
    AirLowerRow = when F is TsuField: Row.high else: AirHeight.pred.Row
    NoneChars = {($None)[0]}
    RuleFieldSep = Pon2UriRuleFieldSep # NOTE: somehow needed

  let
    arr = self.toArr

    airStrs = collect:
      for row in Row.low .. AirLowerRow:
        for cell in arr[row]:
          $cell
    airStr = airStrs.join.strip(trailing = false, chars = NoneChars)

  when F is TsuField:
    ok "{Tsu}{RuleFieldSep}{airStr}".fmt
  else:
    const AirWaterSep = Pon2UriAirWaterSep # NOTE: somehow needed

    let
      waterStrs = collect:
        for row in AirLowerRow.succ .. Row.high:
          for cell in arr[row]:
            $cell
      waterStr = waterStrs.join.strip(leading = false, chars = NoneChars)

    ok "{Water}{RuleFieldSep}{airStr}{AirWaterSep}{waterStr}".fmt

func toUriQueryIshikawa(self: TsuField): Res[string] {.inline.} =
  ## Returns the URI query converted from the field.
  let arr = self.toArr

  if arr.anyIt(Hard in it):
    var lines = newSeqOfCap[string](Height)
    staticFor(row, Row):
      let
        strs = collect:
          for cell in arr[row]:
            CellToTildeIshikawaStr[cell]
        line = strs.join.strip(leading = false, chars = {'0'})

      lines.add if row < Row.high and line.len < Width:
        line & TildeIshikawaLf
      else:
        line

    ok TildeIshikawaPrefix &
      lines.join.strip(trailing = false, chars = {TildeIshikawaLf})
  else:
    var lines = newSeqOfCap[string](Height)
    staticFor(row, Row):
      var chars = newSeqOfCap[char](Height div 2)
      for i in 0 ..< Width div 2:
        let
          col = (i * 2).Col
          cell1 = arr[row][col]
          cell2 = arr[row][col.succ]

        chars.add IshikawaUriChars[
          CellToIshikawaIdx[cell1] * Cell.enumLen + CellToIshikawaIdx[cell2]
        ]

      lines.add chars.join

    ok lines.join.strip(trailing = false, chars = {'0'})

func toUriQueryIshikawa(self: WaterField): Res[string] {.inline.} =
  ## Returns the URI query converted from the field.
  err "Water field not supported on Ishikawa/Ips format: {self}".fmt

func toUriQuery*[F: TsuField or WaterField](
    self: F, fqdn = Pon2
): Res[string] {.inline.} =
  ## Returns the URI query converted from the field.
  case fqdn
  of Pon2: self.toUriQueryPon2
  of Ishikawa, Ips: self.toUriQueryIshikawa

func parseFieldPon2[F: TsuField or WaterField](query: string): Res[F] {.inline.} =
  ## Returns the field converted from the URI query.
  let strs = query.split Pon2UriRuleFieldSep
  if strs.len != 2:
    return err "Invalid field: {query}".fmt

  let rule = ?Pon2UriToRule.getRes(strs[0]).context "Invalid field: {query}".fmt

  var arr {.noinit.}: array[Row, array[Col, Cell]]
  when F is TsuField:
    if rule != Tsu:
      return err "Invalid field (incompatible rule): {query}".fmt

    if strs[1].len > Height * Width:
      return err "Invalid field: {query}".fmt

    let airStr = ($None)[0].repeat(Height * Width - strs[1].len) & strs[1]

    staticFor(row, Row):
      staticFor(col, Col):
        arr[row][col].assign ?($airStr[row.ord * Width + col.ord]).parseCell.context(
          "Invalid field: {query}".fmt
        )
  else:
    if rule != Water:
      return err "Invalid field (incompatible rule): {query}".fmt

    let airWaterStrs = strs[1].split Pon2UriAirWaterSep
    if airWaterStrs.len != 2 or airWaterStrs[0].len > AirHeight * Width or
        airWaterStrs[1].len > WaterHeight * Width:
      return err "Invalid field: {query}".fmt

    let
      airStrRaw = airWaterStrs[0]
      airStr = ($None)[0].repeat(AirHeight * Width - airStrRaw.len) & airStrRaw
    staticFor(row, Row.low .. LowerAirRow):
      staticFor(col, Col):
        arr[row][col].assign ?($airStr[row.ord * Width + col.ord]).parseCell.context(
          "Invalid field: {query}".fmt
        )

    let
      waterStrRaw = airWaterStrs[1]
      waterStr = waterStrRaw & ($None)[0].repeat(WaterHeight * Width - waterStrRaw.len)
    staticFor(row, LowerAirRow.succ .. Row.high):
      staticFor(col, Col):
        arr[row][col].assign ?($waterStr[(row.ord - AirHeight) * Width + col.ord]).parseCell.context(
          "Invalid field: {query}".fmt
        )

  ok toField[F](arr)

func splitByLen(str: string, length: int): seq[string] {.inline.} =
  ## Returns the strings split by the specified length.
  if str == "":
    @[""]
  else:
    collect:
      for firstIdx in countup(0, str.len.pred, length):
        str.substr(firstIdx, min(firstIdx.succ length, str.len).pred)

func parseTsuFieldIshikawa(query: string): Res[TsuField] {.inline.} =
  ## Returns the field converted from the URI query.
  if query.startsWith TildeIshikawaPrefix:
    let query2 = query[1 ..^ 1]
    if query2.len > Height * Width - 1:
      return err "Invalid field: {query}".fmt

    let
      strsSeq = collect:
        for str in query2.split TildeIshikawaLf:
          str.splitByLen Width
      strs = strsSeq.concat

    if strs.len > Height:
      return err "Invalid field: {query}".fmt

    let firstRow = (Height - strs.len).Row
    var arr = initArrWith[Row, array[Col, Cell]](initArrWith[Col, Cell](None))
    for rowIdx, str in strs:
      for colIdx, c in str:
        arr[firstRow.succ rowIdx][Col.low.succ colIdx].assign ?TildeIshikawaCharToCell
        .getRes(c)
        .context("Invalid field: {query}".fmt)

    ok arr.toTsuField
  else:
    if query.len > Height * Width div 2:
      return err "Invalid field: {query}".fmt

    var arr {.noinit.}: array[Row, array[Col, Cell]]
    for i, c in '0'.repeat(Height * Width div 2 - query.len) & query:
      let
        idx = ?IshikawaUriCharToIdx.getRes(c).context("Invalid field: {query}".fmt)
        cell1 =
          ?IshikawaIdxToCell.getRes(idx div Cell.enumLen).context(
            "Invalid field: {query}".fmt
          )
        cell2 =
          ?IshikawaIdxToCell.getRes(idx mod Cell.enumLen).context(
            "Invalid field: {query}".fmt
          )
        row = (i div (Width div 2)).Row
        col = (i mod (Width div 2) * 2).Col

      arr[row][col].assign cell1
      arr[row][col.succ].assign cell2

    ok arr.toTsuField

func parseTsuField*(query: string, fqdn: IdeFqdn): Res[TsuField] {.inline.} =
  ## Returns the Tsu field converted from the URI query.
  case fqdn
  of Pon2:
    parseFieldPon2[TsuField](query)
  of Ishikawa, Ips:
    query.parseTsuFieldIshikawa

func parseWaterField*(query: string, fqdn: IdeFqdn): Res[WaterField] {.inline.} =
  ## Returns the Water field converted from the URI query.
  case fqdn
  of Pon2:
    parseFieldPon2[WaterField](query)
  of Ishikawa, Ips:
    err "Water field not supported on Ishikawa/Ips format: {query}".fmt

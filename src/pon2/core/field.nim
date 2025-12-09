## This module implements fields.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, strformat, sugar, typetraits]
import ./[cell, common, fqdn, moveresult, pair, placement, popresult, rule, step]
import
  ../private/[
    arrayutils, assign, bitutils, core, macros, math, results2, staticfor, strutils,
    tables,
  ]

export cell, common, moveresult, placement, popresult, results2, rule

type Field* = object ## Puyo Puyo field.
  rule*: Rule
  binaryFields: array[3, BinaryField]

defineExpand "", "0", "1", "2"

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init(
    T: type Field, rule: Rule, bit0, bit1, bit2: BinaryField
): Field {.inline, noinit.} =
  Field(rule: rule, binaryFields: [bit0, bit1, bit2])

func init*(T: type Field, rule: Rule = Rule.Tsu): Field {.inline, noinit.} =
  T.init(rule, BinaryField.init, BinaryField.init, BinaryField.init)

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `*`(self: Field, binaryField: BinaryField): Field {.inline, noinit.} =
  Field.init(
    self.rule,
    self.binaryFields[0] * binaryField,
    self.binaryFields[1] * binaryField,
    self.binaryFields[2] * binaryField,
  )

# ------------------------------------------------
# Property
# ------------------------------------------------

func exist(self: Field): BinaryField {.inline, noinit.} =
  ## Returns the binary field where puyos exist.
  sum(self.binaryFields[0], self.binaryFields[1], self.binaryFields[2])

func isDead*(self: Field): bool {.inline, noinit.} =
  ## Returns `true` if the field is in a defeated state.
  self.exist.isDead Behaviours[self.rule].dead

# ------------------------------------------------
# Placement
# ------------------------------------------------

func invalidPlacements*(self: Field): set[Placement] {.inline, noinit.} =
  ## Returns the invalid placements.
  self.exist.invalidPlacements

func validPlacements*(self: Field): set[Placement] {.inline, noinit.} =
  ## Returns the valid placements.
  self.exist.validPlacements

func validDoublePlacements*(self: Field): set[Placement] {.inline, noinit.} =
  ## Returns the valid placements for double pairs.
  self.exist.validDoublePlacements

# ------------------------------------------------
# Indexer
# ------------------------------------------------

func toCell(bit0, bit1, bit2: bool): Cell {.inline, noinit.} =
  ## Returns the cell converted from the bits.
  (bit0.int + (bit1.int shl 1) + (bit2.int shl 2)).Cell

func `[]`*(self: Field, row: Row, col: Col): Cell {.inline, noinit.} =
  toCell(
    self.binaryFields[0][row, col],
    self.binaryFields[1][row, col],
    self.binaryFields[2][row, col],
  )

template withBits(cell: Cell, body: untyped): untyped =
  ## Runs `body` with `bit0`, `bit1`, and `bit2` exposed.
  block:
    let c = cell.ord

    expand bit:
      let bit {.inject.} = c.testBit _

    body

func `[]=`*(self: var Field, row: Row, col: Col, cell: Cell) {.inline, noinit.} =
  cell.withBits:
    expand bit:
      self.binaryFields[_][row, col] = bit

# ------------------------------------------------
# Insert / Delete
# ------------------------------------------------

func insert*(self: var Field, row: Row, col: Col, cell: Cell) {.inline, noinit.} =
  ## Inserts the cell and shifts the field.
  ## If (row, col) is in the air, shifts the field upward above where inserted.
  ## If it is in the water, shifts the field downward below where inserted.
  cell.withBits:
    expand bit:
      self.binaryFields[_].insert row, col, bit, Behaviours[self.rule].phys

func del*(self: var Field, row: Row, col: Col) {.inline, noinit.} =
  ## Deletes the cell and shifts the field.
  ## If (row, col) is in the air, shifts the field downward above where deleted.
  ## If it is in the water, shifts the field upward below where deleted.
  staticFor(i, 0 ..< 3):
    self.binaryFields[i].del row, col, Behaviours[self.rule].phys

# ------------------------------------------------
# Puyo Extract
# ------------------------------------------------

func hard(self: Field): BinaryField {.inline, noinit.} =
  ## Returns the binary field where hard puyos exist.
  self.binaryFields[0] - (self.binaryFields[1] + self.binaryFields[2])

func garbage(self: Field): BinaryField {.inline, noinit.} =
  ## Returns the binary field where garbage puyos exist.
  self.binaryFields[1] - (self.binaryFields[0] + self.binaryFields[2])

func red(self: Field): BinaryField {.inline, noinit.} =
  ## Returns the binary field where red puyos exist.
  self.binaryFields[0] * self.binaryFields[1] - self.binaryFields[2]

func green(self: Field): BinaryField {.inline, noinit.} =
  ## Returns the binary field where green puyos exist.
  self.binaryFields[2] - (self.binaryFields[0] + self.binaryFields[1])

func blue(self: Field): BinaryField {.inline, noinit.} =
  ## Returns the binary field where blue puyos exist.
  self.binaryFields[0] * self.binaryFields[2] - self.binaryFields[1]

func yellow(self: Field): BinaryField {.inline, noinit.} =
  ## Returns the binary field where yellow puyos exist.
  self.binaryFields[1] * self.binaryFields[2] - self.binaryFields[0]

func purple(self: Field): BinaryField {.inline, noinit.} =
  ## Returns the binary field where purple puyos exist.
  product(self.binaryFields[0], self.binaryFields[1], self.binaryFields[2])

# ------------------------------------------------
# Count
# ------------------------------------------------

func cellCount*(self: Field, cell: Cell): int {.inline, noinit.} =
  ## Returns the number of `cell` in the field.
  case cell
  of None:
    Height * Width - self.exist.popcnt
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

func puyoCount*(self: Field): int {.inline, noinit.} =
  ## Returns the number of puyos in the field.
  self.exist.popcnt

func colorPuyoCount*(self: Field): int {.inline, noinit.} =
  ## Returns the number of color puyos in the field.
  (self.binaryFields[2] + self.red).popcnt

func garbagesCount*(self: Field): int {.inline, noinit.} =
  ## Returns the number of hard and garbage puyos in the field.
  ((self.binaryFields[0] xor self.binaryFields[1]) - self.binaryFields[2]).popcnt

# ------------------------------------------------
# Connect - 2
# ------------------------------------------------

func connection2*(self: Field): Field {.inline, noinit.} =
  ## Returns the field where exactly two color puyos are connected.
  self *
    sum(
      self.red.connection2, self.green.connection2, self.blue.connection2,
      self.yellow.connection2, self.purple.connection2,
    )

func connection2Vertical*(self: Field): Field {.inline, noinit.} =
  ## Returns the field where exactly two color puyos are connected vertically.
  self *
    sum(
      self.red.connection2Vertical, self.green.connection2Vertical,
      self.blue.connection2Vertical, self.yellow.connection2Vertical,
      self.purple.connection2Vertical,
    )

func connection2Horizontal*(self: Field): Field {.inline, noinit.} =
  ## Returns the field where exactly two color puyos are connected horizontally.
  self *
    sum(
      self.red.connection2Horizontal, self.green.connection2Horizontal,
      self.blue.connection2Horizontal, self.yellow.connection2Horizontal,
      self.purple.connection2Horizontal,
    )

# ------------------------------------------------
# Connect - 3
# ------------------------------------------------

func connection3*(self: Field): Field {.inline, noinit.} =
  ## Returns the field where exactly three color puyos are connected.
  self *
    sum(
      self.red.connection3, self.green.connection3, self.blue.connection3,
      self.yellow.connection3, self.purple.connection3,
    )

func connection3Vertical*(self: Field): Field {.inline, noinit.} =
  ## Returns the field where exactly three color puyos are connected vertically.
  self *
    sum(
      self.red.connection3Vertical, self.green.connection3Vertical,
      self.blue.connection3Vertical, self.yellow.connection3Vertical,
      self.purple.connection3Vertical,
    )

func connection3Horizontal*(self: Field): Field {.inline, noinit.} =
  ## Returns the field where exactly three color puyos are connected horizontally.
  self *
    sum(
      self.red.connection3Horizontal, self.green.connection3Horizontal,
      self.blue.connection3Horizontal, self.yellow.connection3Horizontal,
      self.purple.connection3Horizontal,
    )

func connection3LShape*(self: Field): Field {.inline, noinit.} =
  ## Returns the field where exactly three color puyos are connected by L-shape.
  self *
    sum(
      self.red.connection3LShape, self.green.connection3LShape,
      self.blue.connection3LShape, self.yellow.connection3LShape,
      self.purple.connection3LShape,
    )

# ------------------------------------------------
# Shift
# ------------------------------------------------

func shiftUp*(self: var Field) {.inline, noinit.} =
  ## Shifts the field upward.
  staticFor(i, 0 ..< 3):
    self.binaryFields[i].shiftUp

func shiftDown*(self: var Field) {.inline, noinit.} =
  ## Shifts the field downward.
  staticFor(i, 0 ..< 3):
    self.binaryFields[i].shiftDown

func shiftRight*(self: var Field) {.inline, noinit.} =
  ## Shifts the field rightward.
  staticFor(i, 0 ..< 3):
    self.binaryFields[i].shiftRight

func shiftLeft*(self: var Field) {.inline, noinit.} =
  ## Shifts the field leftward.
  staticFor(i, 0 ..< 3):
    self.binaryFields[i].shiftLeft

# ------------------------------------------------
# Flip
# ------------------------------------------------

func flipVertical*(self: var Field) {.inline, noinit.} =
  ## Flips the field vertically.
  staticFor(i, 0 ..< 3):
    self.binaryFields[i].flipVertical

func flipHorizontal*(self: var Field) {.inline, noinit.} =
  ## Flips the field horizontally.
  staticFor(i, 0 ..< 3):
    self.binaryFields[i].flipHorizontal

# ------------------------------------------------
# Rotate
# ------------------------------------------------

func rotate*(self: var Field) {.inline, noinit.} =
  ## Rotates the binary field by 180 degrees.
  ## Ghost cells are cleared before the rotation.
  staticFor(i, 0 ..< 3):
    self.binaryFields[i].rotate

func crossRotate*(self: var Field) {.inline, noinit.} =
  ## Rotates the binary field by 180 degrees in groups of three rows.
  ## Ghost cells are cleared before the rotation.
  staticFor(i, 0 ..< 3):
    self.binaryFields[i].crossRotate

# ------------------------------------------------
# Place
# ------------------------------------------------

template withFills(cell: Cell, body: untyped): untyped =
  ## Runs `body` with `fill0`, `fill1`, and `fill2` exposed.
  block:
    let c = cell.ord

    expand fill:
      let fill {.inject.} = if c.testBit _: BinaryField.initOne else: BinaryField.init

    body

func placeTsu(self: var Field, pair: Pair, placement: Placement) {.inline, noinit.} =
  ## Places the pair with Tsu Physics.
  ## This function requires that the field is settled.
  let
    existField = self.exist
    placeMask = existField xor (existField + BinaryField.initFloor).shiftedUp
    pivotMask = (if placement in Down0 .. Down5: placeMask.shiftedUp else: placeMask).kept placement.pivotCol
    rotorMask = (if placement in Up0 .. Up5: placeMask.shiftedUp else: placeMask).kept placement.rotorCol

  let pivot0, pivot1, pivot2: BinaryField
  pair.pivot.withFills:
    expand pivot, fill:
      pivot = fill * pivotMask

  let rotor0, rotor1, rotor2: BinaryField
  pair.rotor.withFills:
    expand rotor, fill:
      rotor = fill * rotorMask

  expand pivot, rotor:
    self.binaryFields[_] += pivot + rotor

func placeWater(self: var Field, pair: Pair, placement: Placement) {.inline, noinit.} =
  ## Places the pair with Water physics.
  ## This function requires that the field is settled.
  let
    pivotCol = placement.pivotCol
    rotorCol = placement.rotorCol

    existField = self.exist
    placeMask =
      (existField xor (existField + BinaryField.initUpperWater).shiftedUpRaw).keptAir
    pivotMask = (if placement in Down0 .. Down5: placeMask.shiftedUp else: placeMask).kept pivotCol
    rotorMask =
      (if placement in Up0 .. Up5: placeMask.shiftedUp else: placeMask).kept rotorCol

  let pivot0, pivot1, pivot2: BinaryField
  pair.pivot.withFills:
    expand pivot, fill:
      pivot = fill * pivotMask

  let rotor0, rotor1, rotor2: BinaryField
  pair.rotor.withFills:
    expand rotor, fill:
      rotor = fill * rotorMask

  expand pivot, rotor:
    self.binaryFields[_] += pivot + rotor

  if not existField[Row.high, pivotCol]:
    staticFor(i, 0 ..< 3):
      self.binaryFields[i].replace pivotCol, self.binaryFields[i].shiftedDownRaw

  if not self.exist[Row.high, rotorCol]:
    staticFor(i, 0 ..< 3):
      self.binaryFields[i].replace rotorCol, self.binaryFields[i].shiftedDownRaw

func place*(self: var Field, pair: Pair, placement: Placement) {.inline, noinit.} =
  ## Places the pair.
  ## This function requires that the field is settled.
  case Behaviours[self.rule].phys
  of Phys.Tsu:
    self.placeTsu pair, placement
  of Phys.Water:
    self.placeWater pair, placement

func place*(
    self: var Field, pair: Pair, optPlacement: OptPlacement
) {.inline, noinit.} =
  ## Places the pair.
  ## This function requires that the field is settled.
  if optPlacement.isOk:
    self.place pair, optPlacement.unsafeValue

# ------------------------------------------------
# Pop
# ------------------------------------------------

func pop*(self: var Field): PopResult {.inline, noinit.} =
  ## Removes puyos that should pop and returns the pop result.
  # NOTE: `ignoreHard` option can be introduced, but (somehow) the performance
  # was almost the same.
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

    touch1More = sum(colorU, colorD, colorR, colorL)
    poppedGarbage = self.garbage.keptVisible * touch1More

    colorUorD = colorU + colorD
    colorRorL = colorR + colorL
    onlyU = colorU - (colorD + colorRorL)
    onlyD = colorD - (colorU + colorRorL)
    onlyR = colorR - (colorL + colorUorD)
    onlyL = colorL - (colorR + colorUorD)

    touch1 = sum(onlyU, onlyD, onlyR, onlyL)
    touch2More = touch1More - touch1

    visibleHard = self.hard.keptVisible
    hardToGarbage = visibleHard * touch1
    poppedHard = visibleHard * touch2More

  self.binaryFields[0].assign self.binaryFields[0] - poppedColor -
    (poppedHard + hardToGarbage)
  self.binaryFields[1].assign self.binaryFields[1] + hardToGarbage -
    (poppedColor + poppedGarbage)
  self.binaryFields[2] -= poppedColor

  PopResult.init(
    poppedR, poppedG, poppedB, poppedY, poppedP, poppedHard, hardToGarbage,
    poppedGarbage, poppedColor,
  )

func canPop*(self: Field): bool {.inline, noinit.} =
  ## Returns `true` if any puyos can pop.
  ## Note that this function is only slightly lighter than `pop`.
  self.red.canPop or self.green.canPop or self.blue.canPop or self.yellow.canPop or
    self.purple.canPop

# ------------------------------------------------
# Drop Garbages
# ------------------------------------------------

func dropGarbages*(
    self: var Field, counts: array[Col, int], dropHard: bool
) {.inline, noinit.} =
  ## Drops hard or garbage puyos.
  ## This function requires that the field is settled and the counts are non-negative.
  let
    existField = self.exist
    notDropHardInt = (not dropHard).int

  case Behaviours[self.rule].phys
  of Phys.Tsu:
    self.binaryFields[notDropHardInt].dropGarbagesTsu counts, existField
  of Phys.Water:
    self.binaryFields[notDropHardInt].dropGarbagesWater self.binaryFields[dropHard.int],
      self.binaryFields[2], counts, existField

# ------------------------------------------------
# Apply
# ------------------------------------------------

func apply*(self: var Field, step: Step) {.inline, noinit.} =
  ## Applies the step.
  ## This function requires that the field is settled.
  case step.kind
  of PairPlacement:
    self.place step.pair, step.optPlacement
  of Garbages:
    self.dropGarbages step.counts, step.dropHard
  of Rotate:
    if step.cross: self.crossRotate else: self.rotate

# ------------------------------------------------
# Settle
# ------------------------------------------------

func settle*(self: var Field) {.inline, noinit.} =
  ## Settles the field.
  case Behaviours[self.rule].phys
  of Phys.Tsu:
    settleTsu(
      self.binaryFields[0], self.binaryFields[1], self.binaryFields[2], self.exist
    )
  of Phys.Water:
    settleWater(
      self.binaryFields[0], self.binaryFields[1], self.binaryFields[2], self.exist
    )

func isSettled*(self: Field): bool {.inline, noinit.} =
  ## Returns `true` if the field is settled.
  ## Note that this function is only slightly lighter than `settle`
  case Behaviours[self.rule].phys
  of Phys.Tsu:
    areSettledTsu(
      self.binaryFields[0], self.binaryFields[1], self.binaryFields[2], self.exist
    )
  of Phys.Water:
    areSettledWater(
      self.binaryFields[0], self.binaryFields[1], self.binaryFields[2], self.exist
    )

# ------------------------------------------------
# Move
# ------------------------------------------------

const MaxChainCount = Height * Width div 4

template moveImpl(
    self: var Field, calcConnection, settleAfterApply: bool, applyBody: untyped
): MoveResult =
  ## Applies `applyBody`, advances the field until chains end, and returns a moving
  ## result.
  ## This function requires that the field is settled.
  var
    chainCount = 0
    popCounts = static(Cell.initArrayWith 0)
    hardToGarbageCount = 0
    detailPopCounts = newSeqOfCap[array[Cell, int]](MaxChainCount)
    detailHardToGarbageCount = newSeqOfCap[int](MaxChainCount)
    fullPopCounts =
      newSeqOfCap[array[Cell, seq[int]]](if calcConnection: MaxChainCount else: 0)

  applyBody

  if settleAfterApply:
    self.settle

  while true:
    let popResult = self.pop
    if not popResult.isPopped:
      if calcConnection:
        return MoveResult.init(
          chainCount, popCounts, hardToGarbageCount, detailPopCounts,
          detailHardToGarbageCount, fullPopCounts,
        )
      else:
        return MoveResult.init(
          chainCount, popCounts, hardToGarbageCount, detailPopCounts,
          detailHardToGarbageCount,
        )

    chainCount.inc
    self.settle

    var cellCounts {.noinit.}: array[Cell, int]
    cellCounts[None].assign 0
    staticFor(cell2, Hard .. Purple):
      let cellCount = popResult.cellCount cell2
      cellCounts[cell2].assign cellCount
      popCounts[cell2].inc cellCount
    detailPopCounts.add cellCounts

    let h2g = popResult.hardToGarbageCount
    hardToGarbageCount.inc h2g
    detailHardToGarbageCount.add h2g

    if calcConnection:
      fullPopCounts.add popResult.connectionCounts

  # NOTE: dummy to suppress warning (not reached here)
  MoveResult.init

func move*(
    self: var Field, pair: Pair, placement: Placement, calcConnection = true
): MoveResult {.inline, noinit.} =
  ## Places the pair, advances the field until chains end, and returns a moving result.
  ## This function requires that the field is settled.
  self.moveImpl(calcConnection, settleAfterApply = false):
    self.place pair, placement

func move*(
    self: var Field, counts: array[Col, int], dropHard: bool, calcConnection = true
): MoveResult {.inline, noinit.} =
  ## Drops hard or garbage puyos, advances the field until chains end, and returns a
  ## moving result.
  ## This function requires that the field is settled and the counts are non-negative.
  self.moveImpl(calcConnection, settleAfterApply = false):
    self.dropGarbages counts, dropHard

func move*(
    self: var Field, cross: bool, calcConnection = true
): MoveResult {.inline, noinit.} =
  ## Rotates the field, advances the field until chains end, and returns a moving
  ## result.
  self.moveImpl(calcConnection, settleAfterApply = true):
    if cross: self.crossRotate else: self.rotate

func move*(
    self: var Field, step: Step, calcConnection = true
): MoveResult {.inline, noinit.} =
  ## Applies the step, advances the field until chains end, and returns a moving result.
  ## This function requires that the field is settled.
  self.moveImpl(calcConnection, settleAfterApply = step.kind == Rotate):
    self.apply step

# ------------------------------------------------
# Field <-> array
# ------------------------------------------------

func toArray*(self: Field): array[Row, array[Col, Cell]] {.inline, noinit.} =
  ## Returns the array converted from the field.
  expand boolArray:
    let boolArray = self.binaryFields[_].toArray

  var cellArray {.noinit.}: array[Row, array[Col, Cell]]
  staticFor(row, Row):
    staticFor(col, Col):
      {.push warning[Uninit]: off.}
      cellArray[row][col].assign toCell(
        boolArray0[row][col], boolArray1[row][col], boolArray2[row][col]
      )
      {.pop.}

  cellArray

func toField*(
    cellArray: array[Row, array[Col, Cell]], rule: Rule
): Field {.inline, noinit.} =
  ## Returns the field converted from the array.
  var boolArray0 {.noinit.}, boolArray1 {.noinit.}, boolArray2 {.noinit.}:
    array[Row, array[Col, bool]]

  staticFor(row, Row):
    staticFor(col, Col):
      cellArray[row][col].withBits:
        {.push warning[Uninit]: off.}
        expand boolArray, bit:
          boolArray[row][col].assign bit
        {.pop.}

  Field.init(
    rule, boolArray0.toBinaryField, boolArray1.toBinaryField, boolArray2.toBinaryField
  )

# ------------------------------------------------
# Field <-> string
# ------------------------------------------------

const
  RulePrefix = "["
  RuleSuffix = "]"
  WaterSep = "~~~~~~"
  LowerAirRow = AirHeight.pred.Row

func `$`*(self: Field): string {.inline, noinit.} =
  var lines = newSeqOfCap[string](Height.succ 2)
  lines.add "{RulePrefix}{self.rule}{RuleSuffix}".fmt

  let
    cellArray = self.toArray
    cellsLines = collect:
      for row in Row:
        join cellArray[row].mapIt $it
  lines &= cellsLines

  if self.rule == Rule.Water:
    lines.insert WaterSep, AirHeight.succ

  lines.join "\n"

func parseField*(str: string): Pon2Result[Field] {.inline, noinit.} =
  ## Returns the field converted from the string representation.
  let errorMsg = "Invalid field: {str}".fmt

  var lines = str.split '\n'
  if lines.len == 0:
    return err errorMsg

  if not (lines[0].startsWith(RulePrefix) and lines[0].endsWith(RuleSuffix)):
    return err errorMsg
  let rule =
    ?lines[0][RulePrefix.len ..^ RuleSuffix.len.succ].parseRule.context errorMsg
  lines.delete 0

  if lines.len != Height.succ (rule == Rule.Water).int:
    return err errorMsg

  if rule == Rule.Water:
    if lines[AirHeight] != WaterSep:
      return err errorMsg

    lines.delete AirHeight

  if lines.anyIt it.len != Width:
    return err errorMsg

  var cellArray {.noinit.}: array[Row, array[Col, Cell]]
  for row in Row:
    staticFor(col, Col):
      {.push warning[Uninit]: off.}
      cellArray[row][col].assign ?($lines[row.ord][col.ord]).parseCell.context errorMsg
      {.pop.}

  ok cellArray.toField rule

# ------------------------------------------------
# Field <-> URI
# ------------------------------------------------

const
  Pon2UriRuleFieldSep = "_"
  Pon2UriAirWaterSep = "~"

  IshikawaUriChars = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-"
  IshikawaUriCharToIndex = collect:
    for i, c in IshikawaUriChars:
      {c: i}
  CellToIshikawaIndex: array[Cell, int] = [0, -1, 6, 1, 2, 3, 4, 5]
  IshikawaIndexToCell = collect:
    for cell, index in CellToIshikawaIndex:
      {index: cell}

  TildeIshikawaPrefix = '~'
  TildeIshikawaLf = '.'
  CellToTildeIshikawaStr: array[Cell, string] = ["0", "9", "6", "1", "2", "3", "4", "5"]
  TildeIshikawaCharToCell = collect:
    for cell, str in CellToTildeIshikawaStr:
      {str[0]: cell}

func toUriQueryPon2(self: Field): Pon2Result[string] {.inline, noinit.} =
  ## Returns the URI query converted from the field.
  const
    NoneChars = {($None)[0]}
    RuleFieldSep = Pon2UriRuleFieldSep # NOTE: strformat needs this

  let
    airLowerRow =
      case self.rule
      of Rule.Tsu, Spinner, CrossSpinner: Row.high
      of Rule.Water: AirHeight.pred.Row
    cellArray = self.toArray

    airStrs = collect:
      for row in Row.low .. airLowerRow:
        for cell in cellArray[row]:
          $cell
    airStr = airStrs.join.strip(trailing = false, chars = NoneChars)

  var query = "{self.rule.ord}{RuleFieldSep}{airStr}".fmt

  if self.rule == Rule.Water:
    let
      waterStrs = collect:
        for row in airLowerRow.succ .. Row.high:
          for cell in cellArray[row]:
            $cell
      waterStr = waterStrs.join.strip(leading = false, chars = NoneChars)

    query &= "{Pon2UriAirWaterSep}{waterStr}".fmt

  ok query

func toUriQueryIshikawa(self: Field): Pon2Result[string] {.inline, noinit.} =
  ## Returns the URI query converted from the field.
  if self.rule != Rule.Tsu:
    return err "non-Tsu field is not supported on Ishikawa/Ips format: {self}".fmt

  let cellArray = self.toArray

  if cellArray.anyIt(Hard in it):
    var lines = newSeqOfCap[string](Height)
    staticFor(row, Row):
      let
        strs = collect:
          for cell in cellArray[row]:
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
          cell1 = cellArray[row][col]
          cell2 = cellArray[row][col.succ]

        chars.add IshikawaUriChars[
          CellToIshikawaIndex[cell1] * static(Cell.enumLen) + CellToIshikawaIndex[cell2]
        ]

      lines.add chars.join

    ok lines.join.strip(trailing = false, chars = {'0'})

func toUriQuery*(self: Field, fqdn = Pon2): Pon2Result[string] {.inline, noinit.} =
  ## Returns the URI query converted from the field.
  case fqdn
  of Pon2: self.toUriQueryPon2
  of Ishikawa, Ips: self.toUriQueryIshikawa

func parseFieldPon2(query: string): Pon2Result[Field] {.inline, noinit.} =
  ## Returns the field converted from the URI query.
  let errorMsg = "Invalid field: {query}".fmt

  if query == "":
    return ok Field.init

  let strs = query.split Pon2UriRuleFieldSep
  if strs.len != 2:
    return err "Invalid field: {query}".fmt

  let ruleOrd = ?strs[0].parseInt.context errorMsg
  if ruleOrd notin Rule.low.ord .. Rule.high.ord:
    return err "Invalid field: {query}".fmt
  let rule = ruleOrd.Rule

  var cellArray {.noinit.}: array[Row, array[Col, Cell]]
  case rule
  of Rule.Tsu, Spinner, CrossSpinner:
    if strs[1].len > Height * Width:
      return err errorMsg

    let airStr = ($None)[0].repeat(Height * Width - strs[1].len) & strs[1]

    staticFor(row, Row):
      staticFor(col, Col):
        cellArray[row][col].assign ?($airStr[row.ord * Width + col.ord]).parseCell.context errorMsg
  of Rule.Water:
    let airWaterStrs = strs[1].split Pon2UriAirWaterSep
    if airWaterStrs.len != 2 or airWaterStrs[0].len > AirHeight * Width or
        airWaterStrs[1].len > WaterHeight * Width:
      return err errorMsg

    let
      airStrRaw = airWaterStrs[0]
      airStr = ($None)[0].repeat(AirHeight * Width - airStrRaw.len) & airStrRaw
    staticFor(row, Row.low .. LowerAirRow):
      staticFor(col, Col):
        cellArray[row][col].assign ?($airStr[row.ord * Width + col.ord]).parseCell.context errorMsg

    let
      waterStrRaw = airWaterStrs[1]
      waterStr = waterStrRaw & ($None)[0].repeat(WaterHeight * Width - waterStrRaw.len)
    staticFor(row, LowerAirRow.succ .. Row.high):
      staticFor(col, Col):
        cellArray[row][col].assign ?($waterStr[(row.ord - AirHeight) * Width + col.ord]).parseCell.context errorMsg

  ok cellArray.toField rule

func splitByLen(str: string, length: int): seq[string] {.inline, noinit.} =
  ## Returns the strings split by the specified length.
  if str == "":
    @[""]
  else:
    collect:
      for firstIndex in countup(0, str.len.pred, length):
        str.substr(firstIndex, min(firstIndex.succ length, str.len).pred)

func parseFieldIshikawa(query: string): Pon2Result[Field] {.inline, noinit.} =
  ## Returns the field converted from the URI query.
  let errorMsg = "Invalid field: {query}".fmt

  if query.startsWith TildeIshikawaPrefix:
    let query2 = query[1 ..^ 1]
    if query2.len > Height * Width - 1:
      return err errorMsg

    let
      strsSeq = collect:
        for str in query2.split TildeIshikawaLf:
          str.splitByLen Width
      strs = strsSeq.concat

    if strs.len > Height:
      return err errorMsg

    let firstRow = (Height - strs.len).Row
    var cellArray = static(Row.initArrayWith Col.initArrayWith None)
    for rowIndex, str in strs:
      for colIndex, c in str:
        cellArray[firstRow.succ rowIndex][Col.low.succ colIndex].assign ?TildeIshikawaCharToCell[
          c
        ].context errorMsg

    ok cellArray.toField Rule.Tsu
  else:
    if query.len > Height * Width div 2:
      return err errorMsg

    var cellArray {.noinit.}: array[Row, array[Col, Cell]]
    for i, c in '0'.repeat(Height * Width div 2 - query.len) & query:
      let
        index = ?IshikawaUriCharToIndex[c].context errorMsg
        (indexQuotient, indexRemainder) = index.divmod static(Cell.enumLen)
        cell1 = ?IshikawaIndexToCell[indexQuotient].context errorMsg
        cell2 = ?IshikawaIndexToCell[indexRemainder].context errorMsg

        (iQuotient, iRemainder) = i.divmod static(Width div 2)
        row = (iQuotient).Row
        col = (iRemainder * 2).Col

      cellArray[row][col].assign cell1
      cellArray[row][col.succ].assign cell2

    ok cellArray.toField Rule.Tsu

func parseField*(
    query: string, fqdn: SimulatorFqdn
): Pon2Result[Field] {.inline, noinit.} =
  ## Returns the field converted from the URI query.
  case fqdn
  of Pon2: query.parseFieldPon2
  of Ishikawa, Ips: query.parseFieldIshikawa

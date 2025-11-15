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

type
  TsuField* = distinct array[3, BinaryField] ## Puyo Puyo field for Tsu rule.
  WaterField* = distinct array[3, BinaryField] ## Puyo Puyo field for Water rule.

defineExpand "", "0", "1", "2"

# ------------------------------------------------
# Borrow
# ------------------------------------------------

func `==`*(f1, f2: TsuField): bool {.borrow.}

func `==`*(f1, f2: WaterField): bool {.borrow.}

func `[]`[I: Ordinal, F: TsuField or WaterField](
    self: F, index: I
): BinaryField {.inline, noinit.} =
  cast[array[3, BinaryField]](self)[index]

func `[]`[I: Ordinal, F: TsuField or WaterField](
    self: var F, index: I
): var BinaryField {.inline, noinit.} =
  cast[ptr array[3, BinaryField]](self.addr)[][index]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init[F: TsuField or WaterField](
    T: type F, bit0, bit1, bit2: BinaryField
): F {.inline, noinit.} =
  cast[F]([bit0, bit1, bit2])

func init*[F: TsuField or WaterField](T: type F): F {.inline, noinit.} =
  T.init(BinaryField.init, BinaryField.init, BinaryField.init)

# ------------------------------------------------
# Convert
# ------------------------------------------------

func toTsuField*(self: TsuField): TsuField {.inline, noinit.} =
  ## Returns the copy of the field.
  self

func toTsuField*(self: WaterField): TsuField {.inline, noinit.} =
  ## Returns the Tsu field converted from the field.
  cast[TsuField](self)

func toWaterField*(self: TsuField): WaterField {.inline, noinit.} =
  ## Returns the Water field converted from the field.
  cast[WaterField](self)

func toWaterField*(self: WaterField): WaterField {.inline, noinit.} =
  ## Returns the copy of the field.
  self

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `*`[F: TsuField or WaterField](
    self: F, binaryField: BinaryField
): F {.inline, noinit.} =
  F.init(self[0] * binaryField, self[1] * binaryField, self[2] * binaryField)

# ------------------------------------------------
# Property
# ------------------------------------------------

func rule*(self: TsuField): Rule {.inline, noinit.} =
  ## Returns the rule.
  Tsu

func rule*(self: WaterField): Rule {.inline, noinit.} =
  ## Returns the rule.
  Water

func exist[F: TsuField or WaterField](self: F): BinaryField {.inline, noinit.} =
  ## Returns the binary field where puyos exist.
  sum(self[0], self[1], self[2])

func isDead*[F: TsuField or WaterField](self: F): bool {.inline, noinit.} =
  ## Returns `true` if the field is in a defeated state.
  const FieldRule = when F is TsuField: Tsu else: Water

  self.exist.isDead FieldRule

# ------------------------------------------------
# Placement
# ------------------------------------------------

func invalidPlacements*[F: TsuField or WaterField](
    self: F
): set[Placement] {.inline, noinit.} =
  ## Returns the invalid placements.
  self.exist.invalidPlacements

func validPlacements*[F: TsuField or WaterField](
    self: F
): set[Placement] {.inline, noinit.} =
  ## Returns the valid placements.
  self.exist.validPlacements

func validDoublePlacements*[F: TsuField or WaterField](
    self: F
): set[Placement] {.inline, noinit.} =
  ## Returns the valid placements for double pairs.
  self.exist.validDoublePlacements

# ------------------------------------------------
# Indexer
# ------------------------------------------------

func toCell(bit0, bit1, bit2: bool): Cell {.inline, noinit.} =
  ## Returns the cell converted from the bits.
  (bit0.int + (bit1.int shl 1) + (bit2.int shl 2)).Cell

func `[]`*[F: TsuField or WaterField](
    self: F, row: Row, col: Col
): Cell {.inline, noinit.} =
  toCell(self[0][row, col], self[1][row, col], self[2][row, col])

template withBits(cell: Cell, body: untyped): untyped =
  ## Runs `body` with `bit0`, `bit1`, and `bit2` exposed.
  block:
    let c = cell.ord

    expand bit:
      let bit {.inject.} = c.testBit _

    body

func `[]=`*[F: TsuField or WaterField](
    self: var F, row: Row, col: Col, cell: Cell
) {.inline, noinit.} =
  cell.withBits:
    expand bit:
      self[_][row, col] = bit

# ------------------------------------------------
# Insert / Delete
# ------------------------------------------------

func insert*[F: TsuField or WaterField](
    self: var F, row: Row, col: Col, cell: Cell
) {.inline, noinit.} =
  ## Inserts the cell and shifts the field.
  ## If (row, col) is in the air, shifts the field upward above where inserted.
  ## If it is in the water, shifts the field downward below where inserted.
  const FieldRule = when F is TsuField: Tsu else: Water

  cell.withBits:
    expand bit:
      self[_].insert row, col, bit, FieldRule

func del*[F: TsuField or WaterField](
    self: var F, row: Row, col: Col
) {.inline, noinit.} =
  ## Deletes the cell and shifts the field.
  ## If (row, col) is in the air, shifts the field downward above where deleted.
  ## If it is in the water, shifts the field upward below where deleted.
  const FieldRule = when F is TsuField: Tsu else: Water

  staticFor(i, 0 ..< 3):
    self[i].del row, col, FieldRule

# ------------------------------------------------
# Puyo Extract
# ------------------------------------------------

func hard[F: TsuField or WaterField](self: F): BinaryField {.inline, noinit.} =
  ## Returns the binary field where hard puyos exist.
  self[0] - (self[1] + self[2])

func garbage[F: TsuField or WaterField](self: F): BinaryField {.inline, noinit.} =
  ## Returns the binary field where garbage puyos exist.
  self[1] - (self[0] + self[2])

func red[F: TsuField or WaterField](self: F): BinaryField {.inline, noinit.} =
  ## Returns the binary field where red puyos exist.
  self[0] * self[1] - self[2]

func green[F: TsuField or WaterField](self: F): BinaryField {.inline, noinit.} =
  ## Returns the binary field where green puyos exist.
  self[2] - (self[0] + self[1])

func blue[F: TsuField or WaterField](self: F): BinaryField {.inline, noinit.} =
  ## Returns the binary field where blue puyos exist.
  self[0] * self[2] - self[1]

func yellow[F: TsuField or WaterField](self: F): BinaryField {.inline, noinit.} =
  ## Returns the binary field where yellow puyos exist.
  self[1] * self[2] - self[0]

func purple[F: TsuField or WaterField](self: F): BinaryField {.inline, noinit.} =
  ## Returns the binary field where purple puyos exist.
  prod(self[0], self[1], self[2])

# ------------------------------------------------
# Count
# ------------------------------------------------

func cellCount*[F: TsuField or WaterField](
    self: F, cell: Cell
): int {.inline, noinit.} =
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

func puyoCount*[F: TsuField or WaterField](self: F): int {.inline, noinit.} =
  ## Returns the number of puyos in the field.
  self.exist.popcnt

func colorPuyoCount*[F: TsuField or WaterField](self: F): int {.inline, noinit.} =
  ## Returns the number of color puyos in the field.
  (self[2] + self.red).popcnt

func garbagesCount*[F: TsuField or WaterField](self: F): int {.inline, noinit.} =
  ## Returns the number of hard and garbage puyos in the field.
  ((self[0] xor self[1]) - self[2]).popcnt

# ------------------------------------------------
# Connect - 2
# ------------------------------------------------

func connection2*[F: TsuField or WaterField](self: F): F {.inline, noinit.} =
  ## Returns the field where exactly two color puyos are connected.
  self *
    sum(
      self.red.connection2, self.green.connection2, self.blue.connection2,
      self.yellow.connection2, self.purple.connection2,
    )

func connection2Vertical*[F: TsuField or WaterField](self: F): F {.inline, noinit.} =
  ## Returns the field where exactly two color puyos are connected vertically.
  self *
    sum(
      self.red.connection2Vertical, self.green.connection2Vertical,
      self.blue.connection2Vertical, self.yellow.connection2Vertical,
      self.purple.connection2Vertical,
    )

func connection2Horizontal*[F: TsuField or WaterField](self: F): F {.inline, noinit.} =
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

func connection3*[F: TsuField or WaterField](self: F): F {.inline, noinit.} =
  ## Returns the field where exactly three color puyos are connected.
  self *
    sum(
      self.red.connection3, self.green.connection3, self.blue.connection3,
      self.yellow.connection3, self.purple.connection3,
    )

func connection3Vertical*[F: TsuField or WaterField](self: F): F {.inline, noinit.} =
  ## Returns the field where exactly three color puyos are connected vertically.
  self *
    sum(
      self.red.connection3Vertical, self.green.connection3Vertical,
      self.blue.connection3Vertical, self.yellow.connection3Vertical,
      self.purple.connection3Vertical,
    )

func connection3Horizontal*[F: TsuField or WaterField](self: F): F {.inline, noinit.} =
  ## Returns the field where exactly three color puyos are connected horizontally.
  self *
    sum(
      self.red.connection3Horizontal, self.green.connection3Horizontal,
      self.blue.connection3Horizontal, self.yellow.connection3Horizontal,
      self.purple.connection3Horizontal,
    )

func connection3LShape*[F: TsuField or WaterField](self: F): F {.inline, noinit.} =
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

func shiftUp*[F: TsuField or WaterField](self: var F) {.inline, noinit.} =
  ## Shifts the field upward.
  staticFor(i, 0 ..< 3):
    self[i].shiftUp

func shiftDown*[F: TsuField or WaterField](self: var F) {.inline, noinit.} =
  ## Shifts the field downward.
  staticFor(i, 0 ..< 3):
    self[i].shiftDown

func shiftRight*[F: TsuField or WaterField](self: var F) {.inline, noinit.} =
  ## Shifts the field rightward.
  staticFor(i, 0 ..< 3):
    self[i].shiftRight

func shiftLeft*[F: TsuField or WaterField](self: var F) {.inline, noinit.} =
  ## Shifts the field leftward.
  staticFor(i, 0 ..< 3):
    self[i].shiftLeft

# ------------------------------------------------
# Flip
# ------------------------------------------------

func flipVertical*[F: TsuField or WaterField](self: var F) {.inline, noinit.} =
  ## Flips the field vertically.
  staticFor(i, 0 ..< 3):
    self[i].flipVertical

func flipHorizontal*[F: TsuField or WaterField](self: var F) {.inline, noinit.} =
  ## Flips the field horizontally.
  staticFor(i, 0 ..< 3):
    self[i].flipHorizontal

# ------------------------------------------------
# Rotate
# ------------------------------------------------

func rotate*[F: TsuField or WaterField](self: var F) {.inline, noinit.} =
  ## Rotates the binary field by 180 degrees.
  ## Ghost cells are cleared before the rotation.
  staticFor(i, 0 ..< 3):
    self[i].rotate

func crossRotate*[F: TsuField or WaterField](self: var F) {.inline, noinit.} =
  ## Rotates the binary field by 180 degrees in groups of three rows.
  ## Ghost cells are cleared before the rotation.
  staticFor(i, 0 ..< 3):
    self[i].crossRotate

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

func place*(self: var TsuField, pair: Pair, placement: Placement) {.inline, noinit.} =
  ## Places the pair.
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
    self[_] += pivot + rotor

func place*(self: var WaterField, pair: Pair, placement: Placement) {.inline, noinit.} =
  ## Places the pair.
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
    self[_] += pivot + rotor

  if not existField[Row.high, pivotCol]:
    staticFor(i, 0 ..< 3):
      self[i].replace pivotCol, self[i].shiftedDownRaw

  if not self.exist[Row.high, rotorCol]:
    staticFor(i, 0 ..< 3):
      self[i].replace rotorCol, self[i].shiftedDownRaw

func place*[F: TsuField or WaterField](
    self: var F, pair: Pair, optPlacement: OptPlacement
) {.inline, noinit.} =
  ## Places the pair.
  ## This function requires that the field is settled.
  if optPlacement.isOk:
    self.place pair, optPlacement.unsafeValue

# ------------------------------------------------
# Pop
# ------------------------------------------------

func pop*[F: TsuField or WaterField](self: var F): PopResult {.inline, noinit.} =
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

  self[0].assign self[0] - poppedColor - (poppedHard + hardToGarbage)
  self[1].assign self[1] + hardToGarbage - (poppedColor + poppedGarbage)
  self[2] -= poppedColor

  PopResult.init(
    poppedR, poppedG, poppedB, poppedY, poppedP, poppedHard, hardToGarbage,
    poppedGarbage, poppedColor,
  )

func canPop*[F: TsuField or WaterField](self: F): bool {.inline, noinit.} =
  ## Returns `true` if any puyos can pop.
  ## Note that this function is only slightly lighter than `pop`.
  self.red.canPop or self.green.canPop or self.blue.canPop or self.yellow.canPop or
    self.purple.canPop

# ------------------------------------------------
# Drop Garbages
# ------------------------------------------------

func dropGarbages*[F: TsuField or WaterField](
    self: var F, counts: array[Col, int], dropHard: bool
) {.inline, noinit.} =
  ## Drops hard or garbage puyos.
  ## This function requires that the field is settled and the counts are non-negative.
  let
    existField = self.exist
    notDropHardInt = (not dropHard).int

  when F is TsuField:
    self[notDropHardInt].dropGarbagesTsu counts, existField
  else:
    self[notDropHardInt].dropGarbagesWater self[dropHard.int],
      self[2], counts, existField

# ------------------------------------------------
# Apply
# ------------------------------------------------

func apply*[F: TsuField or WaterField](self: var F, step: Step) {.inline, noinit.} =
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

func settle*[F: TsuField or WaterField](self: var F) {.inline, noinit.} =
  ## Settles the field.
  when F is TsuField:
    settleTsu(self[0], self[1], self[2], self.exist)
  else:
    settleWater(self[0], self[1], self[2], self.exist)

func isSettled*[F: TsuField or WaterField](self: F): bool {.inline, noinit.} =
  ## Returns `true` if the field is settled.
  ## Note that this function is only slightly lighter than `settle`
  when F is TsuField:
    areSettledTsu(self[0], self[1], self[2], self.exist)
  else:
    areSettledWater(self[0], self[1], self[2], self.exist)

# ------------------------------------------------
# Move
# ------------------------------------------------

const MaxChainCount = Height * Width div 4

template moveImpl[F: TsuField or WaterField](
    self: var F, settleAfterApply, calcConnection: static bool, applyBody: untyped
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

  when calcConnection:
    var fullPopCounts = newSeqOfCap[array[Cell, seq[int]]](MaxChainCount)

  applyBody

  when settleAfterApply:
    self.settle

  while true:
    let popResult = self.pop
    if not popResult.isPopped:
      when calcConnection:
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

    when calcConnection:
      fullPopCounts.add popResult.connectionCounts

  # NOTE: dummy to suppress warning (not reached here)
  MoveResult.init

func move*[F: TsuField or WaterField](
    self: var F, pair: Pair, placement: Placement, calcConnection: static bool = true
): MoveResult {.inline, noinit.} =
  ## Places the pair, advances the field until chains end, and returns a moving result.
  ## This function requires that the field is settled.
  self.moveImpl(settleAfterApply = false, calcConnection = calcConnection):
    self.place pair, placement

func move*[F: TsuField or WaterField](
    self: var F,
    counts: array[Col, int],
    dropHard: bool,
    calcConnection: static bool = true,
): MoveResult {.inline, noinit.} =
  ## Drops hard or garbage puyos, advances the field until chains end, and returns a
  ## moving result.
  ## This function requires that the field is settled and the counts are non-negative.
  self.moveImpl(settleAfterApply = false, calcConnection = calcConnection):
    self.dropGarbages counts, dropHard

func move*[F: TsuField or WaterField](
    self: var F, cross: bool, calcConnection: static bool = true
): MoveResult {.inline, noinit.} =
  ## Rotates the field, advances the field until chains end, and returns a moving
  ## result.
  self.moveImpl(settleAfterApply = true, calcConnection = calcConnection):
    if cross: self.crossRotate else: self.rotate

func move*[F: TsuField or WaterField](
    self: var F, step: Step, calcConnection = true
): MoveResult {.inline, noinit.} =
  ## Applies the step, advances the field until chains end, and returns a moving result.
  ## This function requires that the field is settled.
  if calcConnection:
    if step.kind == Rotate:
      self.moveImpl(settleAfterApply = true, calcConnection = true):
        self.apply step
    else:
      self.moveImpl(settleAfterApply = false, calcConnection = true):
        self.apply step
  else:
    if step.kind == Rotate:
      self.moveImpl(settleAfterApply = true, calcConnection = false):
        self.apply step
    else:
      self.moveImpl(settleAfterApply = false, calcConnection = false):
        self.apply step

# ------------------------------------------------
# Field <-> array
# ------------------------------------------------

func toArray*[F: TsuField or WaterField](
    self: F
): array[Row, array[Col, Cell]] {.inline, noinit.} =
  ## Returns the array converted from the field.
  expand arr:
    let arr = self[_].toArray

  var arr {.noinit.}: array[Row, array[Col, Cell]]
  staticFor(row, Row):
    staticFor(col, Col):
      {.push warning[Uninit]: off.}
      arr[row][col].assign toCell(arr0[row][col], arr1[row][col], arr2[row][col])
      {.pop.}

  arr

func toField[F: TsuField or WaterField](
    cellArray: array[Row, array[Col, Cell]]
): F {.inline, noinit.} =
  ## Returns the field converted from the array.
  var arr0 {.noinit.}, arr1 {.noinit.}, arr2 {.noinit.}: array[Row, array[Col, bool]]

  staticFor(row, Row):
    staticFor(col, Col):
      cellArray[row][col].withBits:
        {.push warning[Uninit]: off.}
        expand arr, bit:
          arr[row][col].assign bit
        {.pop.}

  F.init(arr0.toBinaryField, arr1.toBinaryField, arr2.toBinaryField)

func toTsuField*(arr: array[Row, array[Col, Cell]]): TsuField {.inline, noinit.} =
  ## Returns the Tsu field converted from the array.
  toField[TsuField](arr)

func toWaterField*(arr: array[Row, array[Col, Cell]]): WaterField {.inline, noinit.} =
  ## Returns the Water field converted from the array.
  toField[WaterField](arr)

# ------------------------------------------------
# Field <-> string
# ------------------------------------------------

const
  WaterSep = "~~~~~~"
  LowerAirRow = AirHeight.pred.Row

func toStrImpl[F: TsuField or WaterField](self: F): string {.inline, noinit.} =
  ## Returns the string representation.
  # NOTE: generics `$` does not work
  let arr = self.toArray
  var lines = collect:
    for row in Row:
      join arr[row].mapIt $it

  when F is WaterField:
    lines.insert WaterSep, AirHeight

  lines.join "\n"

func `$`*(self: TsuField): string {.inline, noinit.} =
  self.toStrImpl

func `$`*(self: WaterField): string {.inline, noinit.} =
  self.toStrImpl

func parseField[F: TsuField or WaterField](
    str: string
): StrErrorResult[F] {.inline, noinit.} =
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
      arr[row][col].assign ?($lines[row.ord][col.ord]).parseCell.context "Invalid field: {str}".fmt
      {.pop.}

  ok toField[F](arr)

func parseTsuField*(str: string): StrErrorResult[TsuField] {.inline, noinit.} =
  ## Returns the Tsu field converted from the string representation.
  parseField[TsuField](str)

func parseWaterField*(str: string): StrErrorResult[WaterField] {.inline, noinit.} =
  ## Returns the Water field converted from the string representation.
  parseField[WaterField](str)

# ------------------------------------------------
# Field <-> URI
# ------------------------------------------------

const
  Pon2UriRuleFieldSep = "_"
  Pon2UriAirWaterSep = "~"

  Pon2UriToRule = collect:
    for rule in Rule:
      {$rule: rule}

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

func toUriQueryPon2[F: TsuField or WaterField](
    self: F
): StrErrorResult[string] {.inline, noinit.} =
  ## Returns the URI query converted from the field.
  const
    AirLowerRow = when F is TsuField: Row.high else: AirHeight.pred.Row
    NoneChars = {($None)[0]}
    RuleFieldSep = Pon2UriRuleFieldSep # NOTE: strformat needs this

  let
    arr = self.toArray

    airStrs = collect:
      for row in Row.low .. AirLowerRow:
        for cell in arr[row]:
          $cell
    airStr = airStrs.join.strip(trailing = false, chars = NoneChars)

  when F is TsuField:
    ok "{Tsu}{RuleFieldSep}{airStr}".fmt
  else:
    const AirWaterSep = Pon2UriAirWaterSep # NOTE: strformat needs this

    let
      waterStrs = collect:
        for row in AirLowerRow.succ .. Row.high:
          for cell in arr[row]:
            $cell
      waterStr = waterStrs.join.strip(leading = false, chars = NoneChars)

    ok "{Water}{RuleFieldSep}{airStr}{AirWaterSep}{waterStr}".fmt

func toUriQueryIshikawa(self: TsuField): StrErrorResult[string] {.inline, noinit.} =
  ## Returns the URI query converted from the field.
  let arr = self.toArray

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
          CellToIshikawaIndex[cell1] * static(Cell.enumLen) + CellToIshikawaIndex[cell2]
        ]

      lines.add chars.join

    ok lines.join.strip(trailing = false, chars = {'0'})

func toUriQueryIshikawa(self: WaterField): StrErrorResult[string] {.inline, noinit.} =
  ## Returns the URI query converted from the field.
  err "Water field not supported on Ishikawa/Ips format: {self}".fmt

func toUriQuery*[F: TsuField or WaterField](
    self: F, fqdn = Pon2
): StrErrorResult[string] {.inline, noinit.} =
  ## Returns the URI query converted from the field.
  case fqdn
  of Pon2: self.toUriQueryPon2
  of Ishikawa, Ips: self.toUriQueryIshikawa

func parseFieldPon2[F: TsuField or WaterField](
    query: string
): StrErrorResult[F] {.inline, noinit.} =
  ## Returns the field converted from the URI query.
  when F is TsuField:
    if query == "":
      return ok F.init

  let strs = query.split Pon2UriRuleFieldSep
  if strs.len != 2:
    return err "Invalid field: {query}".fmt

  let rule = ?Pon2UriToRule[strs[0]].context "Invalid field: {query}".fmt

  var arr {.noinit.}: array[Row, array[Col, Cell]]
  when F is TsuField:
    if rule != Tsu:
      return err "Invalid field (incompatible rule): {query}".fmt

    if strs[1].len > Height * Width:
      return err "Invalid field: {query}".fmt

    let airStr = ($None)[0].repeat(Height * Width - strs[1].len) & strs[1]

    staticFor(row, Row):
      staticFor(col, Col):
        arr[row][col].assign ?($airStr[row.ord * Width + col.ord]).parseCell.context "Invalid field: {query}".fmt
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
        arr[row][col].assign ?($airStr[row.ord * Width + col.ord]).parseCell.context "Invalid field: {query}".fmt

    let
      waterStrRaw = airWaterStrs[1]
      waterStr = waterStrRaw & ($None)[0].repeat(WaterHeight * Width - waterStrRaw.len)
    staticFor(row, LowerAirRow.succ .. Row.high):
      staticFor(col, Col):
        arr[row][col].assign ?($waterStr[(row.ord - AirHeight) * Width + col.ord]).parseCell.context "Invalid field: {query}".fmt

  ok toField[F](arr)

func splitByLen(str: string, length: int): seq[string] {.inline, noinit.} =
  ## Returns the strings split by the specified length.
  if str == "":
    @[""]
  else:
    collect:
      for firstIndex in countup(0, str.len.pred, length):
        str.substr(firstIndex, min(firstIndex.succ length, str.len).pred)

func parseTsuFieldIshikawa(query: string): StrErrorResult[TsuField] {.inline, noinit.} =
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
    var arr = static(Row.initArrayWith Col.initArrayWith None)
    for rowIndex, str in strs:
      for colIndex, c in str:
        arr[firstRow.succ rowIndex][Col.low.succ colIndex].assign ?TildeIshikawaCharToCell[
          c
        ].context "Invalid field: {query}".fmt

    ok arr.toTsuField
  else:
    if query.len > Height * Width div 2:
      return err "Invalid field: {query}".fmt

    var arr {.noinit.}: array[Row, array[Col, Cell]]
    for i, c in '0'.repeat(Height * Width div 2 - query.len) & query:
      let
        index = ?IshikawaUriCharToIndex[c].context "Invalid field: {query}".fmt
        (indexQuotient, indexRemainder) = index.divmod static(Cell.enumLen)
        cell1 = ?IshikawaIndexToCell[indexQuotient].context "Invalid field: {query}".fmt
        cell2 =
          ?IshikawaIndexToCell[indexRemainder].context("Invalid field: {query}".fmt)

        (iQuotient, iRemainder) = i.divmod static(Width div 2)
        row = (iQuotient).Row
        col = (iRemainder * 2).Col

      arr[row][col].assign cell1
      arr[row][col.succ].assign cell2

    ok arr.toTsuField

func parseTsuField*(
    query: string, fqdn: SimulatorFqdn
): StrErrorResult[TsuField] {.inline, noinit.} =
  ## Returns the Tsu field converted from the URI query.
  case fqdn
  of Pon2:
    parseFieldPon2[TsuField](query)
  of Ishikawa, Ips:
    query.parseTsuFieldIshikawa

func parseWaterField*(
    query: string, fqdn: SimulatorFqdn
): StrErrorResult[WaterField] {.inline, noinit.} =
  ## Returns the Water field converted from the URI query.
  case fqdn
  of Pon2:
    parseFieldPon2[WaterField](query)
  of Ishikawa, Ips:
    err "Water field not supported on Ishikawa/Ips format: {query}".fmt

## This module implements fields with primitive field.
##

{.experimental: "strictDefs".}

import std/[bitops]
import ./[disappearResult]
import ../[binary]
import ../../../../corepkg/[cell, misc, pair, position]

when defined(cpu32):
  import ./bit32/binary
else:
  import ./bit64/binary

type
  TsuField* = object
    ## Puyo Puyo field with Tsu rule.
    bit2: BinaryField
    bit1: BinaryField
    bit0: BinaryField

  WaterField* = object
    ## Puyo Puyo field with Water rule.
    bit2: BinaryField
    bit1: BinaryField
    bit0: BinaryField

using
  row: Row
  col: Column

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func initZeroField[F: TsuField or WaterField]: F {.inline.} =
  ## Constructor of `Zero***Field`.
  result.bit2 = ZeroBinaryField
  result.bit1 = ZeroBinaryField
  result.bit0 = ZeroBinaryField

const
  ZeroTsuField = initZeroField[TsuField]()
  ZeroWaterField = initZeroField[WaterField]()

func zeroField*[F: TsuField or WaterField]: F {.inline.} =
  ## Returns the field with all elements zero.
  when F is TsuField: ZeroTsuField else: ZeroWaterField

func zeroTsuField*: TsuField {.inline.} = zeroField[TsuField]()
  ## Returns the Tsu field with all elements zero.

func zeroWaterField*: WaterField {.inline.} = zeroField[WaterField]()
  ## Returns the Water field with all elements zero.

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `+`[F: TsuField or WaterField](field1, field2: F): F {.inline.} =
  result.bit2 = field1.bit2 + field2.bit2
  result.bit1 = field1.bit1 + field2.bit1
  result.bit0 = field1.bit0 + field2.bit0

func `*`[F: TsuField or WaterField](field1: F, field2: BinaryField): F
                                   {.inline.} =
  result.bit2 = field1.bit2 * field2
  result.bit1 = field1.bit1 * field2
  result.bit0 = field1.bit0 * field2

func `+=`[F: TsuField or WaterField](field1: var F, field2: F) {.inline.} =
  field1.bit2 += field2.bit2
  field1.bit1 += field2.bit1
  field1.bit0 += field2.bit0

func `-=`[F: TsuField or WaterField](field1: var F, field2: BinaryField)
                                    {.inline.} =
  field1.bit2 -= field2
  field1.bit1 -= field2
  field1.bit0 -= field2

# ------------------------------------------------
# Convert
# ------------------------------------------------

func toTsuField*(self: WaterField): TsuField {.inline.} =
  ## Converts the Water field to the Tsu field.
  result.bit2 = self.bit2
  result.bit1 = self.bit1
  result.bit0 = self.bit0

func toWaterField*(self: TsuField): WaterField {.inline.} =
  ## Converts the Water field to the Water field.
  result.bit2 = self.bit2
  result.bit1 = self.bit1
  result.bit0 = self.bit0

# ------------------------------------------------
# Property
# ------------------------------------------------

func exist*[F: TsuField or WaterField](self: F): BinaryField {.inline.} =
  ## Returns the binary field where any puyo exists.
  sum(self.bit2, self.bit1, self.bit0)

# ------------------------------------------------
# Row, Column
# ------------------------------------------------

func column[F: TsuField or WaterField](self: F; col): F {.inline.} =
  ## Returns the field with only the given column.
  result.bit2 = self.bit2.column col
  result.bit1 = self.bit1.column col
  result.bit0 = self.bit0.column col

func clearColumn[F: TsuField or WaterField](mSelf: var F, col) {.inline.} =
  ## Clears the given column.
  mSelf.bit2.clearColumn col
  mSelf.bit1.clearColumn col
  mSelf.bit0.clearColumn col

# ------------------------------------------------
# Indexer
# ------------------------------------------------

func toCell(bit2, bit1, bit0: bool): Cell {.inline.} =
  ## Converts the bits to the cell.
  Cell.low.succ bit2.int * 4 + bit1.int * 2 + bit0.int
  
func `[]`*[F: TsuField or WaterField](self: F; row, col): Cell {.inline.} =
  toCell(self.bit2[row, col], self.bit1[row, col], self.bit0[row, col])

func toBits(cell: Cell): tuple[bit2: bool, bit1: bool, bit0: bool] {.inline.} =
  ## Returns each bit of the cell.
  let c = cell.int
  result.bit2 = c.testBit 2
  result.bit1 = c.testBit 1
  result.bit0 = c.testBit 0

func `[]=`*[F: TsuField or WaterField](mSelf: var F; row, col; cell: Cell)
                                      {.inline.} =
  let bits = cell.toBits
  mSelf.bit2[row, col] = bits.bit2
  mSelf.bit1[row, col] = bits.bit1
  mSelf.bit0[row, col] = bits.bit0

# ------------------------------------------------
# Insert / RemoveSqueeze
# ------------------------------------------------

func insert[F: TsuField or WaterField](mSelf: var F; row, col; cell: Cell,
                                       insertFn: tsuInsert.type) {.inline.} =
  ## Inserts the cell and shifts the field.
  let bits = cell.toBits

  mSelf.bit2.insertFn row, col, bits.bit2
  mSelf.bit1.insertFn row, col, bits.bit1
  mSelf.bit0.insertFn row, col, bits.bit0

func insert*(mSelf: var TsuField; row, col; cell: Cell) {.inline.} =
  ## Inserts `which` and shifts the field upward above the location
  ## where `which` is inserted.
  mSelf.insert row, col, cell, tsuInsert

func insert*(mSelf: var WaterField; row, col; cell: Cell) {.inline.} =
  ## Inserts `which` and shifts the field and shifts the field.
  ## If `(row, col)` is in the air, shifts the field upward above
  ## the location where inserted.
  ## If it is in the water, shifts the fields downward below the location
  ## where inserted.
  mSelf.insert row, col, cell, waterInsert

func removeSqueeze[F: TsuField or WaterField](
    mSelf: var F; row, col; removeSqueezeFn: tsuRemoveSqueeze.type) {.inline.} =
  ## Removes the cell at `(row, col)` and shifts the field.
  mSelf.bit2.removeSqueezeFn row, col
  mSelf.bit1.removeSqueezeFn row, col
  mSelf.bit0.removeSqueezeFn row, col

func removeSqueeze*(mSelf: var TsuField; row, col) {.inline.} =
  ## Removes the value at `(row, col)` and shifts the field downward
  ## above the location where the cell is removed.
  mSelf.removeSqueeze row, col, tsuRemoveSqueeze

func removeSqueeze*(mSelf: var WaterField; row, col) {.inline.} =
  ## Removes the value at `(row, col)` and shifts the field.
  ## If `(row, col)` is in the air, shifts the field downward above
  ## the location where removed.
  ## If it is in the water, shifts the fields upward below the location
  ## where removed.
  mSelf.removeSqueeze row, col, waterRemoveSqueeze

# ------------------------------------------------
# Puyo Extract
# ------------------------------------------------

func hard[F: TsuField or WaterField](self: F): BinaryField {.inline.} =
  ## Returns the binary field where hard puyos exist.
  self.bit0 - (self.bit2 + self.bit1)

func garbage[F: TsuField or WaterField](self: F): BinaryField {.inline.} =
  ## Returns the binary field where garbage puyos exist.
  self.bit1 - (self.bit2 + self.bit0)

func red[F: TsuField or WaterField](self: F): BinaryField {.inline.} =
  ## Returns the binary field where red puyos exist.
  self.bit1 * self.bit0 - self.bit2

func green[F: TsuField or WaterField](self: F): BinaryField {.inline.} =
  ## Returns the binary field where green puyos exist.
  self.bit2 - (self.bit1 + self.bit0)

func blue[F: TsuField or WaterField](self: F): BinaryField {.inline.} =
  ## Returns the binary field where blue puyos exist.
  self.bit2 * self.bit0 - self.bit1

func yellow[F: TsuField or WaterField](self: F): BinaryField {.inline.} =
  ## Returns the binary field where yellow puyos exist.
  self.bit2 * self.bit1 - self.bit0

func purple[F: TsuField or WaterField](self: F): BinaryField {.inline.} =
  ## Returns the binary field where purple puyos exist.
  prod(self.bit2, self.bit1, self.bit0)

# ------------------------------------------------
# Count - Cell
# ------------------------------------------------

func cellCount*[F: TsuField or WaterField](self: F, cell: Cell): int
                                          {.inline.} =
  ## Returns the number of `cell` in the field.
  case cell
  of None: Height * Width - self.exist.popcnt
  of Hard: self.hard.popcnt
  of Garbage: self.garbage.popcnt
  of Red: self.red.popcnt
  of Green: self.green.popcnt
  of Blue: self.blue.popcnt
  of Yellow: self.yellow.popcnt
  of Purple: self.purple.popcnt

func cellCount*[F: TsuField or WaterField](self: F): int {.inline.} =
  ## Returns the number of cells in the field.
  Height * Width

# ------------------------------------------------
# Count - Puyo
# ------------------------------------------------

func puyoCount*[F: TsuField or WaterField](self: F): int {.inline.} =
  ## Returns the number of puyos in the field.
  self.exist.popcnt

# ------------------------------------------------
# Count - Color
# ------------------------------------------------

func colorCount*[F: TsuField or WaterField](self: F): int {.inline.} = 
  ## Returns the number of color puyos in the field.
  (self.bit2 + self.red).popcnt

# ------------------------------------------------
# Count - Garbage
# ------------------------------------------------
  
func garbageCount*[F: TsuField or WaterField](self: F): int {.inline.} =
  ## Returns the number of garbage puyos in the field.
  popcnt (self.bit0 xor self.bit1) - self.bit2

# ------------------------------------------------
# Connect
# ------------------------------------------------

func connect3*[F: TsuField or WaterField](field: F): F {.inline.} =
  ## Returns the field with only the locations where exactly three color puyos
  ## are connected.
  ## This function ignores ghost puyos.
  field * sum(field.red.connect3, field.green.connect3, field.blue.connect3,
              field.yellow.connect3, field.purple.connect3)

func connect3V*[F: TsuField or WaterField](field: F): F {.inline.} =
  ## Returns the field with only the locations where exactly three color puyos
  ## are connected vertically.
  ## This function ignores ghost puyos.
  field * sum(field.red.connect3V, field.green.connect3V, field.blue.connect3V,
              field.yellow.connect3V, field.purple.connect3V)

func connect3H*[F: TsuField or WaterField](field: F): F {.inline.} =
  ## Returns the field with only the locations where exactly three color puyos
  ## are connected horizontally.
  ## This function ignores ghost puyos.
  field * sum(field.red.connect3H, field.green.connect3H, field.blue.connect3H,
              field.yellow.connect3H, field.purple.connect3H)

func connect3L*[F: TsuField or WaterField](field: F): F {.inline.} =
  ## Returns the field with only the locations where exactly three color puyos
  ## are connected by L-shape.
  ## This function ignores ghost puyos.
  field * sum(field.red.connect3L, field.green.connect3L, field.blue.connect3L,
              field.yellow.connect3L, field.purple.connect3L)

# ------------------------------------------------
# Shift
# ------------------------------------------------

func shiftedUp*[F: TsuField or WaterField](field: F): F {.inline.} =
  ## Returns the field shifted upward.
  result.bit2 = field.bit2.shiftedUp
  result.bit1 = field.bit1.shiftedUp
  result.bit0 = field.bit0.shiftedUp

func shiftedDown*[F: TsuField or WaterField](field: F): F {.inline.} =
  ## Returns the field shifted downward.
  result.bit2 = field.bit2.shiftedDown
  result.bit1 = field.bit1.shiftedDown
  result.bit0 = field.bit0.shiftedDown

func shiftedRight*[F: TsuField or WaterField](field: F): F {.inline.} =
  ## Returns the field shifted rightward.
  result.bit2 = field.bit2.shiftedRight
  result.bit1 = field.bit1.shiftedRight
  result.bit0 = field.bit0.shiftedRight

func shiftedLeft*[F: TsuField or WaterField](field: F): F {.inline.} =
  ## Returns the field shifted leftward.
  result.bit2 = field.bit2.shiftedLeft
  result.bit1 = field.bit1.shiftedLeft
  result.bit0 = field.bit0.shiftedLeft

func shiftedDownWithoutTrim[F: TsuField or WaterField](field: F): F {.inline.} =
  ## Returns the field shifted downward without trimming.
  result.bit2 = field.bit2.shiftedDownWithoutTrim
  result.bit1 = field.bit1.shiftedDownWithoutTrim
  result.bit0 = field.bit0.shiftedDownWithoutTrim

# ------------------------------------------------
# Flip
# ------------------------------------------------

func flippedV*[F: TsuField or WaterField](field: F): F {.inline.} =
  ## Returns the field flipped vertically.
  result.bit2 = field.bit2.flippedV
  result.bit1 = field.bit1.flippedV
  result.bit0 = field.bit0.flippedV

func flippedH*[F: TsuField or WaterField](field: F): F {.inline.} =
  ## Returns the field flipped horizontally.
  result.bit2 = field.bit2.flippedH
  result.bit1 = field.bit1.flippedH
  result.bit0 = field.bit0.flippedH

# ------------------------------------------------
# Disappear
# ------------------------------------------------

func disappear*[F: TsuField or WaterField](mSelf: var F): DisappearResult
                                          {.inline, discardable.} =
  ## Removes puyos that should disappear.
  result.red = mSelf.red.disappeared
  result.green = mSelf.green.disappeared
  result.blue = mSelf.blue.disappeared
  result.yellow = mSelf.yellow.disappeared
  result.purple = mSelf.purple.disappeared

  result.color = sum(result.red, result.green, result.blue, result.yellow,
                     result.purple)
  result.garbage = result.color.expanded * mSelf.garbage

  mSelf -= result.color + result.garbage

func willDisappear*[F: TsuField or WaterField](self: F): bool {.inline.} =
  ## Returns `true` if any puyos will disappear.
  self.red.willDisappear or
  self.green.willDisappear or
  self.blue.willDisappear or
  self.yellow.willDisappear or
  self.purple.willDisappear

# ------------------------------------------------
# Operation
# ------------------------------------------------

func initFillFields[F: TsuField or WaterField]: array[ColorPuyo, F] {.inline.} =
  ## Constructor of `Fill***Fields`.
  result[ColorPuyo.low].bit2 = ZeroBinaryField # dummy to remove warning

  for color in ColorPuyo:
    result[color].bit2 =
      if color.ord.testBit 2: OneBinaryField else: ZeroBinaryField
    result[color].bit1 =
      if color.ord.testBit 1: OneBinaryField else: ZeroBinaryField
    result[color].bit0 =
      if color.ord.testBit 0: OneBinaryField else: ZeroBinaryField

const
  FillTsuFields = initFillFields[TsuField]()
  FillWaterFields = initFillFields[WaterField]()

func put*(mSelf: var TsuField, pair: Pair, pos: Position) {.inline.} =
  ## Puts the pair.
  let
    existField = mSelf.exist
    nextPutMask = existField xor (existField + FloorBinaryField).shiftedUp
    nextPutMasks = [nextPutMask, nextPutMask.shiftedUp]
    axisMask = nextPutMasks[int pos in Down0..Down5].column pos.axisColumn
    childMask = nextPutMasks[int pos in Up0..Up5].column pos.childColumn

  mSelf += FillTsuFields[pair.axis] * axisMask +
    FillTsuFields[pair.child] * childMask

func put*(mSelf: var WaterField, pair: Pair, pos: Position) {.inline.} =
  ## Puts the pair.
  let
    axisCol = pos.axisColumn
    childCol = pos.childColumn

    existField = mSelf.exist
    nextPutMask = (existField xor
      (existField + WaterHighField).shiftedUpWithoutTrim).airTrimmed
    nextPutMasks = [nextPutMask, nextPutMask.shiftedUp]
    axisMask = nextPutMasks[int pos in Down0..Down5].column axisCol
    childMask = nextPutMasks[int pos in Up0..Up5].column childCol

  mSelf += FillWaterFields[pair.axis] * axisMask +
    FillWaterFields[pair.child] * childMask

  let shiftFields1 = [mSelf.shiftedDownWithoutTrim, mSelf]
  mSelf.clearColumn axisCol
  mSelf += shiftFields1[existField.exist(Row.high, axisCol)].column axisCol

  let
    shiftFields2 = [mSelf.shiftedDownWithoutTrim, mSelf]
    existField2 = mSelf.exist
  mSelf.clearColumn childCol
  mSelf += shiftFields2[existField2.exist(Row.high, childCol)].column childCol

func drop*(mSelf: var TsuField) {.inline.} =
  ## Drops floating puyos.
  let mask = mSelf.exist.toDropMask

  mSelf.bit2.drop mask
  mSelf.bit1.drop mask
  mSelf.bit0.drop mask

func drop*(mSelf: var WaterField) {.inline.} =
  ## Drops floating puyos.
  var dropField = mSelf
  block:
    let mask = dropField.exist.toDropMask
    dropField.bit2.drop mask
    dropField.bit1.drop mask
    dropField.bit0.drop mask

  block:
    mSelf.bit2.flipV
    mSelf.bit1.flipV
    mSelf.bit0.flipV

    let mask = mSelf.exist.toDropMask
    mSelf.bit2.drop mask
    mSelf.bit1.drop mask
    mSelf.bit0.drop mask

    mSelf.bit2.flipV
    mSelf.bit1.flipV
    mSelf.bit0.flipV

    mSelf.bit2.shiftDownWithoutTrim Height - WaterHeight
    mSelf.bit1.shiftDownWithoutTrim Height - WaterHeight
    mSelf.bit0.shiftDownWithoutTrim Height - WaterHeight

  let waterDropExistField = mSelf.exist
  mSelf.bit2 = waterDrop(waterDropExistField, dropField.bit2, mSelf.bit2)
  mSelf.bit1 = waterDrop(waterDropExistField, dropField.bit1, mSelf.bit1)
  mSelf.bit0 = waterDrop(waterDropExistField, dropField.bit0, mSelf.bit0)

# ------------------------------------------------
# Field <-> array
# ------------------------------------------------

func toArray*[F: TsuField or WaterField](self: F):
    array[Row, array[Column, Cell]] {.inline.} =
  ## Converts the field to the array.
  let
    arr2 = self.bit2.toArray
    arr1 = self.bit1.toArray
    arr0 = self.bit0.toArray

  result[Row.low][Column.low] = None # dummy to remove warning
  for row in Row.low..Row.high:
    for col in Column.low..Column.high:
      result[row][col] =
        toCell(arr2[row][col], arr1[row][col], arr0[row][col])

func parseField*[F: TsuField or WaterField](
    arr: array[Row, array[Column, Cell]]): F {.inline.} =
  ## Converts the array data to the field.
  var arr2, arr1, arr0: array[Row, array[Column, bool]]
  # dummy to remove warning
  arr2[Row.low][Column.low] = false
  arr1[Row.low][Column.low] = false
  arr0[Row.low][Column.low] = false

  for row in Row.low..Row.high:
    for col in Column.low..Column.high:
      let (bit2, bit1, bit0) = arr[row][col].toBits
      arr2[row][col] = bit2
      arr1[row][col] = bit1
      arr0[row][col] = bit0

  result.bit2 = arr2.parseBinaryField
  result.bit1 = arr1.parseBinaryField
  result.bit0 = arr0.parseBinaryField

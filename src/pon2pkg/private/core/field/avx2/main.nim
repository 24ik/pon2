## This module implements fields with AVX2.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[bitops]
import ./[binary, disappearresult]
import ../[binary as commonBinary]
import ../../../../corepkg/[cell, fieldtype, pair, position]

export binary.`==`

type
  TsuField* = object
    ## Puyo Puyo field with Tsu rule.
    hardGarbage: BinaryField
    noneRed: BinaryField
    greenBlue: BinaryField
    yellowPurple: BinaryField

  WaterField* = object
    ## Puyo Puyo field with Water rule.
    hardGarbage: BinaryField
    noneRed: BinaryField
    greenBlue: BinaryField
    yellowPurple: BinaryField

using
  row: Row
  col: Column

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func zeroField*[F: TsuField or WaterField]: F {.inline.} =
  ## Returns the field with all elements zero.
  result.hardGarbage = zeroBinaryField()
  result.noneRed = zeroBinaryField()
  result.greenBlue = zeroBinaryField()
  result.yellowPurple = zeroBinaryField()

func zeroTsuField*: TsuField {.inline.} = zeroField[TsuField]()
  ## Returns the Tsu field with all elements zero.

func zeroWaterField*: WaterField {.inline.} = zeroField[WaterField]()
  ## Returns the Water field with all elements zero.

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `+=`[F: TsuField or WaterField](field1: var F, field2: F) {.inline.} =
  field1.hardGarbage += field2.hardGarbage
  field1.noneRed += field2.noneRed
  field1.greenBlue += field2.greenBlue
  field1.yellowPurple += field2.yellowPurple

# ------------------------------------------------
# Convert
# ------------------------------------------------

func toTsuField*(self: WaterField): TsuField {.inline.} =
  ## Converts the Water field to the Tsu field.
  result.hardGarbage = self.hardGarbage
  result.noneRed = self.noneRed
  result.greenBlue = self.greenBlue
  result.yellowPurple = self.yellowPurple

func toWaterField*(self: TsuField): WaterField {.inline.} =
  ## Converts the Water field to the Water field.
  result.hardGarbage = self.hardGarbage
  result.noneRed = self.noneRed
  result.greenBlue = self.greenBlue
  result.yellowPurple = self.yellowPurple

# ------------------------------------------------
# Property
# ------------------------------------------------

func exist*(self: TsuField or WaterField): BinaryField {.inline.} =
  ## Returns the binary field where any puyo exists.
  sum(self.hardGarbage, self.noneRed, self.greenBlue, self.yellowPurple).exist

# ------------------------------------------------
# Row, Column
# ------------------------------------------------

func column[F: TsuField or WaterField](self: F; col): F {.inline.} =
  ## Returns the field with only the given column.
  result.hardGarbage = self.hardGarbage.column col
  result.noneRed = self.noneRed.column col
  result.greenBlue = self.greenBlue.column col
  result.yellowPurple = self.yellowPurple.column col

func clearColumn(mSelf: var (TsuField or WaterField); col) {.inline.} =
  ## Clears the given column.
  mSelf.hardGarbage.clearColumn col
  mSelf.noneRed.clearColumn col
  mSelf.greenBlue.clearColumn col
  mSelf.yellowPurple.clearColumn col

# ------------------------------------------------
# Indexer
# ------------------------------------------------

func toCell(hardGarbage, noneRed, greenBlue, yellowPurple: WhichColor): Cell
           {.inline.} =
  ## Converts the values to the cell.
  Cell bitor(
    # digit-0
    hardGarbage.color1.int64, noneRed.color2.int64, greenBlue.color2.int64,
    yellowPurple.color2.int64,
    # digit-1
    bitor(hardGarbage.color2.int64, noneRed.color2.int64,
          yellowPurple.color1.int64, yellowPurple.color2.int64) shl 1,
    # digit-2
    bitor(greenBlue.color1.int64, greenBlue.color2.int64,
          yellowPurple.color1.int64, yellowPurple.color2.int64) shl 2)

func `[]`*(self: TsuField or WaterField; row, col): Cell {.inline.} =
  toCell(self.hardGarbage[row, col], self.noneRed[row, col],
         self.greenBlue[row, col], self.yellowPurple[row, col])

func toWhichColor(cell: Cell): tuple[
    hardGarbage: WhichColor, noneRed: WhichColor, greenBlue: WhichColor,
    yellowPurple: WhichColor] {.inline.} =
  ## Converts the cell to the values.
  let
    c = cell.int64
    bit2: range[0'i64..1'i64] = bitand(c, 4) shr 2
    bit1: range[0'i64..1'i64] = bitand(c, 2) shr 1
    bit0: range[0'i64..1'i64] = bitand(c, 1)
    notBit2: range[0'i64..1'i64] = 1 - bit2
    notBit1: range[0'i64..1'i64] = 1 - bit1
    notBit0: range[0'i64..1'i64] = 1 - bit0

  result.hardGarbage.color1 = bitand(notBit2, notBit1, bit0)
  result.hardGarbage.color2 = bitand(notBit2, bit1, notBit0)
  result.noneRed.color1 = 0'i64
  result.noneRed.color2 = bitand(notBit2, bit1, bit0)
  result.greenBlue.color1 = bitand(bit2, notBit1, notBit0)
  result.greenBlue.color2 = bitand(bit2, notBit1, bit0)
  result.yellowPurple.color1 = bitand(bit2, bit1, notBit0)
  result.yellowPurple.color2 = bitand(bit2, bit1, bit0)

func `[]=`*(mSelf: var (TsuField or WaterField); row, col; cell: Cell)
           {.inline.} =
  let (hardGarbage, noneRed, greenBlue, yellowPurple) = cell.toWhichColor
  mSelf.hardGarbage[row, col] = hardGarbage
  mSelf.noneRed[row, col] = noneRed
  mSelf.greenBlue[row, col] = greenBlue
  mSelf.yellowPurple[row, col] = yellowPurple

# ------------------------------------------------
# Insert / RemoveSqueeze
# ------------------------------------------------

func insert(mSelf: var (TsuField or WaterField); row, col; cell: Cell,
            insertFn: type(tsuInsert)) {.inline.} =
  ## Inserts the cell and shifts the field.
  let (hardGarbage, noneRed, greenBlue, yellowPurple) = cell.toWhichColor

  mSelf.hardGarbage.insertFn row, col, hardGarbage
  mSelf.noneRed.insertFn row, col, noneRed
  mSelf.greenBlue.insertFn row, col, greenBlue
  mSelf.yellowPurple.insertFn row, col, yellowPurple

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

func removeSqueeze(mSelf: var (TsuField or WaterField); row, col;
                   removeSqueezeFn: type(tsuRemoveSqueeze)) {.inline.} =
  ## Removes the cell at `(row, col)` and shifts the field.
  mSelf.hardGarbage.removeSqueezeFn row, col
  mSelf.noneRed.removeSqueezeFn row, col
  mSelf.greenBlue.removeSqueezeFn row, col
  mSelf.yellowPurple.removeSqueezeFn row, col

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
# Count - Puyo
# ------------------------------------------------

func puyoCount*(self: TsuField or WaterField, puyo: Puyo): int {.inline.} =
  ## Returns the number of `puyo` in the field.
  case puyo
  of Hard: self.hardGarbage.popcnt 0
  of Garbage: self.hardGarbage.popcnt 1
  of Red: self.noneRed.popcnt 1
  of Green: self.greenBlue.popcnt 0
  of Blue: self.greenBlue.popcnt 1
  of Yellow: self.yellowPurple.popcnt 0
  of Purple: self.yellowPurple.popcnt 1

func puyoCount*(self: TsuField or WaterField): int {.inline.} =
  ## Returns the number of puyos in the field.
  self.exist.popcnt div 2

# ------------------------------------------------
# Count - Color
# ------------------------------------------------

func colorCount*(self: TsuField or WaterField): int {.inline.} =
  ## Returns the number of color puyos in the field.
  sum(self.noneRed, self.greenBlue, self.yellowPurple).popcnt

# ------------------------------------------------
# Count - Garbage
# ------------------------------------------------

func garbageCount*(self: TsuField or WaterField): int {.inline.} =
  ## Returns the number of garbage puyos in the field.
  self.hardGarbage.popcnt

# ------------------------------------------------
# Connect
# ------------------------------------------------

func connect3*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field with only the locations where exactly three color puyos
  ## are connected.
  ## This function ignores ghost puyos.
  result.noneRed = self.noneRed.connect3
  result.hardGarbage = zeroBinaryField()
  result.greenBlue = self.greenBlue.connect3
  result.yellowPurple = self.yellowPurple.connect3

func connect3V*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field with only the locations where exactly three color puyos
  ## are connected vertically.
  ## This function ignores ghost puyos.
  result.noneRed = self.noneRed.connect3V
  result.hardGarbage = zeroBinaryField()
  result.greenBlue = self.greenBlue.connect3V
  result.yellowPurple = self.yellowPurple.connect3V

func connect3H*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field with only the locations where exactly three color puyos
  ## are connected horizontally.
  ## This function ignores ghost puyos.
  result.noneRed = self.noneRed.connect3H
  result.hardGarbage = zeroBinaryField()
  result.greenBlue = self.greenBlue.connect3H
  result.yellowPurple = self.yellowPurple.connect3H

func connect3L*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field with only the locations where exactly three color puyos
  ## are connected by L-shape.
  ## This function ignores ghost puyos.
  result.noneRed = self.noneRed.connect3L
  result.hardGarbage = zeroBinaryField()
  result.greenBlue = self.greenBlue.connect3L
  result.yellowPurple = self.yellowPurple.connect3L

# ------------------------------------------------
# Shift
# ------------------------------------------------

func shiftedUp*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field shifted upward.
  result.hardGarbage = self.hardGarbage.shiftedUp
  result.noneRed = self.noneRed.shiftedUp
  result.greenBlue = self.greenBlue.shiftedUp
  result.yellowPurple = self.yellowPurple.shiftedUp

func shiftedDown*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field shifted downward.
  result.hardGarbage = self.hardGarbage.shiftedDown
  result.noneRed = self.noneRed.shiftedDown
  result.greenBlue = self.greenBlue.shiftedDown
  result.yellowPurple = self.yellowPurple.shiftedDown

func shiftedRight*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field shifted rightward.
  result.hardGarbage = self.hardGarbage.shiftedRight
  result.noneRed = self.noneRed.shiftedRight
  result.greenBlue = self.greenBlue.shiftedRight
  result.yellowPurple = self.yellowPurple.shiftedRight

func shiftedLeft*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field shifted leftward.
  result.hardGarbage = self.hardGarbage.shiftedLeft
  result.noneRed = self.noneRed.shiftedLeft
  result.greenBlue = self.greenBlue.shiftedLeft
  result.yellowPurple = self.yellowPurple.shiftedLeft

func shiftedDownWithoutTrim[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field shifted downward without trimming.
  result.hardGarbage = self.hardGarbage.shiftedDownWithoutTrim
  result.noneRed = self.noneRed.shiftedDownWithoutTrim
  result.greenBlue = self.greenBlue.shiftedDownWithoutTrim
  result.yellowPurple = self.yellowPurple.shiftedDownWithoutTrim

# ------------------------------------------------
# Flip
# ------------------------------------------------

func flippedV*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field flipped vertically.
  result.hardGarbage = self.hardGarbage.flippedV
  result.noneRed = self.noneRed.flippedV
  result.greenBlue = self.greenBlue.flippedV
  result.yellowPurple = self.yellowPurple.flippedV

func flippedH*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field flipped horizontally.
  result.hardGarbage = self.hardGarbage.flippedH
  result.noneRed = self.noneRed.flippedH
  result.greenBlue = self.greenBlue.flippedH
  result.yellowPurple = self.yellowPurple.flippedH

# ------------------------------------------------
# Disappear
# ------------------------------------------------

func disappear*(mSelf: var (TsuField or WaterField)): DisappearResult
               {.inline, discardable.} =
  ## Removes puyos that should disappear.
  result.red = mSelf.noneRed.disappeared
  result.greenBlue = mSelf.greenBlue.disappeared
  result.yellowPurple = mSelf.yellowPurple.disappeared

  result.color = sum(result.red, result.greenBlue, result.yellowPurple).exist
  result.garbage = result.color.expanded * mSelf.hardGarbage

  mSelf.hardGarbage -= result.garbage
  mSelf.noneRed -= result.red
  mSelf.greenBlue -= result.greenBlue
  mSelf.yellowPurple -= result.yellowPurple

func willDisappear*(self: TsuField or WaterField): bool {.inline.} =
  ## Returns `true` if any puyos will disappear.
  self.greenBlue.willDisappear or
  self.yellowPurple.willDisappear or
  self.noneRed.willDisappear

# ------------------------------------------------
# Operation
# ------------------------------------------------

func put*(mSelf: var TsuField, pair: Pair, pos: Position) {.inline.} =
  ## Puts the pair.
  let
    existField = mSelf.exist
    nextPutMask = existField xor (existField + floorBinaryField()).shiftedUp
    nextPutMasks = [nextPutMask, nextPutMask.shiftedUp]
    axisMask = nextPutMasks[int pos in Down0..Down5].column pos.axisColumn
    childMask = nextPutMasks[int pos in Up0..Up5].column pos.childColumn

    axisWhich = pair.axis.toWhichColor
    childWhich = pair.child.toWhichColor

  mSelf.noneRed += axisMask * axisWhich.noneRed.filled +
    childMask * childWhich.noneRed.filled
  mSelf.greenBlue += axisMask * axisWhich.greenBlue.filled +
    childMask * childWhich.greenBlue.filled
  mSelf.yellowPurple += axisMask * axisWhich.yellowPurple.filled +
    childMask * childWhich.yellowPurple.filled

func put*(mSelf: var WaterField, pair: Pair, pos: Position) {.inline.} =
  ## Puts the pair.
  let
    axisCol = pos.axisColumn
    childCol = pos.childColumn

    existField = mSelf.exist
    nextPutMask = (existField xor
      (existField + waterHighField()).shiftedUpWithoutTrim).airTrimmed
    nextPutMasks = [nextPutMask, nextPutMask.shiftedUp]
    axisMask = nextPutMasks[int pos in Down0..Down5].column axisCol
    childMask = nextPutMasks[int pos in Up0..Up5].column childCol

    axisWhich = pair.axis.toWhichColor
    childWhich = pair.child.toWhichColor

  mSelf.noneRed += axisMask * axisWhich.noneRed.filled +
    childMask * childWhich.noneRed.filled
  mSelf.greenBlue += axisMask * axisWhich.greenBlue.filled +
    childMask * childWhich.greenBlue.filled
  mSelf.yellowPurple += axisMask * axisWhich.yellowPurple.filled +
    childMask * childWhich.yellowPurple.filled

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

  mSelf.hardGarbage.drop mask
  mSelf.noneRed.drop mask
  mSelf.greenBlue.drop mask
  mSelf.yellowPurple.drop mask

func drop*(mSelf: var WaterField) {.inline.} =
  ## Drops floating puyos.
  var dropField = mSelf
  block:
    let mask = dropField.exist.toDropMask
    dropField.hardGarbage.drop mask
    dropField.noneRed.drop mask
    dropField.greenBlue.drop mask
    dropField.yellowPurple.drop mask

  block:
    mSelf.hardGarbage.flipV
    mSelf.noneRed.flipV
    mSelf.greenBlue.flipV
    mSelf.yellowPurple.flipV

    let mask = mSelf.exist.toDropMask
    mSelf.hardGarbage.drop mask
    mSelf.noneRed.drop mask
    mSelf.greenBlue.drop mask
    mSelf.yellowPurple.drop mask

    mSelf.hardGarbage.flipV
    mSelf.noneRed.flipV
    mSelf.greenBlue.flipV
    mSelf.yellowPurple.flipV

    mSelf.hardGarbage.shiftDownWithoutTrim Height - WaterHeight
    mSelf.noneRed.shiftDownWithoutTrim Height - WaterHeight
    mSelf.greenBlue.shiftDownWithoutTrim Height - WaterHeight
    mSelf.yellowPurple.shiftDownWithoutTrim Height - WaterHeight

  let waterDropExistField = mSelf.exist
  mSelf.hardGarbage = waterDrop(
    waterDropExistField, dropField.hardGarbage, mSelf.hardGarbage)
  mSelf.noneRed = waterDrop(
    waterDropExistField, dropField.noneRed, mSelf.noneRed)
  mSelf.greenBlue = waterDrop(
    waterDropExistField, dropField.greenBlue, mSelf.greenBlue)
  mSelf.yellowPurple = waterDrop(
    waterDropExistField, dropField.yellowPurple, mSelf.yellowPurple)

# ------------------------------------------------
# Field <-> array
# ------------------------------------------------

func toArray*(self: TsuField or WaterField): array[Row, array[Column, Cell]]
             {.inline.} =
  ## Converts the field to the array.
  let
    hardGarbage = self.hardGarbage.toArray
    noneRed = self.noneRed.toArray
    greenBlue = self.greenBlue.toArray
    yellowPurple = self.yellowPurple.toArray

  result[Row.low][Column.low] = None # dummy to remove warning
  for row in Row.low..Row.high:
    for col in Column.low..Column.high:
      result[row][col] = toCell(hardGarbage[row][col], noneRed[row][col],
                                greenBlue[row][col], yellowPurple[row][col])

func parseField*[F: TsuField or WaterField](
    arr: array[Row, array[Column, Cell]]): F {.inline.} =
  ## Converts the array to the field.
  var hardGarbageArr, noneRedArr, greenBlueArr, yellowPurpleArr:
    array[Row, array[Column, WhichColor]]
  # dummy to remove warning
  hardGarbageArr[Row.low][Column.low] = WhichColor(color1: 0, color2: 0)
  noneRedArr[Row.low][Column.low] = WhichColor(color1: 0, color2: 0)
  greenBlueArr[Row.low][Column.low] = WhichColor(color1: 0, color2: 0)
  yellowPurpleArr[Row.low][Column.low] = WhichColor(color1: 0, color2: 0)

  for row in Row.low..Row.high:
    for col in Column.low..Column.high:
      let (hardGarbage, noneRed, greenBlue, yellowPurple) =
        arr[row][col].toWhichColor
      hardGarbageArr[row][col] = hardGarbage
      noneRedArr[row][col] = noneRed
      greenBlueArr[row][col] = greenBlue
      yellowPurpleArr[row][col] = yellowPurple

  result.hardGarbage = hardGarbageArr.parseBinaryField
  result.noneRed = noneRedArr.parseBinaryField
  result.greenBlue = greenBlueArr.parseBinaryField
  result.yellowPurple = yellowPurpleArr.parseBinaryField

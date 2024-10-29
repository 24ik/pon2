## This module implements fields with AVX2.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[bitops]
import ./[binary, disappearresult]
import ../[binary as commonBinary]
import ../../../../core/[cell, fieldtype, pair, position]

export binary.`==`

type
  TsuField* = object ## Puyo Puyo field with Tsu rule.
    hardGarbage: BinaryField
    noneRed: BinaryField
    greenBlue: BinaryField
    yellowPurple: BinaryField

  WaterField* = object ## Puyo Puyo field with Water rule.
    hardGarbage: BinaryField
    noneRed: BinaryField
    greenBlue: BinaryField
    yellowPurple: BinaryField

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func initField*[F: TsuField or WaterField](): F {.inline.} =
  ## Returns the field with all cells None.
  F(
    hardGarbage: zeroBinaryField(),
    noneRed: zeroBinaryField(),
    greenBlue: zeroBinaryField(),
    yellowPurple: zeroBinaryField(),
  )

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `+=`[F: TsuField or WaterField](self: var F, field: F) {.inline.} =
  self.hardGarbage += field.hardGarbage
  self.noneRed += field.noneRed
  self.greenBlue += field.greenBlue
  self.yellowPurple += field.yellowPurple

# ------------------------------------------------
# Convert
# ------------------------------------------------

func toTsuField*(self: WaterField): TsuField {.inline.} =
  ## Returns the Tsu field converted from the Water field.
  TsuField(
    hardGarbage: self.hardGarbage,
    noneRed: self.noneRed,
    greenBlue: self.greenBlue,
    yellowPurple: self.yellowPurple,
  )

func toWaterField*(self: TsuField): WaterField {.inline.} =
  ## Returns the Water field converted from the Tsu field.
  WaterField(
    hardGarbage: self.hardGarbage,
    noneRed: self.noneRed,
    greenBlue: self.greenBlue,
    yellowPurple: self.yellowPurple,
  )

# ------------------------------------------------
# Property
# ------------------------------------------------

func exist*(self: TsuField or WaterField): BinaryField {.inline.} =
  ## Returns the binary field where any puyo exists.
  sum(self.hardGarbage, self.noneRed, self.greenBlue, self.yellowPurple).exist

# ------------------------------------------------
# Row, Column
# ------------------------------------------------

func column[F: TsuField or WaterField](self: F, col: Column): F {.inline.} =
  ## Returns the field with only the given column.
  F(
    hardGarbage: self.hardGarbage.column col,
    noneRed: self.noneRed.column col,
    greenBlue: self.greenBlue.column col,
    yellowPurple: self.yellowPurple.column col,
  )

func clearColumn(self: var (TsuField or WaterField), col: Column) {.inline.} =
  ## Clears the given column.
  self.hardGarbage.clearColumn col
  self.noneRed.clearColumn col
  self.greenBlue.clearColumn col
  self.yellowPurple.clearColumn col

# ------------------------------------------------
# Indexer
# ------------------------------------------------

func toCell(
    hardGarbage, noneRed, greenBlue, yellowPurple: WhichColor
): Cell {.inline.} =
  ## Returns the cell converted from which-colors.

  bitor(
    # digit-0
    hardGarbage.color1.int64,
    noneRed.color2.int64,
    greenBlue.color2.int64,
    yellowPurple.color2.int64,
    # digit-1
    bitor(
      hardGarbage.color2.int64, noneRed.color2.int64, yellowPurple.color1.int64,
      yellowPurple.color2.int64,
    ) shl 1,
    # digit-2
    bitor(
      greenBlue.color1.int64, greenBlue.color2.int64, yellowPurple.color1.int64,
      yellowPurple.color2.int64,
    ) shl 2,
  ).Cell

func `[]`*(self: TsuField or WaterField, row: Row, col: Column): Cell {.inline.} =
  toCell(
    self.hardGarbage[row, col],
    self.noneRed[row, col],
    self.greenBlue[row, col],
    self.yellowPurple[row, col],
  )

func toWhichColor(
    cell: Cell
): tuple[
  hardGarbage: WhichColor,
  noneRed: WhichColor,
  greenBlue: WhichColor,
  yellowPurple: WhichColor,
] {.inline.} =
  ## Returns the which-colors converted from the cell.
  let
    c = cell.int64
    bit2: range[0'i64 .. 1'i64] = bitand(c, 4) shr 2
    bit1: range[0'i64 .. 1'i64] = bitand(c, 2) shr 1
    bit0: range[0'i64 .. 1'i64] = bitand(c, 1)
    notBit2: range[0'i64 .. 1'i64] = 1 - bit2
    notBit1: range[0'i64 .. 1'i64] = 1 - bit1
    notBit0: range[0'i64 .. 1'i64] = 1 - bit0

  result = (
    hardGarbage: WhichColor(
      color1: bitand(notBit2, notBit1, bit0), color2: bitand(notBit2, bit1, notBit0)
    ),
    noneRed: WhichColor(color1: 0'i64, color2: bitand(notBit2, bit1, bit0)),
    greenBlue: WhichColor(
      color1: bitand(bit2, notBit1, notBit0), color2: bitand(bit2, notBit1, bit0)
    ),
    yellowPurple:
      WhichColor(color1: bitand(bit2, bit1, notBit0), color2: bitand(bit2, bit1, bit0)),
  )

func `[]=`*(
    self: var (TsuField or WaterField), row: Row, col: Column, cell: Cell
) {.inline.} =
  let (hardGarbage, noneRed, greenBlue, yellowPurple) = cell.toWhichColor
  self.hardGarbage[row, col] = hardGarbage
  self.noneRed[row, col] = noneRed
  self.greenBlue[row, col] = greenBlue
  self.yellowPurple[row, col] = yellowPurple

# ------------------------------------------------
# Insert / RemoveSqueeze
# ------------------------------------------------

func insert(
    self: var (TsuField or WaterField),
    row: Row,
    col: Column,
    cell: Cell,
    insertFn: type(tsuInsert),
) {.inline.} =
  ## Inserts the cell and shifts the field.
  let (hardGarbage, noneRed, greenBlue, yellowPurple) = cell.toWhichColor

  self.hardGarbage.insertFn row, col, hardGarbage
  self.noneRed.insertFn row, col, noneRed
  self.greenBlue.insertFn row, col, greenBlue
  self.yellowPurple.insertFn row, col, yellowPurple

func insert*(self: var TsuField, row: Row, col: Column, cell: Cell) {.inline.} =
  ## Inserts `which` and shifts the field upward above the location
  ## where `which` is inserted.
  self.insert row, col, cell, tsuInsert

func insert*(self: var WaterField, row: Row, col: Column, cell: Cell) {.inline.} =
  ## Inserts `which` and shifts the field and shifts the field.
  ## If `(row, col)` is in the air, shifts the field upward above
  ## the location where inserted.
  ## If it is in the water, shifts the fields downward below the location
  ## where inserted.
  self.insert row, col, cell, waterInsert

func removeSqueeze(
    self: var (TsuField or WaterField),
    row: Row,
    col: Column,
    removeSqueezeFn: type(tsuRemoveSqueeze),
) {.inline.} =
  ## Removes the cell at `(row, col)` and shifts the field.
  self.hardGarbage.removeSqueezeFn row, col
  self.noneRed.removeSqueezeFn row, col
  self.greenBlue.removeSqueezeFn row, col
  self.yellowPurple.removeSqueezeFn row, col

func removeSqueeze*(self: var TsuField, row: Row, col: Column) {.inline.} =
  ## Removes the value at `(row, col)` and shifts the field downward
  ## above the location where the cell is removed.
  self.removeSqueeze row, col, tsuRemoveSqueeze

func removeSqueeze*(self: var WaterField, row: Row, col: Column) {.inline.} =
  ## Removes the value at `(row, col)` and shifts the field.
  ## If `(row, col)` is in the air, shifts the field downward above
  ## the location where removed.
  ## If it is in the water, shifts the fields upward below the location
  ## where removed.
  self.removeSqueeze row, col, waterRemoveSqueeze

# ------------------------------------------------
# Count
# ------------------------------------------------

func puyoCount*(self: TsuField or WaterField, puyo: Puyo): int {.inline.} =
  ## Returns the number of `puyo` in the field.
  case puyo
  of Hard:
    self.hardGarbage.popcnt 0
  of Garbage:
    self.hardGarbage.popcnt 1
  of Red:
    self.noneRed.popcnt 1
  of Green:
    self.greenBlue.popcnt 0
  of Blue:
    self.greenBlue.popcnt 1
  of Yellow:
    self.yellowPurple.popcnt 0
  of Purple:
    self.yellowPurple.popcnt 1

func puyoCount*(self: TsuField or WaterField): int {.inline.} =
  ## Returns the number of puyos in the field.
  self.exist.popcnt div 2

func colorCount*(self: TsuField or WaterField): int {.inline.} =
  ## Returns the number of color puyos in the field.
  sum(self.noneRed, self.greenBlue, self.yellowPurple).popcnt

func garbageCount*(self: TsuField or WaterField): int {.inline.} =
  ## Returns the number of garbage puyos in the field.
  self.hardGarbage.popcnt

# ------------------------------------------------
# Connect
# ------------------------------------------------

func connect2*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field with only the locations where exactly two color puyos
  ## are connected.
  ## This function ignores ghost puyos.
  F(
    noneRed: self.noneRed.connect2,
    hardGarbage: zeroBinaryField(),
    greenBlue: self.greenBlue.connect2,
    yellowPurple: self.yellowPurple.connect2,
  )

func connect2V*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field with only the locations where exactly two color puyos
  ## are connected vertically.
  ## This function ignores ghost puyos.
  F(
    noneRed: self.noneRed.connect2V,
    hardGarbage: zeroBinaryField(),
    greenBlue: self.greenBlue.connect2V,
    yellowPurple: self.yellowPurple.connect2V,
  )

func connect2H*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field with only the locations where exactly two color puyos
  ## are connected horizontally.
  ## This function ignores ghost puyos.
  F(
    noneRed: self.noneRed.connect2H,
    hardGarbage: zeroBinaryField(),
    greenBlue: self.greenBlue.connect2H,
    yellowPurple: self.yellowPurple.connect2H,
  )

func connect3*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field with only the locations where exactly three color puyos
  ## are connected.
  ## This function ignores ghost puyos.
  F(
    noneRed: self.noneRed.connect3,
    hardGarbage: zeroBinaryField(),
    greenBlue: self.greenBlue.connect3,
    yellowPurple: self.yellowPurple.connect3,
  )

func connect3V*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field with only the locations where exactly three color puyos
  ## are connected vertically.
  ## This function ignores ghost puyos.
  F(
    noneRed: self.noneRed.connect3V,
    hardGarbage: zeroBinaryField(),
    greenBlue: self.greenBlue.connect3V,
    yellowPurple: self.yellowPurple.connect3V,
  )

func connect3H*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field with only the locations where exactly three color puyos
  ## are connected horizontally.
  ## This function ignores ghost puyos.
  F(
    noneRed: self.noneRed.connect3H,
    hardGarbage: zeroBinaryField(),
    greenBlue: self.greenBlue.connect3H,
    yellowPurple: self.yellowPurple.connect3H,
  )

func connect3L*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field with only the locations where exactly three color puyos
  ## are connected by L-shape.
  ## This function ignores ghost puyos.
  F(
    noneRed: self.noneRed.connect3L,
    hardGarbage: zeroBinaryField(),
    greenBlue: self.greenBlue.connect3L,
    yellowPurple: self.yellowPurple.connect3L,
  )

# ------------------------------------------------
# Shift
# ------------------------------------------------

func shiftedUp*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field shifted upward.
  F(
    hardGarbage: self.hardGarbage.shiftedUp,
    noneRed: self.noneRed.shiftedUp,
    greenBlue: self.greenBlue.shiftedUp,
    yellowPurple: self.yellowPurple.shiftedUp,
  )

func shiftedDown*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field shifted downward.
  F(
    hardGarbage: self.hardGarbage.shiftedDown,
    noneRed: self.noneRed.shiftedDown,
    greenBlue: self.greenBlue.shiftedDown,
    yellowPurple: self.yellowPurple.shiftedDown,
  )

func shiftedRight*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field shifted rightward.
  F(
    hardGarbage: self.hardGarbage.shiftedRight,
    noneRed: self.noneRed.shiftedRight,
    greenBlue: self.greenBlue.shiftedRight,
    yellowPurple: self.yellowPurple.shiftedRight,
  )

func shiftedLeft*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field shifted leftward.
  F(
    hardGarbage: self.hardGarbage.shiftedLeft,
    noneRed: self.noneRed.shiftedLeft,
    greenBlue: self.greenBlue.shiftedLeft,
    yellowPurple: self.yellowPurple.shiftedLeft,
  )

func shiftedDownWithoutTrim[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field shifted downward without trimming.
  F(
    hardGarbage: self.hardGarbage.shiftedDownWithoutTrim,
    noneRed: self.noneRed.shiftedDownWithoutTrim,
    greenBlue: self.greenBlue.shiftedDownWithoutTrim,
    yellowPurple: self.yellowPurple.shiftedDownWithoutTrim,
  )

# ------------------------------------------------
# Flip
# ------------------------------------------------

func flippedV*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field flipped vertically.
  F(
    hardGarbage: self.hardGarbage.flippedV,
    noneRed: self.noneRed.flippedV,
    greenBlue: self.greenBlue.flippedV,
    yellowPurple: self.yellowPurple.flippedV,
  )

func flippedH*[F: TsuField or WaterField](self: F): F {.inline.} =
  ## Returns the field flipped horizontally.
  F(
    hardGarbage: self.hardGarbage.flippedH,
    noneRed: self.noneRed.flippedH,
    greenBlue: self.greenBlue.flippedH,
    yellowPurple: self.yellowPurple.flippedH,
  )

# ------------------------------------------------
# Disappear
# ------------------------------------------------

func disappear*(
    self: var (TsuField or WaterField)
): DisappearResult {.inline, discardable.} =
  ## Removes puyos that should disappear.
  let
    red = self.noneRed.disappeared
    greenBlue = self.greenBlue.disappeared
    yellowPurple = self.yellowPurple.disappeared

    color = sum(red, greenBlue, yellowPurple).exist
    garbage = color.expanded * self.hardGarbage.visible

  result = DisappearResult(
    red: red,
    greenBlue: greenBlue,
    yellowPurple: yellowPurple,
    color: color,
    garbage: garbage,
  )

  self.hardGarbage -= garbage
  self.noneRed -= red
  self.greenBlue -= greenBlue
  self.yellowPurple -= yellowPurple

func willDisappear*(self: TsuField or WaterField): bool {.inline.} =
  ## Returns `true` if any puyos will disappear.
  self.greenBlue.willDisappear or self.yellowPurple.willDisappear or
    self.noneRed.willDisappear

# ------------------------------------------------
# Operation - Put
# ------------------------------------------------

func put*(self: var TsuField, pair: Pair, pos: Position) {.inline.} =
  ## Puts the pair.
  if pos == Position.None:
    return

  let
    existField = self.exist
    nextPutMask = existField xor (existField + floorBinaryField()).shiftedUp
    nextPutMasks = [nextPutMask, nextPutMask.shiftedUp]
    axisMask = nextPutMasks[int pos in Down0 .. Down5].column pos.axisColumn
    childMask = nextPutMasks[int pos in Up0 .. Up5].column pos.childColumn

    axisWhich = pair.axis.toWhichColor
    childWhich = pair.child.toWhichColor

  self.noneRed +=
    axisMask * axisWhich.noneRed.filled + childMask * childWhich.noneRed.filled
  self.greenBlue +=
    axisMask * axisWhich.greenBlue.filled + childMask * childWhich.greenBlue.filled
  self.yellowPurple +=
    axisMask * axisWhich.yellowPurple.filled + childMask * childWhich.yellowPurple.filled

func put*(self: var WaterField, pair: Pair, pos: Position) {.inline.} =
  ## Puts the pair.
  if pos == Position.None:
    return

  let
    axisCol = pos.axisColumn
    childCol = pos.childColumn

    existField = self.exist
    nextPutMask =
      (existField xor (existField + waterHighField()).shiftedUpWithoutTrim).airTrimmed
    nextPutMasks = [nextPutMask, nextPutMask.shiftedUp]
    axisMask = nextPutMasks[int pos in Down0 .. Down5].column axisCol
    childMask = nextPutMasks[int pos in Up0 .. Up5].column childCol

    axisWhich = pair.axis.toWhichColor
    childWhich = pair.child.toWhichColor

  self.noneRed +=
    axisMask * axisWhich.noneRed.filled + childMask * childWhich.noneRed.filled
  self.greenBlue +=
    axisMask * axisWhich.greenBlue.filled + childMask * childWhich.greenBlue.filled
  self.yellowPurple +=
    axisMask * axisWhich.yellowPurple.filled + childMask * childWhich.yellowPurple.filled

  let shiftFields1 = [self.shiftedDownWithoutTrim, self]
  self.clearColumn axisCol
  self += shiftFields1[existField.exist(Row.high, axisCol)].column axisCol

  let
    shiftFields2 = [self.shiftedDownWithoutTrim, self]
    existField2 = self.exist
  self.clearColumn childCol
  self += shiftFields2[existField2.exist(Row.high, childCol)].column childCol

# ------------------------------------------------
# Operation - Drop
# ------------------------------------------------

func drop*(self: var TsuField) {.inline.} =
  ## Drops floating puyos.
  let mask = self.exist.toDropMask

  self.hardGarbage.drop mask
  self.noneRed.drop mask
  self.greenBlue.drop mask
  self.yellowPurple.drop mask

func drop*(self: var WaterField) {.inline.} =
  ## Drops floating puyos.
  var dropField = self
  block:
    let mask = dropField.exist.toDropMask
    dropField.hardGarbage.drop mask
    dropField.noneRed.drop mask
    dropField.greenBlue.drop mask
    dropField.yellowPurple.drop mask

  block:
    self.hardGarbage.flipV
    self.noneRed.flipV
    self.greenBlue.flipV
    self.yellowPurple.flipV

    let mask = self.exist.toDropMask
    self.hardGarbage.drop mask
    self.noneRed.drop mask
    self.greenBlue.drop mask
    self.yellowPurple.drop mask

    self.hardGarbage.flipV
    self.noneRed.flipV
    self.greenBlue.flipV
    self.yellowPurple.flipV

    self.hardGarbage.shiftDownWithoutTrim Height - WaterHeight
    self.noneRed.shiftDownWithoutTrim Height - WaterHeight
    self.greenBlue.shiftDownWithoutTrim Height - WaterHeight
    self.yellowPurple.shiftDownWithoutTrim Height - WaterHeight

  let waterDropExistField = self.exist
  self.hardGarbage =
    waterDropped(waterDropExistField, dropField.hardGarbage, self.hardGarbage)
  self.noneRed = waterDropped(waterDropExistField, dropField.noneRed, self.noneRed)
  self.greenBlue =
    waterDropped(waterDropExistField, dropField.greenBlue, self.greenBlue)
  self.yellowPurple =
    waterDropped(waterDropExistField, dropField.yellowPurple, self.yellowPurple)

# ------------------------------------------------
# Field <-> array
# ------------------------------------------------

func toArray*(
    self: TsuField or WaterField
): array[Row, array[Column, Cell]] {.inline.} =
  ## Returns the array converted from the field.
  let
    hardGarbage = self.hardGarbage.toArray
    noneRed = self.noneRed.toArray
    greenBlue = self.greenBlue.toArray
    yellowPurple = self.yellowPurple.toArray

  result[Row.low][Column.low] = None # dummy to remove warning
  for row in Row.low .. Row.high:
    for col in Column.low .. Column.high:
      result[row][col] = toCell(
        hardGarbage[row][col],
        noneRed[row][col],
        greenBlue[row][col],
        yellowPurple[row][col],
      )

func parseField*[F: TsuField or WaterField](
    arr: array[Row, array[Column, Cell]]
): F {.inline.} =
  ## Returns the field converted from the array.
  var hardGarbageArr, noneRedArr, greenBlueArr, yellowPurpleArr:
    array[Row, array[Column, WhichColor]]
  # dummy to remove warning
  hardGarbageArr[Row.low][Column.low] = WhichColor(color1: 0, color2: 0)
  noneRedArr[Row.low][Column.low] = WhichColor(color1: 0, color2: 0)
  greenBlueArr[Row.low][Column.low] = WhichColor(color1: 0, color2: 0)
  yellowPurpleArr[Row.low][Column.low] = WhichColor(color1: 0, color2: 0)

  for row in Row.low .. Row.high:
    for col in Column.low .. Column.high:
      let (hardGarbage, noneRed, greenBlue, yellowPurple) = arr[row][col].toWhichColor
      hardGarbageArr[row][col] = hardGarbage
      noneRedArr[row][col] = noneRed
      greenBlueArr[row][col] = greenBlue
      yellowPurpleArr[row][col] = yellowPurple

  result = F(
    hardGarbage: hardGarbageArr.parseBinaryField,
    noneRed: noneRedArr.parseBinaryField,
    greenBlue: greenBlueArr.parseBinaryField,
    yellowPurple: yellowPurpleArr.parseBinaryField,
  )

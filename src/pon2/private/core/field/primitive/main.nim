## This module implements fields with primitive field.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[bitops]
import ./[disappearresult]
import ../[binary]
import ../../../../core/[cell, fieldtype, pair, position]

when defined(cpu32):
  import ./bit32/binary
else:
  import ./bit64/binary

type
  TsuField* = object ## Puyo Puyo field with Tsu rule.
    bit2: BinaryField
    bit1: BinaryField
    bit0: BinaryField

  WaterField* = object ## Puyo Puyo field with Water rule.
    bit2: BinaryField
    bit1: BinaryField
    bit0: BinaryField

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func initZeroField[F: TsuField or WaterField](): F {.inline.} =
  ## Returns `Zero***Field`.
  F(bit2: ZeroBinaryField, bit1: ZeroBinaryField, bit0: ZeroBinaryField)

const
  ZeroTsuField = initZeroField[TsuField]()
  ZeroWaterField = initZeroField[WaterField]()

func initField*[F: TsuField or WaterField](): F {.inline.} =
  ## Returns the field with all cells None.
  when F is TsuField: ZeroTsuField else: ZeroWaterField

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `+`[F: TsuField or WaterField](field1, field2: F): F {.inline.} =
  F(
    bit2: field1.bit2 + field2.bit2,
    bit1: field1.bit1 + field2.bit1,
    bit0: field1.bit0 + field2.bit0,
  )

func `*`[F: TsuField or WaterField](self: F, field: BinaryField): F {.inline.} =
  F(bit2: self.bit2 * field, bit1: self.bit1 * field, bit0: self.bit0 * field)

func `+=`[F: TsuField or WaterField](self: var F, field: F) {.inline.} =
  self.bit2 += field.bit2
  self.bit1 += field.bit1
  self.bit0 += field.bit0

func `-=`[F: TsuField or WaterField](self: var F, field: BinaryField) {.inline.} =
  self.bit2 -= field
  self.bit1 -= field
  self.bit0 -= field

# ------------------------------------------------
# Convert
# ------------------------------------------------

func toTsuField*(self: WaterField): TsuField {.inline.} =
  ## Returns the Tsu field converted from the Water field.
  TsuField(bit2: self.bit2, bit1: self.bit1, bit0: self.bit0)

func toWaterField*(self: TsuField): WaterField {.inline.} =
  ## Returns the Water field converted from the Tsu field.
  WaterField(bit2: self.bit2, bit1: self.bit1, bit0: self.bit0)

# ------------------------------------------------
# Property
# ------------------------------------------------

func exist*(self: TsuField or WaterField): BinaryField {.inline.} =
  ## Returns the binary field where any puyo exists.
  sum(self.bit2, self.bit1, self.bit0)

# ------------------------------------------------
# Row, Column
# ------------------------------------------------

func column[F: TsuField or WaterField](self: F, col: Column): F {.inline.} =
  ## Returns the field with only the given column.
  F(bit2: self.bit2.column col, bit1: self.bit1.column col, bit0: self.bit0.column col)

func clearColumn(self: var (TsuField or WaterField), col: Column) {.inline.} =
  ## Clears the given column.
  self.bit2.clearColumn col
  self.bit1.clearColumn col
  self.bit0.clearColumn col

# ------------------------------------------------
# Indexer
# ------------------------------------------------

func toCell(bit2, bit1, bit0: bool): Cell {.inline.} =
  ## Returns the cell converted from bits.
  Cell.low.succ bit2.int * 4 + bit1.int * 2 + bit0.int

func `[]`*(self: TsuField or WaterField, row: Row, col: Column): Cell {.inline.} =
  toCell(self.bit2[row, col], self.bit1[row, col], self.bit0[row, col])

func toBits(cell: Cell): tuple[bit2: bool, bit1: bool, bit0: bool] {.inline.} =
  ## Returns the bits converted from the cell.
  let c = cell.int
  result = (bit2: c.testBit 2, bit1: c.testBit 1, bit0: c.testBit 0)

func `[]=`*(
    self: var (TsuField or WaterField), row: Row, col: Column, cell: Cell
) {.inline.} =
  let bits = cell.toBits
  self.bit2[row, col] = bits.bit2
  self.bit1[row, col] = bits.bit1
  self.bit0[row, col] = bits.bit0

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
  let bits = cell.toBits

  self.bit2.insertFn row, col, bits.bit2
  self.bit1.insertFn row, col, bits.bit1
  self.bit0.insertFn row, col, bits.bit0

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
  self.bit2.removeSqueezeFn row, col
  self.bit1.removeSqueezeFn row, col
  self.bit0.removeSqueezeFn row, col

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
# Puyo Extract
# ------------------------------------------------

func hard(self: TsuField or WaterField): BinaryField {.inline.} =
  ## Returns the binary field where hard puyos exist.
  self.bit0 - (self.bit2 + self.bit1)

func garbage(self: TsuField or WaterField): BinaryField {.inline.} =
  ## Returns the binary field where garbage puyos exist.
  self.bit1 - (self.bit2 + self.bit0)

func red(self: TsuField or WaterField): BinaryField {.inline.} =
  ## Returns the binary field where red puyos exist.
  self.bit1 * self.bit0 - self.bit2

func green(self: TsuField or WaterField): BinaryField {.inline.} =
  ## Returns the binary field where green puyos exist.
  self.bit2 - (self.bit1 + self.bit0)

func blue(self: TsuField or WaterField): BinaryField {.inline.} =
  ## Returns the binary field where blue puyos exist.
  self.bit2 * self.bit0 - self.bit1

func yellow(self: TsuField or WaterField): BinaryField {.inline.} =
  ## Returns the binary field where yellow puyos exist.
  self.bit2 * self.bit1 - self.bit0

func purple(self: TsuField or WaterField): BinaryField {.inline.} =
  ## Returns the binary field where purple puyos exist.
  prod(self.bit2, self.bit1, self.bit0)

# ------------------------------------------------
# Count
# ------------------------------------------------

func puyoCount*(self: TsuField or WaterField, puyo: Puyo): int {.inline.} =
  ## Returns the number of `puyo` in the field.
  case puyo
  of Hard: self.hard.popcnt
  of Garbage: self.garbage.popcnt
  of Red: self.red.popcnt
  of Green: self.green.popcnt
  of Blue: self.blue.popcnt
  of Yellow: self.yellow.popcnt
  of Purple: self.purple.popcnt

func puyoCount*(self: TsuField or WaterField): int {.inline.} =
  ## Returns the number of puyos in the field.
  self.exist.popcnt

func colorCount*(self: TsuField or WaterField): int {.inline.} =
  ## Returns the number of color puyos in the field.
  (self.bit2 + self.red).popcnt

func garbageCount*(self: TsuField or WaterField): int {.inline.} =
  ## Returns the number of garbage puyos in the field.
  popcnt (self.bit0 xor self.bit1) - self.bit2

# ------------------------------------------------
# Connect
# ------------------------------------------------

func connect2*[F: TsuField or WaterField](field: F): F {.inline.} =
  ## Returns the field with only the locations where exactly two color puyos
  ## are connected.
  ## This function ignores ghost puyos.
  field *
    sum(
      field.red.connect2, field.green.connect2, field.blue.connect2,
      field.yellow.connect2, field.purple.connect2,
    )

func connect2V*[F: TsuField or WaterField](field: F): F {.inline.} =
  ## Returns the field with only the locations where exactly two color puyos
  ## are connected vertically.
  ## This function ignores ghost puyos.
  field *
    sum(
      field.red.connect2V, field.green.connect2V, field.blue.connect2V,
      field.yellow.connect2V, field.purple.connect2V,
    )

func connect2H*[F: TsuField or WaterField](field: F): F {.inline.} =
  ## Returns the field with only the locations where exactly two color puyos
  ## are connected horizontally.
  ## This function ignores ghost puyos.
  field *
    sum(
      field.red.connect2H, field.green.connect2H, field.blue.connect2H,
      field.yellow.connect2H, field.purple.connect2H,
    )

func connect3*[F: TsuField or WaterField](field: F): F {.inline.} =
  ## Returns the field with only the locations where exactly three color puyos
  ## are connected.
  ## This function ignores ghost puyos.
  field *
    sum(
      field.red.connect3, field.green.connect3, field.blue.connect3,
      field.yellow.connect3, field.purple.connect3,
    )

func connect3V*[F: TsuField or WaterField](field: F): F {.inline.} =
  ## Returns the field with only the locations where exactly three color puyos
  ## are connected vertically.
  ## This function ignores ghost puyos.
  field *
    sum(
      field.red.connect3V, field.green.connect3V, field.blue.connect3V,
      field.yellow.connect3V, field.purple.connect3V,
    )

func connect3H*[F: TsuField or WaterField](field: F): F {.inline.} =
  ## Returns the field with only the locations where exactly three color puyos
  ## are connected horizontally.
  ## This function ignores ghost puyos.
  field *
    sum(
      field.red.connect3H, field.green.connect3H, field.blue.connect3H,
      field.yellow.connect3H, field.purple.connect3H,
    )

func connect3L*[F: TsuField or WaterField](field: F): F {.inline.} =
  ## Returns the field with only the locations where exactly three color puyos
  ## are connected by L-shape.
  ## This function ignores ghost puyos.
  field *
    sum(
      field.red.connect3L, field.green.connect3L, field.blue.connect3L,
      field.yellow.connect3L, field.purple.connect3L,
    )

# ------------------------------------------------
# Shift
# ------------------------------------------------

func shiftedUp*[F: TsuField or WaterField](field: F): F {.inline.} =
  ## Returns the field shifted upward.
  F(bit2: field.bit2.shiftedUp, bit1: field.bit1.shiftedUp, bit0: field.bit0.shiftedUp)

func shiftedDown*[F: TsuField or WaterField](field: F): F {.inline.} =
  ## Returns the field shifted downward.
  F(
    bit2: field.bit2.shiftedDown,
    bit1: field.bit1.shiftedDown,
    bit0: field.bit0.shiftedDown,
  )

func shiftedRight*[F: TsuField or WaterField](field: F): F {.inline.} =
  ## Returns the field shifted rightward.
  F(
    bit2: field.bit2.shiftedRight,
    bit1: field.bit1.shiftedRight,
    bit0: field.bit0.shiftedRight,
  )

func shiftedLeft*[F: TsuField or WaterField](field: F): F {.inline.} =
  ## Returns the field shifted leftward.
  F(
    bit2: field.bit2.shiftedLeft,
    bit1: field.bit1.shiftedLeft,
    bit0: field.bit0.shiftedLeft,
  )

func shiftedDownWithoutTrim[F: TsuField or WaterField](field: F): F {.inline.} =
  ## Returns the field shifted downward without trimming.
  F(
    bit2: field.bit2.shiftedDownWithoutTrim,
    bit1: field.bit1.shiftedDownWithoutTrim,
    bit0: field.bit0.shiftedDownWithoutTrim,
  )

# ------------------------------------------------
# Flip
# ------------------------------------------------

func flippedV*[F: TsuField or WaterField](field: F): F {.inline.} =
  ## Returns the field flipped vertically.
  F(bit2: field.bit2.flippedV, bit1: field.bit1.flippedV, bit0: field.bit0.flippedV)

func flippedH*[F: TsuField or WaterField](field: F): F {.inline.} =
  ## Returns the field flipped horizontally.
  F(bit2: field.bit2.flippedH, bit1: field.bit1.flippedH, bit0: field.bit0.flippedH)

# ------------------------------------------------
# Disappear
# ------------------------------------------------

func disappear*(
    self: var (TsuField or WaterField)
): DisappearResult {.inline, discardable.} =
  ## Removes puyos that should disappear.
  let
    red = self.red.disappeared
    green = self.green.disappeared
    blue = self.blue.disappeared
    yellow = self.yellow.disappeared
    purple = self.purple.disappeared

    color = sum(red, green, blue, yellow, purple)
    garbage = color.expanded * self.garbage.visible

  result = DisappearResult(
    red: red,
    green: green,
    blue: blue,
    yellow: yellow,
    purple: purple,
    garbage: garbage,
    color: color,
  )

  self -= color + garbage

func willDisappear*(self: TsuField or WaterField): bool {.inline.} =
  ## Returns `true` if any puyos will disappear.
  self.red.willDisappear or self.green.willDisappear or self.blue.willDisappear or
    self.yellow.willDisappear or self.purple.willDisappear

# ------------------------------------------------
# Operation - Put
# ------------------------------------------------

func initFillFields[F: TsuField or WaterField](): array[ColorPuyo, F] {.inline.} =
  ## Constructor of `Fill***Fields`.
  result[ColorPuyo.low] = initField[F]() # HACK: dummy to suppress warning

  for color in ColorPuyo:
    result[color] = F(
      bit2: if color.ord.testBit 2: OneBinaryField else: ZeroBinaryField,
      bit1: if color.ord.testBit 1: OneBinaryField else: ZeroBinaryField,
      bit0: if color.ord.testBit 0: OneBinaryField else: ZeroBinaryField,
    )

const
  FillTsuFields = initFillFields[TsuField]()
  FillWaterFields = initFillFields[WaterField]()

func put*(self: var TsuField, pair: Pair, pos: Position) {.inline.} =
  ## Puts the pair.
  if pos == Position.None:
    return

  let
    existField = self.exist
    nextPutMask = existField xor (existField + FloorBinaryField).shiftedUp
    nextPutMasks = [nextPutMask, nextPutMask.shiftedUp]
    axisMask = nextPutMasks[int pos in Down0 .. Down5].column pos.axisColumn
    childMask = nextPutMasks[int pos in Up0 .. Up5].column pos.childColumn

  self += FillTsuFields[pair.axis] * axisMask + FillTsuFields[pair.child] * childMask

func put*(self: var WaterField, pair: Pair, pos: Position) {.inline.} =
  ## Puts the pair.
  if pos == Position.None:
    return

  let
    axisCol = pos.axisColumn
    childCol = pos.childColumn

    existField = self.exist
    nextPutMask =
      (existField xor (existField + WaterHighField).shiftedUpWithoutTrim).airTrimmed
    nextPutMasks = [nextPutMask, nextPutMask.shiftedUp]
    axisMask = nextPutMasks[int pos in Down0 .. Down5].column axisCol
    childMask = nextPutMasks[int pos in Up0 .. Up5].column childCol

  self += FillWaterFields[pair.axis] * axisMask + FillWaterFields[pair.child] * childMask

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

  self.bit2.drop mask
  self.bit1.drop mask
  self.bit0.drop mask

func drop*(self: var WaterField) {.inline.} =
  ## Drops floating puyos.
  var dropField = self
  block:
    let mask = dropField.exist.toDropMask
    dropField.bit2.drop mask
    dropField.bit1.drop mask
    dropField.bit0.drop mask

  block:
    self.bit2.flipV
    self.bit1.flipV
    self.bit0.flipV

    let mask = self.exist.toDropMask
    self.bit2.drop mask
    self.bit1.drop mask
    self.bit0.drop mask

    self.bit2.flipV
    self.bit1.flipV
    self.bit0.flipV

    self.bit2.shiftDownWithoutTrim Height - WaterHeight
    self.bit1.shiftDownWithoutTrim Height - WaterHeight
    self.bit0.shiftDownWithoutTrim Height - WaterHeight

  let waterDropExistField = self.exist
  self.bit2 = waterDropped(waterDropExistField, dropField.bit2, self.bit2)
  self.bit1 = waterDropped(waterDropExistField, dropField.bit1, self.bit1)
  self.bit0 = waterDropped(waterDropExistField, dropField.bit0, self.bit0)

# ------------------------------------------------
# Field <-> array
# ------------------------------------------------

func toArray*(
    self: TsuField or WaterField
): array[Row, array[Column, Cell]] {.inline.} =
  ## Returns the array converted from the field.
  let
    arr2 = self.bit2.toArray
    arr1 = self.bit1.toArray
    arr0 = self.bit0.toArray

  result[Row.low][Column.low] = None # HACK: dummy to suppress warning
  for row in Row.low .. Row.high:
    for col in Column.low .. Column.high:
      result[row][col] = toCell(arr2[row][col], arr1[row][col], arr0[row][col])

func parseField*[F: TsuField or WaterField](
    arr: array[Row, array[Column, Cell]]
): F {.inline.} =
  ## Returns the field converted from the array.
  var arr2, arr1, arr0: array[Row, array[Column, bool]]
  # HACK: dummy to suppress warning
  arr2[Row.low][Column.low] = false
  arr1[Row.low][Column.low] = false
  arr0[Row.low][Column.low] = false

  for row in Row.low .. Row.high:
    for col in Column.low .. Column.high:
      let (bit2, bit1, bit0) = arr[row][col].toBits
      arr2[row][col] = bit2
      arr1[row][col] = bit1
      arr0[row][col] = bit0

  result = F(
    bit2: arr2.parseBinaryField,
    bit1: arr1.parseBinaryField,
    bit0: arr0.parseBinaryField,
  )

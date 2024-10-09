## This module implements 32bit binary fields.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[bitops]
import ../../../../[intrinsic]
import ../../../../../core/[fieldtype]

type
  BinaryField* = object
    left: uint32
    center: uint32
    right: uint32

  DropMask* = array[
    Column,
    when UseBmi2:
      uint32
    else:
      PextMask[uint32]
    ,
  ]

const
  ZeroBinaryField* = BinaryField(left: 0'u32, center: 0'u32, right: 0'u32)
    ## Binary field with all elements zero.
  OneBinaryField* =
    BinaryField(left: 0xFFFF_FFFF'u32, center: 0xFFFF_FFFF'u32, right: 0xFFFF_FFFF'u32)
    ## Binary field with all elements one.
  FloorBinaryField* =
    BinaryField(left: 0x0001_0001'u32, center: 0x0001_0001'u32, right: 0x0001_0001'u32)
    ## Binary field with floor bits one.
  WaterHighField* =
    BinaryField(left: 0x0100_0100'u32, center: 0x0100_0100'u32, right: 0x0100_0100'u32)
    ## Binary field with `row==WaterRow.low` bits one.

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `+`*(field1, field2: BinaryField): BinaryField {.inline.} =
  BinaryField(
    left: bitor(field1.left, field2.left),
    center: bitor(field1.center, field2.center),
    right: bitor(field1.right, field2.right),
  )

func `-`*(self, field: BinaryField): BinaryField {.inline.} =
  BinaryField(
    left: self.left.clearMasked field.left,
    center: self.center.clearMasked field.center,
    right: self.right.clearMasked field.right,
  )

func `*`*(field1, field2: BinaryField): BinaryField {.inline.} =
  BinaryField(
    left: bitand(field1.left, field2.left),
    center: bitand(field1.center, field2.center),
    right: bitand(field1.right, field2.right),
  )

func `*`(self: BinaryField, val: uint32): BinaryField {.inline.} =
  BinaryField(
    left: bitand(self.left, val),
    center: bitand(self.center, val),
    right: bitand(self.right, val),
  )

func `xor`*(field1, field2: BinaryField): BinaryField {.inline.} =
  BinaryField(
    left: bitxor(field1.left, field2.left),
    center: bitxor(field1.center, field2.center),
    right: bitxor(field1.right, field2.right),
  )

func `+=`*(self: var BinaryField, field: BinaryField) {.inline.} =
  self.left.setMask field.left
  self.center.setMask field.center
  self.right.setMask field.right

func `-=`*(self: var BinaryField, field: BinaryField) {.inline.} =
  self.left.clearMask field.left
  self.center.clearMask field.center
  self.right.clearMask field.right

func `shl`(self: BinaryField, amount: SomeInteger): BinaryField {.inline.} =
  BinaryField(
    left: self.left shl amount,
    center: self.center shl amount,
    right: self.right shl amount,
  )

func `shr`(self: BinaryField, amount: SomeInteger): BinaryField {.inline.} =
  BinaryField(
    left: self.left shr amount,
    center: self.center shr amount,
    right: self.right shr amount,
  )

func sum*(field1, field2, field3: BinaryField): BinaryField {.inline.} =
  BinaryField(
    left: bitor(field1.left, field2.left, field3.left),
    center: bitor(field1.center, field2.center, field3.center),
    right: bitor(field1.right, field2.right, field3.right),
  )

func sum*(field1, field2, field3, field4: BinaryField): BinaryField {.inline.} =
  BinaryField(
    left: bitor(field1.left, field2.left, field3.left, field4.left),
    center: bitor(field1.center, field2.center, field3.center, field4.center),
    right: bitor(field1.right, field2.right, field3.right, field4.right),
  )

func sum*(field1, field2, field3, field4, field5: BinaryField): BinaryField {.inline.} =
  BinaryField(
    left: bitor(field1.left, field2.left, field3.left, field4.left, field5.left),
    center:
      bitor(field1.center, field2.center, field3.center, field4.center, field5.center),
    right: bitor(field1.right, field2.right, field3.right, field4.right, field5.right),
  )

func sum*(
    field1, field2, field3, field4, field5, field6: BinaryField
): BinaryField {.inline.} =
  BinaryField(
    left: bitor(
      field1.left, field2.left, field3.left, field4.left, field5.left, field6.left
    ),
    center: bitor(
      field1.center, field2.center, field3.center, field4.center, field5.center,
      field6.center,
    ),
    right: bitor(
      field1.right, field2.right, field3.right, field4.right, field5.right, field6.right
    ),
  )

func sum*(
    field1, field2, field3, field4, field5, field6, field7: BinaryField
): BinaryField {.inline.} =
  BinaryField(
    left: bitor(
      field1.left, field2.left, field3.left, field4.left, field5.left, field6.left,
      field7.left,
    ),
    center: bitor(
      field1.center, field2.center, field3.center, field4.center, field5.center,
      field6.center, field7.center,
    ),
    right: bitor(
      field1.right, field2.right, field3.right, field4.right, field5.right,
      field6.right, field7.right,
    ),
  )

func sum*(
    field1, field2, field3, field4, field5, field6, field7, field8: BinaryField
): BinaryField {.inline.} =
  BinaryField(
    left: bitor(
      field1.left, field2.left, field3.left, field4.left, field5.left, field6.left,
      field7.left, field8.left,
    ),
    center: bitor(
      field1.center, field2.center, field3.center, field4.center, field5.center,
      field6.center, field7.center, field8.center,
    ),
    right: bitor(
      field1.right, field2.right, field3.right, field4.right, field5.right,
      field6.right, field7.right, field8.right,
    ),
  )

func prod*(field1, field2, field3: BinaryField): BinaryField {.inline.} =
  BinaryField(
    left: bitand(field1.left, field2.left, field3.left),
    center: bitand(field1.center, field2.center, field3.center),
    right: bitand(field1.right, field2.right, field3.right),
  )

# ------------------------------------------------
# Population Count
# ------------------------------------------------

func popcnt*(self: BinaryField): int {.inline.} =
  ## Population count.
  self.left.popcount + self.center.popcount + self.right.popcount

# ------------------------------------------------
# Trim
# ------------------------------------------------

func trimmed*(self: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field with padding cleared.
  const Mask = 0x3FFE_3FFE'u32

  result = self * BinaryField(left: Mask, center: Mask, right: Mask)

func visible*(self: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field with only the visible area.
  const Mask = 0x1FFE_1FFE'u32

  result = self * BinaryField(left: Mask, center: Mask, right: Mask)

func airTrimmed*(self: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field with only the air area in the Water rule.
  const Mask = 0x3E00_3E00'u32

  result = self * BinaryField(left: Mask, center: Mask, right: Mask)

# ------------------------------------------------
# Row, Column
# ------------------------------------------------

const ColMasks: array[Column, BinaryField] = [
  BinaryField(left: 0xFFFF_0000'u32, center: 0'u32, right: 0'u32),
  BinaryField(left: 0x0000_FFFF'u32, center: 0'u32, right: 0'u32),
  BinaryField(left: 0'u32, center: 0xFFFF_0000'u32, right: 0'u32),
  BinaryField(left: 0'u32, center: 0x0000_FFFF'u32, right: 0'u32),
  BinaryField(left: 0'u32, center: 0'u32, right: 0xFFFF_0000'u32),
  BinaryField(left: 0'u32, center: 0'u32, right: 0x0000_FFFF'u32),
]

func row*(self: BinaryField, row: Row): BinaryField {.inline.} =
  ## Returns the binary field with only the given row.
  self * (0x2000_2000'u32 shr row)

func column*(self: BinaryField, col: Column): BinaryField {.inline.} =
  ## Returns the binary field with only the given column.
  self * ColMasks[col]

func clearColumn*(self: var BinaryField, col: Column) {.inline.} =
  ## Clears the given column.
  self -= self.column col

# ------------------------------------------------
# Indexer
# ------------------------------------------------

func leftCenterRightMasks(
    col: Column
): tuple[left: uint32, center: uint32, right: uint32] {.inline.} =
  ## Returns `(l, c, r)`; among `l`, `c`, and `r`,
  ## those corresponding to `col` is `uint32.high`, and the rest are `0`.
  let
    left = [uint32.high, uint32.high, 0, 0, 0, 0][col]
    right = cast[uint32](-(bitand(col.int32, 4) shr 2))

  result = (left: left, center: uint32.high - left - right, right: right)

func cellMasks(
    row: Row, col: Column
): tuple[left: uint32, center: uint32, right: uint32] {.inline.} =
  ## Returns three masks with only the bit at position `(row, col)` set to `1`.
  const Mask = 0x2000_0000'u32

  let (leftMask, centerMask, rightMask) = col.leftCenterRightMasks
  result = (
    left: bitand(Mask shr (16 * col + row), leftMask),
    center: bitand(Mask shr (16 * (col - 2) + row), centerMask),
    right: bitand(Mask shr (16 * (col - 4) + row), rightMask),
  )

func `[]`*(self: BinaryField, row: Row, col: Column): bool {.inline.} =
  let (leftMask, centerMask, rightMask) = cellMasks(row, col)
  result = bitor(
    bitand(self.left, leftMask),
    bitand(self.center, centerMask),
    bitand(self.right, rightMask),
  ).bool

func exist*(self: BinaryField, row: Row, col: Column): int {.inline.} =
  ## Returns `1` if the bit `(row, col)` is set; otherwise, returns `0`.
  self[row, col].int

func `[]=`*(self: var BinaryField, row: Row, col: Column, val: bool) {.inline.} =
  let
    (leftMask, centerMask, rightMask) = cellMasks(row, col)
    cellMask = BinaryField(left: leftMask, center: centerMask, right: rightMask)

  self = self - cellMask + cellMask * cast[uint32](-val.int32)

# ------------------------------------------------
# Insert / RemoveSqueeze
# ------------------------------------------------

func aboveMasks(
    row: Row, col: Column
): tuple[left: uint32, center: uint32, right: uint32] {.inline.} =
  ## Returns three masks with only the bits above `(row, col)` set to `1`.
  ## Including `(row, col)`.
  let (leftMask, centerMask, rightMask) = col.leftCenterRightMasks
  result = (
    left: bitand(
      uint32.high.masked 16 * (1 - col) + Row.high - row + 1 ..< 16 * (2 - col),
      leftMask,
    ),
    center: bitand(
      uint32.high.masked 16 * (3 - col) + Row.high - row + 1 ..< 16 * (4 - col),
      centerMask,
    ),
    right: bitand(
      uint32.high.masked 16 * (5 - col) + Row.high - row + 1 ..< 16 * (6 - col),
      rightMask,
    ),
  )

func belowMasks(
    row: Row, col: Column
): tuple[left: uint32, center: uint32, right: uint32] {.inline.} =
  ## Returns three masks with only the bits below `(row, col)` set to `1`.
  ## Including `(row, col)`.
  let (leftMask, centerMask, rightMask) = col.leftCenterRightMasks
  result = (
    left: bitand(
      uint32.high.masked 16 * (1 - col) .. 16 * (1 - col) + Row.high - row + 1, leftMask
    ),
    center: bitand(
      uint32.high.masked 16 * (3 - col) .. 16 * (3 - col) + Row.high - row + 1,
      centerMask,
    ),
    right: bitand(
      uint32.high.masked 16 * (5 - col) .. 16 * (5 - col) + Row.high - row + 1,
      rightMask,
    ),
  )

func tsuInsert*(self: var BinaryField, row: Row, col: Column, val: bool) {.inline.} =
  ## Inserts `val` and shifts the binary field upward
  ## above the location where `val` is inserted.
  let
    (leftMask, centerMask, rightMask) = aboveMasks(row, col)
    moveMask = BinaryField(left: leftMask, center: centerMask, right: rightMask)
    moveField = BinaryField(
      left: bitand(self.left, leftMask),
      center: bitand(self.center, centerMask),
      right: bitand(self.right, rightMask),
    )

  self = sum(
    self - moveField,
    moveField shl 1,
    (moveMask xor (moveMask shl 1)) * cast[uint32](-val.int32),
  ).trimmed

func waterInsert*(self: var BinaryField, row: Row, col: Column, val: bool) {.inline.} =
  ## Inserts `val` and shifts the field and shifts the field.
  ## If `(row, col)` is in the air, shifts the field upward above
  ## the location where inserted.
  ## If it is in the water, shifts the fields dwonward below the location
  ## where inserted.
  let
    # air: above, upward
    (leftMaskAir, centerMaskAir, rightMaskAir) = aboveMasks(row, col)
    moveMaskAir =
      BinaryField(left: leftMaskAir, center: centerMaskAir, right: rightMaskAir)
    moveFieldAir = BinaryField(
      left: bitand(self.left, leftMaskAir),
      center: bitand(self.center, centerMaskAir),
      right: bitand(self.right, rightMaskAir),
    )
    addFieldAir =
      moveFieldAir shl 1 +
      (moveMaskAir xor (moveMaskAir shl 1)) * cast[uint32](-val.int32)

    # water: below, downward
    (leftMaskWater, centerMaskWater, rightMaskWater) = belowMasks(row, col)
    moveMaskWater =
      BinaryField(left: leftMaskWater, center: centerMaskWater, right: rightMaskWater)
    moveFieldWater = BinaryField(
      left: bitand(self.left, leftMaskWater),
      center: bitand(self.center, centerMaskWater),
      right: bitand(self.right, rightMaskWater),
    )
    addFieldWater =
      moveFieldWater shr 1 +
      (moveMaskWater xor (moveMaskWater shr 1)) * cast[uint32](-val.int32)

    insertIntoAir = int row in AirRow.low .. AirRow.high
    removeField = [moveFieldWater, moveFieldAir][insertIntoAir]
    addField = [addFieldWater, addFieldAir][insertIntoAir]

  self = (self - removeField + addField).trimmed

func tsuRemoveSqueeze*(self: var BinaryField, row: Row, col: Column) {.inline.} =
  ## Removes the value at `(row, col)` and shifts the binary field downward
  ## above the location where the cell is removed.
  let
    (leftMask, centerMask, rightMask) = aboveMasks(row, col)
    moveMask = BinaryField(left: leftMask, center: centerMask, right: rightMask)
    moveField = BinaryField(
      left: bitand(self.left, leftMask),
      center: bitand(self.center, centerMask),
      right: bitand(self.right, rightMask),
    )

  self = self - moveField + (moveField - (moveMask xor (moveMask shl 1))) shr 1

func waterRemoveSqueeze*(self: var BinaryField, row: Row, col: Column) {.inline.} =
  ## Removes the value at `(row, col)` and shifts the field.
  ## If `(row, col)` is in the air, shifts the field downward above
  ## the location where removed.
  ## If it is in the water, shifts the fields upward below the location
  ## where removed.
  let
    # air: above, downward
    (leftMaskAir, centerMaskAir, rightMaskAir) = aboveMasks(row, col)
    moveMaskAir =
      BinaryField(left: leftMaskAir, center: centerMaskAir, right: rightMaskAir)
    moveFieldAir = BinaryField(
      left: bitand(self.left, leftMaskAir),
      center: bitand(self.center, centerMaskAir),
      right: bitand(self.right, rightMaskAir),
    )
    addFieldAir = (moveFieldAir - (moveMaskAir xor (moveMaskAir shl 1))) shr 1

    # water: below, upward
    (leftMaskWater, centerMaskWater, rightMaskWater) = belowMasks(row, col)
    moveMaskWater =
      BinaryField(left: leftMaskWater, center: centerMaskWater, right: rightMaskWater)
    moveFieldWater = BinaryField(
      left: bitand(self.left, leftMaskWater),
      center: bitand(self.center, centerMaskWater),
      right: bitand(self.right, rightMaskWater),
    )
    addFieldWater = (moveFieldWater - (moveMaskWater xor (moveMaskWater shr 1))) shl 1

    insertIntoAir = int row in AirRow.low .. AirRow.high
    removeField = [moveFieldWater, moveFieldAir][insertIntoAir]
    addField = [addFieldWater, addFieldAir][insertIntoAir]

  self = self - removeField + addField

# ------------------------------------------------
# Property
# ------------------------------------------------

func isZero*(self: BinaryField): bool {.inline.} =
  ## Returns `true` if all elements are zero.
  self == ZeroBinaryField

# ------------------------------------------------
# Shift
# ------------------------------------------------

func shiftedUpWithoutTrim*(self: BinaryField, amount = 1'i32): BinaryField {.inline.} =
  ## Returns the binary field shifted upward.
  self shl amount

func shiftedDownWithoutTrim*(
    self: BinaryField, amount = 1'i32
): BinaryField {.inline.} =
  ## Returns the binary field shifted downward.
  self shr amount

func shiftedRightWithoutTrim*(self: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field shifted rightward.
  BinaryField(
    left: self.left shr 16,
    center: bitor(self.center shr 16, self.left shl 16),
    right: bitor(self.right shr 16, self.center shl 16),
  )

func shiftedLeftWithoutTrim*(self: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field shifted leftward.
  BinaryField(
    left: bitor(self.left shl 16, self.center shr 16),
    center: bitor(self.center shl 16, self.right shr 16),
    right: self.right shl 16,
  )

# ------------------------------------------------
# Flip
# ------------------------------------------------

func flipCol(val: uint32): uint32 {.inline.} =
  ## Returns the value by flipping two columns.
  bitor(val.bitsliced 16 ..< 32, val shl 16)

func flippedV*(self: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field flipped vertically.
  BinaryField(
    left: self.left.reverseBits.flipCol shr 1,
    center: self.center.reverseBits.flipCol shr 1,
    right: self.right.reverseBits.flipCol shr 1,
  )

func flippedH*(self: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field flipped horizontally.
  BinaryField(
    left: self.right.flipCol, center: self.center.flipCol, right: self.left.flipCol
  )

# ------------------------------------------------
# Operation
# ------------------------------------------------

func toColumnArray(self: BinaryField): array[Column, uint32] {.inline.} =
  ## Returns the integer array converted from the field.
  result[0] = self.left.bitsliced 17 ..< 32
  result[1] = self.left.bitsliced 1 ..< 16
  result[2] = self.center.bitsliced 17 ..< 32
  result[3] = self.center.bitsliced 1 ..< 16
  result[4] = self.right.bitsliced 17 ..< 32
  result[5] = self.right.bitsliced 1 ..< 16

func toDropMask*(existField: BinaryField): DropMask {.inline.} =
  ## Returns a drop mask converted from the exist field.
  let existFloor = (existField + FloorBinaryField).toColumnArray

  result[Column.low] = when UseBmi2: 0 else: 0'u32.toPextMask
    # HACK: dummy to suppress warning
  for col in Column.low .. Column.high:
    result[col] =
      when UseBmi2:
        existFloor[col]
      else:
        existFloor[col].toPextMask

func drop*(self: var BinaryField, mask: DropMask) {.inline.} =
  ## Drops floating cells.
  let arr = self.toColumnArray

  self.left = bitor(arr[0].pext(mask[0]) shl 17, arr[1].pext(mask[1]) shl 1)
  self.center = bitor(arr[2].pext(mask[2]) shl 17, arr[3].pext(mask[3]) shl 1)
  self.right = bitor(arr[4].pext(mask[4]) shl 17, arr[5].pext(mask[5]) shl 1)

func waterDropped*(
    waterDropExistField, dropField, waterDropField: BinaryField
): BinaryField {.inline.} =
  ## Drops floating cells in Water rule.
  let
    left = bitor(
      bitand(0xFFFF'u32, cast[uint32](-waterDropExistField.exist(Row.high, 0).int32)) shl
        16,
      bitand(0xFFFF'u32, cast[uint32](-waterDropExistField.exist(Row.high, 1).int32)),
    )
    center = bitor(
      bitand(0xFFFF'u32, cast[uint32](-waterDropExistField.exist(Row.high, 2).int32)) shl
        16,
      bitand(0xFFFF'u32, cast[uint32](-waterDropExistField.exist(Row.high, 3).int32)),
    )
    right = bitor(
      bitand(0xFFFF'u32, cast[uint32](-waterDropExistField.exist(Row.high, 4).int32)) shl
        16,
      bitand(0xFFFF'u32, cast[uint32](-waterDropExistField.exist(Row.high, 5).int32)),
    )
    notLeft = left.bitnot
    notCenter = center.bitnot
    notRight = right.bitnot

  result =
    dropField * BinaryField(left: left, center: center, right: right) +
    waterDropField * BinaryField(left: notLeft, center: notCenter, right: notRight)

# ------------------------------------------------
# BinaryField <-> array
# ------------------------------------------------

func toArray*(self: BinaryField): array[Row, array[Column, bool]] {.inline.} =
  ## Returns the array converted from the field.
  result[Row.low][Column.low] = false # HACK: dummy to suppress warning
  for row in Row.low .. Row.high:
    result[row][0] = self.left.testBit 29 - row
    result[row][1] = self.left.testBit 13 - row
    result[row][2] = self.center.testBit 29 - row
    result[row][3] = self.center.testBit 13 - row
    result[row][4] = self.right.testBit 29 - row
    result[row][5] = self.right.testBit 13 - row

func parseBinaryField*(arr: array[Row, array[Column, bool]]): BinaryField {.inline.} =
  ## Returns the field converted from the array.
  result = BinaryField(left: 0, center: 0, right: 0)

  for row, line in arr:
    for col in 0 ..< 2:
      result.left.setMask line[col].uint32 shl (29 - col * 16 - row)
    for col in 2 ..< 4:
      result.center.setMask line[col].uint32 shl (61 - col * 16 - row)
    for col in 4 ..< 6:
      result.right.setMask line[col].uint32 shl (93 - col * 16 - row)

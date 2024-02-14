## This module implements 64bit binary fields.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[bitops]
import ../../../../[intrinsic]
import ../../../../../corepkg/[fieldtype]

type
  BinaryField* = object
    left: uint64
    right: uint64

  DropMask* = array[
    Column,
    when UseBmi2:
      uint64
    else:
      PextMask[uint64]
    ,
  ]

const
  ZeroBinaryField* = BinaryField(left: 0'u64, right: 0'u64)
    ## Binary field with all elements zero.
  OneBinaryField* =
    BinaryField(left: 0xFFFF_FFFF_FFFF_FFFF'u64, right: 0xFFFF_FFFF_FFFF_FFFF'u64)
    ## Binary field with all elements one.
  FloorBinaryField* =
    BinaryField(left: 0x0001_0001_0001_0001'u64, right: 0x0001_0001_0001_0001'u64)
    ## Binary field with floor bits one.
  WaterHighField* =
    BinaryField(left: 0x0100_0100_0100_0100'u64, right: 0x0100_0100_0100_0100'u64)
    ## Binary field with `row==WaterRow.low` bits one.

using
  self: BinaryField
  mSelf: var BinaryField

  row: Row
  col: Column

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `+`*(self; field: BinaryField): BinaryField {.inline.} =
  result.left = bitor(self.left, field.left)
  result.right = bitor(self.right, field.right)

func `-`*(self; field: BinaryField): BinaryField {.inline.} =
  result.left = self.left.clearMasked field.left
  result.right = self.right.clearMasked field.right

func `*`*(self; field: BinaryField): BinaryField {.inline.} =
  result.left = bitand(self.left, field.left)
  result.right = bitand(self.right, field.right)

func `*`(self; val: uint64): BinaryField {.inline.} =
  result.left = bitand(self.left, val)
  result.right = bitand(self.right, val)

func `xor`*(self; field: BinaryField): BinaryField {.inline.} =
  result.left = bitxor(self.left, field.left)
  result.right = bitxor(self.right, field.right)

func `+=`*(mSelf; field: BinaryField) {.inline.} =
  mSelf.left.setMask field.left
  mSelf.right.setMask field.right

func `-=`*(mSelf; field: BinaryField) {.inline.} =
  mSelf.left.clearMask field.left
  mSelf.right.clearMask field.right

func `shl`(self; amount: SomeInteger): BinaryField {.inline.} =
  result.left = self.left shl amount
  result.right = self.right shl amount

func `shr`(self; amount: SomeInteger): BinaryField {.inline.} =
  result.left = self.left shr amount
  result.right = self.right shr amount

func sum*(field1, field2, field3: BinaryField): BinaryField {.inline.} =
  result.left = bitor(field1.left, field2.left, field3.left)
  result.right = bitor(field1.right, field2.right, field3.right)

func sum*(field1, field2, field3, field4, field5: BinaryField): BinaryField {.inline.} =
  result.left = bitor(field1.left, field2.left, field3.left, field4.left, field5.left)
  result.right =
    bitor(field1.right, field2.right, field3.right, field4.right, field5.right)

func sum*(
    field1, field2, field3, field4, field5, field6, field7: BinaryField
): BinaryField {.inline.} =
  result.left = bitor(
    field1.left, field2.left, field3.left, field4.left, field5.left, field6.left,
    field7.left
  )
  result.right = bitor(
    field1.right, field2.right, field3.right, field4.right, field5.right, field6.right,
    field7.right
  )

func sum*(
    field1, field2, field3, field4, field5, field6, field7, field8: BinaryField
): BinaryField {.inline.} =
  result.left = bitor(
    field1.left, field2.left, field3.left, field4.left, field5.left, field6.left,
    field7.left, field8.left
  )
  result.right = bitor(
    field1.right, field2.right, field3.right, field4.right, field5.right, field6.right,
    field7.right, field8.right
  )

func prod*(field1, field2, field3: BinaryField): BinaryField {.inline.} =
  result.left = bitand(field1.left, field2.left, field3.left)
  result.right = bitand(field1.right, field2.right, field3.right)

# ------------------------------------------------
# Population Count
# ------------------------------------------------

func popcnt*(self): int {.inline.} = ## Population count.
  self.left.popcount + self.right.popcount

# ------------------------------------------------
# Trim
# ------------------------------------------------

func trimmed*(self): BinaryField {.inline.} =
  ## Returns the binary field with padding cleared.
  self * BinaryField(left: 0x0000_3FFE_3FFE_3FFE'u64, right: 0x3FFE_3FFE_3FFE_0000'u64)

func visible*(self): BinaryField {.inline.} =
  ## Returns the binary field with only the visible area.
  self * BinaryField(left: 0x0000_1FFE_1FFE_1FFE'u64, right: 0x1FFE_1FFE_1FFE_0000'u64)

func airTrimmed*(self): BinaryField {.inline.} =
  ## Returns the binary field with only the air area in the Water rule.
  self * BinaryField(left: 0x0000_3E00_3E00_3E00'u64, right: 0x3E00_3E00_3E00_0000'u64)

# ------------------------------------------------
# Row, Column
# ------------------------------------------------

const ColMasks: array[Column, BinaryField] = [
  BinaryField(left: 0x0000_FFFF_0000_0000'u64, right: 0'u64),
  BinaryField(left: 0x0000_0000_FFFF_0000'u64, right: 0'u64),
  BinaryField(left: 0x0000_0000_0000_FFFF'u64, right: 0'u64),
  BinaryField(left: 0'u64, right: 0xFFFF_0000_0000_0000'u64),
  BinaryField(left: 0'u64, right: 0x0000_FFFF_0000_0000'u64),
  BinaryField(left: 0'u64, right: 0x0000_0000_FFFF_0000'u64)
]

func row*(self, row): BinaryField {.inline.} =
  ## Returns the binary field with only the row `row`.
  self *
    BinaryField(
      left: 0x0000_2000_2000_2000'u64 shr row, right: 0x2000_2000_2000_0000'u64 shr row
    )

func column*(self, col): BinaryField {.inline.} =
  ## Returns the binary field with only the given column.
  self * ColMasks[col]

func clearColumn*(mSelf, col) {.inline.} =
  mSelf -= mSelf.column col ## Clears the given column.

# ------------------------------------------------
# Indexer
# ------------------------------------------------

func leftRightMasks(col): tuple[left: uint64, right: uint64] {.inline.} =
  ## Returns `(uint64.high, 0)` if `col` is in {0, 1, 2};
  ## otherwise returns `(0, uint64.high)`.
  let left = [uint64.high, uint64.high, uint64.high, 0, 0, 0][col]
  result.left = left
  result.right = uint64.high - left

func cellMasks(row, col): tuple[left: uint64, right: uint64] {.inline.} =
  ## Returns two masks with only the bit at position `(row, col)` set to `1`.
  let (leftMask, rightMask) = col.leftRightMasks
  result.left = (0x0000_2000_0000_0000'u64 shr (16 * col + row)) and leftMask
  result.right = (0x2000_0000_0000_0000'u64 shr (16 * (col - 3) + row)) and rightMask

func `[]`*(self, row, col): bool {.inline.} =
  let (leftMask, rightMask) = cellMasks(row, col)
  result = bool bitor(bitand(self.left, leftMask), bitand(self.right, rightMask))

func exist*(self, row, col): int {.inline.} =
  ## Returns `1` if the bit `(row, col)` is set; otherwise, returns `0`.
  int self[row, col]

func `[]=`*(mSelf; row; col; val: bool) {.inline.} =
  let
    (leftMask, rightMask) = cellMasks(row, col)
    cellMask = BinaryField(left: leftMask, right: rightMask)

  mSelf = mSelf - cellMask + cellMask * cast[uint64](-val.int64)

# ------------------------------------------------
# Insert / RemoveSqueeze
# ------------------------------------------------

func aboveMasks(row, col): tuple[left: uint64, right: uint64] {.inline.} =
  ## Returns two masks with only the bits above `(row, col)` set to `1`.
  ## Including `(row, col)`.
  let (leftMask, rightMask) = col.leftRightMasks
  result.left = bitand(
    uint64.high.masked 16 * (2 - col) + Row.high - row + 1 ..< 16 * (3 - col), leftMask
  )
  result.right = bitand(
    uint64.high.masked 16 * (6 - col) + Row.high - row + 1 ..< 16 * (7 - col), rightMask
  )

func belowMasks(row, col): tuple[left: uint64, right: uint64] {.inline.} =
  ## Returns two masks with only the bits above `(row, col)` set to `1`.
  ## Including `(row, col)`.
  let (leftMask, rightMask) = col.leftRightMasks
  result.left = bitand(
    uint64.high.masked 16 * (2 - col) .. 16 * (2 - col) + Row.high - row + 1, leftMask
  )
  result.right = bitand(
    uint64.high.masked 16 * (6 - col) .. 16 * (6 - col) + Row.high - row + 1, rightMask
  )

func tsuInsert*(mSelf; row; col; val: bool) {.inline.} =
  ## Inserts `val` and shifts the binary field upward
  ## above the location where `val` is inserted.
  let
    (leftMask, rightMask) = aboveMasks(row, col)
    moveMask = BinaryField(left: leftMask, right: rightMask)
    moveField = BinaryField(
      left: bitand(mSelf.left, leftMask), right: bitand(mSelf.right, rightMask)
    )

  mSelf = sum(
    mSelf - moveField,
    moveField shl 1,
    (moveMask xor (moveMask shl 1)) * cast[uint64](-val.int64),
  ).trimmed

func waterInsert*(mSelf; row; col; val: bool) {.inline.} =
  ## Inserts `val` and shifts the field and shifts the field.
  ## If `(row, col)` is in the air, shifts the field upward above
  ## the location where inserted.
  ## If it is in the water, shifts the fields dwonward below the location
  ## where inserted.
  let
    # air: above, upward
    (leftMaskAir, rightMaskAir) = aboveMasks(row, col)
    moveMaskAir = BinaryField(left: leftMaskAir, right: rightMaskAir)
    moveFieldAir = BinaryField(
      left: bitand(mSelf.left, leftMaskAir), right: bitand(mSelf.right, rightMaskAir)
    )
    addFieldAir =
      moveFieldAir shl 1 +
      (moveMaskAir xor (moveMaskAir shl 1)) * cast[uint64](-val.int64)

    # water: below, downward
    (leftMaskWater, rightMaskWater) = belowMasks(row, col)
    moveMaskWater = BinaryField(left: leftMaskWater, right: rightMaskWater)
    moveFieldWater = BinaryField(
      left: bitand(mSelf.left, leftMaskWater),
      right: bitand(mSelf.right, rightMaskWater),
    )
    addFieldWater =
      moveFieldWater shr 1 +
      (moveMaskWater xor (moveMaskWater shr 1)) * cast[uint64](-val.int64)

    insertIntoAir = int row in AirRow.low .. AirRow.high
    removeField = [moveFieldWater, moveFieldAir][insertIntoAir]
    addField = [addFieldWater, addFieldAir][insertIntoAir]

  mSelf = (mSelf - removeField + addField).trimmed

func tsuRemoveSqueeze*(mSelf, row, col) {.inline.} =
  ## Removes the value at `(row, col)` and shifts the binary field downward
  ## above the location where the cell is removed.
  let
    (leftMask, rightMask) = aboveMasks(row, col)
    moveMask = BinaryField(left: leftMask, right: rightMask)
    moveField = BinaryField(
      left: bitand(mSelf.left, leftMask), right: bitand(mSelf.right, rightMask)
    )

  mSelf = mSelf - moveField + (moveField - (moveMask xor (moveMask shl 1))) shr 1

func waterRemoveSqueeze*(mSelf, row, col) {.inline.} =
  ## Removes the value at `(row, col)` and shifts the field.
  ## If `(row, col)` is in the air, shifts the field downward above
  ## the location where removed.
  ## If it is in the water, shifts the fields upward below the location
  ## where removed.
  let
    # air: above, downward
    (leftMaskAir, rightMaskAir) = aboveMasks(row, col)
    moveMaskAir = BinaryField(left: leftMaskAir, right: rightMaskAir)
    moveFieldAir = BinaryField(
      left: bitand(mSelf.left, leftMaskAir), right: bitand(mSelf.right, rightMaskAir)
    )
    addFieldAir = (moveFieldAir - (moveMaskAir xor (moveMaskAir shl 1))) shr 1

    # water: below, upward
    (leftMaskWater, rightMaskWater) = belowMasks(row, col)
    moveMaskWater = BinaryField(left: leftMaskWater, right: rightMaskWater)
    moveFieldWater = BinaryField(
      left: bitand(mSelf.left, leftMaskWater),
      right: bitand(mSelf.right, rightMaskWater),
    )
    addFieldWater = (moveFieldWater - (moveMaskWater xor (moveMaskWater shr 1))) shl 1

    insertIntoAir = int row in AirRow.low .. AirRow.high
    removeField = [moveFieldWater, moveFieldAir][insertIntoAir]
    addField = [addFieldWater, addFieldAir][insertIntoAir]

  mSelf = mSelf - removeField + addField

# ------------------------------------------------
# Property
# ------------------------------------------------

func isZero*(self): bool {.inline.} = ## Returns `true` if all elements are zero.
  self == ZeroBinaryField

# ------------------------------------------------
# Shift
# ------------------------------------------------

func shiftedUpWithoutTrim*(self; amount = 1'i32): BinaryField {.inline.} =
  ## Returns the binary field shifted upward.
  self shl amount

func shiftedDownWithoutTrim*(self; amount = 1'i32): BinaryField {.inline.} =
  ## Returns the binary field shifted downward.
  self shr amount

func shiftedRightWithoutTrim*(self): BinaryField {.inline.} =
  ## Returns the binary field shifted rightward.
  result.left = self.left shr 16
  result.right = bitor(self.right shr 16, self.left shl 48)

func shiftedLeftWithoutTrim*(self): BinaryField {.inline.} =
  ## Returns the binary field shifted leftward.
  result.left = bitor(self.left shl 16, self.right shr 48)
  result.right = self.right shl 16

# ------------------------------------------------
# Flip
# ------------------------------------------------

func flippedV(val: uint64): uint64 {.inline.} =
  ## `flippedV` for the half field.
  let rev = val.reverseBits
  return
    bitor(
      rev.rotateLeftBits(16).masked 0x0000_FFFF_0000_FFFF'u64,
      rev.rotateRightBits(16).masked 0xFFFF_0000_FFFF_0000'u64,
    ) shr 1

func flippedV*(self): BinaryField {.inline.} =
  ## Returns the binary field flipped vertically.
  result.left = self.left.flippedV
  result.right = self.right.flippedV

func flippedH*(self): BinaryField {.inline.} =
  ## Returns the binary field flipped horizontally.
  result.left = bitor(
    self.right.rotateLeftBits(16).masked 0x0000_FFFF_0000_FFFF'u64,
    (self.right shr 16).masked 0x0000_0000_FFFF_0000'u64,
  )
  result.right = bitor(
    self.left.rotateRightBits(16).masked 0xFFFF_0000_FFFF_0000'u64,
    (self.left shl 16).masked 0x0000_FFFF_0000_0000'u64,
  )

# ------------------------------------------------
# Operation
# ------------------------------------------------

func toColumnArray(self): array[Column, uint64] {.inline.} =
  ## Returns the integer array converted from the field.
  result[0] = self.left.bitsliced 33 ..< 48
  result[1] = self.left.bitsliced 17 ..< 32
  result[2] = self.left.bitsliced 1 ..< 16
  result[3] = self.right.bitsliced 49 ..< 64
  result[4] = self.right.bitsliced 33 ..< 48
  result[5] = self.right.bitsliced 17 ..< 32

func toDropMask*(existField: BinaryField): DropMask {.inline.} =
  ## Returns a drop mask converted from the exist field.
  let arr = (existField + FloorBinaryField).toColumnArray

  result[Column.low] = when UseBmi2: 0 else: 0'u64.toPextMask # dummy to remove warning
  for col in Column.low .. Column.high:
    result[col] =
      when UseBmi2:
        arr[col]
      else:
        arr[col].toPextMask

func drop*(mSelf; mask: DropMask) {.inline.} =
  ## Drops floating cells.
  let arr = mSelf.toColumnArray

  mSelf.left = bitor(
    arr[0].pext(mask[0]) shl 33, arr[1].pext(mask[1]) shl 17, arr[2].pext(mask[2]) shl 1
  )
  mSelf.right = bitor(
    arr[3].pext(mask[3]) shl 49,
    arr[4].pext(mask[4]) shl 33,
    arr[5].pext(mask[5]) shl 17,
  )

func waterDrop*(
    waterDropExistField, dropField, waterDropField: BinaryField
): BinaryField {.inline.} =
  ## Drops floating cells in Water rule.
  let
    left = bitor(
      bitand(0xFFFF'u64, cast[uint64](-waterDropExistField.exist(Row.high, 0).int64)) shl
        32,
      bitand(0xFFFF'u64, cast[uint64](-waterDropExistField.exist(Row.high, 1).int64)) shl
        16,
      bitand(0xFFFF'u64, cast[uint64](-waterDropExistField.exist(Row.high, 2).int64)),
    )
    right = bitor(
      bitand(0xFFFF'u64, cast[uint64](-waterDropExistField.exist(Row.high, 3).int64)) shl
        48,
      bitand(0xFFFF'u64, cast[uint64](-waterDropExistField.exist(Row.high, 4).int64)) shl
        32,
      bitand(0xFFFF'u64, cast[uint64](-waterDropExistField.exist(Row.high, 5).int64)) shl
        16,
    )
    notLeft = left.bitnot
    notRight = right.bitnot

  return
    dropField * BinaryField(left: left, right: right) +
    waterDropField * BinaryField(left: notLeft, right: notRight)

# ------------------------------------------------
# BinaryField <-> array
# ------------------------------------------------

func toArray*(self): array[Row, array[Column, bool]] {.inline.} =
  ## Returns the array converted from the field.
  result[Row.low][Column.low] = false # dummy to remove warning
  for row in Row.low .. Row.high:
    result[row][0] = self.left.testBit 45 - row
    result[row][1] = self.left.testBit 29 - row
    result[row][2] = self.left.testBit 13 - row
    result[row][3] = self.right.testBit 61 - row
    result[row][4] = self.right.testBit 45 - row
    result[row][5] = self.right.testBit 29 - row

func parseBinaryField*(arr: array[Row, array[Column, bool]]): BinaryField {.inline.} =
  ## Returns the field converted from the array.
  result.left = 0
  result.right = 0

  for row, line in arr:
    for col in 0 ..< 3:
      result.left.setMask line[col].uint64 shl (45 - col * 16 - row)

    for col in 3 ..< 6:
      result.right.setMask line[col].uint64 shl (109 - col * 16 - row)

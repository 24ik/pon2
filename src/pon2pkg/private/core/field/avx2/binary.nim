## This module implements binary fields with AVX2.
##

{.experimental: "strictDefs".}

import std/[bitops]
import nimsimd/[avx2]
import ../../[intrinsic]
import ../../../../corepkg/[misc]

type
  BinaryField* = M256i
    ## (PAD, color1:col0-col5, PAD, PAD, color2:col0-col5, PAD)

  WhichColor* = object
    ## Indicates the color.
    color1*: range[0'i64..1'i64]
    color2*: range[0'i64..1'i64]

  DropMask* = array[Width * 2, when UseBmi2: uint16 else: PextMask[uint16]]
    ## Mask used in `drop`.

using
  self: BinaryField
  mSelf: var BinaryField

  row: Row
  col: Column

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func zeroBinaryField*: BinaryField {.inline.} = mm256_setzero_si256()
  ## Returns the binary field with all elements zero.

func floorBinaryField*: BinaryField {.inline.} = mm256_set1_epi16 0b1
  ## Returns the binary field with floor bits one.

func waterHighField*: BinaryField {.inline.} =
  ## Returns the binary field with `row==WaterRow.low` bits one.
  mm256_set1_epi16 0b0010_0000_0000_0000'u16 shr WaterRow.low

func filled*(which: WhichColor): BinaryField {.inline.} =
  ## Returns the binary field filled with the given color.
  let
    c1 = -which.color1
    c2 = -which.color2
  result = mm256_set_epi64x(c1, c1, c2, c2)

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `==`*(self; field: BinaryField): bool {.inline.} =
  bool mm256_testc_si256(mm256_setzero_si256(), mm256_xor_si256(self, field))

func `+`*(self; field: BinaryField): BinaryField {.inline.} =
  mm256_or_si256(self, field)

func `-`*(self; field: BinaryField): BinaryField {.inline.} =
  mm256_andnot_si256(field, self)

func `*`*(self; field: BinaryField): BinaryField {.inline.} =
  mm256_and_si256(self, field)

func `xor`*(self; field: BinaryField): BinaryField {.inline.} =
  mm256_xor_si256(self, field)

func `+=`*(mSelf; field: BinaryField) {.inline.} = mSelf = mSelf + field
func `-=`*(mSelf; field: BinaryField) {.inline.} = mSelf = mSelf - field

func `shl`(self; imm8: int32): BinaryField {.inline.} =
  mm256_slli_epi16(self, imm8)

func `shr`(self; imm8: int32): BinaryField {.inline.} =
  mm256_srli_epi16(self, imm8)

func sum*(field1, field2, field3: BinaryField): BinaryField {.inline.} =
  field1 + field2 + field3

func sum*(field1, field2, field3, field4: BinaryField): BinaryField {.inline.} =
  (field1 + field2) + (field3 + field4)

func sum*(field1, field2, field3, field4, field5: BinaryField): BinaryField
         {.inline.} =
  (field1 + field2) + (field3 + field4 + field5)

func sum*(field1, field2, field3, field4, field5, field6, field7,
          field8: BinaryField): BinaryField {.inline.} =
  ((field1 + field2) + (field3 + field4)) +
    ((field5 + field6) + (field7 + field8))

func prod*(field1, field2, field3: BinaryField): BinaryField {.inline.} =
  field1 * field2 * field3

# ------------------------------------------------
# Population Count
# ------------------------------------------------

func popcnt*(self; color: static range[0..1]): int {.inline.} =
  ## Population count for the `color`.
  # NOTE: YMM[e3, e2, e1, e0] == array[e0, e1, e2, e3]
  const Idx = 2 - 2 * color
  let arr = cast[array[4, uint64]](self)

  result = arr[Idx].popcount + arr[Idx.succ].popcount
  
func popcnt*(self): int {.inline.} =
  ## Population count.
  let arr = cast[array[4, uint64]](self)
  result = arr[0].popcount + arr[1].popcount + arr[2].popcount + arr[3].popcount

# ------------------------------------------------
# Trim
# ------------------------------------------------

func initMask[T: int64 or uint64](left, right: T): BinaryField {.inline.} =
  ## Returns the mask.
  mm256_set_epi64x(left, right, left, right)

func trimmed*(self): BinaryField {.inline.} =
  ## Returns the binary field with padding cleared.
  self * initMask(0x0000_3FFE_3FFE_3FFE'u64, 0x3FFE_3FFE_3FFE_0000'u64)

func visible*(self): BinaryField {.inline.} =
  ## Returns the binary field with only the visible area.
  self * initMask(0x0000_1FFE_1FFE_1FFE'u64, 0x1FFE_1FFE_1FFE_0000'u64)

func initAirTrimMasks: tuple[left: uint64, right: uint64] {.inline.} =
  ## Constructor of `AirTrimMasks`.
  result.left = 0
  result.left.setMask (13 - AirHeight + 1)..13
  result.left.setMask (29 - AirHeight + 1)..29
  result.left.setMask (45 - AirHeight + 1)..45

  result.right = 0
  result.right.setMask (29 - AirHeight + 1)..29
  result.right.setMask (45 - AirHeight + 1)..45
  result.right.setMask (61 - AirHeight + 1)..61

const AirTrimMasks = initAirTrimMasks()

func airTrimmed*(self): BinaryField {.inline.} =
  ## Returns the binary field with only the air area in the Water rule.
  self * initMask(AirTrimMasks.left, AirTrimMasks.right)

# ------------------------------------------------
# Row, Column
# ------------------------------------------------

func row*(self, row): BinaryField {.inline.} =
  ## Returns the binary field with only the given row.
  self * initMask(0x0000_2000_2000_2000'u64 shr row,
                  0x2000_2000_2000_0000'u64 shr row)

func leftRightMasks(col): tuple[left: int64, right: int64] {.inline.} =
  ## Returns `(-1, 0)` if `col` is in {0, 1, 2}; otherwise returns `(0, -1)`.
  let left = [-1, -1, -1, 0, 0, 0][col]
  result.left = left
  result.right = -1 - left

func column*(self, col): BinaryField {.inline.} =
  ## Returns the binary field with only the given column.
  let
    (leftMask, rightMask) = col.leftRightMasks
    left = bitand(0x0000_FFFF_0000_0000'u64 shr (16 * col),
                  cast[uint64](leftMask))
    right = bitand(0x0000_0000_FFFF_0000'u64 shl (16 * (Column.high - col)),
                   cast[uint64](rightMask))

  result = self * initMask(left, right)

func clearColumn*(mSelf, col) {.inline.} = mSelf -= mSelf.column col
  ## Clears the given column.
  
# ------------------------------------------------
# Indexer
# ------------------------------------------------

func cellMasks(row, col): tuple[left: int64, right: int64] {.inline.} =
  ## Returns two masks with only the bit at position `(row, col)` set to `1`.
  let (leftMask, rightMask) = col.leftRightMasks
  result.left = bitand(0x0000_2000_0000_0000'i64 shr (16 * col + row), leftMask)
  result.right = bitand(
    0x0000_0000_0002_0000'i64 shl (16 * (Column.high - col) + Row.high - row),
    rightMask)

func `[]`*(self, row, col): WhichColor {.inline.} =
  let (left, right) = cellMasks(row, col)
  result.color1 = mm256_testc_si256(self, mm256_set_epi64x(left, right, 0, 0))
  result.color2 = mm256_testc_si256(self, mm256_set_epi64x(0, 0, left, right))

func exist*(self, row, col): int {.inline.} =
  ## Returns `1` if the bit `(row, col)` is set; otherwise, returns `0`.
  let which = self[row, col]
  result = int bitor(which.color1, which.color2)

func `[]=`*(mSelf, row, col; which: WhichColor) {.inline.} =
  let
    (left, right) = cellMasks(row, col)
    color1 = -which.color1
    color2 = -which.color2

  mSelf = mSelf - initMask(left, right) + mm256_set_epi64x(
    bitand(left, color1), bitand(right, color1), bitand(left, color2),
    bitand(right, color2))

# ------------------------------------------------
# Insert / RemoveSqueeze
# ------------------------------------------------

func aboveMasks(row, col): tuple[left: int64, right: int64] {.inline.} =
  ## Returns two masks with only the bits above `(row, col)` set to `1`.
  ## Including `(row, col)`.
  let (left, right) = col.leftRightMasks
  result.left = bitand(
    -1'i64.masked 16 * (2 - col) + Row.high - row + 1 ..< 16 * (3 - col), left)
  result.right = bitand(
    -1'i64.masked 16 * (6 - col) + Row.high - row + 1 ..< 16 * (7 - col), right)

func belowMasks(row, col): tuple[left: int64, right: int64] {.inline.} =
  ## Returns two masks with only the bits below `(row, col)` set to `1`.
  ## Including `(row, col)`.
  let (left, right) = col.leftRightMasks
  result.left = bitand(
    -1'i64.masked 16 * (2 - col) .. 16 * (2 - col) + Row.high - row + 1, left)
  result.right = bitand(
    -1'i64.masked 16 * (6 - col) .. 16 * (6 - col) + Row.high - row + 1, right)

func tsuInsert*(mSelf, row, col; which: WhichColor) {.inline.} =
  ## Inserts `which` and shifts the field upward above the location
  ## where `which` is inserted.
  let
    (left, right) = aboveMasks(row, col)
    moveMask = initMask(left, right)
    moveField = moveMask * mSelf

    color1 = -which.color1
    color2 = -which.color2
    insertField = (moveMask xor (moveMask shl 1)) * mm256_set_epi64x(
      bitand(left, color1), bitand(right, color1), bitand(left, color2),
      bitand(right, color2))

  mSelf = mSelf - moveField + ((moveField shl 1).trimmed + insertField)

func waterInsert*(mSelf, row, col; which: WhichColor) {.inline.} =
  ## Inserts `which` and shifts the field and shifts the field.
  ## If `(row, col)` is in the air, shifts the field upward above
  ## the location where inserted.
  ## If it is in the water, shifts the fields downward below the location
  ## where inserted.
  let
    color1 = -which.color1
    color2 = -which.color2

    # air: above, upward
    (leftAir, rightAir) = aboveMasks(row, col)
    moveMaskAir = initMask(leftAir, rightAir)
    moveFieldAir = moveMaskAir * mSelf
    insertFieldAir =
      (moveMaskAir xor (moveMaskAir shl 1)) * mm256_set_epi64x(
        bitand(leftAir, color1), bitand(rightAir, color1),
        bitand(leftAir, color2), bitand(rightAir, color2))
    addFieldAir = (moveFieldAir shl 1).trimmed + insertFieldAir

    # water: below, downward
    (leftWater, rightWater) = belowMasks(row, col)
    moveMaskWater = initMask(leftWater, rightWater)
    moveFieldWater = moveMaskWater * mSelf
    insertFieldWater =
      (moveMaskWater xor (moveMaskWater shr 1)) * mm256_set_epi64x(
        bitand(leftWater, color1), bitand(rightWater, color1),
        bitand(leftWater, color2), bitand(rightWater, color2))
    addFieldWater = (moveFieldWater shr 1).trimmed + insertFieldWater

    insertIntoAir = int row in AirRow.low..AirRow.high
    removeField = [moveFieldWater, moveFieldAir][insertIntoAir]
    addField = [addFieldWater, addFieldAir][insertIntoAir]

  mSelf = mSelf - removeField + addField

func tsuRemoveSqueeze*(mSelf, row, col) {.inline.} =
  ## Removes the value at `(row, col)` and shifts the field downward
  ## above the location where the cell is removed.
  let
    (left, right) = aboveMasks(row, col)
    moveMask = initMask(left, right)
    moveField = moveMask * mSelf

  mSelf = mSelf - moveField +
    (moveField - (moveMask xor (moveMask shl 1))) shr 1

func waterRemoveSqueeze*(mSelf, row, col) {.inline.} =
  ## Removes the value at `(row, col)` and shifts the field.
  ## If `(row, col)` is in the air, shifts the field downward above
  ## the location where removed.
  ## If it is in the water, shifts the fields upward below the location
  ## where removed.
  let
    # air: above, downward
    (leftAir, rightAir) = aboveMasks(row, col)
    moveMaskAir = initMask(leftAir, rightAir)
    moveFieldAir = moveMaskAir * mSelf
    addFieldAir =
      (moveFieldAir - (moveMaskAir xor (moveMaskAir shl 1))) shr 1

    # water: below, upward
    (leftWater, rightWater) = belowMasks(row, col)
    moveMaskWater = initMask(leftWater, rightWater)
    moveFieldWater = moveMaskWater * mSelf
    addFieldWater =
      (moveFieldWater - (moveMaskWater xor (moveMaskWater shr 1))) shl 1

    removeFromAir = int row in AirRow.low..AirRow.high
    removeField = [moveFieldWater, moveFieldAir][removeFromAir]
    addField = [addFieldWater, addFieldAir][removeFromAir]

  mSelf = mSelf - removeField + addField

# ------------------------------------------------
# Property
# ------------------------------------------------

func isZero*(self): bool {.inline.} =
  ## Returns `true` if all elements are zero.
  bool mm256_testc_si256(zeroBinaryField(), self)

func exist*(self): BinaryField {.inline.} =
  ## Returns the field where any cells exist.
  self + mm256_permute4x64_epi64(self, 0b01_00_11_10)

# ------------------------------------------------
# Shift
# ------------------------------------------------

func shiftedUpWithoutTrim*(self; amount: static int32 = 1): BinaryField
                          {.inline.} = self shl amount
  ## Returns the binary field shifted upward.

func shiftedDownWithoutTrim*(self; amount: static int32 = 1): BinaryField
                            {.inline.} = self shr amount
  ## Returns the binary field shifted downward.

func shiftedRightWithoutTrim*(self): BinaryField {.inline.} =
  ## Returns the binary field shifted rightward.
  mm256_srli_si256(self, 2)

func shiftedLeftWithoutTrim*(self): BinaryField {.inline.} =
  ## Returns the binary field shifted leftward.
  mm256_slli_si256(self, 2)

# ------------------------------------------------
# Flip
# ------------------------------------------------

func flippedV(val: uint64): uint64 {.inline.} =
  ## `flippedV` for the single color half field.
  let rev = val.reverseBits
  result = bitor(rev.rotateLeftBits(16).masked 0x0000_FFFF_0000_FFFF'u64,
                 rev.rotateRightBits(16).masked 0xFFFF_0000_FFFF_0000'u64) shr 1

func flippedV*(self): BinaryField {.inline.} =
  ## Returns the binary field flipped vertically.
  var arr = cast[array[4, uint64]](self)

  for val in arr.mitems:
    val = val.flippedV

  result = cast[BinaryField](arr)

func flippedH*(self): BinaryField {.inline.} =
  ## Returns the binary field flipped horizontally.
  let arr = cast[array[16, uint16]](self)

  var newArray: array[16, uint16]
  newArray[0] = 0
  for i in 1..6: newArray[i] = arr[1 + 6 - i]
  newArray[7] = 0
  newArray[8] = 0
  for i in 9..14: newArray[i] = arr[9 + 14 - i]
  newArray[15] = 0

  result = cast[BinaryField](newArray)

# ------------------------------------------------
# Operation
# ------------------------------------------------

func toDropMask*(existField: BinaryField): DropMask {.inline.} =
  ## Converts `existField` to the drop mask.
  let existArray = cast[array[16, uint16]](existField + floorBinaryField())

  result[0] = when UseBmi2: 0 else: 0'u16.toPextMask # dummy to remove warning
  for col in 1..6:
    result[col.pred] =
      when UseBmi2: existArray[col] else: existArray[col].toPextMask
  for col in 9..14:
    result[col.pred 3] =
      when UseBmi2: existArray[col] else: existArray[col].toPextMask

func drop*(mSelf; mask: DropMask) {.inline.} =
  ## Drops floating cells.
  let arr = cast[array[16, uint16]](mSelf)

  var resultArray: array[16, uint16]
  resultArray[0] = 0
  for col in 1..6: resultArray[col] = arr[col].pext mask[col.pred]
  resultArray[7] = 0
  resultArray[8] = 0
  for col in 9..14: resultArray[col] = arr[col].pext mask[col.pred 3]
  resultArray[15] = 0

  mSelf = cast[BinaryField](resultArray)

func waterDrop*(waterDropExistField, dropField,
                waterDropField: BinaryField): BinaryField {.inline.} =
  ## Drops floating cells in Water rule.
  let
    left = bitor(
      bitand(
        0xFFFF'u64,
        cast[uint64](-waterDropExistField.exist(Row.high, 0).int64)) shl 32,
      bitand(
        0xFFFF'u64,
        cast[uint64](-waterDropExistField.exist(Row.high, 1).int64)) shl 16,
      bitand(
        0xFFFF'u64,
        cast[uint64](-waterDropExistField.exist(Row.high, 2).int64)))
    right = bitor(
      bitand(
        0xFFFF'u64,
        cast[uint64](-waterDropExistField.exist(Row.high, 3).int64)) shl 48,
      bitand(
        0xFFFF'u64,
        cast[uint64](-waterDropExistField.exist(Row.high, 4).int64)) shl 32,
      bitand(
        0xFFFF'u64,
        cast[uint64](-waterDropExistField.exist(Row.high, 5).int64)) shl 16)
    notLeft = left.bitnot
    notRight = right.bitnot

  result = dropField * initMask(left, right) +
    waterDropField * initMask(notLeft, notRight)

# ------------------------------------------------
# BinaryField <-> array
# ------------------------------------------------

func toArray*(self): array[Row, array[Column, WhichColor]] {.inline.} =
  ## Converts the binary field to the array.
  let arr = cast[array[16, int16]](self)

  result[Row.low][Column.low] =
    WhichColor(color1: 0, color2: 0) # dummy to remove warning
  for col in Column.low..Column.high:
    # NOTE: YMM[e15, ..., e0] == array[e0, ..., e15]
    let
      colVal1 = arr[14 - col]
      colVal2 = arr[6 - col]

    for row in Row.low..Row.high:
      let rowDigit = Row.high - row + 1
      result[row][col].color1 = int64 colVal1.testBit rowDigit
      result[row][col].color2 = int64 colVal2.testBit rowDigit

func parseBinaryField*(arr: array[Row, array[Column, WhichColor]]): BinaryField
                      {.inline.} =
  ## Converts the array to the binary field.
  var
    color1Left = 0'i64
    color1Right = 0'i64
    color2Left = 0'i64
    color2Right = 0'i64

  for row, line in arr:
    for col in 0..<3:
      let
        which = line[col]
        shift = 45 - col * 16 - row
      color1Left.setMask which.color1 shl shift
      color2Left.setMask which.color2 shl shift

    for col in 3..<6:
      let
        which = line[col]
        shift = 109 - col * 16 - row
      color1Right.setMask which.color1 shl shift
      color2Right.setMask which.color2 shl shift

  result = mm256_set_epi64x(color1Left, color1Right, color2Left, color2Right)

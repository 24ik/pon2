## This module implements binary fields with XMM register.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[hashes, sugar]
import ../../[assign, bitops, expand, simd, staticfor]
import ../../../core/[behaviour, common]

export hashes, simd

type BinaryField* = M128i
  ## Binary field with XMM register.
  # NOTE: use higher 16*6 bits

defineExpand "3", "0", "1", "2"

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const
  ValidMaskElem = 0x3ffe'u16
  WaterMaskElem = toMask2[uint16](1 .. WaterHeight)
  AirMaskElem = ValidMaskElem *~ WaterMaskElem

func init(
    T: type BinaryField, val0, val1, val2, val3, val4, val5: uint16
): T {.inline, noinit.} =
  mm_set_epi16(val0, val1, val2, val3, val4, val5, 0, 0)

func init(T: type BinaryField, val: uint16): T {.inline, noinit.} =
  T.init(val, val, val, val, val, val)

func init*(T: type BinaryField): T {.inline, noinit.} =
  ## Returns the binary field with all elements zero.
  mm_setzero_si128()

func initValid*(T: type BinaryField): T {.inline, noinit.} =
  ## Returns the binary field with all valid elements one.
  T.init ValidMaskElem

func initFloor*(T: type BinaryField): T {.inline, noinit.} =
  ## Returns the binary field with floor bits one.
  T.init 1

func initAirBottom*(T: type BinaryField): T {.inline, noinit.} =
  ## Returns the binary field with the bottom of the air bits one.
  T.init 1'u16 shl (WaterHeight + 1)

func initWaterTop*(T: type BinaryField): T {.inline, noinit.} =
  ## Returns the binary field with the top of the water bits one.
  T.init 1'u16 shl WaterHeight

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `+`*(f1, f2: BinaryField): BinaryField {.inline, noinit.} =
  mm_or_si128(f1, f2)

func `-`*(f1, f2: BinaryField): BinaryField {.inline, noinit.} =
  mm_andnot_si128(f2, f1)

func `*`*(f1, f2: BinaryField): BinaryField {.inline, noinit.} =
  mm_and_si128(f1, f2)

func `xor`*(f1, f2: BinaryField): BinaryField {.inline, noinit.} =
  mm_xor_si128(f1, f2)

func `+=`*(f1: var BinaryField, f2: BinaryField) {.inline, noinit.} =
  f1.assign f1 + f2

func `-=`*(f1: var BinaryField, f2: BinaryField) {.inline, noinit.} =
  f1.assign f1 - f2

func `*=`*(f1: var BinaryField, f2: BinaryField) {.inline, noinit.} =
  f1.assign f1 * f2

# ------------------------------------------------
# Hash
# ------------------------------------------------

func hash*(self: BinaryField): Hash {.inline, noinit.} =
  ## Returns the hash of the binary field.
  var valArray {.noinit, align(16).}: array[2, uint64]
  valArray.addr.mm_store_si128 self

  valArray.hash

# ------------------------------------------------
# Keep
# ------------------------------------------------

func colMask(col: Col): BinaryField {.inline, noinit.} =
  ## Returns the mask corresponding to the column.
  case col
  of Col0:
    BinaryField.init(0xffff'u16, 0, 0, 0, 0, 0)
  of Col1:
    BinaryField.init(0, 0xffff'u16, 0, 0, 0, 0)
  of Col2:
    BinaryField.init(0, 0, 0xffff'u16, 0, 0, 0)
  of Col3:
    BinaryField.init(0, 0, 0, 0xffff'u16, 0, 0)
  of Col4:
    BinaryField.init(0, 0, 0, 0, 0xffff'u16, 0)
  of Col5:
    BinaryField.init(0, 0, 0, 0, 0, 0xffff'u16)

func kept*(self: BinaryField, col: Col): BinaryField {.inline, noinit.} =
  ## Returns the binary field with only the given column.
  self * col.colMask

func keptValid*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field with only the valid area.
  self * BinaryField.initValid

func keptVisible*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field with only the visible area.
  self * BinaryField.init 0x1ffe'u16

func keptAir*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field with only the air area.
  self * BinaryField.init AirMaskElem

# ------------------------------------------------
# Replace
# ------------------------------------------------

func replace*(self: var BinaryField, col: Col, after: BinaryField) {.inline, noinit.} =
  ## Replaces the column of the binary field by `after`.
  let mask = col.colMask
  self.assign self - mask + after * mask

# ------------------------------------------------
# Population Count
# ------------------------------------------------

func popcnt*(self: BinaryField): int {.inline, noinit.} =
  ## Returns the population count.
  var valArray {.noinit, align(16).}: array[2, uint64]
  valArray.addr.mm_store_si128 self

  {.push warning[Uninit]: off.}
  return valArray[0].countOnes + valArray[1].countOnes
  {.pop.}

# ------------------------------------------------
# Shift
# ------------------------------------------------

func shiftedUpRaw*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted upward.
  self.mm_slli_epi16 1

func shiftedDownRaw*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted downward.
  self.mm_srli_epi16 1

func shiftedRightRaw*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted rightward.
  self.mm_srli_si128 2

func shiftedLeftRaw*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted leftward.
  self.mm_slli_si128 2

# ------------------------------------------------
# Flip
# ------------------------------------------------

func flipVertical*(self: var BinaryField) {.inline, noinit.} =
  ## Flips the binary field vertically.
  self.assign self.reverseBits.mm_shuffle_epi8(
    mm_set_epi8(1, 0, 3, 2, 5, 4, 7, 6, 9, 8, 11, 10, -1, -1, -1, -1)
  ).shiftedDownRaw

func flipHorizontal*(self: var BinaryField) {.inline, noinit.} =
  ## Flips the binary field horizontally.
  self.assign self.mm_shuffle_epi8(
    mm_set_epi8(5, 4, 7, 6, 9, 8, 11, 10, 13, 12, 15, 14, -1, -1, -1, -1)
  )

# ------------------------------------------------
# Rotate
# ------------------------------------------------

func rotate*(self: var BinaryField) {.inline, noinit.} =
  ## Rotates the binary field by 180 degrees.
  ## Ghost cells are cleared before the rotation.
  self.assign self.keptVisible.reverseBits.mm_shuffle_epi8(
    mm_set_epi8(11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, -1, -1, -1, -1)
  ).mm_srli_epi16 2

func crossRotate*(self: var BinaryField) {.inline, noinit.} =
  ## Rotates the binary field by 180 degrees in groups of three rows.
  ## Ghost cells are cleared before the rotation.
  self.assign self.keptVisible.reverseBits.mm_shuffle_epi8(
    mm_set_epi8(5, 4, 3, 2, 1, 0, 11, 10, 9, 8, 7, 6, -1, -1, -1, -1)
  ).mm_srli_epi16 2

# ------------------------------------------------
# Indexer
# ------------------------------------------------

func indexFromMsb(row: Row, col: Col): int {.inline, noinit.} =
  ## Returns the bit index for indexers.
  col.ord shl 4 + (row.ord + 2)

func `[]`*(self: BinaryField, row: Row, col: Col): bool {.inline, noinit.} =
  case col
  of Col0 .. Col3:
    self.mm_extract_epi64(1).getBitBE indexFromMsb(row, col)
  of Col4, Col5:
    self.mm_extract_epi64(0).getBitBE indexFromMsb(row, col.pred 4)

func `[]=`*(self: var BinaryField, row: Row, col: Col, val: bool) {.inline, noinit.} =
  var valArray {.noinit, align(16).}: array[2, uint64]
  valArray.addr.mm_store_si128 self

  {.push warning[Uninit]: off.}
  case col
  of Col0 .. Col3:
    valArray[1].changeBitBE indexFromMsb(row, col), val
  of Col4, Col5:
    valArray[0].changeBitBE indexFromMsb(row, col.pred 4), val
  {.pop.}

  self.assign valArray.addr.mm_load_si128

# ------------------------------------------------
# Insert / Delete
# ------------------------------------------------

func isInWater(row: Row, phys: Phys): bool {.inline, noinit.} =
  ## Returns `true` if the row is in the water.
  phys == Phys.Water and row >= WaterTopRow

func insert(
    self: var uint64, col: Col, row: Row, val: bool, phys: Phys, validMaskElem: uint64
) {.inline, noinit.} =
  ## Inserts the value and shifts the binary field's element.
  ## `col` should be in `Col0..Col3`.
  ## If (row, col) is in the air, shifts the binary field's element upward above where
  ## inserted.
  ## If it is in the water, shifts the binary field's element downward below where
  ## inserted.
  let
    colShift = col.ord shl 4
    rowColShift = colShift + row.ord
    colMask = 0xffff_0000_0000_0000'u64 shr colShift

  let
    below: uint64
    above: uint64
  if row.isInWater phys:
    let belowMask = 0x3fff_0000_0000_0000'u64 shr rowColShift
    below = ((self and belowMask) shr 1) and validMaskElem
    above = self *~ belowMask
  else:
    let belowMask = 0x1fff_0000_0000_0000'u64 shr rowColShift
    below = self and belowMask
    above = ((self *~ belowMask) shl 1) and validMaskElem

  self.assign ((below or above) and colMask) or (self *~ colMask)
  self.changeBitBE rowColShift + 2, val

func insert*(
    self: var BinaryField, row: Row, col: Col, val: bool, phys: Phys
) {.inline, noinit.} =
  ## Inserts the value and shifts the binary field.
  ## If (row, col) is in the air, shifts the binary field upward above where inserted.
  ## If it is in the water, shifts the binary field downward below where inserted.
  var valArray {.noinit, align(16).}: array[2, uint64]
  valArray.addr.mm_store_si128 self

  {.push warning[Uninit]: off.}
  case col
  of Col0 .. Col3:
    valArray[1].insert col, row, val, phys, 0x3ffe_3ffe_3ffe_3ffe'u64
  of Col4, Col5:
    valArray[0].insert col.pred 4, row, val, phys, 0x3ffe_3ffe_0000_0000'u64
  {.pop.}

  self.assign valArray.addr.mm_load_si128

func del(
    self: var uint64, col: Col, row: Row, phys: Phys, validMaskElem: uint64
) {.inline, noinit.} =
  ## Deletes the value and shifts the binary field's element.
  ## `col` should be in `Col0..Col3`.
  ## If (row, col) is in the air, shifts the binary field's element downward above
  ## where deleted.
  ## If it is in the water, shifts the binary field's element upward below where
  ## deleted.
  let
    colShift = col.ord shl 4
    rowColShift = colShift + row.ord
    colMask = 0xffff_0000_0000_0000'u64 shr colShift
    belowMask = 0x1fff_0000_0000_0000'u64 shr rowColShift
    aboveMask = not (0x3fff_0000_0000_0000'u64 shr rowColShift)

  let
    below: uint64
    above: uint64
  if row.isInWater phys:
    below = ((self and belowMask) shl 1) and validMaskElem
    above = self and aboveMask
  else:
    below = self and belowMask
    above = ((self and aboveMask) shr 1) and validMaskElem

  self.assign ((below or above) and colMask) or (self *~ colMask)

func del*(self: var BinaryField, row: Row, col: Col, phys: Phys) {.inline, noinit.} =
  ## Deletes the value and shifts the binary field.
  ## If (row, col) is in the air, shifts the binary field downward above where deleted.
  ## If it is in the water, shifts the binary field upward below where deleted.
  var valArray {.noinit, align(16).}: array[2, uint64]
  valArray.addr.mm_store_si128 self

  {.push warning[Uninit]: off.}
  case col
  of Col0 .. Col3:
    valArray[1].del col, row, phys, 0x3ffe_3ffe_3ffe_3ffe'u64
  of Col4, Col5:
    valArray[0].del col.pred 4, row, phys, 0x3ffe_3ffe_0000_0000'u64
  {.pop.}

  self.assign valArray.addr.mm_load_si128

# ------------------------------------------------
# Drop Nuisance
# ------------------------------------------------

func dropNuisanceTsu*(
    self: var BinaryField, counts: array[Col, int], existField: BinaryField
) {.inline, noinit.} =
  ## Drops cells by Tsu physics.
  ## This function requires that the mask is settled and the counts are non-negative.
  let notExist = BinaryField.initValid - existField
  var valArray {.noinit, align(16).}: array[8, uint16]
  valArray.addr.mm_store_si128 notExist

  staticFor(col, Col):
    const ArrayIndex = 7 - col.ord
    let notExistElem = valArray[ArrayIndex]
    valArray[ArrayIndex].assign notExistElem *~ (notExistElem shl counts[col])

  self += valArray.addr.mm_load_si128

func dropNuisanceWater*(
    self, other1, other2: var BinaryField,
    counts: array[Col, int],
    existField: BinaryField,
) {.inline, noinit.} =
  ## Drops cells by Water physics.
  ## `other1` and `other2` are only shifted.
  ## This function requires that the mask is settled and the counts are non-negative.
  var
    valArraySelf {.noinit, align(16).}: array[8, uint16]
    valArrayOther1 {.noinit, align(16).}: array[8, uint16]
    valArrayOther2 {.noinit, align(16).}: array[8, uint16]
    valArrayExist {.noinit, align(16).}: array[8, uint16]
  valArraySelf.addr.mm_store_si128 self
  valArrayOther1.addr.mm_store_si128 other1
  valArrayOther2.addr.mm_store_si128 other2
  valArrayExist.addr.mm_store_si128 existField

  staticFor(col, Col):
    const ArrayIndex = 7 - col.ord

    let
      count = counts[col]
      exist = valArrayExist[ArrayIndex]

    if exist == 0:
      if count <= WaterHeight:
        valArraySelf[ArrayIndex].assign WaterMaskElem *~ (WaterMaskElem shr count)
      else:
        valArraySelf[ArrayIndex].assign WaterMaskElem or
          (AirMaskElem *~ (AirMaskElem shl (count - WaterHeight)))
    else:
      let
        shift = min(count, exist.tzcnt - 1)
        shiftExist = exist shr shift
        emptySpace = ValidMaskElem *~ (shiftExist or shiftExist.blsmsk)
        nuisance = emptySpace *~ (emptySpace shl count)

      valArraySelf[ArrayIndex].assign (valArraySelf[ArrayIndex] shr shift) or nuisance
      valArrayOther1[ArrayIndex].assign valArrayOther1[ArrayIndex] shr shift
      valArrayOther2[ArrayIndex].assign valArrayOther2[ArrayIndex] shr shift

  self.assign valArraySelf.addr.mm_load_si128
  other1.assign valArrayOther1.addr.mm_load_si128
  other2.assign valArrayOther2.addr.mm_load_si128

# ------------------------------------------------
# Settle
# ------------------------------------------------

func write(
    self: out array[Col, PextMask[uint16]], existField: BinaryField
) {.inline, noinit.} =
  ## Initializes the masks.
  var valArray {.noinit, align(16).}: array[8, uint16]
  valArray.addr.mm_store_si128 existField

  staticFor(col, Col):
    {.push warning[ProveInit]: off.}
    self[col].assign PextMask[uint16].init valArray[7 - col.ord]
    {.pop.}

func settleTsu(
    self: var BinaryField, masks: array[Col, PextMask[uint16]]
) {.inline, noinit.} =
  ## Settles the binary field by Tsu physics.
  var valArray {.noinit, align(16).}: array[8, uint16]
  valArray.addr.mm_store_si128 self

  staticFor(col, Col):
    const ArrayIndex = 7 - col.ord
    valArray[ArrayIndex].assign valArray[ArrayIndex].pext masks[col]

  self.assign valArray.addr.mm_load_si128.shiftedUpRaw

func settleTsu*(
    field0, field1, field2: var BinaryField, existField: BinaryField
) {.inline, noinit.} =
  ## Settles the binary fields by Tsu physics.
  var masks {.noinit.}: array[Col, PextMask[uint16]]
  masks.write existField

  expand3 field:
    field.settleTsu masks

func settleWater(
    self: var BinaryField, masks: array[Col, PextMask[uint16]]
) {.inline, noinit.} =
  ## Settles the binary field by Water physics.
  var valArray {.noinit, align(16).}: array[8, uint16]
  valArray.addr.mm_store_si128 self

  staticFor(col, Col):
    const ArrayIndex = 7 - col.ord
    let mask = masks[col]
    valArray[ArrayIndex].assign valArray[ArrayIndex].pext(mask) shl
      max(1, 1 + WaterHeight - mask.popcnt)

  self.assign valArray.addr.mm_load_si128

func settleWater*(
    field0, field1, field2: var BinaryField, existField: BinaryField
) {.inline, noinit.} =
  ## Settles the binary fields by Water physics.
  var masks {.noinit.}: array[Col, PextMask[uint16]]
  masks.write existField

  expand3 field:
    field.settleWater masks

func areSettledTsu*(
    field0, field1, field2, existField: BinaryField
): bool {.inline, noinit.} =
  ## Returns `true` if all binary fields are settled by Tsu physics.
  ## Note that this function is only slightly lighter than `settleTsu`.
  var masks {.noinit.}: array[Col, PextMask[uint16]]
  masks.write existField

  field0.dup(settleTsu(masks)) == field0 and field1.dup(settleTsu(masks)) == field1 and
    field2.dup(settleTsu(masks)) == field2

func areSettledWater*(
    field0, field1, field2, existField: BinaryField
): bool {.inline, noinit.} =
  ## Returns `true` if all binary fields are settled by Tsu physics.
  ## Note that this function is only slightly lighter than `settleWater`.
  var masks {.noinit.}: array[Col, PextMask[uint16]]
  masks.write existField

  field0.dup(settleWater(masks)) == field0 and field1.dup(settleWater(masks)) == field1 and
    field2.dup(settleWater(masks)) == field2

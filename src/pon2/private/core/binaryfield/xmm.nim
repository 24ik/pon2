## This module implements binary fields with XMM register.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[hashes, sugar]
import ../../[assign, bitutils, macros, simd, staticfor]
import ../../../core/[common, rule]

export hashes, simd

type XmmBinaryField* = M128i
  ## Binary field with XMM register.
  # use higher 16*6 bits

defineExpand "6", "0", "1", "2", "3", "4", "5"

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const ValidMaskElem = 0x3ffe'u16

func init(
    T: type XmmBinaryField, val0, val1, val2, val3, val4, val5: uint16
): T {.inline, noinit.} =
  mm_set_epi16(val0, val1, val2, val3, val4, val5, 0, 0)

func init(T: type XmmBinaryField, val: uint16): T {.inline, noinit.} =
  T.init(val, val, val, val, val, val)

func init*(T: type XmmBinaryField): T {.inline, noinit.} =
  ## Returns the binary field with all elements zero.
  mm_setzero_si128()

func initOne*(T: type XmmBinaryField): T {.inline, noinit.} =
  ## Returns the binary field with all valid elements one.
  T.init ValidMaskElem

func initFloor*(T: type XmmBinaryField): T {.inline, noinit.} =
  ## Returns the binary field with floor bits one.
  T.init 1

func initLowerAir*(T: type XmmBinaryField): T {.inline, noinit.} =
  ## Returns the binary field with lower air bits one.
  const LowerAirMaskElem = 1'u16 shl WaterHeight.succ
  T.init LowerAirMaskElem

func initUpperWater*(T: type XmmBinaryField): T {.inline, noinit.} =
  ## Returns the binary field with upper underwater bits one.
  const UpperWaterMaskElem = 1'u16 shl WaterHeight
  T.init UpperWaterMaskElem

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `+`*(f1, f2: XmmBinaryField): XmmBinaryField {.inline, noinit.} =
  mm_or_si128(f1, f2)

func `-`*(f1, f2: XmmBinaryField): XmmBinaryField {.inline, noinit.} =
  mm_andnot_si128(f2, f1)

func `*`*(f1, f2: XmmBinaryField): XmmBinaryField {.inline, noinit.} =
  mm_and_si128(f1, f2)

func `xor`*(f1, f2: XmmBinaryField): XmmBinaryField {.inline, noinit.} =
  mm_xor_si128(f1, f2)

func `+=`*(f1: var XmmBinaryField, f2: XmmBinaryField) {.inline, noinit.} =
  f1.assign f1 + f2

func `-=`*(f1: var XmmBinaryField, f2: XmmBinaryField) {.inline, noinit.} =
  f1.assign f1 - f2

func `*=`*(f1: var XmmBinaryField, f2: XmmBinaryField) {.inline, noinit.} =
  f1.assign f1 * f2

func sum*(f1, f2, f3: XmmBinaryField): XmmBinaryField {.inline, noinit.} =
  f1 + f2 + f3

func sum*(f1, f2, f3, f4: XmmBinaryField): XmmBinaryField {.inline, noinit.} =
  (f1 + f2) + (f3 + f4)

func sum*(f1, f2, f3, f4, f5: XmmBinaryField): XmmBinaryField {.inline, noinit.} =
  (f1 + f2 + f3) + (f4 + f5)

func sum*(f1, f2, f3, f4, f5, f6: XmmBinaryField): XmmBinaryField {.inline, noinit.} =
  (f1 + f2) + (f3 + f4) + (f5 + f6)

func sum*(
    f1, f2, f3, f4, f5, f6, f7: XmmBinaryField
): XmmBinaryField {.inline, noinit.} =
  (f1 + f2) + (f3 + f4) + (f5 + f6 + f7)

func sum*(
    f1, f2, f3, f4, f5, f6, f7, f8: XmmBinaryField
): XmmBinaryField {.inline, noinit.} =
  ((f1 + f2) + (f3 + f4)) + ((f5 + f6) + (f7 + f8))

func product*(f1, f2, f3: XmmBinaryField): XmmBinaryField {.inline, noinit.} =
  f1 * f2 * f3

# ------------------------------------------------
# Hash
# ------------------------------------------------

func hash*(self: XmmBinaryField): Hash {.inline, noinit.} =
  ## Returns the hash of the binary field.
  var valArray {.noinit, align(16).}: array[2, uint64]
  valArray.addr.mm_store_si128 self

  valArray.hash

# ------------------------------------------------
# Keep
# ------------------------------------------------

func initValidMask(): XmmBinaryField {.inline, noinit.} =
  ## Returns the valid mask.
  XmmBinaryField.init ValidMaskElem

func initAirMaskElem(): uint16 {.inline, noinit.} =
  ## Returns `AirMaskElem`.
  var mask = 0'u16
  for i in 0 ..< AirHeight:
    mask.setBitBE 2.succ i

  mask

const AirMaskElem = initAirMaskElem()

func colMask(col: Col): XmmBinaryField {.inline, noinit.} =
  ## Returns the mask corresponding to the column.
  case col
  of Col0:
    XmmBinaryField.init(0xffff'u16, 0, 0, 0, 0, 0)
  of Col1:
    XmmBinaryField.init(0, 0xffff'u16, 0, 0, 0, 0)
  of Col2:
    XmmBinaryField.init(0, 0, 0xffff'u16, 0, 0, 0)
  of Col3:
    XmmBinaryField.init(0, 0, 0, 0xffff'u16, 0, 0)
  of Col4:
    XmmBinaryField.init(0, 0, 0, 0, 0xffff'u16, 0)
  of Col5:
    XmmBinaryField.init(0, 0, 0, 0, 0, 0xffff'u16)

func kept*(self: XmmBinaryField, row: Row): XmmBinaryField {.inline, noinit.} =
  ## Returns the binary field with only the given row.
  self * XmmBinaryField.init(0x2000'u16 shr row.ord)

func kept*(self: XmmBinaryField, col: Col): XmmBinaryField {.inline, noinit.} =
  ## Returns the binary field with only the given column.
  self * col.colMask

func keptValid*(self: XmmBinaryField): XmmBinaryField {.inline, noinit.} =
  ## Returns the binary field with only the valid area.
  self * XmmBinaryField.initOne

func keptVisible*(self: XmmBinaryField): XmmBinaryField {.inline, noinit.} =
  ## Returns the binary field with only the visible area.
  self * XmmBinaryField.init 0x1ffe'u16

func keptAir*(self: XmmBinaryField): XmmBinaryField {.inline, noinit.} =
  ## Returns the binary field with only the air area.
  self * XmmBinaryField.init AirMaskElem

func keepValid*(self: var XmmBinaryField) {.inline, noinit.} =
  ## Keeps only the valid area.
  self *= initValidMask()

# ------------------------------------------------
# Clear
# ------------------------------------------------

func clear*(self: var XmmBinaryField) {.inline, noinit.} =
  ## Clears the binary field.
  self.assign XmmBinaryField.init

# ------------------------------------------------
# Replace
# ------------------------------------------------

func replace*(
    self: var XmmBinaryField, col: Col, after: XmmBinaryField
) {.inline, noinit.} =
  ## Replaces the column of the binary field by `after`.
  let mask = col.colMask
  self.assign (self - mask) + (after * mask)

# ------------------------------------------------
# Population Count
# ------------------------------------------------

func popcnt*(self: XmmBinaryField): int {.inline, noinit.} =
  ## Returns the population count.
  var arr {.noinit, align(16).}: array[2, uint64]
  arr.addr.mm_store_si128 self

  {.push warning[Uninit]: off.}
  return arr[0].countOnes + arr[1].countOnes
  {.pop.}

# ------------------------------------------------
# Shift - Out-place
# ------------------------------------------------

func shiftedUpRaw*(self: XmmBinaryField): XmmBinaryField {.inline, noinit.} =
  ## Returns the binary field shifted upward.
  self.mm_slli_epi16 1

func shiftedUp*(self: XmmBinaryField): XmmBinaryField {.inline, noinit.} =
  ## Returns the binary field shifted upward and extracted the valid area.
  self.shiftedUpRaw.keptValid

func shiftedDownRaw*(self: XmmBinaryField): XmmBinaryField {.inline, noinit.} =
  ## Returns the binary field shifted downward.
  self.mm_srli_epi16 1

func shiftedDown*(self: XmmBinaryField): XmmBinaryField {.inline, noinit.} =
  ## Returns the binary field shifted downward and extracted the valid area.
  self.shiftedDownRaw.keptValid

func shiftedRightRaw*(self: XmmBinaryField): XmmBinaryField {.inline, noinit.} =
  ## Returns the binary field shifted rightward.
  self.mm_srli_si128 2

func shiftedRight*(self: XmmBinaryField): XmmBinaryField {.inline, noinit.} =
  ## Returns the binary field shifted rightward and extracted the valid area.
  self.shiftedRightRaw.keptValid

func shiftedLeftRaw*(self: XmmBinaryField): XmmBinaryField {.inline, noinit.} =
  ## Returns the binary field shifted leftward.
  self.mm_slli_si128 2

func shiftedLeft*(self: XmmBinaryField): XmmBinaryField {.inline, noinit.} =
  ## Returns the binary field shifted leftward and extracted the valid area.
  self.shiftedLeftRaw

# ------------------------------------------------
# Shift - In-place
# ------------------------------------------------

func shiftUpRaw*(self: var XmmBinaryField) {.inline, noinit.} =
  ## Shifts the binary field upward.
  self.assign self.shiftedUpRaw

func shiftUp*(self: var XmmBinaryField) {.inline, noinit.} =
  ## Shifts the binary field upward and extracts the valid area.
  self.assign self.shiftedUp

func shiftDownRaw*(self: var XmmBinaryField) {.inline, noinit.} =
  ## Shifts the binary field downward.
  self.assign self.shiftedDownRaw

func shiftDown*(self: var XmmBinaryField) {.inline, noinit.} =
  ## Shifts the binary field downward and extracts the valid area.
  self.assign self.shiftedDown

func shiftRightRaw*(self: var XmmBinaryField) {.inline, noinit.} =
  ## Shifts the binary field rightward.
  self.assign self.shiftedRightRaw

func shiftRight*(self: var XmmBinaryField) {.inline, noinit.} =
  ## Shifts the binary field rightward and extracts the valid area.
  self.assign self.shiftedRight

func shiftLeftRaw*(self: var XmmBinaryField) {.inline, noinit.} =
  ## Shifts the binary field rightward.
  self.assign self.shiftedLeftRaw

func shiftLeft*(self: var XmmBinaryField) {.inline, noinit.} =
  ## Shifts the binary field leftward and extracts the valid area.
  self.assign self.shiftedLeft

# ------------------------------------------------
# Flip
# ------------------------------------------------

func flipVertical*(self: var XmmBinaryField) {.inline, noinit.} =
  ## Flips the binary field vertically.
  self.assign self.reverseBits.mm_shuffle_epi8(
    mm_set_epi8(1, 0, 3, 2, 5, 4, 7, 6, 9, 8, 11, 10, -1, -1, -1, -1)
  ).shiftedDownRaw

func flipHorizontal*(self: var XmmBinaryField) {.inline, noinit.} =
  ## Flips the binary field horizontally.
  self.assign self.mm_shuffle_epi8(
    mm_set_epi8(5, 4, 7, 6, 9, 8, 11, 10, 13, 12, 15, 14, -1, -1, -1, -1)
  )

# ------------------------------------------------
# Rotate
# ------------------------------------------------

func rotate*(self: var XmmBinaryField) {.inline, noinit.} =
  ## Rotates the binary field by 180 degrees.
  ## Ghost cells are cleared before the rotation.
  self.assign self.keptVisible.reverseBits.mm_shuffle_epi8(
    mm_set_epi8(11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, -1, -1, -1, -1)
  ).mm_srli_epi16 2

func crossRotate*(self: var XmmBinaryField) {.inline, noinit.} =
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

func `[]`*(
    self: XmmBinaryField, row: static Row, col: static Col
): bool {.inline, noinit.} =
  staticCase:
    case col
    of Col0 .. Col3:
      self.mm_extract_epi64(1).getBitBE static(indexFromMsb(row, col))
    of Col4, Col5:
      self.mm_extract_epi64(0).getBitBE static(indexFromMsb(row, col.pred 4))

func `[]`*(self: XmmBinaryField, row: Row, col: Col): bool {.inline, noinit.} =
  case col
  of Col0 .. Col3:
    self.mm_extract_epi64(1).getBitBE indexFromMsb(row, col)
  of Col4, Col5:
    self.mm_extract_epi64(0).getBitBE indexFromMsb(row, col.pred 4)

func `[]=`*(
    self: var XmmBinaryField, row: Row, col: Col, val: bool
) {.inline, noinit.} =
  var arr {.noinit, align(16).}: array[2, uint64]
  arr.addr.mm_store_si128 self

  {.push warning[Uninit]: off.}
  case col
  of Col0 .. Col3:
    arr[1].changeBitBE indexFromMsb(row, col), val
  of Col4, Col5:
    arr[0].changeBitBE indexFromMsb(row, col.pred 4), val
  {.pop.}

  self.assign arr.addr.mm_load_si128

# ------------------------------------------------
# Insert / Delete
# ------------------------------------------------

func isInWater(row: Row, phys: Phys): bool {.inline, noinit.} =
  ## Returns `true` if the row is in the water.
  phys == Phys.Water and row.ord + WaterHeight >= Height

func insert(
    self: var uint64, col: Col, row: Row, val: bool, phys: Phys, col0123: static bool
) {.inline, noinit.} =
  ## Inserts the value and shifts the binary field's element.
  ## If (row, col) is in the air, shifts the binary field's element upward above where
  ## inserted.
  ## If it is in the water, shifts the binary field's element downward below where
  ## inserted.
  const ValidMask =
    when col0123: 0x3ffe_3ffe_3ffe_3ffe'u64 else: 0x3ffe_3ffe_0000_0000'u64

  let
    colShift = col.ord shl 4
    rowColShift = colShift + row.ord
    colMask = 0xffff_0000_0000_0000'u64 shr colShift

  let
    below: uint64
    above: uint64
  if row.isInWater phys:
    let belowMask = 0x3fff_0000_0000_0000'u64 shr rowColShift
    below = ((self and belowMask) shr 1) and ValidMask
    above = self *~ belowMask
  else:
    let belowMask = 0x1fff_0000_0000_0000'u64 shr rowColShift
    below = self and belowMask
    above = ((self *~ belowMask) shl 1) and ValidMask

  self.assign ((below or above) and colMask) or (self *~ colMask)
  self.changeBitBE rowColShift + 2, val

func insert*(
    self: var XmmBinaryField, row: Row, col: Col, val: bool, phys: Phys
) {.inline, noinit.} =
  ## Inserts the value and shifts the binary field.
  ## If (row, col) is in the air, shifts the binary field upward above where inserted.
  ## If it is in the water, shifts the binary field downward below where inserted.
  var arr {.noinit, align(16).}: array[2, uint64]
  arr.addr.mm_store_si128 self

  {.push warning[Uninit]: off.}
  case col
  of Col0 .. Col3:
    arr[1].insert(col, row, val, phys, col0123 = true)
  of Col4, Col5:
    arr[0].insert(col.pred 4, row, val, phys, col0123 = false)
  {.pop.}

  self.assign arr.addr.mm_load_si128

func del(
    self: var uint64, col: Col, row: Row, phys: Phys, col0123: static bool
) {.inline, noinit.} =
  ## Deletes the value and shifts the binary field's element.
  ## If (row, col) is in the air, shifts the binary field's element downward above
  ## where deleted.
  ## If it is in the water, shifts the binary field's element upward below where
  ## deleted.
  const ValidMask =
    when col0123: 0x3ffe_3ffe_3ffe_3ffe'u64 else: 0x3ffe_3ffe_0000_0000'u64

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
    below = ((self and belowMask) shl 1) and ValidMask
    above = self and aboveMask
  else:
    below = self and belowMask
    above = ((self and aboveMask) shr 1) and ValidMask

  self.assign ((below or above) and colMask) or (self *~ colMask)

func del*(self: var XmmBinaryField, row: Row, col: Col, phys: Phys) {.inline, noinit.} =
  ## Deletes the value and shifts the binary field.
  ## If (row, col) is in the air, shifts the binary field downward above where deleted.
  ## If it is in the water, shifts the binary field upward below where deleted.
  var valArray {.noinit, align(16).}: array[2, uint64]
  valArray.addr.mm_store_si128 self

  {.push warning[Uninit]: off.}
  case col
  of Col0 .. Col3:
    valArray[1].del(col, row, phys, col0123 = true)
  of Col4, Col5:
    valArray[0].del(col.pred 4, row, phys, col0123 = false)
  {.pop.}

  self.assign valArray.addr.mm_load_si128

# ------------------------------------------------
# Drop Garbages
# ------------------------------------------------

func dropGarbagesTsu*(
    self: var XmmBinaryField, counts: array[Col, int], existField: XmmBinaryField
) {.inline, noinit.} =
  ## Drops cells by Tsu rule.
  ## This function requires that the mask is settled and the counts are non-negative.
  let notExist = XmmBinaryField.initOne - existField
  var valArray {.noinit, align(16).}: array[8, uint16]
  valArray.addr.mm_store_si128 notExist

  expand6 Col:
    block:
      const ArrayIndex = 7 - _
      let notExistElem = valArray[ArrayIndex]
      valArray[ArrayIndex].assign notExistElem *~ (notExistElem shl counts[Col])

  self += valArray.addr.mm_load_si128

func dropGarbagesWater*(
    self, other1, other2: var XmmBinaryField,
    counts: array[Col, int],
    existField: XmmBinaryField,
) {.inline, noinit.} =
  ## Drops cells by Water rule.
  ## `self` is shifted and is dropped garbages; `other1` and `other2` are only shifted.
  ## This function requires that the mask is settled and the counts are non-negative.
  const WaterMaskElem = ValidMaskElem *~ AirMaskElem

  var
    valArraySelf {.noinit, align(16).}: array[8, uint16]
    valArrayOther1 {.noinit, align(16).}: array[8, uint16]
    valArrayOther2 {.noinit, align(16).}: array[8, uint16]
    valArrayExist {.noinit, align(16).}: array[8, uint16]
  valArraySelf.addr.mm_store_si128 self
  valArrayOther1.addr.mm_store_si128 other1
  valArrayOther2.addr.mm_store_si128 other2
  valArrayExist.addr.mm_store_si128 existField

  expand6 Col:
    block:
      const ArrayIndex = 7 - _

      let
        cnt = counts[Col]
        exist = valArrayExist[ArrayIndex]

      if exist == 0:
        if cnt <= WaterHeight:
          valArraySelf[ArrayIndex].assign WaterMaskElem *~ (WaterMaskElem shr cnt)
        else:
          valArraySelf[ArrayIndex].assign WaterMaskElem or
            (AirMaskElem *~ (AirMaskElem shl (cnt - WaterHeight)))
      else:
        let
          shift = min(cnt, exist.tzcnt - 1)
          shiftExist = exist shr shift
          emptySpace = ValidMaskElem *~ (shiftExist or shiftExist.blsmsk)
          garbages = emptySpace *~ (emptySpace shl cnt)

        valArraySelf[ArrayIndex].assign (valArraySelf[ArrayIndex] shr shift) or garbages
        valArrayOther1[ArrayIndex].assign valArrayOther1[ArrayIndex] shr shift
        valArrayOther2[ArrayIndex].assign valArrayOther2[ArrayIndex] shr shift

  self.assign valArraySelf.addr.mm_load_si128
  other1.assign valArrayOther1.addr.mm_load_si128
  other2.assign valArrayOther2.addr.mm_load_si128

# ------------------------------------------------
# Settle
# ------------------------------------------------

func write(
    self: out array[Col, PextMask[uint16]], existField: XmmBinaryField
) {.inline, noinit.} =
  ## Initializes the masks.
  var valArray {.noinit, align(16).}: array[8, uint16]
  valArray.addr.mm_store_si128 existField

  staticFor(col, Col):
    {.push warning[ProveInit]: off.}
    self[col].assign PextMask[uint16].init valArray[7 - col.ord]
    {.pop.}

func settleTsu(
    self: var XmmBinaryField, masks: array[Col, PextMask[uint16]]
) {.inline, noinit.} =
  ## Settles the binary field by Tsu rule.
  var valArray {.noinit, align(16).}: array[8, uint16]
  valArray.addr.mm_store_si128 self

  expand6 Col:
    block:
      const ArrayIndex = 7 - Col.ord
      valArray[ArrayIndex].assign valArray[ArrayIndex].pext masks[Col]

  self.assign valArray.addr.mm_load_si128.shiftedUpRaw

func settleTsu*(
    field1, field2, field3: var XmmBinaryField, existField: XmmBinaryField
) {.inline, noinit.} =
  ## Settles the binary fields by Tsu rule.
  var masks: array[Col, PextMask[uint16]]
  masks.write existField

  field1.settleTsu masks
  field2.settleTsu masks
  field3.settleTsu masks

func settleWater(
    self: var XmmBinaryField, masks: array[Col, PextMask[uint16]]
) {.inline, noinit.} =
  ## Settles the binary field by Water rule.
  var valArray {.noinit, align(16).}: array[8, uint16]
  valArray.addr.mm_store_si128 self

  expand6 Col:
    block:
      const ArrayIndex = 7 - Col.ord
      let mask = masks[Col]
      valArray[ArrayIndex].assign valArray[ArrayIndex].pext(mask) shl
        max(1, 1 + WaterHeight - mask.popcnt)

  self.assign valArray.addr.mm_load_si128

func settleWater*(
    field1, field2, field3: var XmmBinaryField, existField: XmmBinaryField
) {.inline, noinit.} =
  ## Settles the binary fields by Water rule.
  var masks: array[Col, PextMask[uint16]]
  masks.write existField

  field1.settleWater masks
  field2.settleWater masks
  field3.settleWater masks

func areSettledTsu*(
    field1, field2, field3, existField: XmmBinaryField
): bool {.inline, noinit.} =
  ## Returns `true` if all binary fields are settled by Tsu rule.
  ## Note that this function is only slightly lighter than `settleTsu`.
  var masks: array[Col, PextMask[uint16]]
  masks.write existField

  field1.dup(settleTsu(_, masks)) == field1 and field2.dup(settleTsu(_, masks)) == field2 and
    field3.dup(settleTsu(_, masks)) == field3

func areSettledWater*(
    field1, field2, field3, existField: XmmBinaryField
): bool {.inline, noinit.} =
  ## Returns `true` if all binary fields are settled by Water rule.
  ## Note that this function is only slightly lighter than `settleWater`.
  var masks: array[Col, PextMask[uint16]]
  masks.write existField

  field1.dup(settleWater(_, masks)) == field1 and
    field2.dup(settleWater(_, masks)) == field2 and
    field3.dup(settleWater(_, masks)) == field3

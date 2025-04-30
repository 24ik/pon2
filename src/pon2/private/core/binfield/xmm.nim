## This module implements binary fields with XMM register.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import ../../[assign3, bitops3, macros2, simd, staticfor2]
import ../../../core/[common, rule]

export simd

type XmmBinField* = M128i
  ## Binary field with XMM register.
  # use higher 16*6 bits

defineExpand "6", "0", "1", "2", "3", "4", "5"

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const ValidMaskElem = 0x3ffe'u16

func init(
    T: type XmmBinField, val0, val1, val2, val3, val4, val5: uint16
): T {.inline.} =
  mm_set_epi16(val0, val1, val2, val3, val4, val5, 0, 0)

func init(T: type XmmBinField, val: uint16): T {.inline.} =
  T.init(val, val, val, val, val, val)

func init*(T: type XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field with all elements zero.
  mm_setzero_si128()

func initOne*(T: type XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field with all valid elements one.
  T.init ValidMaskElem

func initFloor*(T: type XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field with floor bits one.
  T.init 1

func initLowerAir*(T: type XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field with lower air bits one.
  const LowerAirMaskElem = 1'u16 shl WaterHeight.succ
  T.init LowerAirMaskElem

func initUpperWater*(T: type XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field with upper underwater bits one.
  const UpperWaterMaskElem = 1'u16 shl WaterHeight
  T.init UpperWaterMaskElem

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `+`*(f1, f2: XmmBinField): XmmBinField {.inline.} =
  mm_or_si128(f1, f2)

func `-`*(f1, f2: XmmBinField): XmmBinField {.inline.} =
  mm_andnot_si128(f2, f1)

func `*`*(f1, f2: XmmBinField): XmmBinField {.inline.} =
  mm_and_si128(f1, f2)

func `xor`*(f1, f2: XmmBinField): XmmBinField {.inline.} =
  mm_xor_si128(f1, f2)

func `+=`*(f1: var XmmBinField, f2: XmmBinField) {.inline.} =
  f1.assign f1 + f2

func `-=`*(f1: var XmmBinField, f2: XmmBinField) {.inline.} =
  f1.assign f1 - f2

func `*=`*(f1: var XmmBinField, f2: XmmBinField) {.inline.} =
  f1.assign f1 * f2

func sum*(f1, f2, f3: XmmBinField): XmmBinField {.inline.} =
  f1 + f2 + f3

func sum*(f1, f2, f3, f4: XmmBinField): XmmBinField {.inline.} =
  (f1 + f2) + (f3 + f4)

func sum*(f1, f2, f3, f4, f5: XmmBinField): XmmBinField {.inline.} =
  (f1 + f2 + f3) + (f4 + f5)

func sum*(f1, f2, f3, f4, f5, f6: XmmBinField): XmmBinField {.inline.} =
  (f1 + f2) + (f3 + f4) + (f5 + f6)

func sum*(f1, f2, f3, f4, f5, f6, f7: XmmBinField): XmmBinField {.inline.} =
  (f1 + f2) + (f3 + f4) + (f5 + f6 + f7)

func sum*(f1, f2, f3, f4, f5, f6, f7, f8: XmmBinField): XmmBinField {.inline.} =
  ((f1 + f2) + (f3 + f4)) + ((f5 + f6) + (f7 + f8))

func prod*(f1, f2, f3: XmmBinField): XmmBinField {.inline.} =
  f1 * f2 * f3

# ------------------------------------------------
# Keep
# ------------------------------------------------

func initValidMask(): XmmBinField {.inline.} =
  ## Returns the valid mask.
  XmmBinField.init ValidMaskElem

func initAirMaskElem(): uint16 {.inline.} =
  ## Returns `AirMaskElem`.
  var mask = 0'u16
  for i in 0 ..< AirHeight:
    mask.setBitBE 2.succ i

  mask

const AirMaskElem = initAirMaskElem()

func colMask(col: Col): XmmBinField {.inline.} =
  ## Returns the mask corresponding to the column.
  case col
  of Col0:
    XmmBinField.init(0xffff'u16, 0, 0, 0, 0, 0)
  of Col1:
    XmmBinField.init(0, 0xffff'u16, 0, 0, 0, 0)
  of Col2:
    XmmBinField.init(0, 0, 0xffff'u16, 0, 0, 0)
  of Col3:
    XmmBinField.init(0, 0, 0, 0xffff'u16, 0, 0)
  of Col4:
    XmmBinField.init(0, 0, 0, 0, 0xffff'u16, 0)
  of Col5:
    XmmBinField.init(0, 0, 0, 0, 0, 0xffff'u16)

func kept*(self: XmmBinField, row: Row): XmmBinField {.inline.} =
  ## Returns the binary field with only the given row.
  self * XmmBinField.init(0x2000'u16 shr row.ord)

func kept*(self: XmmBinField, col: Col): XmmBinField {.inline.} =
  ## Returns the binary field with only the given column.
  self * col.colMask

func keptValid*(self: XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field with only the valid area.
  self * XmmBinField.initOne

func keptVisible*(self: XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field with only the visible area.
  self * XmmBinField.init 0x1ffe'u16

func keptAir*(self: XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field with only the air area.
  self * XmmBinField.init AirMaskElem

func keepValid*(self: var XmmBinField) {.inline.} =
  ## Keeps only the valid area.
  self *= initValidMask()

# ------------------------------------------------
# Clear
# ------------------------------------------------

func clear*(self: var XmmBinField) {.inline.} =
  ## Clears the binary field.
  self.assign XmmBinField.init

# ------------------------------------------------
# Replace
# ------------------------------------------------

func replace*(self: var XmmBinField, col: Col, after: XmmBinField) {.inline.} =
  ## Replaces the column of the binary field by `after`.
  let mask = col.colMask
  self.assign (self - mask) + (after * mask)

# ------------------------------------------------
# Population Count
# ------------------------------------------------

func popcnt*(self: XmmBinField): int {.inline.} =
  ## Returns the population count.
  var arr {.noinit, align(16).}: array[2, uint64]
  arr.addr.mm_store_si128 self

  {.push warning[Uninit]: off.}
  return arr[0].countOnes + arr[1].countOnes
  {.pop.}

# ------------------------------------------------
# Shift - Out-place
# ------------------------------------------------

func shiftedUpRaw*(self: XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field shifted upward.
  self.mm_slli_epi16 1

func shiftedUp*(self: XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field shifted upward and extracted the valid area.
  self.shiftedUpRaw.keptValid

func shiftedDownRaw*(self: XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field shifted downward.
  self.mm_srli_epi16 1

func shiftedDown*(self: XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field shifted downward and extracted the valid area.
  self.shiftedDownRaw.keptValid

func shiftedRightRaw*(self: XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field shifted rightward.
  self.mm_srli_si128 2

func shiftedRight*(self: XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field shifted rightward and extracted the valid area.
  self.shiftedRightRaw.keptValid

func shiftedLeftRaw*(self: XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field shifted leftward.
  self.mm_slli_si128 2

func shiftedLeft*(self: XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field shifted leftward and extracted the valid area.
  self.shiftedLeftRaw

# ------------------------------------------------
# Shift - In-place
# ------------------------------------------------

func shiftUpRaw*(self: var XmmBinField) {.inline.} =
  ## Shifts the binary field upward.
  self.assign self.shiftedUpRaw

func shiftUp*(self: var XmmBinField) {.inline.} =
  ## Shifts the binary field upward and extracts the valid area.
  self.assign self.shiftedUp

func shiftDownRaw*(self: var XmmBinField) {.inline.} =
  ## Shifts the binary field downward.
  self.assign self.shiftedDownRaw

func shiftDown*(self: var XmmBinField) {.inline.} =
  ## Shifts the binary field downward and extracts the valid area.
  self.assign self.shiftedDown

func shiftRightRaw*(self: var XmmBinField) {.inline.} =
  ## Shifts the binary field rightward.
  self.assign self.shiftedRightRaw

func shiftRight*(self: var XmmBinField) {.inline.} =
  ## Shifts the binary field rightward and extracts the valid area.
  self.assign self.shiftedRight

func shiftLeftRaw*(self: var XmmBinField) {.inline.} =
  ## Shifts the binary field rightward.
  self.assign self.shiftedLeftRaw

func shiftLeft*(self: var XmmBinField) {.inline.} =
  ## Shifts the binary field leftward and extracts the valid area.
  self.assign self.shiftedLeft

# ------------------------------------------------
# Flip
# ------------------------------------------------

func flipVertical*(self: var XmmBinField) {.inline.} =
  ## Flips the binary field vertically.
  self.assign self.reverseBits.mm_shuffle_epi8(
    mm_set_epi8(1, 0, 3, 2, 5, 4, 7, 6, 9, 8, 11, 10, -1, -1, -1, -1)
  ).shiftedDownRaw

func flipHorizontal*(self: var XmmBinField) {.inline.} =
  ## Flips the binary field horizontally.
  self.assign self.mm_shuffle_epi8(
    mm_set_epi8(5, 4, 7, 6, 9, 8, 11, 10, 13, 12, 15, 14, -1, -1, -1, -1)
  )

# ------------------------------------------------
# Indexer
# ------------------------------------------------

func idxFromMsb(row: Row, col: Col): int {.inline.} =
  ## Returns the bit index for indexers.
  col.ord shl 4 + (row.ord + 2)

func `[]`*(self: XmmBinField, row: static Row, col: static Col): bool {.inline.} =
  when col in {Col0, Col1, Col2, Col3}:
    self.mm_extract_epi64(1).getBitBE static(idxFromMsb(row, col))
  else:
    self.mm_extract_epi64(0).getBitBE static(idxFromMsb(row, col.pred 4))

func `[]`*(self: XmmBinField, row: Row, col: Col): bool {.inline.} =
  case col
  of Col0, Col1, Col2, Col3:
    self.mm_extract_epi64(1).getBitBE idxFromMsb(row, col)
  of Col4, Col5:
    self.mm_extract_epi64(0).getBitBE idxFromMsb(row, col.pred 4)

func `[]=`*(self: var XmmBinField, row: Row, col: Col, val: bool) {.inline.} =
  var arr {.noinit, align(16).}: array[2, uint64]
  arr.addr.mm_store_si128 self

  {.push warning[Uninit]: off.}
  case col
  of Col0, Col1, Col2, Col3:
    arr[1].changeBitBE idxFromMsb(row, col), val
  of Col4, Col5:
    arr[0].changeBitBE idxFromMsb(row, col.pred 4), val
  {.pop.}

  self.assign arr.addr.mm_load_si128

# ------------------------------------------------
# Insert / Delete
# ------------------------------------------------

func isInWater(row: Row, rule: static Rule): bool {.inline.} =
  ## Returns `true` if the row is in the water.
  (static rule == Water) and row.ord + WaterHeight >= Height

func insert(
    self: var uint64,
    col: Col,
    row: Row,
    val: bool,
    rule: static Rule,
    col0123: static bool,
) {.inline.} =
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
  if row.isInWater rule:
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
    self: var XmmBinField, row: Row, col: Col, val: bool, rule: static Rule
) {.inline.} =
  ## Inserts the value and shifts the binary field.
  ## If (row, col) is in the air, shifts the binary field upward above where inserted.
  ## If it is in the water, shifts the binary field downward below where inserted.
  var arr {.noinit, align(16).}: array[2, uint64]
  arr.addr.mm_store_si128 self

  {.push warning[Uninit]: off.}
  case col
  of Col0, Col1, Col2, Col3:
    arr[1].insert col, row, val, rule, true
  of Col4, Col5:
    arr[0].insert col.pred 4, row, val, rule, false
  {.pop.}

  self.assign arr.addr.mm_load_si128

func delete(
    self: var uint64, col: Col, row: Row, rule: static Rule, col0123: static bool
) {.inline.} =
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
  if row.isInWater rule:
    below = ((self and belowMask) shl 1) and ValidMask
    above = self and aboveMask
  else:
    below = self and belowMask
    above = ((self and aboveMask) shr 1) and ValidMask

  self.assign ((below or above) and colMask) or (self *~ colMask)

func delete*(self: var XmmBinField, row: Row, col: Col, rule: static Rule) {.inline.} =
  ## Deletes the value and shifts the binary field.
  ## If (row, col) is in the air, shifts the binary field downward above where deleted.
  ## If it is in the water, shifts the binary field upward below where deleted.
  var arr {.noinit, align(16).}: array[2, uint64]
  arr.addr.mm_store_si128 self

  {.push warning[Uninit]: off.}
  case col
  of Col0, Col1, Col2, Col3:
    arr[1].delete col, row, rule, true
  of Col4, Col5:
    arr[0].delete col.pred 4, row, rule, false
  {.pop.}

  self.assign arr.addr.mm_load_si128

# ------------------------------------------------
# Drop Garbages
# ------------------------------------------------

func dropGarbagesTsu*(
    self: var XmmBinField, cnts: array[Col, int], existField: XmmBinField
) {.inline.} =
  ## Drops cells by Tsu rule.
  ## This function requires that the mask is settled and the counts are non-negative.
  let notExist = XmmBinField.initOne - existField
  var arr {.noinit, align(16).}: array[8, uint16]
  arr.addr.mm_store_si128 notExist

  expand6 Col:
    block:
      const ArrIdx = 7 - _
      let notExistElem = arr[ArrIdx]
      arr[ArrIdx].assign notExistElem *~ (notExistElem shl cnts[Col])

  self += arr.addr.mm_load_si128

func dropGarbagesWater*(
    self, other1, other2: var XmmBinField,
    cnts: array[Col, int],
    existField: XmmBinField,
) {.inline.} =
  ## Drops cells by Water rule.
  ## `self` is shifted and is dropped garbages; `other1` and `other2` are only shifted.
  ## This function requires that the mask is settled and the counts are non-negative.
  const WaterMaskElem = ValidMaskElem *~ AirMaskElem

  var
    arrSelf {.noinit, align(16).}: array[8, uint16]
    arrOther1 {.noinit, align(16).}: array[8, uint16]
    arrOther2 {.noinit, align(16).}: array[8, uint16]
    arrExist {.noinit, align(16).}: array[8, uint16]
  arrSelf.addr.mm_store_si128 self
  arrOther1.addr.mm_store_si128 other1
  arrOther2.addr.mm_store_si128 other2
  arrExist.addr.mm_store_si128 existField

  expand6 Col:
    block:
      const ArrIdx = 7 - _

      let
        cnt = cnts[Col]
        exist = arrExist[ArrIdx]

      if exist == 0:
        if cnt <= WaterHeight:
          arrSelf[ArrIdx].assign WaterMaskElem *~ (WaterMaskElem shr cnt)
        else:
          arrSelf[ArrIdx].assign WaterMaskElem or
            (AirMaskElem *~ (AirMaskElem shl (cnt - WaterHeight)))
      else:
        let
          shift = min(cnt, exist.tzcnt - 1)
          shiftExist = exist shr shift
          emptySpace = ValidMaskElem *~ (shiftExist or shiftExist.blsmsk)
          garbages = emptySpace *~ (emptySpace shl cnt)

        arrSelf[ArrIdx].assign (arrSelf[ArrIdx] shr shift) or garbages
        arrOther1[ArrIdx].assign arrOther1[ArrIdx] shr shift
        arrOther2[ArrIdx].assign arrOther2[ArrIdx] shr shift

  self.assign arrSelf.addr.mm_load_si128
  other1.assign arrOther1.addr.mm_load_si128
  other2.assign arrOther2.addr.mm_load_si128

# ------------------------------------------------
# Settle
# ------------------------------------------------

func write(self: out array[Col, PextMask[uint16]], existField: XmmBinField) {.inline.} =
  ## Initializes the masks.
  var arr {.noinit, align(16).}: array[8, uint16]
  arr.addr.mm_store_si128 existField

  staticFor(col, Col):
    {.push warning[ProveInit]: off.}
    self[col].assign PextMask[uint16].init arr[7 - col.ord]
    {.pop.}

func settleTsu(self: var XmmBinField, masks: array[Col, PextMask[uint16]]) {.inline.} =
  ## Settles the binary field by Tsu rule.
  var arr {.noinit, align(16).}: array[8, uint16]
  arr.addr.mm_store_si128 self

  expand6 Col:
    block:
      const ArrIdx = 7 - Col.ord
      arr[ArrIdx].assign arr[ArrIdx].pext masks[Col]

  self.assign arr.addr.mm_load_si128.shiftedUpRaw

func settleTsu*(
    field1, field2, field3: var XmmBinField, existField: XmmBinField
) {.inline.} =
  ## Settles the binary fields by Tsu rule.
  var masks: array[Col, PextMask[uint16]]
  masks.write existField

  field1.settleTsu masks
  field2.settleTsu masks
  field3.settleTsu masks

func settleWater(
    self: var XmmBinField, masks: array[Col, PextMask[uint16]]
) {.inline.} =
  ## Settles the binary field by Water rule.
  var arr {.noinit, align(16).}: array[8, uint16]
  arr.addr.mm_store_si128 self

  expand6 Col:
    block:
      const ArrIdx = 7 - Col.ord
      let mask = masks[Col]
      arr[ArrIdx].assign arr[ArrIdx].pext(mask) shl max(
        1, 1 + WaterHeight - mask.popcnt
      )

  self.assign arr.addr.mm_load_si128

func settleWater*(
    field1, field2, field3: var XmmBinField, existField: XmmBinField
) {.inline.} =
  ## Settles the binary fields by Water rule.
  var masks: array[Col, PextMask[uint16]]
  masks.write existField

  field1.settleWater masks
  field2.settleWater masks
  field3.settleWater masks

func areSettledTsu*(field1, field2, field3, existField: XmmBinField): bool {.inline.} =
  ## Returns `true` if all binary fields are settled by Tsu rule.
  ## Note that this function is only slightly lighter than `settleTsu`.
  var masks: array[Col, PextMask[uint16]]
  masks.write existField

  field1.dup(settleTsu(_, masks)) == field1 and field2.dup(settleTsu(_, masks)) == field2 and
    field3.dup(settleTsu(_, masks)) == field3

func areSettledWater*(
    field1, field2, field3, existField: XmmBinField
): bool {.inline.} =
  ## Returns `true` if all binary fields are settled by Water rule.
  ## Note that this function is only slightly lighter than `settleWater`.
  var masks: array[Col, PextMask[uint16]]
  masks.write existField

  field1.dup(settleWater(_, masks)) == field1 and
    field2.dup(settleWater(_, masks)) == field2 and
    field3.dup(settleWater(_, masks)) == field3

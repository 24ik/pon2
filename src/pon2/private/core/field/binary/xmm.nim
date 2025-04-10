## This module implements binary fields with XMM register.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import stew/[bitops2]
import ../../../[assign3, bitops3, simd, staticfor2]
import ../../../../core/[common, rule]

type
  XmmBinField* = M128i
    ## Binary field with XMM register.
    # use higher 16*6 bits

  XmmDropMask* = array[Col, PextMask[uint16]] ## Mask used in dropping.

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init(
    T: type XmmBinField, val0, val1, val2, val3, val4, val5: uint16
): T {.inline.} =
  mm_set_epi16(val0, val1, val2, val3, val4, val5, 0, 0)

func init(T: type XmmBinField, val: uint16): T {.inline.} =
  T.init(val, val, val, val, val, val)

func initZero*(T: type XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field with all elements zero.
  mm_setzero_si128()

func initOne*(T: type XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field with all elements one.
  mm_cmpeq_epi16(T.initZero, T.initZero)

func initFloor*(T: type XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field with floor bits one.
  T.init 1

func initLowerAir*(T: type XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field with lower air bits one.
  T.init static(1'u16 shl WaterHeight.succ)

func initUpperWater*(T: type XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field with upper underwater bits one.
  T.init static(1'u16 shl WaterHeight)

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `+`*(f1, f2: XmmBinField): XmmBinField {.inline.} =
  mm_or_si128(f1, f2)

func `-`*(f1, f2: XmmBinField): XmmBinField {.inline.} =
  mm_andnot_si128(f2, f1)

func `*`*(f1, f2: XmmBinField): XmmBinField {.inline.} =
  mm_and_si128(f2, f1)

func `xor`*(f1, f2: XmmBinField): XmmBinField {.inline.} =
  mm_xor_si128(f2, f1)

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
  XmmBinField.init 0x3ffe'u16

func initAirMaskElem(): uint16 {.inline.} =
  ## Returns the air mask's element.
  var mask = 0'u16
  for i in 0 ..< AirHeight:
    mask.setBitBE i.succ 2

  mask

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
  self * initValidMask()

func keptVisible*(self: XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field with only the visible area.
  self * XmmBinField.init 0x1ffe'u16

func keptAir*(self: XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field with only the air area.
  const AirMaskElem = initAirMaskElem()
  self * XmmBinField.init AirMaskElem

func keepValid*(self: var XmmBinField) {.inline.} =
  ## Keeps only the valid area.
  self *= initValidMask()

func keptValid(self: uint64): uint64 {.inline.} =
  ## Keeps only the valid area.
  self and 0x3ffe_3ffe_3ffe_0000'u64

# ------------------------------------------------
# Clear
# ------------------------------------------------

func clear*(self: var XmmBinField) {.inline.} =
  ## Clears the binary field.
  self.assign XmmBinField.initZero

func clear*(self: var XmmBinField, col: Col) {.inline.} =
  ## Clears the binary field only at the given column.
  self -= col.colMask

# ------------------------------------------------
# Population Count
# ------------------------------------------------

func popcnt*(self: XmmBinField): int {.inline.} =
  ## Returns the population count.
  var arr {.align(16).}: array[2, uint64]
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

func flippedVertical*(self: XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field flipped vertically.

  self.reverseBits.mm_shuffle_epi8(
    mm_set_epi8(1, 0, 3, 2, 5, 4, 7, 6, 9, 8, 11, 10, -1, -1, -1, -1)
  ).shiftedDownRaw

func flippedHorizontal*(self: XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field flipped horizontally.
  self.mm_shuffle_epi8(
    mm_set_epi8(5, 4, 7, 6, 9, 8, 11, 10, 13, 12, 15, 14, -1, -1, -1, -1)
  )

func flipVertical*(self: var XmmBinField) {.inline.} =
  ## Flips the binary field vertically.
  self.assign self.flippedVertical

func flipHorizontal*(self: var XmmBinField) {.inline.} =
  ## Flips the binary field horizontally.
  self.assign self.flippedHorizontal

# ------------------------------------------------
# Indexer
# ------------------------------------------------

func idxFromMsb(row: Row, col: Col): int {.inline.} =
  ## Returns the bit index for indexers.
  col.ord shl 4 + (row.ord + 2)

func `[]`*(self: XmmBinField, row: static Row, col: static Col): bool {.inline.} =
  when col in {Col0, Col1, Col2}:
    self.mm_extract_epi64(1).getBitBE static(idxFromMsb(row, col))
  else:
    self.mm_extract_epi64(0).getBitBE static(idxFromMsb(row, col.pred 3))

func `[]`*(self: XmmBinField, row: Row, col: Col): bool {.inline.} =
  case col
  of Col0, Col1, Col2:
    self.mm_extract_epi64(1).getBitBE idxFromMsb(row, col)
  else:
    self.mm_extract_epi64(0).getBitBE idxFromMsb(row, col.pred 3)

func `[]=`*(self: var XmmBinField, row: Row, col: Col, val: bool) {.inline.} =
  var arr {.align(16).}: array[2, uint64]
  arr.addr.mm_store_si128 self

  {.push warning[Uninit]: off.}
  case col
  of Col0, Col1, Col2:
    arr[1].changeBitBE idxFromMsb(row, col), val
  of Col3, Col4, Col5:
    arr[0].changeBitBE idxFromMsb(row, col.pred 3), val
  {.pop.}

  self.assign arr.addr.mm_load_si128

# ------------------------------------------------
# Insert / Delete
# ------------------------------------------------

func isInWater(row: Row, rule: static Rule): bool {.inline.} =
  ## Returns `true` if the row is in the water.
  (static rule == Water) and row.ord + WaterHeight >= Height

func insert(
    self: var uint64, col: Col, row: Row, val: bool, rule: static Rule
) {.inline.} =
  ## Inserts the value and shifts the binary field's element.
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
  if row.isInWater rule:
    let belowMask = 0x3fff_0000_0000_0000'u64 shr rowColShift
    below = ((self and belowMask) shr 1).keptValid
    above = self *~ belowMask
  else:
    let belowMask = 0x1fff_0000_0000_0000'u64 shr rowColShift
    below = self and belowMask
    above = ((self *~ belowMask) shl 1).keptValid

  self.assign ((below or above) and colMask) or (self *~ colMask)
  self.changeBitBE rowColShift + 2, val

func insert*(
    self: var XmmBinField, row: Row, col: Col, val: bool, rule: static Rule
) {.inline.} =
  ## Inserts the value and shifts the binary field.
  ## If (row, col) is in the air, shifts the binary field upward above where inserted.
  ## If it is in the water, shifts the binary field downward below where inserted.
  var arr {.align(16).}: array[2, uint64]
  arr.addr.mm_store_si128 self

  {.push warning[Uninit]: off.}
  case col
  of Col0, Col1, Col2:
    arr[1].insert col, row, val, rule
  of Col3, Col4, Col5:
    arr[0].insert col.pred 3, row, val, rule
  {.pop.}

  self.assign arr.addr.mm_load_si128

func delete(self: var uint64, col: Col, row: Row, rule: static Rule) {.inline.} =
  ## Deletes the value and shifts the binary field's element.
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
  if row.isInWater rule:
    below = ((self and belowMask) shl 1).keptValid
    above = self and aboveMask
  else:
    below = self and belowMask
    above = ((self and aboveMask) shr 1).keptValid

  self.assign ((below or above) and colMask) or (self *~ colMask)

func delete*(self: var XmmBinField, row: Row, col: Col, rule: static Rule) {.inline.} =
  ## Deletes the value and shifts the binary field.
  ## If (row, col) is in the air, shifts the binary field downward above where deleted.
  ## If it is in the water, shifts the binary field upward below where deleted.
  var arr {.align(16).}: array[2, uint64]
  arr.addr.mm_store_si128 self

  {.push warning[Uninit]: off.}
  case col
  of Col0, Col1, Col2:
    arr[1].delete col, row, rule
  of Col3, Col4, Col5:
    arr[0].delete col.pred 3, row, rule
  {.pop.}

  self.assign arr.addr.mm_load_si128

# ------------------------------------------------
# Drop
# ------------------------------------------------

func toDropMask*(existField: XmmBinField): XmmDropMask {.inline.} =
  ## Returns a drop mask converted from the exist field.
  var arr {.align(16).}: array[8, uint16]
  arr.addr.mm_store_si128 existField

  {.push warning[Uninit]: off.}
  var dropMask: XmmDropMask
  staticFor(col, Col):
    dropMask[col].assign PextMask[uint16].init arr[7 - col.ord]

  return dropMask
  {.pop.}

func drop*(self: var XmmBinField, mask: XmmDropMask) {.inline.} =
  ## Floating cells drop.
  var arr {.align(16).}: array[8, uint16]
  arr.addr.mm_store_si128 self

  {.push warning[Uninit]: off.}
  self.assign XmmBinField.init(
    arr[7].pext(mask[Col0]),
    arr[6].pext(mask[Col1]),
    arr[5].pext(mask[Col2]),
    arr[4].pext(mask[Col3]),
    arr[3].pext(mask[Col4]),
    arr[2].pext(mask[Col5]),
  ).shiftedUpRaw
  {.pop.}

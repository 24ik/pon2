## This module implements binary fields with XMM register.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import nimsimd/[sse42]
import stew/[bitops2]
import ../../../[assign3, intrinsic, staticfor2]
import ../../../../core/[common, rule]

type
  XmmBinField* = M128i
    ## Binary field with XMM register.
    # only use higher 16*6 bits

  XmmDropMask* = array[Col, PextMask[uint16]] ## Mask used in dropping.

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init(
    T: type XmmBinField, val0, val1, val2, val3, val4, val5: uint16
): T {.inline.} =
  mm_set_epi16(val0, val1, val2, val3, val4, val5, 0, 0)

func init(T: type XmmBinField, val: uint16): T {.inline.} =
  mm_set1_epi16 val

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

func `==`*(f1, f2: XmmBinField): bool {.inline.} =
  let diff = mm_xor_si128(f1, f2)
  mm_testz_si128(diff, diff).bool

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
  ((f1 + f2) + (f3 + f4)) + (f5 + f6)

func sum*(f1, f2, f3, f4, f5, f6, f7: XmmBinField): XmmBinField {.inline.} =
  ((f1 + f2) + (f3 + f4)) + (f5 + f6 + f7)

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

func cntOne*(self: XmmBinField): int {.inline.} =
  ## Returns the number of one bits.
  var arr {.noinit, align(16).}: array[2, uint64]
  arr.addr.mm_store_si128 self

  arr[0].countOnes + arr[1].countOnes

# ------------------------------------------------
# Shift
# ------------------------------------------------

func shiftedUpRaw*(self: XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field shifted upward.
  self.mm_slli_epi16 1

func shiftedDownRaw*(self: XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field shifted downward.
  self.mm_srli_epi16 1

func shiftedRightRaw*(self: XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field shifted rightward.
  self.mm_srli_si128 2

func shiftedLeftRaw*(self: XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field shifted leftward.
  self.mm_slli_si128 2

func shiftUpRaw*(self: var XmmBinField) {.inline.} =
  ## Shifts the binary field upward.
  self.assign self.shiftedUpRaw

func shiftDownRaw*(self: var XmmBinField) {.inline.} =
  ## Shifts the binary field downward.
  self.assign self.shiftedDownRaw

func shiftRightRaw*(self: var XmmBinField) {.inline.} =
  ## Shifts the binary field rightward.
  self.assign self.shiftedRightRaw

func shiftLeftRaw*(self: var XmmBinField) {.inline.} =
  ## Shifts the binary field rightward.
  self.assign self.shiftedLeftRaw

# ------------------------------------------------
# Flip
# ------------------------------------------------

func flippedV*(self: XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field flipped vertically.

  self.reverseBits.mm_shuffle_epi8(
    mm_set_epi8(1, 0, 3, 2, 5, 4, 7, 6, 9, 8, 11, 10, -1, -1, -1, -1)
  ).shiftedDownRaw

func flippedH*(self: XmmBinField): XmmBinField {.inline.} =
  ## Returns the binary field flipped horizontally.
  self.mm_shuffle_epi8(
    mm_set_epi8(5, 4, 7, 6, 9, 8, 11, 10, 13, 12, 15, 14, -1, -1, -1, -1)
  )

func flipV*(self: var XmmBinField) {.inline.} =
  ## Flips the binary field vertically.
  self.assign self.flippedV

func flipH*(self: var XmmBinField) {.inline.} =
  ## Flips the binary field horizontally.
  self.assign self.flippedH

# ------------------------------------------------
# Indexer
# ------------------------------------------------

func rowColShiftAmt(row: static Row, col: Col): int {.inline.} =
  ## Returns the shift amount at (row, col).
  col.ord shl 4 + static(row.ord)

func rowColShiftAmt(row: Row, col: Col): int {.inline.} =
  ## Returns the shift amount at (row, col).
  col.ord shl 4 + row.ord

func rowColMask(rcShiftAmt, rcShiftAmtInv: static int): XmmBinField {.inline.} =
  ## Returns the mask with only (row, col) bit one.
  const
    Mask0123 = 0x2000_0000_0000_0000'u64 shr rcShiftAmt
    Mask45 = 0x0000_0002_0000_0000'u64 shl rcShiftAmtInv

  mm_set_epi64x(Mask0123, Mask45)

func rowColMask(rcShiftAmt, rcShiftAmtInv: int): XmmBinField {.inline.} =
  ## Returns the mask with only (row, col) bit one.
  let
    mask0123 = 0x2000_0000_0000_0000'u64 shr rcShiftAmt
    mask45 = 0x0000_0002_0000_0000'u64 shl rcShiftAmtInv

  mm_set_epi64x(mask0123, mask45)

func rowColMask(row: static Row, col: static Col): XmmBinField {.inline.} =
  ## Returns the mask with only (row, col) bit one.
  const
    AmtMax = rowColShiftAmt(Row.high, Col.high)
    RcShiftAmt = rowColShiftAmt(row, col)
    RcShiftAmtInv = AmtMax - RcShiftAmt

  rowColMask(RcShiftAmt, RcShiftAmtInv)

func rowColMask(row: static Row, col: Col): XmmBinField {.inline.} =
  ## Returns the mask with only (row, col) bit one.
  const AmtMax = rowColShiftAmt(Row.high, Col.high)
  let
    rcShiftAmt = rowColShiftAmt(row, col)
    rcShiftAmtInv = AmtMax - rcShiftAmt

  rowColMask(rcShiftAmt, rcShiftAmtInv)

func rowColMask(row: Row, col: Col): XmmBinField {.inline.} =
  ## Returns the mask with only (row, col) bit one.
  const AmtMax = rowColShiftAmt(Row.high, Col.high)
  let
    rcShiftAmt = rowColShiftAmt(row, col)
    rcShiftAmtInv = AmtMax - rcShiftAmt

  rowColMask(rcShiftAmt, rcShiftAmtInv)

func `[]`*(self: XmmBinField, row: static Row, col: static Col): bool {.inline.} =
  bool self.mm_testc_si128 rowColMask(row, col)

func `[]`*(self: XmmBinField, row: static Row, col: Col): bool {.inline.} =
  bool self.mm_testc_si128 rowColMask(row, col)

func `[]`*(self: XmmBinField, row: Row, col: Col): bool {.inline.} =
  bool self.mm_testc_si128 rowColMask(row, col)

func `[]=`(self: var XmmBinField, rcMask: XmmBinField, val: bool) {.inline.} =
  if val:
    self += rcMask
  else:
    self -= rcMask

func `[]=`*(self: var XmmBinField, row: Row, col: Col, val: bool) {.inline.} =
  self[rowColMask(row, col)] = val

# ------------------------------------------------
# Insert / Delete
# ------------------------------------------------

func isInWater(row: Row, rule: static Rule): bool {.inline.} =
  ## Returns `true` if the row is in the water.
  (static rule == Water) and row.ord + WaterHeight >= Height

func insert*(
    self: var XmmBinField, row: Row, col: Col, val: bool, rule: static Rule
) {.inline.} =
  ## Inserts the value and shifts the binary field.
  ## If (row, col) is in the air, shifts the binary field upward above where inserted.
  ## If it is in the water, shifts the binary field downward below where inserted.
  let
    rcShiftAmt = rowColShiftAmt(row, col)
    rcShiftAmtInv = rowColShiftAmt(Row.high, Col.high) - rcShiftAmt

  let
    below: XmmBinField
    above: XmmBinField
  if row.isInWater rule:
    let
      belowMask0123 = 0x3fff_0000_0000_0000'u64 shr rcShiftAmt
      aboveMask45 = 0x0000_fffc_0000_0000'u64 shl rcShiftAmtInv
      belowMask = mm_set_epi64x(belowMask0123, not aboveMask45)

    below = (self * belowMask).shiftedDownRaw
    above = self - belowMask
  else:
    let
      belowMask0123 = 0x1fff_0000_0000_0000'u64 shr rcShiftAmt
      aboveMask45 = 0x0000_fffe_0000_0000'u64 shl rcShiftAmtInv
      belowMask = mm_set_epi64x(belowMask0123, not aboveMask45)

    below = self * belowMask
    above = (self - belowMask).shiftedUpRaw

  let colMask = col.colMask
  self.assign (below + above) * colMask + (self - colMask)
  self[rowColMask(rcShiftAmt, rcShiftAmtInv)] = val
  self.keepValid

func delete*(self: var XmmBinField, row: Row, col: Col, rule: static Rule) {.inline.} =
  ## Deletes the value and shifts the binary field.
  ## If (row, col) is in the air, shifts the binary field downward above where deleted.
  ## If it is in the water, shifts the binary field upward below where deleted.
  const
    BelowMaskBase = 0x1fff_0000_0000_0000'u64
    AboveMaskBase = 0x0000_fffc_0000_0000'u64

  let
    rcShiftAmtMax = rowColShiftAmt(Row.high, Col.high)
    rcShiftAmt = rowColShiftAmt(row, col)
    rcShiftAmtInv = rcShiftAmtMax - rcShiftAmt
    rcShiftAmt2 = (col.ord - 4) shl 4 + row.ord
    rcShiftAmtInv2 = rcShiftAmtMax - rcShiftAmt2

    belowMask0123 = BelowMaskBase shr rcShiftAmt
    belowMask45 = BelowMaskBase shr rcShiftAmt2
    aboveMask0123 = AboveMaskBase shl rcShiftAmtInv2
    aboveMask45 = AboveMaskBase shl rcShiftAmtInv

    belowMask = mm_set_epi64x(belowMask0123, belowMask45)
    aboveMask = mm_set_epi64x(aboveMask0123, aboveMask45)

  let
    below: XmmBinField
    above: XmmBinField
  if row.isInWater rule:
    below = (self * belowMask).shiftedUpRaw
    above = self * aboveMask
  else:
    below = self * belowMask
    above = (self * aboveMask).shiftedDownRaw

  let colMask = col.colMask
  self.assign (below + above) * colMask + (self - colMask)
  self.keepValid

# ------------------------------------------------
# Drop
# ------------------------------------------------

func toDropMask*(existField: XmmBinField): XmmDropMask {.inline.} =
  ## Returns a drop mask converted from the exist field.
  var arr {.noinit, align(16).}: array[8, uint16]
  arr.addr.mm_store_si128 existField

  var dropMask {.noinit.}: XmmDropMask
  staticFor(col, Col):
    dropMask[col].assign PextMask[uint16].init arr[7 - col.ord]

  dropMask

func drop*(self: var XmmBinField, mask: XmmDropMask) {.inline.} =
  ## Floating cells drop.
  var arr {.noinit, align(16).}: array[8, uint16]
  arr.addr.mm_store_si128 self

  self.assign XmmBinField.init(
    arr[7].pext(mask[Col0]),
    arr[6].pext(mask[Col1]),
    arr[5].pext(mask[Col2]),
    arr[4].pext(mask[Col3]),
    arr[3].pext(mask[Col4]),
    arr[2].pext(mask[Col5]),
  ).shiftedUpRaw

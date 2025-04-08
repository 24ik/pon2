## This module implements binary fields with 32bit operations.
# 
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[bitops, sugar]
import stew/[bitops2]
import ../../../[assign3, bitops3, intrinsic, staticfor2]
import ../../../../core/[common, rule]

type
  Bit32BinField* = object ## Binary field with 32bit operations.
    left: uint32
    center: uint32
    right: uint32

  Bit32DropMask* = array[Col, PextMask[uint32]] ## Mask used in dropping.

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init(
    T: type Bit32BinField, left: uint32, center: uint32, right: uint32
): T {.inline.} =
  T(left: left, center: center, right: right)

func initZero*(T: type Bit32BinField): Bit32BinField {.inline.} =
  ## Returns the binary field with all elements zero.
  T.init(0, 0, 0)

func initOne*(T: type Bit32BinField): Bit32BinField {.inline.} =
  ## Returns the binary field with all elements one.
  const Initializer = 0xffff_ffff'u32
  T.init(Initializer, Initializer, Initializer)

func initFloor*(T: type Bit32BinField): Bit32BinField {.inline.} =
  ## Returns the binary field with floor bits one.
  const Initializer = 0x0001_0001'u32
  T.init(Initializer, Initializer, Initializer)

func initLowerAir*(T: type Bit32BinField): Bit32BinField {.inline.} =
  ## Returns the binary field with lower air bits one.
  const Initializer = 0x0001_0001'u32 shl WaterHeight.succ
  T.init(Initializer, Initializer, Initializer)

func initUpperWater*(T: type Bit32BinField): Bit32BinField {.inline.} =
  ## Returns the binary field with upper underwater bits one.
  const Initializer = 0x0001_0001'u32 shl WaterHeight
  T.init(Initializer, Initializer, Initializer)

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `+`*(f1, f2: Bit32BinField): Bit32BinField {.inline.} =
  Bit32BinField.init(f1.left or f2.left, f1.center or f2.center, f1.right or f2.right)

func `-`*(f1, f2: Bit32BinField): Bit32BinField {.inline.} =
  Bit32BinField.init(
    f1.left.clearMasked f2.left,
    f1.center.clearMasked f2.center,
    f1.right.clearMasked f2.right,
  )

func `*`*(f1, f2: Bit32BinField): Bit32BinField {.inline.} =
  Bit32BinField.init(
    f1.left and f2.left, f1.center and f2.center, f1.right and f2.right
  )

func `*`(self: Bit32BinField, val: uint32): Bit32BinField {.inline.} =
  Bit32BinField.init(self.left and val, self.center and val, self.right and val)

func `xor`*(f1, f2: Bit32BinField): Bit32BinField {.inline.} =
  Bit32BinField.init(
    f1.left xor f2.left, f1.center xor f2.center, f1.right xor f2.right
  )

func `+=`*(f1: var Bit32BinField, f2: Bit32BinField) {.inline.} =
  f1.left.setMask2 f2.left
  f1.center.setMask2 f2.center
  f1.right.setMask2 f2.right

func `-=`*(f1: var Bit32BinField, f2: Bit32BinField) {.inline.} =
  f1.left.clearMask2 f2.left
  f1.center.clearMask2 f2.center
  f1.right.clearMask2 f2.right

func `*=`*(f1: var Bit32BinField, f2: Bit32BinField) {.inline.} =
  f1.left.mask2 f2.left
  f1.center.mask2 f2.center
  f1.right.mask2 f2.right

func `*=`(self: var Bit32BinField, val: uint32) {.inline.} =
  self.left.mask2 val
  self.center.mask2 val
  self.right.mask2 val

func sum*(f1, f2, f3: Bit32BinField): Bit32BinField {.inline.} =
  Bit32BinField.init(
    bitor2(f1.left, f2.left, f3.left),
    bitor2(f1.center, f2.center, f3.center),
    bitor2(f1.right, f2.right, f3.right),
  )

func sum*(f1, f2, f3, f4: Bit32BinField): Bit32BinField {.inline.} =
  Bit32BinField.init(
    bitor2(f1.left, f2.left, f3.left, f4.left),
    bitor2(f1.center, f2.center, f3.center, f4.center),
    bitor2(f1.right, f2.right, f3.right, f4.right),
  )

func sum*(f1, f2, f3, f4, f5: Bit32BinField): Bit32BinField {.inline.} =
  Bit32BinField.init(
    bitor2(f1.left, f2.left, f3.left, f4.left, f5.left),
    bitor2(f1.center, f2.center, f3.center, f4.center, f5.center),
    bitor2(f1.right, f2.right, f3.right, f4.right, f5.right),
  )

func sum*(f1, f2, f3, f4, f5, f6: Bit32BinField): Bit32BinField {.inline.} =
  Bit32BinField.init(
    bitor2(f1.left, f2.left, f3.left, f4.left, f5.left, f6.left),
    bitor2(f1.center, f2.center, f3.center, f4.center, f5.center, f6.center),
    bitor2(f1.right, f2.right, f3.right, f4.right, f5.right, f6.right),
  )

func sum*(f1, f2, f3, f4, f5, f6, f7: Bit32BinField): Bit32BinField {.inline.} =
  Bit32BinField.init(
    bitor2(f1.left, f2.left, f3.left, f4.left, f5.left, f6.left, f7.left),
    bitor2(f1.center, f2.center, f3.center, f4.center, f5.center, f6.center, f7.center),
    bitor2(f1.right, f2.right, f3.right, f4.right, f5.right, f6.right, f7.right),
  )

func sum*(f1, f2, f3, f4, f5, f6, f7, f8: Bit32BinField): Bit32BinField {.inline.} =
  Bit32BinField.init(
    bitor2(f1.left, f2.left, f3.left, f4.left, f5.left, f6.left, f7.left, f8.left),
    bitor2(
      f1.center, f2.center, f3.center, f4.center, f5.center, f6.center, f7.center,
      f8.center,
    ),
    bitor2(
      f1.right, f2.right, f3.right, f4.right, f5.right, f6.right, f7.right, f8.right
    ),
  )

func prod*(f1, f2, f3: Bit32BinField): Bit32BinField {.inline.} =
  Bit32BinField.init(
    bitand2(f1.left, f2.left, f3.left),
    bitand2(f1.center, f2.center, f3.center),
    bitand2(f1.right, f2.right, f3.right),
  )

# ------------------------------------------------
# Keep
# ------------------------------------------------

func initAirMask(): uint32 {.inline.} =
  ## Returns `AirMask`.
  var mask = 0'u32
  for i in 0 ..< AirHeight:
    mask.setBitBE i.succ 2
    mask.setBitBE i.succ 18

  mask

const
  ValidMask = 0x3ffe_3ffe'u32
  AirMask = initAirMask()

func colMaskLeft(colOrd: int): uint32 {.inline.} =
  ## Returns the mask for the left with only the column bits one.
  0xffff_0000'u32 shr (colOrd shl 4)

func colMaskCenter(colOrd: int): uint32 {.inline.} =
  ## Returns the mask for the center with only the column bits one.
  0x0000_ffff'u32 shl ((3 and not colOrd) shl 4)

func colMaskRight(colOrd: int): uint32 {.inline.} =
  ## Returns the mask for the right with only the column bits one.
  0x0000_ffff'u32 shl ((5 and not colOrd) shl 4)

func kept*(self: Bit32BinField, row: Row): Bit32BinField {.inline.} =
  ## Returns the binary field with only the given row.
  self * (0x2000_2000'u32 shr row.ord)

func kept*(self: Bit32BinField, col: Col): Bit32BinField {.inline.} =
  ## Returns the binary field with only the given column.
  Bit32BinField.init(
    self.left and col.ord.colMaskLeft,
    self.center and col.ord.colMaskCenter,
    self.right and col.ord.colMaskRight,
  )

func keptValid*(self: Bit32BinField): Bit32BinField {.inline.} =
  ## Returns the binary field with only the valid area.
  self * ValidMask

func keptVisible*(self: Bit32BinField): Bit32BinField {.inline.} =
  ## Returns the binary field with only the visible area.
  self * 0x1ffe_1ffe'u32

func keptAir*(self: Bit32BinField): Bit32BinField {.inline.} =
  ## Returns the binary field with only the air area.
  self * AirMask

func keepValid*(self: var Bit32BinField) {.inline.} =
  ## Keeps only the valid area.
  self *= ValidMask

func keepValid(self: var uint32) {.inline.} =
  ## Keeps only the valid area.
  self.mask2 ValidMask

# ------------------------------------------------
# Clear
# ------------------------------------------------

func clear*(self: var Bit32BinField) {.inline.} =
  ## Clears the binary field.
  self.left.assign 0
  self.center.assign 0
  self.right.assign 0

func clear*(self: var Bit32BinField, col: Col) {.inline.} =
  ## Clears the binary field only at the given column.
  self.left.clearMask2 col.ord.colMaskLeft
  self.center.clearMask2 col.ord.colMaskCenter
  self.right.clearMask2 col.ord.colMaskRight

# ------------------------------------------------
# Population Count
# ------------------------------------------------

func cntOne*(self: Bit32BinField): int {.inline.} =
  ## Returns the number of one bits.
  self.left.countOnes + self.center.countOnes + self.right.countOnes

# ------------------------------------------------
# Shift
# ------------------------------------------------

func shiftUpRaw*(self: var Bit32BinField) {.inline.} =
  ## Shifts the binary field upward.
  self.left.assign self.left shl 1
  self.center.assign self.center shl 1
  self.right.assign self.right shl 1

func shiftDownRaw*(self: var Bit32BinField) {.inline.} =
  ## Shifts the binary field downward.
  self.left.assign self.left shr 1
  self.center.assign self.center shr 1
  self.right.assign self.right shr 1

func shiftRightRaw*(self: var Bit32BinField) {.inline.} =
  ## Shifts the binary field rightward.
  self.left.assign self.left shr 16
  self.center.assign (self.left shl 16) or (self.center shr 16)
  self.right.assign (self.center shl 16) or (self.right shr 16)

func shiftLeftRaw*(self: var Bit32BinField) {.inline.} =
  ## Shifts the binary field rightward.
  self.left.assign (self.left shl 16) or (self.center shr 16)
  self.center.assign (self.center shl 16) or (self.right shr 16)
  self.right.assign self.right shl 16

func shiftedUpRaw*(self: Bit32BinField): Bit32BinField {.inline.} =
  ## Returns the binary field shifted upward.
  self.dup shiftUpRaw

func shiftedDownRaw*(self: Bit32BinField): Bit32BinField {.inline.} =
  ## Returns the binary field shifted downward.
  self.dup shiftDownRaw

func shiftedRightRaw*(self: Bit32BinField): Bit32BinField {.inline.} =
  ## Returns the binary field shifted rightward.
  self.dup shiftRightRaw

func shiftedLeftRaw*(self: Bit32BinField): Bit32BinField {.inline.} =
  ## Returns the binary field shifted leftward.
  self.dup shiftLeftRaw

# ------------------------------------------------
# Flip
# ------------------------------------------------

func flipped(val: uint32): uint32 {.inline.} =
  ## Returns the value two columns flipped.
  (val.bitsliced 16 ..< 32) or (val shl 16)

func flipV*(self: var Bit32BinField) {.inline.} =
  ## Flips the binary field vertically.
  self.left.assign (self.left.reverseBits shr 1).flipped
  self.center.assign (self.center.reverseBits shr 1).flipped
  self.right.assign (self.right.reverseBits shr 1).flipped

func flipH*(self: var Bit32BinField) {.inline.} =
  ## Flips the binary field horizontally.
  let newRight = self.left.flipped

  self.left.assign self.right.flipped
  self.center.assign self.center.flipped
  self.right.assign newRight

func flippedV*(self: Bit32BinField): Bit32BinField {.inline.} =
  ## Returns the binary field flipped vertically.
  self.dup flipV

func flippedH*(self: Bit32BinField): Bit32BinField {.inline.} =
  ## Returns the binary field flipped horizontally.
  self.dup flipH

# ------------------------------------------------
# Indexer
# ------------------------------------------------

func idxFromMsb(row: static Row, col: Col): int {.inline.} =
  ## Returns the bit index for indexers.
  col.ord shl 4 + static(row.ord + 2)

func idxFromMsb(row: Row, col: Col): int {.inline.} =
  ## Returns the bit index for indexers.
  col.ord shl 4 + row.ord + 2

func `[]`*(self: Bit32BinField, row: static Row, col: static Col): bool {.inline.} =
  when col in {Col0, Col1}:
    self.left.getBitBE static(idxFromMsb(row, col))
  elif col in {Col2, Col3}:
    self.center.getBitBE static(idxFromMsb(row, col.pred 2))
  else:
    self.right.getBitBE static(idxFromMsb(row, col.pred 4))

func `[]`*(self: Bit32BinField, row: static Row, col: Col): bool {.inline.} =
  case col
  of Col0, Col1:
    self.left.getBitBE idxFromMsb(row, col)
  of Col2, Col3:
    self.center.getBitBE idxFromMsb(row, col.pred 2)
  of Col4, Col5:
    self.right.getBitBE idxFromMsb(row, col.pred 4)

func `[]`*(self: Bit32BinField, row: Row, col: Col): bool {.inline.} =
  case col
  of Col0, Col1:
    self.left.getBitBE idxFromMsb(row, col)
  of Col2, Col3:
    self.center.getBitBE idxFromMsb(row, col.pred 2)
  of Col4, Col5:
    self.right.getBitBE idxFromMsb(row, col.pred 4)

func `[]=`*(self: var Bit32BinField, row: Row, col: Col, val: bool) {.inline.} =
  case col
  of Col0, Col1:
    self.left.changeBitBE idxFromMsb(row, col), val
  of Col2, Col3:
    self.center.changeBitBE idxFromMsb(row, col.pred 2), val
  of Col4, Col5:
    self.right.changeBitBE idxFromMsb(row, col.pred 4), val

# ------------------------------------------------
# Insert / Delete
# ------------------------------------------------

func isInWater(row: Row, rule: static Rule): bool {.inline.} =
  ## Returns `true` if the row is in the water.
  (static rule == Water) and row.ord + WaterHeight >= Height

func insert(
    self: var uint32, col0OrCol1: Col, row: Row, val: bool, rule: static Rule
) {.inline.} =
  ## Inserts the value and shifts the binary field's element.
  ## If (row, col) is in the air, shifts the binary field's element upward above where
  ## inserted.
  ## If it is in the water, shifts the binary field's element downward below where
  ## inserted.
  let
    colShift = col0OrCol1.ord shl 4
    rowColShift = colShift + row.ord
    colMask = 0xffff_0000'u32 shr colShift

  let
    below: uint32
    above: uint32
  if row.isInWater rule:
    let belowMask = 0x3fff_0000'u32 shr rowColShift
    below = (self and belowMask) shr 1
    above = self and not belowMask
  else:
    let belowMask = 0x1fff_0000'u32 shr rowColShift
    below = self and belowMask
    above = (self and not belowMask) shl 1

  self.assign bitor2((below or above) and colMask, self and not colMask)
  self.changeBitBE rowColShift + 2, val
  self.keepValid

func insert*(
    self: var Bit32BinField, row: Row, col: Col, val: bool, rule: static Rule
) {.inline.} =
  ## Inserts the value and shifts the binary field.
  ## If (row, col) is in the air, shifts the binary field upward above where inserted.
  ## If it is in the water, shifts the binary field downward below where inserted.
  case col
  of Col0, Col1:
    self.left.insert col, row, val, rule
  of Col2, Col3:
    self.center.insert col.pred 2, row, val, rule
  of Col4, Col5:
    self.right.insert col.pred 4, row, val, rule

func delete(self: var uint32, col0OrCol1: Col, row: Row, rule: static Rule) {.inline.} =
  ## Deletes the value and shifts the binary field's element.
  ## If (row, col) is in the air, shifts the binary field's element downward above
  ## where deleted.
  ## If it is in the water, shifts the binary field's element upward below where
  ## deleted.
  let
    colShift = col0OrCol1.ord shl 4
    rowColShift = colShift + row.ord
    colMask = 0xffff_0000'u32 shr colShift
    belowMask = 0x1fff_0000'u32 shr rowColShift
    aboveMask = not (0x3fff_0000'u32 shr rowColShift)

  let
    below: uint32
    above: uint32
  if row.isInWater rule:
    below = (self and belowMask) shl 1
    above = self and aboveMask
  else:
    below = self and belowMask
    above = (self and aboveMask) shr 1

  self.assign bitor2((below or above) and colMask, self and not colMask)
  self.keepValid

func delete*(
    self: var Bit32BinField, row: Row, col: Col, rule: static Rule
) {.inline.} =
  ## Deletes the value and shifts the binary field.
  ## If (row, col) is in the air, shifts the binary field downward above where deleted.
  ## If it is in the water, shifts the binary field upward below where deleted.
  case col
  of Col0, Col1:
    self.left.delete col, row, rule
  of Col2, Col3:
    self.center.delete col.pred 2, row, rule
  of Col4, Col5:
    self.right.delete col.pred 4, row, rule

# ------------------------------------------------
# Drop
# ------------------------------------------------

func colVal(self: Bit32BinField, col: static Col): uint32 {.inline.} =
  ## Returns the value corresponding to the column.
  when col == Col0:
    self.left.bitsliced 16 ..< 32
  elif col == Col1:
    self.left.bitsliced 0 ..< 16
  elif col == Col2:
    self.center.bitsliced 16 ..< 32
  elif col == Col3:
    self.center.bitsliced 0 ..< 16
  elif col == Col4:
    self.right.bitsliced 16 ..< 32
  else:
    self.right.bitsliced 0 ..< 16

func toDropMask*(existField: Bit32BinField): Bit32DropMask {.inline.} =
  ## Returns a drop mask converted from the exist field.
  var dropMask: Bit32DropMask
  staticFor(col, Col):
    dropMask[col].assign PextMask[uint32].init existField.colVal col

  dropMask

func drop*(self: var Bit32BinField, mask: Bit32DropMask) {.inline.} =
  ## Floating cells drop.
  self.left.assign (self.colVal(Col0).pext(mask[Col0]) shl 17) or
    (self.colVal(Col1).pext(mask[Col1]) shl 1)
  self.center.assign (self.colVal(Col2).pext(mask[Col2]) shl 17) or
    (self.colVal(Col3).pext(mask[Col3]) shl 1)
  self.right.assign (self.colVal(Col4).pext(mask[Col4]) shl 17) or
    (self.colVal(Col5).pext(mask[Col5]) shl 1)

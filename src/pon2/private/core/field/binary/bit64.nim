## This module implements binary fields with 64bit operations.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[bitops, sugar]
import stew/[bitops2]
import ../../../[assign3, bitops3, staticfor2]
import ../../../../core/[common, rule]

type
  Bit64BinField* = object ## Binary field with 64bit operations.
    col012: uint64 # use higher 16*3 bits
    col345: uint64 # use higher 16*3 bits

  Bit64DropMask* = array[Col, PextMask[uint64]] ## Mask used in dropping.

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init(T: type Bit64BinField, col012: uint64, col345: uint64): T {.inline.} =
  T(col012: col012, col345: col345)

func initZero*(T: type Bit64BinField): Bit64BinField {.inline.} =
  ## Returns the binary field with all elements zero.
  T.init(0, 0)

func initOne*(T: type Bit64BinField): Bit64BinField {.inline.} =
  ## Returns the binary field with all elements one.
  const Initializer = 0xffff_ffff_ffff_ffff'u64
  T.init(Initializer, Initializer)

func initFloor*(T: type Bit64BinField): Bit64BinField {.inline.} =
  ## Returns the binary field with floor bits one.
  const Initializer = 0x0001_0001_0001_0000'u64
  T.init(Initializer, Initializer)

func initLowerAir*(T: type Bit64BinField): Bit64BinField {.inline.} =
  ## Returns the binary field with lower air bits one.
  const Initializer = 0x0001_0001_0001_0000'u64 shl WaterHeight.succ
  T.init(Initializer, Initializer)

func initUpperWater*(T: type Bit64BinField): Bit64BinField {.inline.} =
  ## Returns the binary field with upper underwater bits one.
  const Initializer = 0x0001_0001_0001_0000'u64 shl WaterHeight
  T.init(Initializer, Initializer)

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `+`*(f1, f2: Bit64BinField): Bit64BinField {.inline.} =
  Bit64BinField.init(f1.col012 or f2.col012, f1.col345 or f2.col345)

func `-`*(f1, f2: Bit64BinField): Bit64BinField {.inline.} =
  Bit64BinField.init(f1.col012 *~ f2.col012, f1.col345 *~ f2.col345)

func `*`*(f1, f2: Bit64BinField): Bit64BinField {.inline.} =
  Bit64BinField.init(f1.col012 and f2.col012, f1.col345 and f2.col345)

func `*`(self: Bit64BinField, val: uint64): Bit64BinField {.inline.} =
  Bit64BinField.init(self.col012 and val, self.col345 and val)

func `xor`*(f1, f2: Bit64BinField): Bit64BinField {.inline.} =
  Bit64BinField.init(f1.col012 xor f2.col012, f1.col345 xor f2.col345)

func `+=`*(f1: var Bit64BinField, f2: Bit64BinField) {.inline.} =
  f1.col012.assign f1.col012 or f2.col012
  f1.col345.assign f1.col345 or f2.col345

func `-=`*(f1: var Bit64BinField, f2: Bit64BinField) {.inline.} =
  f1.col012.assign f1.col012 *~ f2.col012
  f1.col345.assign f1.col345 *~ f2.col345

func `*=`*(f1: var Bit64BinField, f2: Bit64BinField) {.inline.} =
  f1.col012.assign f1.col012 and f2.col012
  f1.col345.assign f1.col345 and f2.col345

func `*=`(self: var Bit64BinField, val: uint64) {.inline.} =
  self.col012.assign self.col012 and val
  self.col345.assign self.col345 and val

func sum*(f1, f2, f3: Bit64BinField): Bit64BinField {.inline.} =
  Bit64BinField.init(
    bitor2(f1.col012, f2.col012, f3.col012), bitor2(f1.col345, f2.col345, f3.col345)
  )

func sum*(f1, f2, f3, f4: Bit64BinField): Bit64BinField {.inline.} =
  Bit64BinField.init(
    bitor2(f1.col012, f2.col012, f3.col012, f4.col012),
    bitor2(f1.col345, f2.col345, f3.col345, f4.col345),
  )

func sum*(f1, f2, f3, f4, f5: Bit64BinField): Bit64BinField {.inline.} =
  Bit64BinField.init(
    bitor2(f1.col012, f2.col012, f3.col012, f4.col012, f5.col012),
    bitor2(f1.col345, f2.col345, f3.col345, f4.col345, f5.col345),
  )

func sum*(f1, f2, f3, f4, f5, f6: Bit64BinField): Bit64BinField {.inline.} =
  Bit64BinField.init(
    bitor2(f1.col012, f2.col012, f3.col012, f4.col012, f5.col012, f6.col012),
    bitor2(f1.col345, f2.col345, f3.col345, f4.col345, f5.col345, f6.col345),
  )

func sum*(f1, f2, f3, f4, f5, f6, f7: Bit64BinField): Bit64BinField {.inline.} =
  Bit64BinField.init(
    bitor2(f1.col012, f2.col012, f3.col012, f4.col012, f5.col012, f6.col012, f7.col012),
    bitor2(f1.col345, f2.col345, f3.col345, f4.col345, f5.col345, f6.col345, f7.col345),
  )

func sum*(f1, f2, f3, f4, f5, f6, f7, f8: Bit64BinField): Bit64BinField {.inline.} =
  Bit64BinField.init(
    bitor2(
      f1.col012, f2.col012, f3.col012, f4.col012, f5.col012, f6.col012, f7.col012,
      f8.col012,
    ),
    bitor2(
      f1.col345, f2.col345, f3.col345, f4.col345, f5.col345, f6.col345, f7.col345,
      f8.col345,
    ),
  )

func prod*(f1, f2, f3: Bit64BinField): Bit64BinField {.inline.} =
  Bit64BinField.init(
    bitand2(f1.col012, f2.col012, f3.col012), bitand2(f1.col345, f2.col345, f3.col345)
  )

# ------------------------------------------------
# Keep
# ------------------------------------------------

func initAirMask(): uint64 {.inline.} =
  ## Returns `AirMask`.
  var mask = 0'u64
  for i in 0 ..< AirHeight:
    mask.setBitBE i.succ 2
    mask.setBitBE i.succ 18
    mask.setBitBE i.succ 34

  mask

const
  ValidMask = 0x3ffe_3ffe_3ffe_0000'u64
  AirMask = initAirMask()

func writeColMasks(col: Col, mask012, mask345: out uint64) {.inline.} =
  ## Writes the masks with only the column bits one.
  const MaskBase = 0xffff_0000_0000_0000'u64

  case col
  of Col0, Col1, Col2:
    mask012 = MaskBase shr (col.ord shl 4)
    mask345 = 0
  of Col3, Col4, Col5:
    mask012 = 0
    mask345 = MaskBase shr (col.pred(3).ord shl 4)

func kept*(self: Bit64BinField, row: Row): Bit64BinField {.inline.} =
  ## Returns the binary field with only the given row.
  self * (0x2000_2000_2000_0000'u64 shr row.ord)

func kept*(self: Bit64BinField, col: Col): Bit64BinField {.inline.} =
  ## Returns the binary field with only the given column.
  var mask012 {.noinit.}, mask345 {.noinit.}: uint64
  col.writeColMasks mask012, mask345

  Bit64BinField.init(self.col012 and mask012, self.col345 and mask345)

func keptValid*(self: Bit64BinField): Bit64BinField {.inline.} =
  ## Returns the binary field with only the valid area.
  self * ValidMask

func keptVisible*(self: Bit64BinField): Bit64BinField {.inline.} =
  ## Returns the binary field with only the visible area.
  self * 0x1ffe_1ffe_1ffe_0000'u64

func keptAir*(self: Bit64BinField): Bit64BinField {.inline.} =
  ## Returns the binary field with only the air area.
  self * AirMask

func keepValid*(self: var Bit64BinField) {.inline.} =
  ## Keeps only the valid area.
  self *= ValidMask

func keptValid(self: uint64): uint64 {.inline.} =
  ## Returns the value with only the valid area.
  self and ValidMask

# ------------------------------------------------
# Clear
# ------------------------------------------------

func clear*(self: var Bit64BinField) {.inline.} =
  ## Clears the binary field.
  self.col012.assign 0
  self.col345.assign 0

func clear*(self: var Bit64BinField, col: Col) {.inline.} =
  ## Clears the binary field only at the given column.
  var mask012 {.noinit.}, mask345 {.noinit.}: uint64
  col.writeColMasks mask012, mask345

  self.col012.assign self.col012 *~ mask012
  self.col345.assign self.col345 *~ mask345

# ------------------------------------------------
# Population Count
# ------------------------------------------------

func popcnt*(self: Bit64BinField): int {.inline.} =
  ## Returns the population count.
  self.col012.countOnes + self.col345.countOnes

# ------------------------------------------------
# Shift - In-place
# ------------------------------------------------

func shiftUpRaw*(self: var Bit64BinField) {.inline.} =
  ## Shifts the binary field upward.
  self.col012.assign self.col012 shl 1
  self.col345.assign self.col345 shl 1

func shiftUp*(self: var Bit64BinField) {.inline.} =
  ## Shifts the binary field upward and extracts the valid area.
  self.col012.assign (self.col012 shl 1).keptValid
  self.col345.assign (self.col345 shl 1).keptValid

func shiftDownRaw*(self: var Bit64BinField) {.inline.} =
  ## Shifts the binary field downward.
  self.col012.assign self.col012 shr 1
  self.col345.assign self.col345 shr 1

func shiftDown*(self: var Bit64BinField) {.inline.} =
  ## Shifts the binary field downward and extracts the valid area.
  self.col012.assign (self.col012 shr 1).keptValid
  self.col345.assign (self.col345 shr 1).keptValid

func shiftRightRaw*(self: var Bit64BinField) {.inline.} =
  ## Shifts the binary field rightward.
  let
    new012 = self.col012 shr 16
    new345 = (self.col012 shl 32) or (self.col345 shr 16)

  self.col012.assign new012
  self.col345.assign new345

func shiftRight*(self: var Bit64BinField) {.inline.} =
  ## Shifts the binary field rightward and extracts the valid area.
  let
    new012 = (self.col012 shr 16).keptValid
    new345 = (self.col012 shl 32) or (self.col345 shr 16).keptValid

  self.col012.assign new012
  self.col345.assign new345

func shiftLeftRaw*(self: var Bit64BinField) {.inline.} =
  ## Shifts the binary field leftward.
  let
    newLeft = (self.col012 shl 16) or (self.col345 shr 32)
    newRight = self.col345 shl 16

  self.col012.assign newLeft
  self.col345.assign newRight

func shiftLeft*(self: var Bit64BinField) {.inline.} =
  ## Shifts the binary field leftward and extracts the valid area.
  let
    newLeft = (self.col012 shl 16) or (self.col345 shr 32).keptValid
    newRight = self.col345 shl 16

  self.col012.assign newLeft
  self.col345.assign newRight

# ------------------------------------------------
# Shift - Out-place
# ------------------------------------------------

func shiftedUpRaw*(self: Bit64BinField): Bit64BinField {.inline.} =
  ## Returns the binary field shifted upward.
  self.dup shiftUpRaw

func shiftedUp*(self: Bit64BinField): Bit64BinField {.inline.} =
  ## Returns the binary field shifted upward and extracted the valid area.
  self.dup shiftUp

func shiftedDownRaw*(self: Bit64BinField): Bit64BinField {.inline.} =
  ## Returns the binary field shifted downward.
  self.dup shiftDownRaw

func shiftedDown*(self: Bit64BinField): Bit64BinField {.inline.} =
  ## Returns the binary field shifted downward and extracted the valid area.
  self.dup shiftDown

func shiftedRightRaw*(self: Bit64BinField): Bit64BinField {.inline.} =
  ## Returns the binary field shifted rightward.
  self.dup shiftRightRaw

func shiftedRight*(self: Bit64BinField): Bit64BinField {.inline.} =
  ## Returns the binary field shifted rightward and extracted the valid area.
  self.dup shiftRight

func shiftedLeftRaw*(self: Bit64BinField): Bit64BinField {.inline.} =
  ## Returns the binary field shifted leftward.
  self.dup shiftLeftRaw

func shiftedLeft*(self: Bit64BinField): Bit64BinField {.inline.} =
  ## Returns the binary field shifted leftward and extracted the valid area.
  self.dup shiftLeft

# ------------------------------------------------
# Flip
# ------------------------------------------------

func flipped(val: uint64): uint64 {.inline.} =
  ## Returns the value three columns flipped.
  bitor2(
    val shl 32,
    val and 0x0000_ffff_0000_0000'u64,
    (val and 0xffff_0000_0000_0000'u64) shr 32,
  )

func flipVertical*(self: var Bit64BinField) {.inline.} =
  ## Flips the binary field vertically.
  self.col012.assign (self.col012.reverseBits shl 15).flipped
  self.col345.assign (self.col345.reverseBits shl 15).flipped

func flipHorizontal*(self: var Bit64BinField) {.inline.} =
  ## Flips the binary field horizontally.
  let
    new012 = self.col345.flipped
    new345 = self.col012.flipped

  self.col012.assign new012
  self.col345.assign new345

func flippedVertical*(self: Bit64BinField): Bit64BinField {.inline.} =
  ## Returns the binary field flipped vertically.
  self.dup flipVertical

func flippedHorizontal*(self: Bit64BinField): Bit64BinField {.inline.} =
  ## Returns the binary field flipped horizontally.
  self.dup flipHorizontal

# ------------------------------------------------
# Indexer
# ------------------------------------------------

func idxFromMsb(row: Row, col: Col): int {.inline.} =
  ## Returns the bit index for indexers.
  col.ord shl 4 + (row.ord + 2)

func `[]`*(self: Bit64BinField, row: static Row, col: static Col): bool {.inline.} =
  when col in {Col0, Col1, Col2}:
    self.col012.getBitBE static(idxFromMsb(row, col))
  else:
    self.col345.getBitBE static(idxFromMsb(row, col.pred 3))

func `[]`*(self: Bit64BinField, row: Row, col: Col): bool {.inline.} =
  case col
  of Col0, Col1, Col2:
    self.col012.getBitBE idxFromMsb(row, col)
  of Col3, Col4, Col5:
    self.col345.getBitBE idxFromMsb(row, col.pred 3)

func `[]=`*(self: var Bit64BinField, row: Row, col: Col, val: bool) {.inline.} =
  case col
  of Col0, Col1, Col2:
    self.col012.changeBitBE idxFromMsb(row, col), val
  of Col3, Col4, Col5:
    self.col345.changeBitBE idxFromMsb(row, col.pred 3), val

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
    self: var Bit64BinField, row: Row, col: Col, val: bool, rule: static Rule
) {.inline.} =
  ## Inserts the value and shifts the binary field.
  ## If (row, col) is in the air, shifts the binary field upward above where inserted.
  ## If it is in the water, shifts the binary field downward below where inserted.
  case col
  of Col0, Col1, Col2:
    self.col012.insert col, row, val, rule
  of Col3, Col4, Col5:
    self.col345.insert col.pred 3, row, val, rule

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

func delete*(
    self: var Bit64BinField, row: Row, col: Col, rule: static Rule
) {.inline.} =
  ## Deletes the value and shifts the binary field.
  ## If (row, col) is in the air, shifts the binary field downward above where deleted.
  ## If it is in the water, shifts the binary field upward below where deleted.
  case col
  of Col0, Col1, Col2:
    self.col012.delete col, row, rule
  of Col3, Col4, Col5:
    self.col345.delete col.pred 3, row, rule

# ------------------------------------------------
# Drop
# ------------------------------------------------

func colVal(self: Bit64BinField, col: static Col): uint64 {.inline.} =
  ## Returns the value corresponding to the column.
  when col == Col0:
    self.col012.bextr(48, 16)
  elif col == Col1:
    self.col012.bextr(32, 16)
  elif col == Col2:
    self.col012.bextr(16, 16)
  elif col == Col3:
    self.col345.bextr(48, 16)
  elif col == Col4:
    self.col345.bextr(32, 16)
  else:
    self.col345.bextr(16, 16)

func toDropMask*(existField: Bit64BinField): Bit64DropMask {.inline.} =
  ## Returns a drop mask converted from the exist field.
  {.push warning[Uninit]: off.}
  var dropMask: Bit64DropMask
  staticFor(col, Col):
    dropMask[col].assign PextMask[uint64].init existField.colVal col

  return dropMask
  {.pop.}

func drop*(self: var Bit64BinField, mask: Bit64DropMask) {.inline.} =
  ## Falling floating cells.
  self.col012.assign bitor2(
    self.colVal(Col0).pext(mask[Col0]) shl 49,
    self.colVal(Col1).pext(mask[Col1]) shl 33,
    self.colVal(Col2).pext(mask[Col2]) shl 17,
  )
  self.col345.assign bitor2(
    self.colVal(Col3).pext(mask[Col3]) shl 49,
    self.colVal(Col4).pext(mask[Col4]) shl 33,
    self.colVal(Col5).pext(mask[Col5]) shl 17,
  )

## This module implements binary fields with 32bit operations.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import ../../[assign, bitops, expand, staticcase, staticfor]
import ../../../core/[behaviour, common]

type Bit32BinaryField* = array[3, uint32] ## Binary field with 32bit operations.

defineExpand "6", "0", "1", "2", "3", "4", "5"
defineExpand "3", "0", "1", "2"

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const ValidMask = 0x3ffe_3ffe'u32

func init*(T: type Bit32BinaryField): T {.inline, noinit.} =
  ## Returns the binary field with all elements zero.
  [0, 0, 0]

func initOne*(T: type Bit32BinaryField): T {.inline, noinit.} =
  ## Returns the binary field with all valid elements one.
  [ValidMask, ValidMask, ValidMask]

func initFloor*(T: type Bit32BinaryField): T {.inline, noinit.} =
  ## Returns the binary field with floor bits one.
  const Initializer = 0x0001_0001'u32
  [Initializer, Initializer, Initializer]

func initLowerAir*(T: type Bit32BinaryField): T {.inline, noinit.} =
  ## Returns the binary field with lower air bits one.
  const Initializer = 0x0001_0001'u32 shl WaterHeight.succ
  [Initializer, Initializer, Initializer]

func initUpperWater*(T: type Bit32BinaryField): T {.inline, noinit.} =
  ## Returns the binary field with upper underwater bits one.
  const Initializer = 0x0001_0001'u32 shl WaterHeight
  [Initializer, Initializer, Initializer]

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `+`*(f1, f2: Bit32BinaryField): Bit32BinaryField {.inline, noinit.} =
  [f1[0] or f2[0], f1[1] or f2[1], f1[2] or f2[2]]

func `-`*(f1, f2: Bit32BinaryField): Bit32BinaryField {.inline, noinit.} =
  [f1[0] *~ f2[0], f1[1] *~ f2[1], f1[2] *~ f2[2]]

func `*`*(f1, f2: Bit32BinaryField): Bit32BinaryField {.inline, noinit.} =
  [f1[0] and f2[0], f1[1] and f2[1], f1[2] and f2[2]]

func `*`(self: Bit32BinaryField, val: uint32): Bit32BinaryField {.inline, noinit.} =
  [self[0] and val, self[1] and val, self[2] and val]

func `xor`*(f1, f2: Bit32BinaryField): Bit32BinaryField {.inline, noinit.} =
  [f1[0] xor f2[0], f1[1] xor f2[1], f1[2] xor f2[2]]

func `+=`*(f1: var Bit32BinaryField, f2: Bit32BinaryField) {.inline, noinit.} =
  staticFor(i, 0 ..< 3):
    f1[i].assign f1[i] or f2[i]

func `-=`*(f1: var Bit32BinaryField, f2: Bit32BinaryField) {.inline, noinit.} =
  staticFor(i, 0 ..< 3):
    f1[i].assign f1[i] *~ f2[i]

func `*=`*(f1: var Bit32BinaryField, f2: Bit32BinaryField) {.inline, noinit.} =
  staticFor(i, 0 ..< 3):
    f1[i].assign f1[i] and f2[i]

func `*=`(self: var Bit32BinaryField, val: uint32) {.inline, noinit.} =
  staticFor(i, 0 ..< 3):
    self[i].assign self[i] and val

func sum*(f1, f2, f3: Bit32BinaryField): Bit32BinaryField {.inline, noinit.} =
  [
    bitor2(f1[0], f2[0], f3[0]),
    bitor2(f1[1], f2[1], f3[1]),
    bitor2(f1[2], f2[2], f3[2]),
  ]

func sum*(f1, f2, f3, f4: Bit32BinaryField): Bit32BinaryField {.inline, noinit.} =
  [
    bitor2(f1[0], f2[0], f3[0], f4[0]),
    bitor2(f1[1], f2[1], f3[1], f4[1]),
    bitor2(f1[2], f2[2], f3[2], f4[2]),
  ]

func sum*(f1, f2, f3, f4, f5: Bit32BinaryField): Bit32BinaryField {.inline, noinit.} =
  [
    bitor2(f1[0], f2[0], f3[0], f4[0], f5[0]),
    bitor2(f1[1], f2[1], f3[1], f4[1], f5[1]),
    bitor2(f1[2], f2[2], f3[2], f4[2], f5[2]),
  ]

func sum*(
    f1, f2, f3, f4, f5, f6: Bit32BinaryField
): Bit32BinaryField {.inline, noinit.} =
  [
    bitor2(f1[0], f2[0], f3[0], f4[0], f5[0], f6[0]),
    bitor2(f1[1], f2[1], f3[1], f4[1], f5[1], f6[1]),
    bitor2(f1[2], f2[2], f3[2], f4[2], f5[2], f6[2]),
  ]

func sum*(
    f1, f2, f3, f4, f5, f6, f7: Bit32BinaryField
): Bit32BinaryField {.inline, noinit.} =
  [
    bitor2(f1[0], f2[0], f3[0], f4[0], f5[0], f6[0], f7[0]),
    bitor2(f1[1], f2[1], f3[1], f4[1], f5[1], f6[1], f7[1]),
    bitor2(f1[2], f2[2], f3[2], f4[2], f5[2], f6[2], f7[2]),
  ]

func sum*(
    f1, f2, f3, f4, f5, f6, f7, f8: Bit32BinaryField
): Bit32BinaryField {.inline, noinit.} =
  [
    bitor2(f1[0], f2[0], f3[0], f4[0], f5[0], f6[0], f7[0], f8[0]),
    bitor2(f1[1], f2[1], f3[1], f4[1], f5[1], f6[1], f7[1], f8[1]),
    bitor2(f1[2], f2[2], f3[2], f4[2], f5[2], f6[2], f7[2], f8[2]),
  ]

func product*(f1, f2, f3: Bit32BinaryField): Bit32BinaryField {.inline, noinit.} =
  [
    bitand2(f1[0], f2[0], f3[0]),
    bitand2(f1[1], f2[1], f3[1]),
    bitand2(f1[2], f2[2], f3[2]),
  ]

# ------------------------------------------------
# Keep
# ------------------------------------------------

func initAirMask(): uint32 {.inline, noinit.} =
  ## Returns `AirMask`.
  var mask = 0'u32
  for i in 0 ..< AirHeight:
    mask.setBitBE 2.succ i
    mask.setBitBE 18.succ i

  mask

const
  AirMask = initAirMask()
  ColMaskBase = 0xffff_0000'u32

template withColMasks(col: Col, body: untyped): untyped =
  ## Runs `body` with `mask0`, `mask1`, and `mask2` exposed.
  case col
  of Col0, Col1:
    let
      mask0 {.inject.} = ColMaskBase shr (col.ord shl 4)
      mask1 {.inject.} = 0'u32
      mask2 {.inject.} = 0'u32

    body
  of Col2, Col3:
    let
      mask0 {.inject.} = 0'u32
      mask1 {.inject.} = ColMaskBase shr (col.pred(2).ord shl 4)
      mask2 {.inject.} = 0'u32

    body
  of Col4, Col5:
    let
      mask0 {.inject.} = 0'u32
      mask1 {.inject.} = 0'u32
      mask2 {.inject.} = ColMaskBase shr (col.pred(4).ord shl 4)

    body

func kept*(self: Bit32BinaryField, row: Row): Bit32BinaryField {.inline, noinit.} =
  ## Returns the binary field with only the given row.
  self * (0x2000_2000'u32 shr row.ord)

func kept*(self: Bit32BinaryField, col: Col): Bit32BinaryField {.inline, noinit.} =
  ## Returns the binary field with only the given column.
  col.withColMasks:
    [self[0] and mask0, self[1] and mask1, self[2] and mask2]

func keptValid*(self: Bit32BinaryField): Bit32BinaryField {.inline, noinit.} =
  ## Returns the binary field with only the valid area.
  self * ValidMask

func keptVisible*(self: Bit32BinaryField): Bit32BinaryField {.inline, noinit.} =
  ## Returns the binary field with only the visible area.
  self * 0x1ffe_1ffe'u32

func keptAir*(self: Bit32BinaryField): Bit32BinaryField {.inline, noinit.} =
  ## Returns the binary field with only the air area.
  self * AirMask

func keepValid*(self: var Bit32BinaryField) {.inline, noinit.} =
  ## Keeps only the valid area.
  self *= ValidMask

func keptValid(self: uint32): uint32 {.inline, noinit.} =
  ## Returns the value with only the valid area.
  self and ValidMask

# ------------------------------------------------
# Clear
# ------------------------------------------------

func clear*(self: var Bit32BinaryField) {.inline, noinit.} =
  ## Clears the binary field.
  staticFor(i, 0 ..< 3):
    self[i].assign 0

# ------------------------------------------------
# Replace
# ------------------------------------------------

func replace*(
    self: var Bit32BinaryField, col: Col, after: Bit32BinaryField
) {.inline, noinit.} =
  ## Replaces the column of the binary field by `after`.
  col.withColMasks:
    expand3 mask:
      self[_].assign (self[_] *~ mask) or (after[_] and mask)

# ------------------------------------------------
# Population Count
# ------------------------------------------------

func popcnt*(self: Bit32BinaryField): int {.inline, noinit.} =
  ## Returns the population count.
  self[0].countOnes + self[1].countOnes + self[2].countOnes

# ------------------------------------------------
# Shift - Out-place
# NOTE: `sugar.dup` decreases the performance.
# ------------------------------------------------

template shiftedUpRawImpl(self: Bit32BinaryField, body: untyped): untyped =
  ## Runs `body` with `after0`, `after1`, and `after2` exposed.
  let
    after0 {.inject.} = self[0] shl 1
    after1 {.inject.} = self[1] shl 1
    after2 {.inject.} = self[2] shl 1

  body

template shiftedUpImpl(self: Bit32BinaryField, body: untyped): untyped =
  ## Runs `body` with `after0`, `after1`, and `after2` exposed.
  let
    after0 {.inject.} = (self[0] shl 1).keptValid
    after1 {.inject.} = (self[1] shl 1).keptValid
    after2 {.inject.} = (self[2] shl 1).keptValid

  body

template shiftedDownRawImpl(self: Bit32BinaryField, body: untyped): untyped =
  ## Runs `body` with `after0`, `after1`, and `after2` exposed.
  let
    after0 {.inject.} = self[0] shr 1
    after1 {.inject.} = self[1] shr 1
    after2 {.inject.} = self[2] shr 1

  body

template shiftedDownImpl(self: Bit32BinaryField, body: untyped): untyped =
  ## Runs `body` with `after0`, `after1`, and `after2` exposed.
  let
    after0 {.inject.} = (self[0] shr 1).keptValid
    after1 {.inject.} = (self[1] shr 1).keptValid
    after2 {.inject.} = (self[2] shr 1).keptValid

  body

template shiftedRightImpl(self: Bit32BinaryField, body: untyped): untyped =
  ## Runs `body` with `after0`, `after1`, and `after2` exposed.
  let
    after0 {.inject.} = self[0] shr 16
    after1 {.inject.} = (self[0] shl 16) or (self[1] shr 16)
    after2 {.inject.} = (self[1] shl 16) or (self[2] shr 16)

  body

template shiftedLeftImpl(self: Bit32BinaryField, body: untyped): untyped =
  ## Runs `body` with `after0`, `after1`, and `after2` exposed.
  let
    after0 {.inject.} = (self[0] shl 16) or (self[1] shr 16)
    after1 {.inject.} = (self[1] shl 16) or (self[2] shr 16)
    after2 {.inject.} = self[2] shl 16

  body

func shiftedUpRaw*(self: Bit32BinaryField): Bit32BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted upward.
  self.shiftedUpRawImpl:
    [after0, after1, after2]

func shiftedUp*(self: Bit32BinaryField): Bit32BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted upward and extracted the valid area.
  self.shiftedUpImpl:
    [after0, after1, after2]

func shiftedDownRaw*(self: Bit32BinaryField): Bit32BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted downward.
  self.shiftedDownRawImpl:
    [after0, after1, after2]

func shiftedDown*(self: Bit32BinaryField): Bit32BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted downward and extracted the valid area.
  self.shiftedDownImpl:
    [after0, after1, after2]

func shiftedRightRaw*(self: Bit32BinaryField): Bit32BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted rightward.
  self.shiftedRightImpl:
    [after0, after1, after2]

func shiftedRight*(self: Bit32BinaryField): Bit32BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted rightward and extracted the valid area.
  self.shiftedRightImpl:
    [after0, after1, after2]

func shiftedLeftRaw*(self: Bit32BinaryField): Bit32BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted leftward.
  self.shiftedLeftImpl:
    [after0, after1, after2]

func shiftedLeft*(self: Bit32BinaryField): Bit32BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted leftward and extracted the valid area.
  self.shiftedLeftImpl:
    [after0, after1, after2]

# ------------------------------------------------
# Shift - In-place
# ------------------------------------------------

func shiftUpRaw*(self: var Bit32BinaryField) {.inline, noinit.} =
  ## Shifts the binary field upward.
  self.shiftedUpRawImpl:
    expand3 after:
      self[_].assign after

func shiftUp*(self: var Bit32BinaryField) {.inline, noinit.} =
  ## Shifts the binary field upward and extracts the valid area.
  self.shiftedUpImpl:
    expand3 after:
      self[_].assign after

func shiftDownRaw*(self: var Bit32BinaryField) {.inline, noinit.} =
  ## Shifts the binary field downward.
  self.shiftedDownRawImpl:
    expand3 after:
      self[_].assign after

func shiftDown*(self: var Bit32BinaryField) {.inline, noinit.} =
  ## Shifts the binary field downward and extracts the valid area.
  self.shiftedDownImpl:
    expand3 after:
      self[_].assign after

func shiftRightRaw*(self: var Bit32BinaryField) {.inline, noinit.} =
  ## Shifts the binary field rightward.
  self.shiftedRightImpl:
    expand3 after:
      self[_].assign after

func shiftRight*(self: var Bit32BinaryField) {.inline, noinit.} =
  ## Shifts the binary field rightward and extracts the valid area.
  self.shiftedRightImpl:
    expand3 after:
      self[_].assign after

func shiftLeftRaw*(self: var Bit32BinaryField) {.inline, noinit.} =
  ## Shifts the binary field leftward.
  self.shiftedLeftImpl:
    expand3 after:
      self[_].assign after

func shiftLeft*(self: var Bit32BinaryField) {.inline, noinit.} =
  ## Shifts the binary field leftward and extracts the valid area.
  self.shiftedLeftImpl:
    expand3 after:
      self[_].assign after

# ------------------------------------------------
# Flip
# ------------------------------------------------

func flipped(val: uint32): uint32 {.inline, noinit.} =
  ## Returns the value two columns flipped.
  (val shr 16) or (val shl 16)

func flipVertical*(self: var Bit32BinaryField) {.inline, noinit.} =
  ## Flips the binary field vertically.
  staticFor(i, 0 ..< 2):
    self[i].assign (self[i].reverseBits shr 1).flipped

func flipHorizontal*(self: var Bit32BinaryField) {.inline, noinit.} =
  ## Flips the binary field horizontally.
  let
    after2 = self[0].flipped
    after1 = self[1].flipped
    after0 = self[2].flipped

  expand3 after:
    self[_].assign after

# ------------------------------------------------
# Rotate
# ------------------------------------------------

func rotate*(self: var Bit32BinaryField) {.inline, noinit.} =
  ## Rotates the binary field by 180 degrees.
  ## Ghost cells are cleared before the rotation.
  let
    visible = self.keptVisible

    after2 = visible[0].reverseBits shr 2
    after1 = visible[1].reverseBits shr 2
    after0 = visible[2].reverseBits shr 2

  expand3 after:
    self[_].assign after

func crossRotate*(self: var Bit32BinaryField) {.inline, noinit.} =
  ## Rotates the binary field by 180 degrees in groups of three rows.
  ## Ghost cells are cleared before the rotation.
  let
    visible = self.keptVisible

    rev0 = visible[0].reverseBits shr 2
    rev1 = visible[1].reverseBits shr 2
    rev2 = visible[2].reverseBits shr 2

    after0 = (rev1 shl 16) or (rev0 shr 16)
    after1 = (rev0 shl 16) or (rev2 shr 16)
    after2 = (rev2 shl 16) or (rev1 shr 16)

  expand3 after:
    self[_].assign after

# ------------------------------------------------
# Indexer
# ------------------------------------------------

func indexFromMsb(row: Row, col: Col): int {.inline, noinit.} =
  ## Returns the bit index for indexers.
  col.ord shl 4 + (row.ord + 2)

func `[]`*(
    self: Bit32BinaryField, row: static Row, col: static Col
): bool {.inline, noinit.} =
  staticCase:
    case col
    of Col0, Col1:
      self[0].getBitBE static(indexFromMsb(row, col))
    of Col2, Col3:
      self[1].getBitBE static(indexFromMsb(row, col.pred 2))
    of Col4, Col5:
      self[2].getBitBE static(indexFromMsb(row, col.pred 4))

func `[]`*(self: Bit32BinaryField, row: Row, col: Col): bool {.inline, noinit.} =
  case col
  of Col0, Col1:
    self[0].getBitBE indexFromMsb(row, col)
  of Col2, Col3:
    self[1].getBitBE indexFromMsb(row, col.pred 2)
  of Col4, Col5:
    self[2].getBitBE indexFromMsb(row, col.pred 4)

func `[]=`*(
    self: var Bit32BinaryField, row: Row, col: Col, val: bool
) {.inline, noinit.} =
  case col
  of Col0, Col1:
    self[0].changeBitBE indexFromMsb(row, col), val
  of Col2, Col3:
    self[1].changeBitBE indexFromMsb(row, col.pred 2), val
  of Col4, Col5:
    self[2].changeBitBE indexFromMsb(row, col.pred 4), val

# ------------------------------------------------
# Insert / Delete
# ------------------------------------------------

func isInWater(row: Row, phys: Phys): bool {.inline, noinit.} =
  ## Returns `true` if the row is in the water.
  phys == Phys.Water and row.ord + WaterHeight >= Height

func insert(
    self: var uint32, col: Col, row: Row, val: bool, phys: Phys
) {.inline, noinit.} =
  ## Inserts the value and shifts the binary field's element.
  ## If (row, col) is in the air, shifts the binary field's element upward above where
  ## inserted.
  ## If it is in the water, shifts the binary field's element downward below where
  ## inserted.
  let
    colShift = col.ord shl 4
    rowColShift = colShift + row.ord
    colMask = 0xffff_0000'u32 shr colShift

  let
    below: uint32
    above: uint32
  if row.isInWater phys:
    let belowMask = 0x3fff_0000'u32 shr rowColShift
    below = ((self and belowMask) shr 1).keptValid
    above = self *~ belowMask
  else:
    let belowMask = 0x1fff_0000'u32 shr rowColShift
    below = self and belowMask
    above = ((self *~ belowMask) shl 1).keptValid

  self.assign ((below or above) and colMask) or (self *~ colMask)
  self.changeBitBE rowColShift + 2, val

func insert*(
    self: var Bit32BinaryField, row: Row, col: Col, val: bool, phys: Phys
) {.inline, noinit.} =
  ## Inserts the value and shifts the binary field.
  ## If (row, col) is in the air, shifts the binary field upward above where inserted.
  ## If it is in the water, shifts the binary field downward below where inserted.
  case col
  of Col0, Col1:
    self[0].insert col, row, val, phys
  of Col2, Col3:
    self[1].insert col.pred 2, row, val, phys
  of Col4, Col5:
    self[2].insert col.pred 4, row, val, phys

func del(self: var uint32, col: Col, row: Row, phys: Phys) {.inline, noinit.} =
  ## Deletes the value and shifts the binary field's element.
  ## If (row, col) is in the air, shifts the binary field's element downward above
  ## where deleted.
  ## If it is in the water, shifts the binary field's element upward below where
  ## deleted.
  let
    colShift = col.ord shl 4
    rowColShift = colShift + row.ord
    colMask = 0xffff_0000'u32 shr colShift
    belowMask = 0x1fff_0000'u32 shr rowColShift
    aboveMask = not (0x3fff_0000'u32 shr rowColShift)

  let
    below: uint32
    above: uint32
  if row.isInWater phys:
    below = ((self and belowMask) shl 1).keptValid
    above = self and aboveMask
  else:
    below = self and belowMask
    above = ((self and aboveMask) shr 1).keptValid

  self.assign ((below or above) and colMask) or (self *~ colMask)

func del*(
    self: var Bit32BinaryField, row: Row, col: Col, phys: Phys
) {.inline, noinit.} =
  ## Deletes the value and shifts the binary field.
  ## If (row, col) is in the air, shifts the binary field downward above where deleted.
  ## If it is in the water, shifts the binary field upward below where deleted.
  case col
  of Col0, Col1:
    self[0].del col, row, phys
  of Col2, Col3:
    self[1].del col.pred 2, row, phys
  of Col4, Col5:
    self[2].del col.pred 4, row, phys

# ------------------------------------------------
# Drop Garbages
# ------------------------------------------------

const
  MaskL = 0x3ffe_0000'u32
  MaskR = 0x0000_3ffe'u32

func extracted(self: Bit32BinaryField, col: static Col): uint32 {.inline, noinit.} =
  ## Returns the value corresponding to the column.
  staticCase:
    case col
    of Col0:
      self[0] and MaskL
    of Col1:
      self[0] and MaskR
    of Col2:
      self[1] and MaskL
    of Col3:
      self[1] and MaskR
    of Col4:
      self[2] and MaskL
    of Col5:
      self[2] and MaskR

func dropGarbagesTsu*(
    self: var Bit32BinaryField, counts: array[Col, int], existField: Bit32BinaryField
) {.inline, noinit.} =
  ## Drops cells by Tsu rule.
  ## This function requires that the mask is settled and the counts are non-negative.
  let
    notExist01 = (not existField[0]).keptValid
    notExist23 = (not existField[1]).keptValid
    notExist45 = (not existField[2]).keptValid

    notExist0 = notExist01 and MaskL
    notExist1 = notExist01 and MaskR
    notExist2 = notExist23 and MaskL
    notExist3 = notExist23 and MaskR
    notExist4 = notExist45 and MaskL
    notExist5 = notExist45 and MaskR

  expand6 garbages, notExist, Col:
    let garbages = notExist *~ (notExist shl counts[Col])

  self[0].assign bitor2(self[0], garbages0, garbages1)
  self[1].assign bitor2(self[1], garbages2, garbages3)
  self[2].assign bitor2(self[2], garbages4, garbages5)

func dropGarbagesWater*(
    self, other1, other2: var Bit32BinaryField,
    counts: array[Col, int],
    existField: Bit32BinaryField,
) {.inline, noinit.} =
  ## Drops cells by Water rule.
  ## `self` is shifted and is dropped garbages; `other1` and `other2` are only shifted.
  ## This function requires that the mask is settled and the counts are non-negative.
  const WaterMask = ValidMask *~ AirMask

  expand6 afterSelf, afterOther1, afterOther2, Col:
    let afterSelf, afterOther1, afterOther2: uint32

    block:
      when Col in {Col0, Col2, Col4}:
        const
          TrailingInvalid = 17
          Mask = MaskL
      else:
        const
          TrailingInvalid = 1
          Mask = MaskR

      const
        MaskA = AirMask and Mask
        MaskW = WaterMask and Mask

      let
        cnt = counts[Col]
        exist = existField.extracted Col

      if exist == 0:
        if cnt <= WaterHeight:
          afterSelf = MaskW *~ (MaskW shr cnt)
        else:
          afterSelf = MaskW or (MaskA *~ (MaskA shl (cnt - WaterHeight)))

        afterOther1 = 0
        afterOther2 = 0
      else:
        let
          shift = min(cnt, exist.tzcnt - TrailingInvalid)
          shiftExist = exist shr shift
          emptySpace = Mask *~ (shiftExist or shiftExist.blsmsk)
          garbages = emptySpace *~ (emptySpace shl cnt)

          colSelf = self.extracted Col
          colOther1 = other1.extracted Col
          colOther2 = other2.extracted Col

        afterSelf = (colSelf shr shift) or garbages
        afterOther1 = colOther1 shr shift
        afterOther2 = colOther2 shr shift

  self[0].assign afterSelf0 or afterSelf1
  self[1].assign afterSelf2 or afterSelf3
  self[2].assign afterSelf4 or afterSelf5

  other1[0].assign afterOther10 or afterOther11
  other1[1].assign afterOther12 or afterOther13
  other1[2].assign afterOther14 or afterOther15

  other2[0].assign afterOther20 or afterOther21
  other2[1].assign afterOther22 or afterOther23
  other2[2].assign afterOther24 or afterOther25

# ------------------------------------------------
# Settle
# ------------------------------------------------

func write(
    self: out array[Col, PextMask[uint32]], existField: Bit32BinaryField
) {.inline, noinit.} =
  ## Initializes the masks.
  staticFor(col, Col):
    {.push warning[ProveInit]: off.}
    self[col].assign PextMask[uint32].init existField.extracted col
    {.pop.}

func shiftAmount(col: Col): int {.inline, noinit.} =
  ## Returns the shift amount.
  case col
  of Col0, Col2, Col4: 17
  of Col1, Col3, Col5: 1

func settleTsu(
    self: var Bit32BinaryField, masks: array[Col, PextMask[uint32]]
) {.inline, noinit.} =
  ## Settles the binary field by Tsu rule.
  expand6 after, Col:
    let after: uint32

    block:
      const ShiftAmount = Col.shiftAmount
      after = self.extracted(Col).pext(masks[Col]) shl ShiftAmount

  self[0].assign after0 or after1
  self[1].assign after2 or after3
  self[2].assign after4 or after5

func settleTsu*(
    field1, field2, field3: var Bit32BinaryField, existField: Bit32BinaryField
) {.inline, noinit.} =
  ## Settles the binary fields by Tsu rule.
  var masks: array[Col, PextMask[uint32]]
  masks.write existField

  field1.settleTsu masks
  field2.settleTsu masks
  field3.settleTsu masks

func settleWater(
    self: var Bit32BinaryField, masks: array[Col, PextMask[uint32]]
) {.inline, noinit.} =
  ## Settles the binary field by Water rule.
  expand6 after, Col:
    let after: uint32

    block:
      const ShiftAmount = Col.shiftAmount
      after =
        self.extracted(Col).pext(masks[Col]) shl
        max(ShiftAmount, ShiftAmount + WaterHeight - masks[Col].popcnt)

  self[0].assign after0 or after1
  self[1].assign after2 or after3
  self[2].assign after4 or after5

func settleWater*(
    field1, field2, field3: var Bit32BinaryField, existField: Bit32BinaryField
) {.inline, noinit.} =
  ## Settles the binary fields by Water rule.
  var masks: array[Col, PextMask[uint32]]
  masks.write existField

  field1.settleWater masks
  field2.settleWater masks
  field3.settleWater masks

func areSettledTsu*(
    field1, field2, field3, existField: Bit32BinaryField
): bool {.inline, noinit.} =
  ## Returns `true` if all binary fields are settled by Tsu rule.
  ## Note that this function is only slightly lighter than `settleTsu`.
  var masks: array[Col, PextMask[uint32]]
  masks.write existField

  field1.dup(settleTsu(_, masks)) == field1 and field2.dup(settleTsu(_, masks)) == field2 and
    field3.dup(settleTsu(_, masks)) == field3

func areSettledWater*(
    field1, field2, field3, existField: Bit32BinaryField
): bool {.inline, noinit.} =
  ## Returns `true` if all binary fields are settled by Water rule.
  ## Note that this function is only slightly lighter than `settleWater`.
  var masks: array[Col, PextMask[uint32]]
  masks.write existField

  field1.dup(settleWater(_, masks)) == field1 and
    field2.dup(settleWater(_, masks)) == field2 and
    field3.dup(settleWater(_, masks)) == field3

## This module implements binary fields with 64bit operations.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import ../../[assign, bitutils, macros, staticfor]
import ../../../core/[common, rule]

type Bit64BinaryField* = array[2, uint64]
  ## Binary field with 64bit operations.
  # NOTE: each element (higher 16*3 bits) corresponds to three columns

defineExpand "6", "0", "1", "2", "3", "4", "5"
defineExpand "2", "0", "1"

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const ValidMask = 0x3ffe_3ffe_3ffe_0000'u64

func init*(T: type Bit64BinaryField): T {.inline, noinit.} =
  ## Returns the binary field with all elements zero.
  [0, 0]

func initOne*(T: type Bit64BinaryField): T {.inline, noinit.} =
  ## Returns the binary field with all valid elements one.
  [ValidMask, ValidMask]

func initFloor*(T: type Bit64BinaryField): T {.inline, noinit.} =
  ## Returns the binary field with floor bits one.
  const Initializer = 0x0001_0001_0001_0000'u64
  [Initializer, Initializer]

func initLowerAir*(T: type Bit64BinaryField): T {.inline, noinit.} =
  ## Returns the binary field with lower air bits one.
  const Initializer = 0x0001_0001_0001_0000'u64 shl WaterHeight.succ
  [Initializer, Initializer]

func initUpperWater*(T: type Bit64BinaryField): T {.inline, noinit.} =
  ## Returns the binary field with upper underwater bits one.
  const Initializer = 0x0001_0001_0001_0000'u64 shl WaterHeight
  [Initializer, Initializer]

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `+`*(f1, f2: Bit64BinaryField): Bit64BinaryField {.inline, noinit.} =
  [f1[0] or f2[0], f1[1] or f2[1]]

func `-`*(f1, f2: Bit64BinaryField): Bit64BinaryField {.inline, noinit.} =
  [f1[0] *~ f2[0], f1[1] *~ f2[1]]

func `*`*(f1, f2: Bit64BinaryField): Bit64BinaryField {.inline, noinit.} =
  [f1[0] and f2[0], f1[1] and f2[1]]

func `*`(self: Bit64BinaryField, val: uint64): Bit64BinaryField {.inline, noinit.} =
  [self[0] and val, self[1] and val]

func `xor`*(f1, f2: Bit64BinaryField): Bit64BinaryField {.inline, noinit.} =
  [f1[0] xor f2[0], f1[1] xor f2[1]]

func `+=`*(f1: var Bit64BinaryField, f2: Bit64BinaryField) {.inline, noinit.} =
  staticFor(i, 0 ..< 2):
    f1[i].assign f1[i] or f2[i]

func `-=`*(f1: var Bit64BinaryField, f2: Bit64BinaryField) {.inline, noinit.} =
  staticFor(i, 0 ..< 2):
    f1[i].assign f1[i] *~ f2[i]

func `*=`*(f1: var Bit64BinaryField, f2: Bit64BinaryField) {.inline, noinit.} =
  staticFor(i, 0 ..< 2):
    f1[i].assign f1[i] and f2[i]

func `*=`(self: var Bit64BinaryField, val: uint64) {.inline, noinit.} =
  staticFor(i, 0 ..< 2):
    self[i].assign self[i] and val

func sum*(f1, f2, f3: Bit64BinaryField): Bit64BinaryField {.inline, noinit.} =
  [bitor2(f1[0], f2[0], f3[0]), bitor2(f1[1], f2[1], f3[1])]

func sum*(f1, f2, f3, f4: Bit64BinaryField): Bit64BinaryField {.inline, noinit.} =
  [bitor2(f1[0], f2[0], f3[0], f4[0]), bitor2(f1[1], f2[1], f3[1], f4[1])]

func sum*(f1, f2, f3, f4, f5: Bit64BinaryField): Bit64BinaryField {.inline, noinit.} =
  [bitor2(f1[0], f2[0], f3[0], f4[0], f5[0]), bitor2(f1[1], f2[1], f3[1], f4[1], f5[1])]

func sum*(
    f1, f2, f3, f4, f5, f6: Bit64BinaryField
): Bit64BinaryField {.inline, noinit.} =
  [
    bitor2(f1[0], f2[0], f3[0], f4[0], f5[0], f6[0]),
    bitor2(f1[1], f2[1], f3[1], f4[1], f5[1], f6[1]),
  ]

func sum*(
    f1, f2, f3, f4, f5, f6, f7: Bit64BinaryField
): Bit64BinaryField {.inline, noinit.} =
  [
    bitor2(f1[0], f2[0], f3[0], f4[0], f5[0], f6[0], f7[0]),
    bitor2(f1[1], f2[1], f3[1], f4[1], f5[1], f6[1], f7[1]),
  ]

func sum*(
    f1, f2, f3, f4, f5, f6, f7, f8: Bit64BinaryField
): Bit64BinaryField {.inline, noinit.} =
  [
    bitor2(f1[0], f2[0], f3[0], f4[0], f5[0], f6[0], f7[0], f8[0]),
    bitor2(f1[1], f2[1], f3[1], f4[1], f5[1], f6[1], f7[1], f8[1]),
  ]

func product*(f1, f2, f3: Bit64BinaryField): Bit64BinaryField {.inline, noinit.} =
  [bitand2(f1[0], f2[0], f3[0]), bitand2(f1[1], f2[1], f3[1])]

# ------------------------------------------------
# Keep
# ------------------------------------------------

func initAirMask(): uint64 {.inline, noinit.} =
  ## Returns `AirMask`.
  var mask = 0'u64
  for i in 0 ..< AirHeight:
    mask.setBitBE 2.succ i
    mask.setBitBE 18.succ i
    mask.setBitBE 34.succ i

  mask

const
  AirMask = initAirMask()
  ColMaskBase = 0xffff_0000_0000_0000'u64

template withColMasks(col: Col, body: untyped): untyped =
  ## Runs `body` with `mask0` and `mask1` exposed.
  case col
  of Col0 .. Col2:
    let
      mask0 {.inject.} = ColMaskBase shr (col.ord shl 4)
      mask1 {.inject.} = 0'u64

    body
  of Col3 .. Col5:
    let
      mask0 {.inject.} = 0'u64
      mask1 {.inject.} = ColMaskBase shr (col.pred(3).ord shl 4)

    body

func kept*(self: Bit64BinaryField, row: Row): Bit64BinaryField {.inline, noinit.} =
  ## Returns the binary field with only the given row.
  self * (0x2000_2000_2000_0000'u64 shr row.ord)

func kept*(self: Bit64BinaryField, col: Col): Bit64BinaryField {.inline, noinit.} =
  ## Returns the binary field with only the given column.
  col.withColMasks:
    [self[0] and mask0, self[1] and mask1]

func keptValid*(self: Bit64BinaryField): Bit64BinaryField {.inline, noinit.} =
  ## Returns the binary field with only the valid area.
  self * ValidMask

func keptVisible*(self: Bit64BinaryField): Bit64BinaryField {.inline, noinit.} =
  ## Returns the binary field with only the visible area.
  self * 0x1ffe_1ffe_1ffe_0000'u64

func keptAir*(self: Bit64BinaryField): Bit64BinaryField {.inline, noinit.} =
  ## Returns the binary field with only the air area.
  self * AirMask

func keepValid*(self: var Bit64BinaryField) {.inline, noinit.} =
  ## Keeps only the valid area.
  self *= ValidMask

func keptValid(self: uint64): uint64 {.inline, noinit.} =
  ## Returns the value with only the valid area.
  self and ValidMask

# ------------------------------------------------
# Clear
# ------------------------------------------------

func clear*(self: var Bit64BinaryField) {.inline, noinit.} =
  ## Clears the binary field.
  staticFor(i, 0 ..< 2):
    self[i].assign 0

# ------------------------------------------------
# Replace
# ------------------------------------------------

func replace*(
    self: var Bit64BinaryField, col: Col, after: Bit64BinaryField
) {.inline, noinit.} =
  ## Replaces the column of the binary field by `after`.
  col.withColMasks:
    expand2 mask:
      self[_].assign (self[_] *~ mask) or (after[_] and mask)

# ------------------------------------------------
# Population Count
# ------------------------------------------------

func popcnt*(self: Bit64BinaryField): int {.inline, noinit.} =
  ## Returns the population count.
  self[0].countOnes + self[1].countOnes

# ------------------------------------------------
# Shift - Out-place
# NOTE: `sugar.dup` decreases the performance.
# ------------------------------------------------

template shiftedUpRawImpl(self: Bit64BinaryField, body: untyped): untyped =
  ## Runs `body` with `after0` and `after1` exposed.
  let
    after0 {.inject.} = self[0] shl 1
    after1 {.inject.} = self[1] shl 1

  body

template shiftedUpImpl(self: Bit64BinaryField, body: untyped): untyped =
  ## Runs `body` with `after0` and `after1` exposed.
  let
    after0 {.inject.} = (self[0] shl 1).keptValid
    after1 {.inject.} = (self[1] shl 1).keptValid

  body

template shiftedDownRawImpl(self: Bit64BinaryField, body: untyped): untyped =
  ## Runs `body` with `after0` and `after1` exposed.
  let
    after0 {.inject.} = self[0] shr 1
    after1 {.inject.} = self[1] shr 1

  body

template shiftedDownImpl(self: Bit64BinaryField, body: untyped): untyped =
  ## Runs `body` with `after0` and `after1` exposed.
  let
    after0 {.inject.} = (self[0] shr 1).keptValid
    after1 {.inject.} = (self[1] shr 1).keptValid

  body

template shiftedRightRawImpl(self: Bit64BinaryField, body: untyped): untyped =
  ## Runs `body` with `after0` and `after1` exposed.
  let
    after0 {.inject.} = self[0] shr 16
    after1 {.inject.} = (self[0] shl 32) or (self[1] shr 16)

  body

template shiftedRightImpl(self: Bit64BinaryField, body: untyped): untyped =
  ## Runs `body` with `after0` and `after1` exposed.
  let
    after0 {.inject.} = (self[0] shr 16).keptValid
    after1 {.inject.} = ((self[0] shl 32) or (self[1] shr 16)).keptValid

  body

template shiftedLeftRawImpl(self: Bit64BinaryField, body: untyped): untyped =
  ## Runs `body` with `after0` and `after1` exposed.
  let
    after0 {.inject.} = (self[0] shl 16) or (self[1] shr 32)
    after1 {.inject.} = self[1] shl 16

  body

template shiftedLeftImpl(self: Bit64BinaryField, body: untyped): untyped =
  ## Runs `body` with `after0` and `after1` exposed.
  let
    after0 {.inject.} = ((self[0] shl 16) or (self[1] shr 32)).keptValid
    after1 {.inject.} = (self[1] shl 16).keptValid

  body

func shiftedUpRaw*(self: Bit64BinaryField): Bit64BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted upward.
  self.shiftedUpRawImpl:
    [after0, after1]

func shiftedUp*(self: Bit64BinaryField): Bit64BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted upward and extracted the valid area.
  self.shiftedUpImpl:
    [after0, after1]

func shiftedDownRaw*(self: Bit64BinaryField): Bit64BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted downward.
  self.shiftedDownRawImpl:
    [after0, after1]

func shiftedDown*(self: Bit64BinaryField): Bit64BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted downward and extracted the valid area.
  self.shiftedDownImpl:
    [after0, after1]

func shiftedRightRaw*(self: Bit64BinaryField): Bit64BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted rightward.
  self.shiftedRightRawImpl:
    [after0, after1]

func shiftedRight*(self: Bit64BinaryField): Bit64BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted rightward and extracted the valid area.
  self.shiftedRightImpl:
    [after0, after1]

func shiftedLeftRaw*(self: Bit64BinaryField): Bit64BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted leftward.
  self.shiftedLeftRawImpl:
    [after0, after1]

func shiftedLeft*(self: Bit64BinaryField): Bit64BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted leftward and extracted the valid area.
  self.shiftedLeftImpl:
    [after0, after1]

# ------------------------------------------------
# Shift - In-place
# ------------------------------------------------

func shiftUpRaw*(self: var Bit64BinaryField) {.inline, noinit.} =
  ## Shifts the binary field upward.
  self.shiftedUpRawImpl:
    expand2 after:
      self[_].assign after

func shiftUp*(self: var Bit64BinaryField) {.inline, noinit.} =
  ## Shifts the binary field upward and extracts the valid area.
  self.shiftedUpImpl:
    expand2 after:
      self[_].assign after

func shiftDownRaw*(self: var Bit64BinaryField) {.inline, noinit.} =
  ## Shifts the binary field downward.
  self.shiftedDownRawImpl:
    expand2 after:
      self[_].assign after

func shiftDown*(self: var Bit64BinaryField) {.inline, noinit.} =
  ## Shifts the binary field downward and extracts the valid area.
  self.shiftedDownImpl:
    expand2 after:
      self[_].assign after

func shiftRightRaw*(self: var Bit64BinaryField) {.inline, noinit.} =
  ## Shifts the binary field rightward.
  self.shiftedRightRawImpl:
    expand2 after:
      self[_].assign after

func shiftRight*(self: var Bit64BinaryField) {.inline, noinit.} =
  ## Shifts the binary field rightward and extracts the valid area.
  self.shiftedRightImpl:
    expand2 after:
      self[_].assign after

func shiftLeftRaw*(self: var Bit64BinaryField) {.inline, noinit.} =
  ## Shifts the binary field leftward.
  self.shiftedLeftRawImpl:
    expand2 after:
      self[_].assign after

func shiftLeft*(self: var Bit64BinaryField) {.inline, noinit.} =
  ## Shifts the binary field leftward and extracts the valid area.
  self.shiftedLeftImpl:
    expand2 after:
      self[_].assign after

# ------------------------------------------------
# Flip
# ------------------------------------------------

func flipped(val: uint64): uint64 {.inline, noinit.} =
  ## Returns the value three columns flipped.
  bitor2(
    val shl 32,
    val and 0x0000_ffff_0000_0000'u64,
    (val and 0xffff_0000_0000_0000'u64) shr 32,
  )

func flipVertical*(self: var Bit64BinaryField) {.inline, noinit.} =
  ## Flips the binary field vertically.
  staticFor(i, 0 ..< 2):
    self[i].assign (self[i].reverseBits shl 15).flipped

func flipHorizontal*(self: var Bit64BinaryField) {.inline, noinit.} =
  ## Flips the binary field horizontally.
  let
    after0 = self[1].flipped
    after1 = self[0].flipped

  expand2 after:
    self[_].assign after

# ------------------------------------------------
# Rotate
# ------------------------------------------------

func rotate*(self: var Bit64BinaryField) {.inline, noinit.} =
  ## Rotates the binary field by 180 degrees.
  ## Ghost cells are cleared before the rotation.
  let
    visible = self.keptVisible

    after1 = visible[0].reverseBits shl 14
    after0 = visible[1].reverseBits shl 14

  expand2 after:
    self[_].assign after

func crossRotate*(self: var Bit64BinaryField) {.inline, noinit.} =
  ## Rotates the binary field by 180 degrees in groups of three rows.
  ## Ghost cells are cleared before the rotation.
  let
    visible = self.keptVisible

    after0 = visible[0].reverseBits shl 14
    after1 = visible[1].reverseBits shl 14

  expand2 after:
    self[_].assign after

# ------------------------------------------------
# Indexer
# ------------------------------------------------

func indexFromMsb(row: Row, col: Col): int {.inline, noinit.} =
  ## Returns the bit index for indexers.
  col.ord shl 4 + (row.ord + 2)

func `[]`*(
    self: Bit64BinaryField, row: static Row, col: static Col
): bool {.inline, noinit.} =
  staticCase:
    case col
    of Col0 .. Col2:
      self[0].getBitBE static(indexFromMsb(row, col))
    of Col3 .. Col5:
      self[1].getBitBE static(indexFromMsb(row, col.pred 3))

func `[]`*(self: Bit64BinaryField, row: Row, col: Col): bool {.inline, noinit.} =
  case col
  of Col0 .. Col2:
    self[0].getBitBE indexFromMsb(row, col)
  of Col3 .. Col5:
    self[1].getBitBE indexFromMsb(row, col.pred 3)

func `[]=`*(
    self: var Bit64BinaryField, row: Row, col: Col, val: bool
) {.inline, noinit.} =
  case col
  of Col0 .. Col2:
    self[0].changeBitBE indexFromMsb(row, col), val
  of Col3 .. Col5:
    self[1].changeBitBE indexFromMsb(row, col.pred 3), val

# ------------------------------------------------
# Insert / Delete
# ------------------------------------------------

func isInWater(row: Row, phys: Phys): bool {.inline, noinit.} =
  ## Returns `true` if the row is in the water.
  phys == Phys.Water and row.ord + WaterHeight >= Height

func insert(
    self: var uint64, col: Col, row: Row, val: bool, phys: Phys
) {.inline, noinit.} =
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
  if row.isInWater phys:
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
    self: var Bit64BinaryField, row: Row, col: Col, val: bool, phys: Phys
) {.inline, noinit.} =
  ## Inserts the value and shifts the binary field.
  ## If (row, col) is in the air, shifts the binary field upward above where inserted.
  ## If it is in the water, shifts the binary field downward below where inserted.
  case col
  of Col0 .. Col2:
    self[0].insert col, row, val, phys
  of Col3 .. Col5:
    self[1].insert col.pred 3, row, val, phys

func del(self: var uint64, col: Col, row: Row, phys: Phys) {.inline, noinit.} =
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
  if row.isInWater phys:
    below = ((self and belowMask) shl 1).keptValid
    above = self and aboveMask
  else:
    below = self and belowMask
    above = ((self and aboveMask) shr 1).keptValid

  self.assign ((below or above) and colMask) or (self *~ colMask)

func del*(
    self: var Bit64BinaryField, row: Row, col: Col, phys: Phys
) {.inline, noinit.} =
  ## Deletes the value and shifts the binary field.
  ## If (row, col) is in the air, shifts the binary field downward above where deleted.
  ## If it is in the water, shifts the binary field upward below where deleted.
  case col
  of Col0 .. Col2:
    self[0].del col, row, phys
  of Col3 .. Col5:
    self[1].del col.pred 3, row, phys

# ------------------------------------------------
# Drop Garbages
# ------------------------------------------------

const
  MaskL = 0x3ffe_0000_0000_0000'u64
  MaskC = 0x0000_3ffe_0000_0000'u64
  MaskR = 0x0000_0000_3ffe_0000'u64

func extracted(self: Bit64BinaryField, col: static Col): uint64 {.inline, noinit.} =
  ## Returns the value corresponding to the column.
  staticCase:
    case col
    of Col0:
      self[0] and MaskL
    of Col1:
      self[0] and MaskC
    of Col2:
      self[0] and MaskR
    of Col3:
      self[1] and MaskL
    of Col4:
      self[1] and MaskC
    of Col5:
      self[1] and MaskR

func dropGarbagesTsu*(
    self: var Bit64BinaryField, counts: array[Col, int], existField: Bit64BinaryField
) {.inline, noinit.} =
  ## Drops cells by Tsu rule.
  ## This function requires that the mask is settled and the counts are non-negative.
  let
    notExist012 = (not existField[0]).keptValid
    notExist345 = (not existField[1]).keptValid

    notExist0 = notExist012 and MaskL
    notExist1 = notExist012 and MaskC
    notExist2 = notExist012 and MaskR
    notExist3 = notExist345 and MaskL
    notExist4 = notExist345 and MaskC
    notExist5 = notExist345 and MaskR

  expand6 garbages, notExist, Col:
    let garbages = notExist *~ (notExist shl counts[Col])

  self[0].assign bitor2(self[0], garbages0, garbages1, garbages2)
  self[1].assign bitor2(self[1], garbages3, garbages4, garbages5)

func dropGarbagesWater*(
    self, other1, other2: var Bit64BinaryField,
    counts: array[Col, int],
    existField: Bit64BinaryField,
) {.inline, noinit.} =
  ## Drops cells by Water rule.
  ## `self` is shifted and is dropped garbages; `other1` and `other2` are only shifted.
  ## This function requires that the mask is settled and the counts are non-negative.
  const WaterMask = ValidMask *~ AirMask

  expand6 afterSelf, afterOther1, afterOther2, Col:
    let afterSelf, afterOther1, afterOther2: uint64

    block:
      when Col in {Col0, Col3}:
        const
          TrailingInvalid = 49
          Mask = MaskL
      elif Col in {Col1, Col4}:
        const
          TrailingInvalid = 33
          Mask = MaskC
      else:
        const
          TrailingInvalid = 17
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

  self[0].assign bitor2(afterSelf0, afterSelf1, afterSelf2)
  self[1].assign bitor2(afterSelf3, afterSelf4, afterSelf5)

  other1[0].assign bitor2(afterOther10, afterOther11, afterOther12)
  other1[1].assign bitor2(afterOther13, afterOther14, afterOther15)

  other2[0].assign bitor2(afterOther20, afterOther21, afterOther22)
  other2[1].assign bitor2(afterOther23, afterOther24, afterOther25)

# ------------------------------------------------
# Settle
# ------------------------------------------------

func write(
    self: out array[Col, PextMask[uint64]], existField: Bit64BinaryField
) {.inline, noinit.} =
  ## Initializes the masks.
  staticFor(col, Col):
    {.push warning[ProveInit]: off.}
    self[col].assign PextMask[uint64].init existField.extracted col
    {.pop.}

func shiftAmount(col: Col): int {.inline, noinit.} =
  ## Returns the shift amount.
  case col
  of Col0, Col3: 49
  of Col1, Col4: 33
  of Col2, Col5: 17

func settleTsu(
    self: var Bit64BinaryField, masks: array[Col, PextMask[uint64]]
) {.inline, noinit.} =
  ## Settles the binary field by Tsu rule.
  expand6 after, Col:
    let after: uint64

    block:
      const ShiftAmount = Col.shiftAmount
      after = self.extracted(Col).pext(masks[Col]) shl ShiftAmount

  self[0].assign bitor2(after0, after1, after2)
  self[1].assign bitor2(after3, after4, after5)

func settleTsu*(
    field1, field2, field3: var Bit64BinaryField, existField: Bit64BinaryField
) {.inline, noinit.} =
  ## Settles the binary field by Tsu rule.
  var masks: array[Col, PextMask[uint64]]
  masks.write existField

  field1.settleTsu masks
  field2.settleTsu masks
  field3.settleTsu masks

func settleWater(
    self: var Bit64BinaryField, masks: array[Col, PextMask[uint64]]
) {.inline, noinit.} =
  ## Settles the binary field by Water rule.
  expand6 after, Col:
    let after: uint64

    block:
      const ShiftAmount = Col.shiftAmount
      after =
        self.extracted(Col).pext(masks[Col]) shl
        max(ShiftAmount, ShiftAmount + WaterHeight - masks[Col].popcnt)

  self[0].assign bitor2(after0, after1, after2)
  self[1].assign bitor2(after3, after4, after5)

func settleWater*(
    field1, field2, field3: var Bit64BinaryField, existField: Bit64BinaryField
) {.inline, noinit.} =
  ## Settles the binary field by Water rule.
  var masks: array[Col, PextMask[uint64]]
  masks.write existField

  field1.settleWater masks
  field2.settleWater masks
  field3.settleWater masks

func areSettledTsu*(
    field1, field2, field3, existField: Bit64BinaryField
): bool {.inline, noinit.} =
  ## Returns `true` if all binary fields are settled by Tsu rule.
  ## Note that this function is only slightly lighter than `settleTsu`.
  var masks: array[Col, PextMask[uint64]]
  masks.write existField

  field1.dup(settleTsu(_, masks)) == field1 and field2.dup(settleTsu(_, masks)) == field2 and
    field3.dup(settleTsu(_, masks)) == field3

func areSettledWater*(
    field1, field2, field3, existField: Bit64BinaryField
): bool {.inline, noinit.} =
  ## Returns `true` if all binary fields are settled by Water rule.
  ## Note that this function is only slightly lighter than `settleWater`.
  var masks: array[Col, PextMask[uint64]]
  masks.write existField

  field1.dup(settleWater(_, masks)) == field1 and
    field2.dup(settleWater(_, masks)) == field2 and
    field3.dup(settleWater(_, masks)) == field3

## This module implements binary fields with 64bit operations.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import ../../[assign, bitops, expand, staticcase, staticfor]
import ../../../core/[behaviour, common]

type BinaryField* = array[2, uint64]
  ## Binary field with 64bit operations.
  # NOTE: use higher 16*3 bits

defineExpand "6", "0", "1", "2", "3", "4", "5"
defineExpand "3", "0", "1", "2"
defineExpand "2", "0", "1"

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const
  ValidMaskElem = 0x3ffe_3ffe_3ffe_0000'u64
  WaterMaskElemBase = toMask2[uint64](1 .. WaterHeight)
  WaterMaskElem = bitor2(
    WaterMaskElemBase,
    WaterMaskElemBase shl 16,
    WaterMaskElemBase shl 32,
    WaterMaskElemBase shl 48,
  )
  AirMaskElem = ValidMaskElem *~ WaterMaskElem

func init(T: type BinaryField, val: uint64): T {.inline, noinit.} =
  [val, val]

func init*(T: type BinaryField): T {.inline, noinit.} =
  ## Returns the binary field with all elements zero.
  T.init 0

func initValid*(T: type BinaryField): T {.inline, noinit.} =
  ## Returns the binary field with all valid elements one.
  T.init ValidMaskElem

func initFloor*(T: type BinaryField): T {.inline, noinit.} =
  ## Returns the binary field with floor bits one.
  T.init 0x0001_0001_0001_0000'u64

func initAirBottom*(T: type BinaryField): T {.inline, noinit.} =
  ## Returns the binary field with the bottom of the air bits one.
  T.init 0x0001_0001_0001_0000'u64 shl (WaterHeight + 1)

func initWaterTop*(T: type BinaryField): T {.inline, noinit.} =
  ## Returns the binary field with the top of the water bits one.
  T.init 0x0001_0001_0001_0000'u64 shl WaterHeight

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `+`*(f1, f2: BinaryField): BinaryField {.inline, noinit.} =
  [f1[0] or f2[0], f1[1] or f2[1]]

func `-`*(f1, f2: BinaryField): BinaryField {.inline, noinit.} =
  [f1[0] *~ f2[0], f1[1] *~ f2[1]]

func `*`*(f1, f2: BinaryField): BinaryField {.inline, noinit.} =
  [f1[0] and f2[0], f1[1] and f2[1]]

func `xor`*(f1, f2: BinaryField): BinaryField {.inline, noinit.} =
  [f1[0] xor f2[0], f1[1] xor f2[1]]

func `+=`*(f1: var BinaryField, f2: BinaryField) {.inline, noinit.} =
  staticFor(i, 0 ..< 2):
    f1[i].assign f1[i] or f2[i]

func `-=`*(f1: var BinaryField, f2: BinaryField) {.inline, noinit.} =
  staticFor(i, 0 ..< 2):
    f1[i].assign f1[i] *~ f2[i]

func `*=`*(f1: var BinaryField, f2: BinaryField) {.inline, noinit.} =
  staticFor(i, 0 ..< 2):
    f1[i].assign f1[i] and f2[i]

func `*`(self: BinaryField, val: uint64): BinaryField {.inline, noinit.} =
  [self[0] and val, self[1] and val]

# ------------------------------------------------
# Keep
# ------------------------------------------------

const ColMaskBase = 0xffff_0000_0000_0000'u64

func colMask(col: Col): BinaryField {.inline, noinit.} =
  ## Returns the mask corresponding to the column.
  case col
  of Col0 .. Col2:
    [ColMaskBase shr (col.ord shl 4), 0]
  of Col3 .. Col5:
    [0, ColMaskBase shr ((col.ord - 3) shl 4)]

func kept*(self: BinaryField, col: Col): BinaryField {.inline, noinit.} =
  ## Returns the binary field with only the given column.
  self * col.colMask

func keptValid*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field with only the valid area.
  self * ValidMaskElem

func keptVisible*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field with only the visible area.
  self * 0x1ffe_1ffe_1ffe_0000'u64

func keptAir*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field with only the air area.
  self * AirMaskElem

func keptValid(self: uint64): uint64 {.inline, noinit.} =
  ## Returns the value with only the valid area.
  self and ValidMaskElem

# ------------------------------------------------
# Replace
# ------------------------------------------------

func replace*(self: var BinaryField, col: Col, after: BinaryField) {.inline, noinit.} =
  ## Replaces the column of the binary field by `after`.
  let mask = col.colMask

  staticFor(i, 0 ..< 2):
    self[i].assign (self[i] *~ mask[i]) or (after[i] and mask[i])

# ------------------------------------------------
# Population Count
# ------------------------------------------------

func popcnt*(self: BinaryField): int {.inline, noinit.} =
  ## Returns the population count.
  self[0].countOnes + self[1].countOnes

# ------------------------------------------------
# Shift
# ------------------------------------------------

func shiftedUpRaw*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted upward.
  [self[0] shl 1, self[1] shl 1]

func shiftedDownRaw*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted downward.
  [self[0] shr 1, self[1] shr 1]

func shiftedRightRaw*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted rightward.
  [self[0] shr 16, (self[0] shl 32) or (self[1] shr 16)]

func shiftedLeftRaw*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted leftward.
  [(self[0] shl 16) or (self[1] shr 32), self[1] shl 16]

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

func flipVertical*(self: var BinaryField) {.inline, noinit.} =
  ## Flips the binary field vertically.
  staticFor(i, 0 ..< 2):
    self[i].assign (self[i].reverseBits shl 15).flipped

func flipHorizontal*(self: var BinaryField) {.inline, noinit.} =
  ## Flips the binary field horizontally.
  expand2 after:
    let after = self[1 - _].flipped

  expand2 after:
    self[_].assign after

# ------------------------------------------------
# Rotate
# ------------------------------------------------

func rotate*(self: var BinaryField) {.inline, noinit.} =
  ## Rotates the binary field by 180 degrees.
  ## Ghost cells are cleared before the rotation.
  let visible = self.keptVisible

  staticFor(i, 0 ..< 2):
    self[i].assign visible[1 - i].reverseBits shl 14

func crossRotate*(self: var BinaryField) {.inline, noinit.} =
  ## Rotates the binary field by 180 degrees in groups of three rows.
  ## Ghost cells are cleared before the rotation.
  let visible = self.keptVisible

  staticFor(i, 0 ..< 2):
    self[i].assign visible[i].reverseBits shl 14

# ------------------------------------------------
# Indexer
# ------------------------------------------------

func indexFromMsb(row: Row, col: Col): int {.inline, noinit.} =
  ## Returns the bit index for indexers.
  col.ord shl 4 + (row.ord + 2)

func `[]`*(self: BinaryField, row: Row, col: Col): bool {.inline, noinit.} =
  case col
  of Col0 .. Col2:
    self[0].getBitBE indexFromMsb(row, col)
  of Col3 .. Col5:
    self[1].getBitBE indexFromMsb(row, col.pred 3)

func `[]=`*(self: var BinaryField, row: Row, col: Col, val: bool) {.inline, noinit.} =
  case col
  of Col0 .. Col2:
    self[0].changeBitBE indexFromMsb(row, col), val
  of Col3 .. Col5:
    self[1].changeBitBE indexFromMsb(row, col.pred 3), val

# ------------------------------------------------
# Insert / Delete
# ------------------------------------------------

func isInWater(row: Row, physics: Physics): bool {.inline, noinit.} =
  ## Returns `true` if the row is in the water.
  physics == Physics.Water and row >= WaterTopRow

func insert(
    self: var uint64, col: Col, row: Row, val: bool, physics: Physics
) {.inline, noinit.} =
  ## Inserts the value and shifts the binary field's element.
  ## `col` should be in `Col0..Col2`.
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
  if row.isInWater physics:
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
    self: var BinaryField, row: Row, col: Col, val: bool, physics: Physics
) {.inline, noinit.} =
  ## Inserts the value and shifts the binary field.
  ## If (row, col) is in the air, shifts the binary field upward above where inserted.
  ## If it is in the water, shifts the binary field downward below where inserted.
  case col
  of Col0 .. Col2:
    self[0].insert col, row, val, physics
  of Col3 .. Col5:
    self[1].insert col.pred 3, row, val, physics

func del(self: var uint64, col: Col, row: Row, physics: Physics) {.inline, noinit.} =
  ## Deletes the value and shifts the binary field's element.
  ## `col` should be in `Col0..Col2`.
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
  if row.isInWater physics:
    below = ((self and belowMask) shl 1).keptValid
    above = self and aboveMask
  else:
    below = self and belowMask
    above = ((self and aboveMask) shr 1).keptValid

  self.assign ((below or above) and colMask) or (self *~ colMask)

func del*(
    self: var BinaryField, row: Row, col: Col, physics: Physics
) {.inline, noinit.} =
  ## Deletes the value and shifts the binary field.
  ## If (row, col) is in the air, shifts the binary field downward above where deleted.
  ## If it is in the water, shifts the binary field upward below where deleted.
  case col
  of Col0 .. Col2:
    self[0].del col, row, physics
  of Col3 .. Col5:
    self[1].del col.pred 3, row, physics

# ------------------------------------------------
# Drop Nuisance
# ------------------------------------------------

const
  MaskLeft = 0x3ffe_0000_0000_0000'u64
  MaskCenter = 0x0000_3ffe_0000_0000'u64
  MaskRight = 0x0000_0000_3ffe_0000'u64

func extracted(self: BinaryField, col: static Col): uint64 {.inline, noinit.} =
  ## Returns the value corresponding to the column.
  staticCase:
    case col
    of Col0:
      self[0] and MaskLeft
    of Col1:
      self[0] and MaskCenter
    of Col2:
      self[0] and MaskRight
    of Col3:
      self[1] and MaskLeft
    of Col4:
      self[1] and MaskCenter
    of Col5:
      self[1] and MaskRight

func shiftAmount(col: Col): int {.inline, noinit.} =
  ## Returns the shift amount.
  case col
  of Col0, Col3: 49
  of Col1, Col4: 33
  of Col2, Col5: 17

func dropNuisanceTsu*(
    self: var BinaryField, counts: array[Col, int], existField: BinaryField
) {.inline, noinit.} =
  ## Drops cells by Tsu physics.
  ## This function requires that the mask is settled and the counts are non-negative.
  let
    notExist012 = (not existField[0]).keptValid
    notExist345 = (not existField[1]).keptValid

    notExist0 = notExist012 and MaskLeft
    notExist1 = notExist012 and MaskCenter
    notExist2 = notExist012 and MaskRight
    notExist3 = notExist345 and MaskLeft
    notExist4 = notExist345 and MaskCenter
    notExist5 = notExist345 and MaskRight

  expand6 garbages, notExist, Col:
    let garbages = notExist *~ (notExist shl counts[Col])

  self[0].assign bitor2(self[0], garbages0, garbages1, garbages2)
  self[1].assign bitor2(self[1], garbages3, garbages4, garbages5)

func dropNuisanceWater*(
    self, other1, other2: var BinaryField,
    counts: array[Col, int],
    existField: BinaryField,
) {.inline, noinit.} =
  ## Drops cells by Water physics.
  ## `other1` and `other2` are only shifted.
  ## This function requires that the mask is settled and the counts are non-negative.
  expand6 afterSelf, afterOther1, afterOther2, Col:
    let afterSelf, afterOther1, afterOther2: uint64

    block:
      const
        TrailingInvalid = Col.shiftAmount

        Mask =
          case Col
          of Col0, Col3: MaskLeft
          of Col1, Col4: MaskCenter
          of Col2, Col5: MaskRight
        MaskAir = AirMaskElem and Mask
        MaskWater = WaterMaskElem and Mask

      let
        count = counts[Col]
        exist = existField.extracted Col

      if exist == 0:
        if count <= WaterHeight:
          afterSelf = MaskWater *~ (MaskWater shr count)
        else:
          afterSelf = MaskWater or (MaskAir *~ (MaskAir shl (count - WaterHeight)))

        afterOther1 = 0
        afterOther2 = 0
      else:
        let
          shift = min(count, exist.tzcnt - TrailingInvalid)
          shiftExist = exist shr shift
          emptySpace = Mask *~ (shiftExist or shiftExist.blsmsk)
          nuisance = emptySpace *~ (emptySpace shl count)

          colSelf = self.extracted Col
          colOther1 = other1.extracted Col
          colOther2 = other2.extracted Col

        afterSelf = (colSelf shr shift) or nuisance
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
    self: out array[Col, PextMask[uint64]], existField: BinaryField
) {.inline, noinit.} =
  ## Initializes the masks.
  staticFor(col, Col):
    {.push warning[ProveInit]: off.}
    self[col].assign PextMask[uint64].init existField.extracted col
    {.pop.}

func settleTsu(
    self: var BinaryField, masks: array[Col, PextMask[uint64]]
) {.inline, noinit.} =
  ## Settles the binary field by Tsu physics.
  expand6 after, Col:
    let after = self.extracted(Col).pext(masks[Col]) shl Col.shiftAmount

  self[0].assign bitor2(after0, after1, after2)
  self[1].assign bitor2(after3, after4, after5)

func settleTsu*(
    field0, field1, field2: var BinaryField, existField: BinaryField
) {.inline, noinit.} =
  ## Settles the binary field by Tsu physics.
  var masks {.noinit.}: array[Col, PextMask[uint64]]
  masks.write existField

  expand3 field:
    field.settleTsu masks

func settleWater(
    self: var BinaryField, masks: array[Col, PextMask[uint64]]
) {.inline, noinit.} =
  ## Settles the binary field by Water physics.
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
    field0, field1, field2: var BinaryField, existField: BinaryField
) {.inline, noinit.} =
  ## Settles the binary field by Water physics.
  var masks {.noinit.}: array[Col, PextMask[uint64]]
  masks.write existField

  expand3 field:
    field.settleWater masks

func areSettledTsu*(
    field0, field1, field2, existField: BinaryField
): bool {.inline, noinit.} =
  ## Returns `true` if all binary fields are settled by Tsu physics.
  ## Note that this function is only slightly lighter than `settleTsu`.
  var masks {.noinit.}: array[Col, PextMask[uint64]]
  masks.write existField

  field0.dup(settleTsu(masks)) == field0 and field1.dup(settleTsu(masks)) == field1 and
    field2.dup(settleTsu(masks)) == field2

func areSettledWater*(
    field0, field1, field2, existField: BinaryField
): bool {.inline, noinit.} =
  ## Returns `true` if all binary fields are settled by Water physics.
  ## Note that this function is only slightly lighter than `settleWater`.
  var masks {.noinit.}: array[Col, PextMask[uint64]]
  masks.write existField

  field0.dup(settleWater(masks)) == field0 and field1.dup(settleWater(masks)) == field1 and
    field2.dup(settleWater(masks)) == field2

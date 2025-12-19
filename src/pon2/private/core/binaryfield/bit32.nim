## This module implements binary fields with 32bit operations.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import ../../[assign, bitops, expand, staticcase, staticfor]
import ../../../core/[behaviour, common]

type BinaryField* = array[3, uint32] ## Binary field with 32bit operations.

defineExpand "6", "0", "1", "2", "3", "4", "5"
defineExpand "3", "0", "1", "2"

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const
  ValidMaskElem = 0x3ffe_3ffe'u32
  WaterMaskElemBase = toMask2[uint32](1 .. WaterHeight)
  WaterMaskElem = bitor2(WaterMaskElemBase, WaterMaskElemBase shl 16)
  AirMaskElem = ValidMaskElem *~ WaterMaskElem

func init(T: type BinaryField, val: uint32): T {.inline, noinit.} =
  [val, val, val]

func init*(T: type BinaryField): T {.inline, noinit.} =
  ## Returns the binary field with all elements zero.
  T.init 0

func initValid*(T: type BinaryField): T {.inline, noinit.} =
  ## Returns the binary field with all valid elements one.
  T.init ValidMaskElem

func initFloor*(T: type BinaryField): T {.inline, noinit.} =
  ## Returns the binary field with floor bits one.
  T.init 0x0001_0001'u32

func initAirBottom*(T: type BinaryField): T {.inline, noinit.} =
  ## Returns the binary field with the bottom of the air bits one.
  T.init 0x0001_0001'u32 shl (WaterHeight + 1)

func initWaterTop*(T: type BinaryField): T {.inline, noinit.} =
  ## Returns the binary field with the top of the water bits one.
  T.init 0x0001_0001'u32 shl WaterHeight

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `+`*(f1, f2: BinaryField): BinaryField {.inline, noinit.} =
  [f1[0] or f2[0], f1[1] or f2[1], f1[2] or f2[2]]

func `-`*(f1, f2: BinaryField): BinaryField {.inline, noinit.} =
  [f1[0] *~ f2[0], f1[1] *~ f2[1], f1[2] *~ f2[2]]

func `*`*(f1, f2: BinaryField): BinaryField {.inline, noinit.} =
  [f1[0] and f2[0], f1[1] and f2[1], f1[2] and f2[2]]

func `xor`*(f1, f2: BinaryField): BinaryField {.inline, noinit.} =
  [f1[0] xor f2[0], f1[1] xor f2[1], f1[2] xor f2[2]]

func `+=`*(f1: var BinaryField, f2: BinaryField) {.inline, noinit.} =
  staticFor(i, 0 ..< 3):
    f1[i].assign f1[i] or f2[i]

func `-=`*(f1: var BinaryField, f2: BinaryField) {.inline, noinit.} =
  staticFor(i, 0 ..< 3):
    f1[i].assign f1[i] *~ f2[i]

func `*=`*(f1: var BinaryField, f2: BinaryField) {.inline, noinit.} =
  staticFor(i, 0 ..< 3):
    f1[i].assign f1[i] and f2[i]

func `*`(self: BinaryField, val: uint32): BinaryField {.inline, noinit.} =
  [self[0] and val, self[1] and val, self[2] and val]

# ------------------------------------------------
# Keep
# ------------------------------------------------

const ColMaskBase = 0xffff_0000'u32

func colMask(col: Col): BinaryField {.inline, noinit.} =
  ## Returns the mask corresponding to the column.
  case col
  of Col0, Col1:
    [ColMaskBase shr (col.ord shl 4), 0, 0]
  of Col2, Col3:
    [0, ColMaskBase shr ((col.ord - 2) shl 4), 0]
  of Col4, Col5:
    [0, 0, ColMaskBase shr ((col.ord - 4) shl 4)]

func kept*(self: BinaryField, col: Col): BinaryField {.inline, noinit.} =
  ## Returns the binary field with only the given column.
  self * col.colMask

func keptValid*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field with only the valid area.
  self * ValidMaskElem

func keptVisible*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field with only the visible area.
  self * 0x1ffe_1ffe'u32

func keptAir*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field with only the air area.
  self * AirMaskElem

func keptValid(self: uint32): uint32 {.inline, noinit.} =
  ## Returns the value with only the valid area.
  self and ValidMaskElem

# ------------------------------------------------
# Replace
# ------------------------------------------------

func replace*(self: var BinaryField, col: Col, after: BinaryField) {.inline, noinit.} =
  ## Replaces the column of the binary field by `after`.
  let mask = col.colMask

  staticFor(i, 0 ..< 3):
    self[i].assign (self[i] *~ mask[i]) or (after[i] and mask[i])

# ------------------------------------------------
# Population Count
# ------------------------------------------------

func popcnt*(self: BinaryField): int {.inline, noinit.} =
  ## Returns the population count.
  self[0].countOnes + self[1].countOnes + self[2].countOnes

# ------------------------------------------------
# Shift
# ------------------------------------------------

func shiftedUpRaw*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted upward.
  [self[0] shl 1, self[1] shl 1, self[2] shl 1]

func shiftedDownRaw*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted downward.
  [self[0] shr 1, self[1] shr 1, self[2] shr 1]

func shiftedRightRaw*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted rightward.
  [
    self[0] shr 16,
    (self[0] shl 16) or (self[1] shr 16),
    (self[1] shl 16) or (self[2] shr 16),
  ]

func shiftedLeftRaw*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted leftward.
  [
    (self[0] shl 16) or (self[1] shr 16),
    (self[1] shl 16) or (self[2] shr 16),
    self[2] shl 16,
  ]

# ------------------------------------------------
# Flip
# ------------------------------------------------

func flipped(val: uint32): uint32 {.inline, noinit.} =
  ## Returns the value two columns flipped.
  (val shr 16) or (val shl 16)

func flipVertical*(self: var BinaryField) {.inline, noinit.} =
  ## Flips the binary field vertically.
  staticFor(i, 0 ..< 3):
    self[i].assign (self[i].reverseBits shr 1).flipped

func flipHorizontal*(self: var BinaryField) {.inline, noinit.} =
  ## Flips the binary field horizontally.
  expand3 after:
    let after = self[2 - _].flipped

  expand3 after:
    self[_].assign after

# ------------------------------------------------
# Rotate
# ------------------------------------------------

func rotate*(self: var BinaryField) {.inline, noinit.} =
  ## Rotates the binary field by 180 degrees.
  ## Ghost cells are cleared before the rotation.
  let visible = self.keptVisible

  staticFor(i, 0 ..< 3):
    self[i].assign visible[2 - i].reverseBits shr 2

func crossRotate*(self: var BinaryField) {.inline, noinit.} =
  ## Rotates the binary field by 180 degrees in groups of three rows.
  ## Ghost cells are cleared before the rotation.
  let
    visible = self.keptVisible

    reverse0 = visible[0].reverseBits shr 2
    reverse1 = visible[1].reverseBits shr 2
    reverse2 = visible[2].reverseBits shr 2

  self[0].assign (reverse1 shl 16) or (reverse0 shr 16)
  self[1].assign (reverse0 shl 16) or (reverse2 shr 16)
  self[2].assign (reverse2 shl 16) or (reverse1 shr 16)

# ------------------------------------------------
# Indexer
# ------------------------------------------------

func indexFromMsb(row: Row, col: Col): int {.inline, noinit.} =
  ## Returns the bit index for indexers.
  col.ord shl 4 + (row.ord + 2)

func `[]`*(self: BinaryField, row: Row, col: Col): bool {.inline, noinit.} =
  case col
  of Col0, Col1:
    self[0].getBitBE indexFromMsb(row, col)
  of Col2, Col3:
    self[1].getBitBE indexFromMsb(row, col.pred 2)
  of Col4, Col5:
    self[2].getBitBE indexFromMsb(row, col.pred 4)

func `[]=`*(self: var BinaryField, row: Row, col: Col, val: bool) {.inline, noinit.} =
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

func isInWater(row: Row, physics: Physics): bool {.inline, noinit.} =
  ## Returns `true` if the row is in the water.
  physics == Physics.Water and row >= WaterTopRow

func insert(
    self: var uint32, col: Col, row: Row, val: bool, physics: Physics
) {.inline, noinit.} =
  ## Inserts the value and shifts the binary field's element.
  ## `col` should be in `Col0..Col1`.
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
  if row.isInWater physics:
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
    self: var BinaryField, row: Row, col: Col, val: bool, physics: Physics
) {.inline, noinit.} =
  ## Inserts the value and shifts the binary field.
  ## If (row, col) is in the air, shifts the binary field upward above where inserted.
  ## If it is in the water, shifts the binary field downward below where inserted.
  case col
  of Col0, Col1:
    self[0].insert col, row, val, physics
  of Col2, Col3:
    self[1].insert col.pred 2, row, val, physics
  of Col4, Col5:
    self[2].insert col.pred 4, row, val, physics

func del(self: var uint32, col: Col, row: Row, physics: Physics) {.inline, noinit.} =
  ## Deletes the value and shifts the binary field's element.
  ## `col` should be in `Col0..Col1`.
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
  of Col0, Col1:
    self[0].del col, row, physics
  of Col2, Col3:
    self[1].del col.pred 2, row, physics
  of Col4, Col5:
    self[2].del col.pred 4, row, physics

# ------------------------------------------------
# Drop Nuisance
# ------------------------------------------------

const
  MaskLeft = 0x3ffe_0000'u32
  MaskRight = 0x0000_3ffe'u32

func extracted(self: BinaryField, col: static Col): uint32 {.inline, noinit.} =
  ## Returns the value corresponding to the column.
  staticCase:
    case col
    of Col0:
      self[0] and MaskLeft
    of Col1:
      self[0] and MaskRight
    of Col2:
      self[1] and MaskLeft
    of Col3:
      self[1] and MaskRight
    of Col4:
      self[2] and MaskLeft
    of Col5:
      self[2] and MaskRight

func shiftAmount(col: Col): int {.inline, noinit.} =
  ## Returns the shift amount.
  case col
  of Col0, Col2, Col4: 17
  of Col1, Col3, Col5: 1

func dropNuisanceTsu*(
    self: var BinaryField, counts: array[Col, int], existField: BinaryField
) {.inline, noinit.} =
  ## Drops cells by Tsu physics.
  ## This function requires that the mask is settled and the counts are non-negative.
  let
    notExist01 = (not existField[0]).keptValid
    notExist23 = (not existField[1]).keptValid
    notExist45 = (not existField[2]).keptValid

    notExist0 = notExist01 and MaskLeft
    notExist1 = notExist01 and MaskRight
    notExist2 = notExist23 and MaskLeft
    notExist3 = notExist23 and MaskRight
    notExist4 = notExist45 and MaskLeft
    notExist5 = notExist45 and MaskRight

  expand6 garbages, notExist, Col:
    let garbages = notExist *~ (notExist shl counts[Col])

  self[0].assign bitor2(self[0], garbages0, garbages1)
  self[1].assign bitor2(self[1], garbages2, garbages3)
  self[2].assign bitor2(self[2], garbages4, garbages5)

func dropNuisanceWater*(
    self, other1, other2: var BinaryField,
    counts: array[Col, int],
    existField: BinaryField,
) {.inline, noinit.} =
  ## Drops cells by Water rule.
  ## `other1` and `other2` are only shifted.
  ## This function requires that the mask is settled and the counts are non-negative.
  expand6 afterSelf, afterOther1, afterOther2, Col:
    let afterSelf, afterOther1, afterOther2: uint32

    block:
      const
        TrailingInvalid = Col.shiftAmount

        Mask =
          case Col
          of Col0, Col2, Col4: MaskLeft
          of Col1, Col3, Col5: MaskRight
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
    self: out array[Col, PextMask[uint32]], existField: BinaryField
) {.inline, noinit.} =
  ## Initializes the masks.
  staticFor(col, Col):
    {.push warning[ProveInit]: off.}
    self[col].assign PextMask[uint32].init existField.extracted col
    {.pop.}

func settleTsu(
    self: var BinaryField, masks: array[Col, PextMask[uint32]]
) {.inline, noinit.} =
  ## Settles the binary field by Tsu physics.
  expand6 after, Col:
    let after = self.extracted(Col).pext(masks[Col]) shl Col.shiftAmount

  self[0].assign after0 or after1
  self[1].assign after2 or after3
  self[2].assign after4 or after5

func settleTsu*(
    field0, field1, field2: var BinaryField, existField: BinaryField
) {.inline, noinit.} =
  ## Settles the binary fields by Tsu physics.
  var masks {.noinit.}: array[Col, PextMask[uint32]]
  masks.write existField

  expand3 field:
    field.settleTsu masks

func settleWater(
    self: var BinaryField, masks: array[Col, PextMask[uint32]]
) {.inline, noinit.} =
  ## Settles the binary field by Water physics.
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
    field0, field1, field2: var BinaryField, existField: BinaryField
) {.inline, noinit.} =
  ## Settles the binary fields by Water physics.
  var masks {.noinit.}: array[Col, PextMask[uint32]]
  masks.write existField

  expand3 field:
    field.settleWater masks

func areSettledTsu*(
    field0, field1, field2, existField: BinaryField
): bool {.inline, noinit.} =
  ## Returns `true` if all binary fields are settled by Tsu physics.
  ## Note that this function is only slightly lighter than `settleTsu`.
  var masks {.noinit.}: array[Col, PextMask[uint32]]
  masks.write existField

  field0.dup(settleTsu(masks)) == field0 and field1.dup(settleTsu(masks)) == field1 and
    field2.dup(settleTsu(masks)) == field2

func areSettledWater*(
    field0, field1, field2, existField: BinaryField
): bool {.inline, noinit.} =
  ## Returns `true` if all binary fields are settled by Water physics.
  ## Note that this function is only slightly lighter than `settleWater`.
  var masks {.noinit.}: array[Col, PextMask[uint32]]
  masks.write existField

  field0.dup(settleWater(masks)) == field0 and field1.dup(settleWater(masks)) == field1 and
    field2.dup(settleWater(masks)) == field2

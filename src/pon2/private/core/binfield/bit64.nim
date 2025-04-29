## This module implements binary fields with 64bit operations.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import ../../[assign3, bitops3, macros2, staticfor2]
import ../../../core/[common, rule]

type Bit64BinField* = object ## Binary field with 64bit operations.
  col012: uint64 # use higher 16*3 bits
  col345: uint64 # use higher 16*3 bits

defineExpand "", "012", "345"
defineExpand "6", "0", "1", "2", "3", "4", "5"

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const ValidMask = 0x3ffe_3ffe_3ffe_0000'u64

func init(T: type Bit64BinField, col012: uint64, col345: uint64): T {.inline.} =
  T(col012: col012, col345: col345)

func init*(T: type Bit64BinField): Bit64BinField {.inline.} =
  ## Returns the binary field with all elements zero.
  T.init(0, 0)

func initOne*(T: type Bit64BinField): Bit64BinField {.inline.} =
  ## Returns the binary field with all valid elements one.
  T.init(ValidMask, ValidMask)

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
  expand col:
    f1.col.assign f1.col or f2.col

func `-=`*(f1: var Bit64BinField, f2: Bit64BinField) {.inline.} =
  expand col:
    f1.col.assign f1.col *~ f2.col

func `*=`*(f1: var Bit64BinField, f2: Bit64BinField) {.inline.} =
  expand col:
    f1.col.assign f1.col and f2.col

func `*=`(self: var Bit64BinField, val: uint64) {.inline.} =
  expand col:
    self.col.assign self.col and val

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
    mask.setBitBE 2.succ i
    mask.setBitBE 18.succ i
    mask.setBitBE 34.succ i

  mask

const
  AirMask = initAirMask()
  ColMaskBase = 0xffff_0000_0000_0000'u64

template withColMasks(col: Col, body: untyped): untyped =
  ## Runs `body` with `mask012` and `mask345` exposed.
  case col
  of Col0, Col1, Col2:
    let
      mask012 {.inject.} = ColMaskBase shr (col.ord shl 4)
      mask345 {.inject.} = 0'u64

    body
  of Col3, Col4, Col5:
    let
      mask012 {.inject.} = 0'u64
      mask345 {.inject.} = ColMaskBase shr (col.pred(3).ord shl 4)

    body

func kept*(self: Bit64BinField, row: Row): Bit64BinField {.inline.} =
  ## Returns the binary field with only the given row.
  self * (0x2000_2000_2000_0000'u64 shr row.ord)

func kept*(self: Bit64BinField, col: Col): Bit64BinField {.inline.} =
  ## Returns the binary field with only the given column.
  col.withColMasks:
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
  expand col:
    self.col.assign 0

# ------------------------------------------------
# Replace
# ------------------------------------------------

func replace*(self: var Bit64BinField, col: Col, after: Bit64BinField) {.inline.} =
  ## Replaces the column of the binary field by `after`.
  col.withColMasks:
    expand col, mask:
      self.col.assign (self.col *~ mask) or (after.col and mask)

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
  expand col:
    self.col.assign self.col shl 1

func shiftUp*(self: var Bit64BinField) {.inline.} =
  ## Shifts the binary field upward and extracts the valid area.
  expand col:
    self.col.assign (self.col shl 1).keptValid

func shiftDownRaw*(self: var Bit64BinField) {.inline.} =
  ## Shifts the binary field downward.
  expand col:
    self.col.assign self.col shr 1

func shiftDown*(self: var Bit64BinField) {.inline.} =
  ## Shifts the binary field downward and extracts the valid area.
  expand col:
    self.col.assign (self.col shr 1).keptValid

func shiftRightRaw*(self: var Bit64BinField) {.inline.} =
  ## Shifts the binary field rightward.
  let
    after012 = self.col012 shr 16
    after345 = (self.col012 shl 32) or (self.col345 shr 16)

  expand col, after:
    self.col.assign after

func shiftRight*(self: var Bit64BinField) {.inline.} =
  ## Shifts the binary field rightward and extracts the valid area.
  let
    after012 = (self.col012 shr 16).keptValid
    after345 = (self.col012 shl 32) or (self.col345 shr 16).keptValid

  expand col, after:
    self.col.assign after

func shiftLeftRaw*(self: var Bit64BinField) {.inline.} =
  ## Shifts the binary field leftward.
  let
    after012 = (self.col012 shl 16) or (self.col345 shr 32)
    after345 = self.col345 shl 16

  expand col, after:
    self.col.assign after

func shiftLeft*(self: var Bit64BinField) {.inline.} =
  ## Shifts the binary field leftward and extracts the valid area.
  let
    after012 = (self.col012 shl 16) or (self.col345 shr 32).keptValid
    after345 = self.col345 shl 16

  expand col, after:
    self.col.assign after

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
  expand col:
    self.col.assign (self.col.reverseBits shl 15).flipped

func flipHorizontal*(self: var Bit64BinField) {.inline.} =
  ## Flips the binary field horizontally.
  let
    after012 = self.col345.flipped
    after345 = self.col012.flipped

  expand col, after:
    self.col.assign after

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
# Drop Garbages
# ------------------------------------------------

const
  MaskL = 0x3ffe_0000_0000_0000'u64
  MaskC = 0x0000_3ffe_0000_0000'u64
  MaskR = 0x0000_0000_3ffe_0000'u64

func extracted(self: Bit64BinField, col: static Col): uint64 {.inline.} =
  ## Returns the value corresponding to the column.
  when col == Col0:
    self.col012 and MaskL
  elif col == Col1:
    self.col012 and MaskC
  elif col == Col2:
    self.col012 and MaskR
  elif col == Col3:
    self.col345 and MaskL
  elif col == Col4:
    self.col345 and MaskC
  else:
    self.col345 and MaskR

func dropGarbagesTsu*(
    self: var Bit64BinField, cnts: array[Col, int], existField: Bit64BinField
) {.inline.} =
  ## Drops cells by Tsu rule.
  ## This function requires that the mask is settled and the counts are non-negative.
  expand notExist, col:
    let notExist = (not existField.col).keptValid

  let
    notExist0 = notExist012 and MaskL
    notExist1 = notExist012 and MaskC
    notExist2 = notExist012 and MaskR
    notExist3 = notExist345 and MaskL
    notExist4 = notExist345 and MaskC
    notExist5 = notExist345 and MaskR

  expand6 garbages, notExist, Col:
    let garbages = notExist *~ (notExist shl cnts[Col])

  self.col012.assign bitor2(self.col012, garbages0, garbages1, garbages2)
  self.col345.assign bitor2(self.col345, garbages3, garbages4, garbages5)

func dropGarbagesWater*(
    self, other1, other2: var Bit64BinField,
    cnts: array[Col, int],
    existField: Bit64BinField,
) {.inline.} =
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
        cnt = cnts[Col]
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

  self.col012.assign bitor2(afterSelf0, afterSelf1, afterSelf2)
  self.col345.assign bitor2(afterSelf3, afterSelf4, afterSelf5)

  other1.col012.assign bitor2(afterOther10, afterOther11, afterOther12)
  other1.col345.assign bitor2(afterOther13, afterOther14, afterOther15)

  other2.col012.assign bitor2(afterOther20, afterOther21, afterOther22)
  other2.col345.assign bitor2(afterOther23, afterOther24, afterOther25)

# ------------------------------------------------
# Settle
# ------------------------------------------------

func write(
    self: out array[Col, PextMask[uint64]], existField: Bit64BinField
) {.inline.} =
  ## Initializes the masks.
  staticFor(col, Col):
    {.push warning[ProveInit]: off.}
    self[col].assign PextMask[uint64].init existField.extracted col
    {.pop.}

func shiftAmt(col: Col): int {.inline.} =
  ## Returns the shift amount.
  case col
  of Col0, Col3: 49
  of Col1, Col4: 33
  of Col2, Col5: 17

func settleTsu(
    self: var Bit64BinField, masks: array[Col, PextMask[uint64]]
) {.inline.} =
  ## Settles the binary field by Tsu rule.
  expand6 after, Col:
    let after: uint64

    block:
      const ShiftAmt = Col.shiftAmt
      after = self.extracted(Col).pext(masks[Col]) shl ShiftAmt

  self.col012.assign bitor2(after0, after1, after2)
  self.col345.assign bitor2(after3, after4, after5)

func settleTsu*(
    field1, field2, field3: var Bit64BinField, existField: Bit64BinField
) {.inline.} =
  ## Settles the binary field by Tsu rule.
  var masks: array[Col, PextMask[uint64]]
  masks.write existField

  field1.settleTsu masks
  field2.settleTsu masks
  field3.settleTsu masks

func settleWater(
    self: var Bit64BinField, masks: array[Col, PextMask[uint64]]
) {.inline.} =
  ## Settles the binary field by Water rule.
  expand6 after, Col:
    let after: uint64

    block:
      const ShiftAmt = Col.shiftAmt
      after =
        self.extracted(Col).pext(masks[Col]) shl
        max(ShiftAmt, ShiftAmt + WaterHeight - masks[Col].popcnt)

  self.col012.assign bitor2(after0, after1, after2)
  self.col345.assign bitor2(after3, after4, after5)

func settleWater*(
    field1, field2, field3: var Bit64BinField, existField: Bit64BinField
) {.inline.} =
  ## Settles the binary field by Water rule.
  var masks: array[Col, PextMask[uint64]]
  masks.write existField

  field1.settleWater masks
  field2.settleWater masks
  field3.settleWater masks

func areSettledTsu*(
    field1, field2, field3, existField: Bit64BinField
): bool {.inline.} =
  ## Returns `true` if all binary fields are settled by Tsu rule.
  ## Note that this function is only slightly lighter than `settleTsu`.
  var masks: array[Col, PextMask[uint64]]
  masks.write existField

  field1.dup(settleTsu(_, masks)) == field1 and field2.dup(settleTsu(_, masks)) == field2 and
    field3.dup(settleTsu(_, masks)) == field3

func areSettledWater*(
    field1, field2, field3, existField: Bit64BinField
): bool {.inline.} =
  ## Returns `true` if all binary fields are settled by Water rule.
  ## Note that this function is only slightly lighter than `settleWater`.
  var masks: array[Col, PextMask[uint64]]
  masks.write existField

  field1.dup(settleWater(_, masks)) == field1 and
    field2.dup(settleWater(_, masks)) == field2 and
    field3.dup(settleWater(_, masks)) == field3

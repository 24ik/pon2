## This module implements binary fields with 32bit operations.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import ../../[assign3, bitops3, macros2, staticfor2]
import ../../../core/[common, rule]

type Bit32BinField* = object ## Binary field with 32bit operations.
  col01: uint32
  col23: uint32
  col45: uint32

defineExpand "", "01", "23", "45"
defineExpand "6", "0", "1", "2", "3", "4", "5"

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const ValidMask = 0x3ffe_3ffe'u32

func init(
    T: type Bit32BinField, col01: uint32, col23: uint32, col45: uint32
): T {.inline.} =
  T(col01: col01, col23: col23, col45: col45)

func init*(T: type Bit32BinField): Bit32BinField {.inline.} =
  ## Returns the binary field with all elements zero.
  T.init(0, 0, 0)

func initOne*(T: type Bit32BinField): Bit32BinField {.inline.} =
  ## Returns the binary field with all valid elements one.
  T.init(ValidMask, ValidMask, ValidMask)

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
  Bit32BinField.init(f1.col01 or f2.col01, f1.col23 or f2.col23, f1.col45 or f2.col45)

func `-`*(f1, f2: Bit32BinField): Bit32BinField {.inline.} =
  Bit32BinField.init(f1.col01 *~ f2.col01, f1.col23 *~ f2.col23, f1.col45 *~ f2.col45)

func `*`*(f1, f2: Bit32BinField): Bit32BinField {.inline.} =
  Bit32BinField.init(
    f1.col01 and f2.col01, f1.col23 and f2.col23, f1.col45 and f2.col45
  )

func `*`(self: Bit32BinField, val: uint32): Bit32BinField {.inline.} =
  Bit32BinField.init(self.col01 and val, self.col23 and val, self.col45 and val)

func `xor`*(f1, f2: Bit32BinField): Bit32BinField {.inline.} =
  Bit32BinField.init(
    f1.col01 xor f2.col01, f1.col23 xor f2.col23, f1.col45 xor f2.col45
  )

func `+=`*(f1: var Bit32BinField, f2: Bit32BinField) {.inline.} =
  expand col:
    f1.col.assign f1.col or f2.col

func `-=`*(f1: var Bit32BinField, f2: Bit32BinField) {.inline.} =
  expand col:
    f1.col.assign f1.col *~ f2.col

func `*=`*(f1: var Bit32BinField, f2: Bit32BinField) {.inline.} =
  expand col:
    f1.col.assign f1.col and f2.col

func `*=`(self: var Bit32BinField, val: uint32) {.inline.} =
  expand col:
    self.col.assign self.col and val

func sum*(f1, f2, f3: Bit32BinField): Bit32BinField {.inline.} =
  Bit32BinField.init(
    bitor2(f1.col01, f2.col01, f3.col01),
    bitor2(f1.col23, f2.col23, f3.col23),
    bitor2(f1.col45, f2.col45, f3.col45),
  )

func sum*(f1, f2, f3, f4: Bit32BinField): Bit32BinField {.inline.} =
  Bit32BinField.init(
    bitor2(f1.col01, f2.col01, f3.col01, f4.col01),
    bitor2(f1.col23, f2.col23, f3.col23, f4.col23),
    bitor2(f1.col45, f2.col45, f3.col45, f4.col45),
  )

func sum*(f1, f2, f3, f4, f5: Bit32BinField): Bit32BinField {.inline.} =
  Bit32BinField.init(
    bitor2(f1.col01, f2.col01, f3.col01, f4.col01, f5.col01),
    bitor2(f1.col23, f2.col23, f3.col23, f4.col23, f5.col23),
    bitor2(f1.col45, f2.col45, f3.col45, f4.col45, f5.col45),
  )

func sum*(f1, f2, f3, f4, f5, f6: Bit32BinField): Bit32BinField {.inline.} =
  Bit32BinField.init(
    bitor2(f1.col01, f2.col01, f3.col01, f4.col01, f5.col01, f6.col01),
    bitor2(f1.col23, f2.col23, f3.col23, f4.col23, f5.col23, f6.col23),
    bitor2(f1.col45, f2.col45, f3.col45, f4.col45, f5.col45, f6.col45),
  )

func sum*(f1, f2, f3, f4, f5, f6, f7: Bit32BinField): Bit32BinField {.inline.} =
  Bit32BinField.init(
    bitor2(f1.col01, f2.col01, f3.col01, f4.col01, f5.col01, f6.col01, f7.col01),
    bitor2(f1.col23, f2.col23, f3.col23, f4.col23, f5.col23, f6.col23, f7.col23),
    bitor2(f1.col45, f2.col45, f3.col45, f4.col45, f5.col45, f6.col45, f7.col45),
  )

func sum*(f1, f2, f3, f4, f5, f6, f7, f8: Bit32BinField): Bit32BinField {.inline.} =
  Bit32BinField.init(
    bitor2(
      f1.col01, f2.col01, f3.col01, f4.col01, f5.col01, f6.col01, f7.col01, f8.col01
    ),
    bitor2(
      f1.col23, f2.col23, f3.col23, f4.col23, f5.col23, f6.col23, f7.col23, f8.col23
    ),
    bitor2(
      f1.col45, f2.col45, f3.col45, f4.col45, f5.col45, f6.col45, f7.col45, f8.col45
    ),
  )

func prod*(f1, f2, f3: Bit32BinField): Bit32BinField {.inline.} =
  Bit32BinField.init(
    bitand2(f1.col01, f2.col01, f3.col01),
    bitand2(f1.col23, f2.col23, f3.col23),
    bitand2(f1.col45, f2.col45, f3.col45),
  )

# ------------------------------------------------
# Keep
# ------------------------------------------------

func initAirMask(): uint32 {.inline.} =
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
  ## Runs `body` with `mask01`, `mask23`, and `mask45` exposed.
  case col
  of Col0, Col1:
    let
      mask01 {.inject.} = ColMaskBase shr (col.ord shl 4)
      mask23 {.inject.} = 0'u32
      mask45 {.inject.} = 0'u32

    body
  of Col2, Col3:
    let
      mask01 {.inject.} = 0'u32
      mask23 {.inject.} = ColMaskBase shr (col.pred(2).ord shl 4)
      mask45 {.inject.} = 0'u32

    body
  of Col4, Col5:
    let
      mask01 {.inject.} = 0'u32
      mask23 {.inject.} = 0'u32
      mask45 {.inject.} = ColMaskBase shr (col.pred(4).ord shl 4)

    body

func kept*(self: Bit32BinField, row: Row): Bit32BinField {.inline.} =
  ## Returns the binary field with only the given row.
  self * (0x2000_2000'u32 shr row.ord)

func kept*(self: Bit32BinField, col: Col): Bit32BinField {.inline.} =
  ## Returns the binary field with only the given column.
  col.withColMasks:
    Bit32BinField.init(
      self.col01 and mask01, self.col23 and mask23, self.col45 and mask45
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

func keptValid(self: uint32): uint32 {.inline.} =
  ## Returns the value with only the valid area.
  self and ValidMask

# ------------------------------------------------
# Clear
# ------------------------------------------------

func clear*(self: var Bit32BinField) {.inline.} =
  ## Clears the binary field.
  expand col:
    self.col.assign 0

# ------------------------------------------------
# Replace
# ------------------------------------------------

func replace*(self: var Bit32BinField, col: Col, after: Bit32BinField) {.inline.} =
  ## Replaces the column of the binary field by `after`.
  col.withColMasks:
    expand col, mask:
      self.col.assign (self.col *~ mask) or (after.col and mask)

# ------------------------------------------------
# Population Count
# ------------------------------------------------

func popcnt*(self: Bit32BinField): int {.inline.} =
  ## Returns the population count.
  self.col01.countOnes + self.col23.countOnes + self.col45.countOnes

# ------------------------------------------------
# Shift - In-place
# ------------------------------------------------

func shiftUpRaw*(self: var Bit32BinField) {.inline.} =
  ## Shifts the binary field upward.
  expand col:
    self.col.assign self.col shl 1

func shiftUp*(self: var Bit32BinField) {.inline.} =
  ## Shifts the binary field upward and extracts the valid area.
  expand col:
    self.col.assign (self.col shl 1).keptValid

func shiftDownRaw*(self: var Bit32BinField) {.inline.} =
  ## Shifts the binary field downward.
  expand col:
    self.col.assign self.col shr 1

func shiftDown*(self: var Bit32BinField) {.inline.} =
  ## Shifts the binary field downward and extracts the valid area.
  expand col:
    self.col.assign (self.col shr 1).keptValid

func shiftRightRaw*(self: var Bit32BinField) {.inline.} =
  ## Shifts the binary field rightward.
  let
    after01 = self.col01 shr 16
    after23 = (self.col01 shl 16) or (self.col23 shr 16)
    after45 = (self.col23 shl 16) or (self.col45 shr 16)

  expand col, after:
    self.col.assign after

func shiftRight*(self: var Bit32BinField) {.inline.} =
  ## Shifts the binary field rightward and extracts the valid area.
  self.shiftRightRaw

func shiftLeftRaw*(self: var Bit32BinField) {.inline.} =
  ## Shifts the binary field leftward.
  let
    after01 = (self.col01 shl 16) or (self.col23 shr 16)
    after23 = (self.col23 shl 16) or (self.col45 shr 16)
    after45 = self.col45 shl 16

  expand col, after:
    self.col.assign after

func shiftLeft*(self: var Bit32BinField) {.inline.} =
  ## Shifts the binary field leftward and extracts the valid area.
  self.shiftLeftRaw

# ------------------------------------------------
# Shift - Out-place
# ------------------------------------------------

func shiftedUpRaw*(self: Bit32BinField): Bit32BinField {.inline.} =
  ## Returns the binary field shifted upward.
  self.dup shiftUpRaw

func shiftedUp*(self: Bit32BinField): Bit32BinField {.inline.} =
  ## Returns the binary field shifted upward and extracted the valid area.
  self.dup shiftUp

func shiftedDownRaw*(self: Bit32BinField): Bit32BinField {.inline.} =
  ## Returns the binary field shifted downward.
  self.dup shiftDownRaw

func shiftedDown*(self: Bit32BinField): Bit32BinField {.inline.} =
  ## Returns the binary field shifted downward and extracted the valid area.
  self.dup shiftDown

func shiftedRightRaw*(self: Bit32BinField): Bit32BinField {.inline.} =
  ## Returns the binary field shifted rightward.
  self.dup shiftRightRaw

func shiftedRight*(self: Bit32BinField): Bit32BinField {.inline.} =
  ## Returns the binary field shifted rightward and extracted the valid area.
  self.dup shiftRight

func shiftedLeftRaw*(self: Bit32BinField): Bit32BinField {.inline.} =
  ## Returns the binary field shifted leftward.
  self.dup shiftLeftRaw

func shiftedLeft*(self: Bit32BinField): Bit32BinField {.inline.} =
  ## Returns the binary field shifted leftward and extracted the valid area.
  self.dup shiftLeft

# ------------------------------------------------
# Flip
# ------------------------------------------------

func flipped(val: uint32): uint32 {.inline.} =
  ## Returns the value two columns flipped.
  (val shr 16) or (val shl 16)

func flipVertical*(self: var Bit32BinField) {.inline.} =
  ## Flips the binary field vertically.
  expand col:
    self.col.assign (self.col.reverseBits shr 1).flipped

func flipHorizontal*(self: var Bit32BinField) {.inline.} =
  ## Flips the binary field horizontally.
  let
    after01 = self.col45.flipped
    after23 = self.col23.flipped
    after45 = self.col01.flipped

  expand col, after:
    self.col.assign after

func flippedVertical*(self: Bit32BinField): Bit32BinField {.inline.} =
  ## Returns the binary field flipped vertically.
  self.dup flipVertical

func flippedHorizontal*(self: Bit32BinField): Bit32BinField {.inline.} =
  ## Returns the binary field flipped horizontally.
  self.dup flipHorizontal

# ------------------------------------------------
# Indexer
# ------------------------------------------------

func idxFromMsb(row: Row, col: Col): int {.inline.} =
  ## Returns the bit index for indexers.
  col.ord shl 4 + (row.ord + 2)

func `[]`*(self: Bit32BinField, row: static Row, col: static Col): bool {.inline.} =
  when col in {Col0, Col1}:
    self.col01.getBitBE static(idxFromMsb(row, col))
  elif col in {Col2, Col3}:
    self.col23.getBitBE static(idxFromMsb(row, col.pred 2))
  else:
    self.col45.getBitBE static(idxFromMsb(row, col.pred 4))

func `[]`*(self: Bit32BinField, row: Row, col: Col): bool {.inline.} =
  case col
  of Col0, Col1:
    self.col01.getBitBE idxFromMsb(row, col)
  of Col2, Col3:
    self.col23.getBitBE idxFromMsb(row, col.pred 2)
  of Col4, Col5:
    self.col45.getBitBE idxFromMsb(row, col.pred 4)

func `[]=`*(self: var Bit32BinField, row: Row, col: Col, val: bool) {.inline.} =
  case col
  of Col0, Col1:
    self.col01.changeBitBE idxFromMsb(row, col), val
  of Col2, Col3:
    self.col23.changeBitBE idxFromMsb(row, col.pred 2), val
  of Col4, Col5:
    self.col45.changeBitBE idxFromMsb(row, col.pred 4), val

# ------------------------------------------------
# Insert / Delete
# ------------------------------------------------

func isInWater(row: Row, rule: static Rule): bool {.inline.} =
  ## Returns `true` if the row is in the water.
  (static rule == Water) and row.ord + WaterHeight >= Height

func insert(
    self: var uint32, col: Col, row: Row, val: bool, rule: static Rule
) {.inline.} =
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
  if row.isInWater rule:
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
    self: var Bit32BinField, row: Row, col: Col, val: bool, rule: static Rule
) {.inline.} =
  ## Inserts the value and shifts the binary field.
  ## If (row, col) is in the air, shifts the binary field upward above where inserted.
  ## If it is in the water, shifts the binary field downward below where inserted.
  case col
  of Col0, Col1:
    self.col01.insert col, row, val, rule
  of Col2, Col3:
    self.col23.insert col.pred 2, row, val, rule
  of Col4, Col5:
    self.col45.insert col.pred 4, row, val, rule

func delete(self: var uint32, col: Col, row: Row, rule: static Rule) {.inline.} =
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
  if row.isInWater rule:
    below = ((self and belowMask) shl 1).keptValid
    above = self and aboveMask
  else:
    below = self and belowMask
    above = ((self and aboveMask) shr 1).keptValid

  self.assign ((below or above) and colMask) or (self *~ colMask)

func delete*(
    self: var Bit32BinField, row: Row, col: Col, rule: static Rule
) {.inline.} =
  ## Deletes the value and shifts the binary field.
  ## If (row, col) is in the air, shifts the binary field downward above where deleted.
  ## If it is in the water, shifts the binary field upward below where deleted.
  case col
  of Col0, Col1:
    self.col01.delete col, row, rule
  of Col2, Col3:
    self.col23.delete col.pred 2, row, rule
  of Col4, Col5:
    self.col45.delete col.pred 4, row, rule

# ------------------------------------------------
# Drop Garbages
# ------------------------------------------------

const
  MaskL = 0x3ffe_0000'u32
  MaskR = 0x0000_3ffe'u32

func extracted(self: Bit32BinField, col: static Col): uint32 {.inline.} =
  ## Returns the value corresponding to the column.
  when col == Col0:
    self.col01 and MaskL
  elif col == Col1:
    self.col01 and MaskR
  elif col == Col2:
    self.col23 and MaskL
  elif col == Col3:
    self.col23 and MaskR
  elif col == Col4:
    self.col45 and MaskL
  else:
    self.col45 and MaskR

func dropGarbagesTsu*(
    self: var Bit32BinField, cnts: array[Col, int], existField: Bit32BinField
) {.inline.} =
  ## Drops cells by Tsu rule.
  ## This function requires that the mask is settled and the counts are non-negative.
  expand notExist, col:
    let notExist = (not existField.col).keptValid

  let
    notExist0 = notExist01 and MaskL
    notExist1 = notExist01 and MaskR
    notExist2 = notExist23 and MaskL
    notExist3 = notExist23 and MaskR
    notExist4 = notExist45 and MaskL
    notExist5 = notExist45 and MaskR

  expand6 garbages, notExist, Col:
    let garbages = notExist *~ (notExist shl cnts[Col])

  self.col01.assign bitor2(self.col01, garbages0, garbages1)
  self.col23.assign bitor2(self.col23, garbages2, garbages3)
  self.col45.assign bitor2(self.col45, garbages4, garbages5)

func dropGarbagesWater*(
    self, other1, other2: var Bit32BinField,
    cnts: array[Col, int],
    existField: Bit32BinField,
) {.inline.} =
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

  self.col01.assign afterSelf0 or afterSelf1
  self.col23.assign afterSelf2 or afterSelf3
  self.col45.assign afterSelf4 or afterSelf5

  other1.col01.assign afterOther10 or afterOther11
  other1.col23.assign afterOther12 or afterOther13
  other1.col45.assign afterOther14 or afterOther15

  other2.col01.assign afterOther20 or afterOther21
  other2.col23.assign afterOther22 or afterOther23
  other2.col45.assign afterOther24 or afterOther25

# ------------------------------------------------
# Settle
# ------------------------------------------------

func write(
    self: out array[Col, PextMask[uint32]], existField: Bit32BinField
) {.inline.} =
  ## Initializes the masks.
  staticFor(col, Col):
    {.push warning[ProveInit]: off.}
    self[col].assign PextMask[uint32].init existField.extracted col
    {.pop.}

func shiftAmt(col: Col): int {.inline.} =
  ## Returns the shift amount.
  case col
  of Col0, Col2, Col4: 17
  of Col1, Col3, Col5: 1

func settleTsu(
    self: var Bit32BinField, masks: array[Col, PextMask[uint32]]
) {.inline.} =
  ## Settles the binary field by Tsu rule.
  expand6 after, Col:
    let after: uint32

    block:
      const ShiftAmt = Col.shiftAmt
      after = self.extracted(Col).pext(masks[Col]) shl ShiftAmt

  self.col01.assign after0 or after1
  self.col23.assign after2 or after3
  self.col45.assign after4 or after5

func settleTsu*(
    field1, field2, field3: var Bit32BinField, existField: Bit32BinField
) {.inline.} =
  ## Settles the binary fields by Tsu rule.
  var masks: array[Col, PextMask[uint32]]
  masks.write existField

  field1.settleTsu masks
  field2.settleTsu masks
  field3.settleTsu masks

func settleWater(
    self: var Bit32BinField, masks: array[Col, PextMask[uint32]]
) {.inline.} =
  ## Settles the binary field by Water rule.
  expand6 after, Col:
    let after: uint32

    block:
      const ShiftAmt = Col.shiftAmt
      after =
        self.extracted(Col).pext(masks[Col]) shl
        max(ShiftAmt, ShiftAmt + WaterHeight - masks[Col].popcnt)

  self.col01.assign after0 or after1
  self.col23.assign after2 or after3
  self.col45.assign after4 or after5

func settleWater*(
    field1, field2, field3: var Bit32BinField, existField: Bit32BinField
) {.inline.} =
  ## Settles the binary fields by Water rule.
  var masks: array[Col, PextMask[uint32]]
  masks.write existField

  field1.settleWater masks
  field2.settleWater masks
  field3.settleWater masks

func areSettledTsu*(
    field1, field2, field3, existField: Bit32BinField
): bool {.inline.} =
  ## Returns `true` if all binary fields are settled by Tsu rule.
  ## Note that this function is only slightly lighter than `settleTsu`.
  var masks: array[Col, PextMask[uint32]]
  masks.write existField

  field1.dup(settleTsu(_, masks)) == field1 and field2.dup(settleTsu(_, masks)) == field2 and
    field3.dup(settleTsu(_, masks)) == field3

func areSettledWater*(
    field1, field2, field3, existField: Bit32BinField
): bool {.inline.} =
  ## Returns `true` if all binary fields are settled by Water rule.
  ## Note that this function is only slightly lighter than `settleWater`.
  var masks: array[Col, PextMask[uint32]]
  masks.write existField

  field1.dup(settleWater(_, masks)) == field1 and
    field2.dup(settleWater(_, masks)) == field2 and
    field3.dup(settleWater(_, masks)) == field3

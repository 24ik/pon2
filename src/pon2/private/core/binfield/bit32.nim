## This module implements binary fields with 32bit operations.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[bitops, sugar]
import stew/[bitops2]
import ../../[assign3, bitops3, macros2, staticfor2]
import ../../../core/[common, rule]

type
  Bit32BinField* = object ## Binary field with 32bit operations.
    col01: uint32
    col23: uint32
    col45: uint32

  Bit32DropMask* = array[Col, PextMask[uint32]] ## Mask used in dropping.

# ------------------------------------------------
# Macro
# ------------------------------------------------

macro expand(identsAndBody: varargs[untyped]): untyped =
  ## Runs the body (the last argument) three times with specified identifiers
  ## (the rest arguments) replaced by `{ident}01`, `{ident}23`, and `{ident}45`.
  let
    body = identsAndBody[^1]
    idents = identsAndBody[0 ..^ 2]
    stmts = nnkStmtList.newNimNode body

  var body01 = body
  for id in idents:
    body01 = body01.replaced(id, (id.strVal & "01").ident)
  stmts.add body01

  var body23 = body
  for id in idents:
    body23 = body23.replaced(id, (id.strVal & "23").ident)
  stmts.add body23

  var body45 = body
  for id in idents:
    body45 = body45.replaced(id, (id.strVal & "45").ident)
  stmts.add body45

  stmts

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init(
    T: type Bit32BinField, col01: uint32, col23: uint32, col45: uint32
): T {.inline.} =
  T(col01: col01, col23: col23, col45: col45)

func init*(T: type Bit32BinField): Bit32BinField {.inline.} =
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
    mask.setBitBE i.succ 2
    mask.setBitBE i.succ 18

  mask

const
  ValidMask = 0x3ffe_3ffe'u32
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
# Drop
# ------------------------------------------------

func colVal(self: Bit32BinField, col: static Col): uint32 {.inline.} =
  ## Returns the value corresponding to the column.
  when col == Col0:
    self.col01.bextr(16, 16)
  elif col == Col1:
    self.col01 and 0x0000_ffff'u32
  elif col == Col2:
    self.col23.bextr(16, 16)
  elif col == Col3:
    self.col23 and 0x0000_ffff'u32
  elif col == Col4:
    self.col45.bextr(16, 16)
  else:
    self.col45 and 0x0000_ffff'u32

func toDropMask*(existField: Bit32BinField): Bit32DropMask {.inline.} =
  ## Returns a drop mask converted from the exist field.
  {.push warning[Uninit]: off.}
  var dropMask: Bit32DropMask
  staticFor(col, Col):
    dropMask[col].assign PextMask[uint32].init existField.colVal col

  return dropMask
  {.pop.}

func dropTsu(self: var Bit32BinField, mask: Bit32DropMask) {.inline.} =
  ## Falling floating cells.
  self.col01.assign (self.colVal(Col0).pext(mask[Col0]) shl 17) or
    (self.colVal(Col1).pext(mask[Col1]) shl 1)

  self.col23.assign (self.colVal(Col2).pext(mask[Col2]) shl 17) or
    (self.colVal(Col3).pext(mask[Col3]) shl 1)

  self.col45.assign (self.colVal(Col4).pext(mask[Col4]) shl 17) or
    (self.colVal(Col5).pext(mask[Col5]) shl 1)

func dropWater(self: var Bit32BinField, mask: Bit32DropMask) {.inline.} =
  ## Falling floating cells.
  let
    col0 = self.colVal Col0
    col1 = self.colVal Col1
    col2 = self.colVal Col2
    col3 = self.colVal Col3
    col4 = self.colVal Col4
    col5 = self.colVal Col5

  self.col01.assign (
    col0.pext(mask[Col0]) shl max(17, 17 + WaterHeight - mask[Col0].popcnt)
  ) or (col1.pext(mask[Col1]) shl max(1, 1 + WaterHeight - mask[Col1].popcnt))

  self.col23.assign (
    col2.pext(mask[Col2]) shl max(17, 17 + WaterHeight - mask[Col2].popcnt)
  ) or (col3.pext(mask[Col3]) shl max(1, 1 + WaterHeight - mask[Col3].popcnt))

  self.col45.assign (
    col4.pext(mask[Col4]) shl max(17, 17 + WaterHeight - mask[Col4].popcnt)
  ) or (col5.pext(mask[Col5]) shl max(1, 1 + WaterHeight - mask[Col5].popcnt))

func drop*(self: var Bit32BinField, mask: Bit32DropMask, rule: static Rule) {.inline.} =
  ## Falling floating cells.
  when rule == Tsu:
    self.dropTsu mask
  else:
    self.dropWater mask

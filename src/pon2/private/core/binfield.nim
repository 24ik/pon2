## This module implements binary fields.
##
## Low-level Implementation Documentations:
## - [xmm](./binfield/xmm.html)
## - [bit64](./binfield/bit64.html)
## - [bit32](./binfield/bit32.html)
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[setutils]
import ../[assign, macros, simd, staticfor]
import ../../core/[common, placement, rule]

export common, placement

when Sse42Available:
  import ./binfield/[xmm]
  export xmm

  type BinField* = XmmBinField ## Binary field.
elif defined(cpu32):
  import ./binfield/[bit32]
  export bit32

  type BinField* = Bit32BinField ## Binary field.
else:
  import ./binfield/[bit64]
  export bit64

  type BinField* = Bit64BinField ## Binary field.

# ------------------------------------------------
# Property
# ------------------------------------------------

func isDead*(self: BinField, rule: static Rule): bool {.inline, noinit.} =
  ## Returns `true` if the binary field is in a defeated state.
  staticCase:
    case rule
    of Tsu:
      self[Row1, Col2]
    of Water:
      self * BinField.initLowerAir != BinField.init

# ------------------------------------------------
# Placement
# ------------------------------------------------

const
  AllCols = {Col.low .. Col.high}
  OuterCols: array[Col, set[Col]] =
    [{Col0}, {Col0, Col1}, AllCols, {Col3, Col4, Col5}, {Col4, Col5}, {Col5}]
  InvalidPlcmts: array[Col, set[Placement]] = [
    {Up0, Right0, Down0, Left1},
    {Up1, Right1, Down1, Left1, Right0, Left2},
    {Up2, Right2, Down2, Left2, Right1, Left3},
    {Up3, Right3, Down3, Left3, Right2, Left4},
    {Up4, Right4, Down4, Left4, Right3, Left5},
    {Up5, Down5, Left5, Right4},
  ]

func invalidPlacements*(self: BinField): set[Placement] {.inline, noinit.} =
  ## Returns the invalid placements.
  var
    invalidPlcmts = set[Placement]({})
    availableCols = AllCols

  # If puyo exists at 12th row, that column and outer ones are unavailable,
  # and the pivot-puyo cannot be lifted at that column.
  staticFor(col, Col):
    if self[Row1, col]:
      availableCols.excl OuterCols[col]
      invalidPlcmts.incl Placement.init(col, Down)

  # If there is an available column with height 11, or the heights of the 2nd and
  # 4th columns are both 12, all columns are available.
  var canMawashi = self[Row1, Col1] and self[Row1, Col3]
  for col in availableCols:
    canMawashi.assign canMawashi or self[Row2, col]
  if canMawashi:
    availableCols.assign AllCols

  # If puyo exists at 13th row, that column and outer ones are unavailable.
  staticFor(col, Col):
    if self[Row0, col]:
      availableCols.excl OuterCols[col]

  for col in availableCols.complement:
    invalidPlcmts.incl InvalidPlcmts[col]

  invalidPlcmts

func validPlacements*(self: BinField): set[Placement] {.inline, noinit.} =
  ## Returns the valid placements.
  self.invalidPlacements.complement

func validDblPlacements*(self: BinField): set[Placement] {.inline, noinit.} =
  ## Returns the valid placements for double pairs.
  DblPlacements - self.invalidPlacements

# ------------------------------------------------
# Dilate
# ------------------------------------------------

func dilated(self: BinField): BinField {.inline, noinit.} =
  ## Dilates the binary field.
  sum(
    self, self.shiftedUpRaw, self.shiftedDownRaw, self.shiftedRightRaw,
    self.shiftedLeftRaw,
  )

func dilatedVertical(self: BinField): BinField {.inline, noinit.} =
  ## Dilates the binary field vertically.
  sum(self, self.shiftedUpRaw, self.shiftedDownRaw)

func dilatedHorizontal(self: BinField): BinField {.inline, noinit.} =
  ## Dilates the binary field horizontally.
  sum(self, self.shiftedRightRaw, self.shiftedLeftRaw)

# ------------------------------------------------
# Pop
# ------------------------------------------------

template withConn(self: BinField, body: untyped): untyped =
  ## Calculates the connection data and runs the body with `connVisible`,
  ## `connHas3`, and `connHas2` exposed.
  ## This function ignores ghost puyos.
  block:
    let
      connVisible {.inject.} = self.keptVisible

      hasU = connVisible * connVisible.shiftedDownRaw
      hasD = connVisible * self.shiftedUpRaw
      hasR = connVisible * self.shiftedLeftRaw
      hasL = connVisible * self.shiftedRightRaw

      hasUD = hasU * hasD
      hasRL = hasR * hasL
      hasUorD = hasU + hasD
      hasRorL = hasR + hasL

      connHas3 {.inject.} = hasUD * hasRorL + hasRL * hasUorD
      connHas2 {.inject.} = sum(hasUD, hasRL, hasUorD * hasRorL)

    body

func extractedPop*(self: BinField): BinField {.inline, noinit.} =
  ## Returns the binary field with cells that will pop.
  self.withConn:
    let
      hasHas2U = connHas2 * connHas2.shiftedDownRaw
      hasHas2D = connHas2 * connHas2.shiftedUpRaw
      hasHas2R = connHas2 * connHas2.shiftedLeftRaw
      hasHas2L = connHas2 * connHas2.shiftedRightRaw

    connVisible * sum(connHas3, hasHas2U, hasHas2D, hasHas2R, hasHas2L).dilated

func canPop*(self: BinField): bool {.inline, noinit.} =
  ## Returns `true` if any cell can pop.
  ## Note that this function is only slightly lighter than `extractedPop`.
  self.withConn:
    let
      hasHas2U = connHas2 * connHas2.shiftedDownRaw
      hasHas2R = connHas2 * connHas2.shiftedLeftRaw

    sum(connHas3, hasHas2U, hasHas2R) != BinField.init

# ------------------------------------------------
# Connect - 2
# ------------------------------------------------

func conn2(self: BinField, inclV, inclH: static bool): BinField {.inline, noinit.} =
  ## Returns the binary field where exactly two cells are connected.
  let
    existU = self.shiftedDownRaw
    existD = self.shiftedUpRaw
    existR = self.shiftedLeftRaw
    existL = self.shiftedRightRaw
    existDR = existD.shiftedLeftRaw

  when inclV:
    let
      existDD = existD.shiftedUpRaw
      existDL = existD.shiftedRightRaw
      hasD = self * existD
      hasExactD = hasD - sum(existU, existR, existL, existDD, existDR, existDL)
      conn2V = hasExactD + hasExactD.shiftedDownRaw

  when inclH:
    let
      existRR = existR.shiftedLeftRaw
      existRU = existR.shiftedDownRaw
      hasR = self * existR
      hasExactR = hasR - sum(existL, existU, existD, existRR, existRU, existDR)
      conn2H = hasExactR + hasExactR.shiftedRightRaw

  when inclV and inclH:
    conn2V + conn2H
  elif inclV:
    conn2V
  elif inclH:
    conn2H
  else:
    BinField.init # dummy

func conn2*(self: BinField): BinField {.inline, noinit.} =
  ## Returns the binary field where exactly two cells are connected.
  self.conn2(inclV = true, inclH = true)

func conn2Vertical*(self: BinField): BinField {.inline, noinit.} =
  ## Returns the binary field where exactly two cells are connected vertically.
  self.conn2(inclV = true, inclH = false)

func conn2Horizontal*(self: BinField): BinField {.inline, noinit.} =
  ## Returns the binary field where exactly two cells are connected horizontally.
  self.conn2(inclV = false, inclH = true)

# ------------------------------------------------
# Connect - 3
# ------------------------------------------------

func conn3Impl(self: BinField, onlyL: static bool): BinField {.inline, noinit.} =
  ## Returns the binary field where exactly three cells are connected.
  let
    hasU = self * self.shiftedDownRaw
    hasD = self * self.shiftedUpRaw
    hasR = self * self.shiftedLeftRaw
    hasL = self * self.shiftedRightRaw

    hasUD = hasU * hasD
    hasRL = hasR * hasL
    hasUorD = hasU + hasD
    hasRorL = hasR + hasL

    has3 = hasUD * hasRorL + hasRL * hasUorD
    has2 = sum(hasUD, hasRL, hasUorD * hasRorL)

    hasHas2U = has2 * has2.shiftedDownRaw
    hasHas2D = has2 * has2.shiftedUpRaw
    hasHas2R = has2 * has2.shiftedLeftRaw
    hasHas2L = has2 * has2.shiftedRightRaw

    canPop = sum(has3, hasHas2U, hasHas2D, hasHas2R, hasHas2L).dilated
    exclude =
      when onlyL:
        sum(hasUD.dilatedVertical, hasRL.dilatedHorizontal, canPop)
      else:
        canPop

  has2.dilated * self - exclude

func conn3*(self: BinField): BinField {.inline, noinit.} =
  ## Returns the binary field where exactly three cells are connected.
  self.conn3Impl false

func conn3Vertical*(self: BinField): BinField {.inline, noinit.} =
  ## Returns the binary field where exactly three cells are connected vertically.
  let
    existU = self.shiftedDownRaw
    existD = self.shiftedUpRaw
    existR = self.shiftedLeftRaw
    existL = self.shiftedRightRaw

    existUU = existU.shiftedDownRaw
    existUR = existU.shiftedLeftRaw
    existUL = existU.shiftedRightRaw
    existDD = existD.shiftedUpRaw
    existDR = existD.shiftedLeftRaw
    existDL = existD.shiftedRightRaw

    hasU = self * existU
    hasD = self * existD

    hasExactUD =
      hasU * hasD -
      sum(existR, existL, existUU, existUR, existUL, existDD, existDR, existDL)

  hasExactUD.dilatedVertical

func conn3Horizontal*(self: BinField): BinField {.inline, noinit.} =
  ## Returns the binary field where exactly three cells are connected horizontally.
  let
    existU = self.shiftedDownRaw
    existD = self.shiftedUpRaw
    existR = self.shiftedLeftRaw
    existL = self.shiftedRightRaw

    existRR = existR.shiftedLeftRaw
    existRU = existR.shiftedDownRaw
    existRD = existR.shiftedUpRaw
    existLL = existL.shiftedRightRaw
    existLU = existL.shiftedDownRaw
    existLD = existL.shiftedUpRaw

    hasR = self * existR
    hasL = self * existL

    hasExactRL =
      hasR * hasL -
      sum(existU, existD, existRR, existRU, existRD, existLL, existLU, existLD)

  hasExactRL.dilatedHorizontal

func conn3LShape*(self: BinField): BinField {.inline, noinit.} =
  ## Returns the binary field where exactly three cells are connected by L-shape.
  self.conn3Impl true

# ------------------------------------------------
# BinaryField <-> array
# ------------------------------------------------

func toArr*(self: BinField): array[Row, array[Col, bool]] {.inline, noinit.} =
  ## Returns the array converted from the binary field.
  var arr {.noinit.}: array[Row, array[Col, bool]]
  staticFor(row, Row):
    staticFor(col, Col):
      {.push warning[Uninit]: off.}
      arr[row][col].assign self[row, col]
      {.pop.}

  arr

func toBinField*(arr: array[Row, array[Col, bool]]): BinField {.inline, noinit.} =
  ## Returns the binary field converted from the array.
  var binField = BinField.init
  staticFor(row, Row):
    staticFor(col, Col):
      binField[row, col] = arr[row][col]

  binField

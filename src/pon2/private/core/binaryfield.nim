## This module implements binary fields.
##
## Low-level Implementation Documentations:
## - [xmm](./binaryfield/xmm.html)
## - [bit64](./binaryfield/bit64.html)
## - [bit32](./binaryfield/bit32.html)
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[setutils]
import ../[assign, simd, staticfor]
import ../../core/[behaviour, common, placement]

export common, placement

when Sse42Available:
  import ./binaryfield/[xmm]
  import ../[math]
  export xmm

  type BinaryField* = XmmBinaryField ## Binary field.
elif defined(cpu32):
  import ./binaryfield/[bit32]
  export bit32

  type BinaryField* = Bit32BinaryField ## Binary field.
else:
  import ./binaryfield/[bit64]
  export bit64

  type BinaryField* = Bit64BinaryField ## Binary field.

# ------------------------------------------------
# Property
# ------------------------------------------------

func isDead*(self: BinaryField, deadRule: DeadRule): bool {.inline, noinit.} =
  ## Returns `true` if the binary field is in a defeated state.
  case deadRule
  of DeadRule.Tsu:
    self[Row1, Col2]
  of Fever:
    self[Row1, Col2] or self[Row1, Col3]
  of DeadRule.Water:
    self * BinaryField.initLowerAir != BinaryField.init

# ------------------------------------------------
# Placement
# ------------------------------------------------

const
  AllCols = {Col.low .. Col.high}
  OuterCols: array[Col, set[Col]] =
    [{Col0}, {Col0, Col1}, AllCols, {Col3, Col4, Col5}, {Col4, Col5}, {Col5}]
  InvalidPlacements: array[Col, set[Placement]] = [
    {Up0, Right0, Down0, Left1},
    {Up1, Right1, Down1, Left1, Right0, Left2},
    {Up2, Right2, Down2, Left2, Right1, Left3},
    {Up3, Right3, Down3, Left3, Right2, Left4},
    {Up4, Right4, Down4, Left4, Right3, Left5},
    {Up5, Down5, Left5, Right4},
  ]

func invalidPlacements*(self: BinaryField): set[Placement] {.inline, noinit.} =
  ## Returns the invalid placements.
  var
    invalidPlacements = set[Placement]({})
    availableCols = AllCols

  # If puyo exists at 12th row, that column and outer ones are unavailable,
  # and the pivot-puyo cannot be lifted at that column.
  staticFor(col, Col):
    if self[Row1, col]:
      availableCols.excl OuterCols[col]
      invalidPlacements.incl Placement.init(col, Down)

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
    invalidPlacements.incl InvalidPlacements[col]

  invalidPlacements.incl Placement.None

  invalidPlacements

func validPlacements*(self: BinaryField): set[Placement] {.inline, noinit.} =
  ## Returns the valid placements.
  self.invalidPlacements.complement

func validDoublePlacements*(self: BinaryField): set[Placement] {.inline, noinit.} =
  ## Returns the valid placements for double pairs.
  DoublePlacements - self.invalidPlacements

# ------------------------------------------------
# Dilate
# ------------------------------------------------

func dilated(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Dilates the binary field.
  sum(
    self, self.shiftedUpRaw, self.shiftedDownRaw, self.shiftedRightRaw,
    self.shiftedLeftRaw,
  )

func dilatedVertical(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Dilates the binary field vertically.
  sum(self, self.shiftedUpRaw, self.shiftedDownRaw)

func dilatedHorizontal(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Dilates the binary field horizontally.
  sum(self, self.shiftedRightRaw, self.shiftedLeftRaw)

# ------------------------------------------------
# Pop
# ------------------------------------------------

template withConnection(self: BinaryField, body: untyped): untyped =
  ## Calculates the connection data and runs the body with `connectionVisible`,
  ## `connectionHas3`, and `connectionHas2` exposed.
  ## This function ignores ghost puyos.
  block:
    let
      connectionVisible {.inject.} = self.keptVisible

      hasU = connectionVisible * connectionVisible.shiftedDownRaw
      hasD = connectionVisible * self.shiftedUpRaw
      hasR = connectionVisible * self.shiftedLeftRaw
      hasL = connectionVisible * self.shiftedRightRaw

      hasUD = hasU * hasD
      hasRL = hasR * hasL
      hasUorD = hasU + hasD
      hasRorL = hasR + hasL

      connectionHas3 {.inject.} = hasUD * hasRorL + hasRL * hasUorD
      connectionHas2 {.inject.} = sum(hasUD, hasRL, hasUorD * hasRorL)

    body

func extractedPop*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field with cells that will pop.
  self.withConnection:
    let
      hasHas2U = connectionHas2 * connectionHas2.shiftedDownRaw
      hasHas2D = connectionHas2 * connectionHas2.shiftedUpRaw
      hasHas2R = connectionHas2 * connectionHas2.shiftedLeftRaw
      hasHas2L = connectionHas2 * connectionHas2.shiftedRightRaw

    connectionVisible *
      sum(connectionHas3, hasHas2U, hasHas2D, hasHas2R, hasHas2L).dilated

func canPop*(self: BinaryField): bool {.inline, noinit.} =
  ## Returns `true` if any cell can pop.
  ## Note that this function is only slightly lighter than `extractedPop`.
  self.withConnection:
    let
      hasHas2U = connectionHas2 * connectionHas2.shiftedDownRaw
      hasHas2R = connectionHas2 * connectionHas2.shiftedLeftRaw

    sum(connectionHas3, hasHas2U, hasHas2R) != BinaryField.init

# ------------------------------------------------
# Connect - 2
# ------------------------------------------------

func connection2(
    self: BinaryField, inclV, inclH: static bool
): BinaryField {.inline, noinit.} =
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
      connection2V = hasExactD + hasExactD.shiftedDownRaw

  when inclH:
    let
      existRR = existR.shiftedLeftRaw
      existRU = existR.shiftedDownRaw
      hasR = self * existR
      hasExactR = hasR - sum(existL, existU, existD, existRR, existRU, existDR)
      connection2H = hasExactR + hasExactR.shiftedRightRaw

  when inclV and inclH:
    connection2V + connection2H
  elif inclV:
    connection2V
  elif inclH:
    connection2H
  else:
    BinaryField.init # dummy

func connection2*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field where exactly two cells are connected.
  self.connection2(inclV = true, inclH = true)

func connection2Vertical*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field where exactly two cells are connected vertically.
  self.connection2(inclV = true, inclH = false)

func connection2Horizontal*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field where exactly two cells are connected horizontally.
  self.connection2(inclV = false, inclH = true)

# ------------------------------------------------
# Connect - 3
# ------------------------------------------------

func connection3Impl(
    self: BinaryField, onlyL: static bool
): BinaryField {.inline, noinit.} =
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

func connection3*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field where exactly three cells are connected.
  self.connection3Impl false

func connection3Vertical*(self: BinaryField): BinaryField {.inline, noinit.} =
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

func connection3Horizontal*(self: BinaryField): BinaryField {.inline, noinit.} =
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

func connection3LShape*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field where exactly three cells are connected by L-shape.
  self.connection3Impl true

# ------------------------------------------------
# BinaryField <-> array
# ------------------------------------------------

func toArray*(self: BinaryField): array[Row, array[Col, bool]] {.inline, noinit.} =
  ## Returns the array converted from the binary field.
  var arr {.noinit.}: array[Row, array[Col, bool]]
  staticFor(row, Row):
    staticFor(col, Col):
      {.push warning[Uninit]: off.}
      arr[row][col].assign self[row, col]
      {.pop.}

  arr

func toBinaryField*(
    valArray: array[Row, array[Col, bool]]
): BinaryField {.inline, noinit.} =
  ## Returns the binary field converted from the array.
  var binaryField = BinaryField.init
  staticFor(row, Row):
    staticFor(col, Col):
      binaryField[row, col] = valArray[row][col]

  binaryField

## This module implements binary fields.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[setutils]
import ../[assign, math, setutils, simd, staticfor]
import ../../core/[behaviour, common, placement]

export common, placement

when Sse42Available:
  import ./binaryfield/[xmm]
  export xmm
elif defined(cpu32):
  import ./binaryfield/[bit32]
  export bit32
else:
  import ./binaryfield/[bit64]
  export bit64

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
    self * BinaryField.initAirBottom != BinaryField.init

# ------------------------------------------------
# Placement
# ------------------------------------------------

const
  AllCols = Col.fullSet
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

  # If puyo exists at `Row1`, that column and outer ones are unavailable,
  # and the pivot-puyo cannot be lifted at that column.
  staticFor(col, Col):
    if self[Row1, col]:
      availableCols.excl OuterCols[col]
      invalidPlacements.incl Placement.init(col, Down)

  # If available columns with height 11 exist, or the heights of the 2nd and
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
# Shift
# ------------------------------------------------

func shiftedUp*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted upward and trimmed.
  self.shiftedUpRaw.keptValid

func shiftedDown*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted downward and trimmed.
  self.shiftedDownRaw.keptValid

func shiftedRight*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted rightward and trimmed.
  self.shiftedRightRaw.keptValid

func shiftedLeft*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field shifted leftward and trimmed.
  self.shiftedLeftRaw.keptValid

func shiftUp*(self: var BinaryField) {.inline, noinit.} =
  ## Shifts the binary field upward and trims.
  self.assign self.shiftedUp

func shiftDown*(self: var BinaryField) {.inline, noinit.} =
  ## Shifts the binary field downward and trims.
  self.assign self.shiftedDown

func shiftRight*(self: var BinaryField) {.inline, noinit.} =
  ## Shifts the binary field rightward and trims.
  self.assign self.shiftedRight

func shiftLeft*(self: var BinaryField) {.inline, noinit.} =
  ## Shifts the binary field leftward and trims.
  self.assign self.shiftedLeft

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

template popHelper(self: BinaryField, body: untyped): untyped =
  ## Helper of `extractedPop` and `canPop`.
  let
    visible {.inject.} = self.keptVisible

    existUp = visible.shiftedDownRaw
    existDown = visible.shiftedUpRaw
    existRight = visible.shiftedLeftRaw
    existLeft = visible.shiftedRightRaw

    existUpDown = existUp * existDown
    existRightLeft = existRight * existLeft
    existUpOrDown = existUp + existDown
    existRightOrLeft = existRight + existLeft

    has3 {.inject.} =
      (existUpDown * existRightOrLeft + existRightLeft * existUpOrDown) * visible
    has2 {.inject.} =
      (existUpDown + existRightLeft + existUpOrDown * existRightOrLeft) * visible

  body

func extractedPop*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field with cells that will pop.
  self.popHelper:
    visible * (
      has3 +
      has2 *
      sum(
        has2.shiftedUpRaw, has2.shiftedDownRaw, has2.shiftedRightRaw,
        has2.shiftedLeftRaw,
      )
    ).dilated

func canPop*(self: BinaryField): bool {.inline, noinit.} =
  ## Returns `true` if any cell can pop.
  ## Note that this function is only slightly lighter than `extractedPop`.
  self.popHelper:
    (has3 + has2 * sum(has2.shiftedDownRaw, has2.shiftedLeftRaw)) != BinaryField.init

# ------------------------------------------------
# Connection - 2
# ------------------------------------------------

func connection2(
    self: BinaryField, inclVertical, inclHorizontal: static bool
): BinaryField {.inline, noinit.} =
  ## Returns the binary field where exactly two cells are connected.
  let
    existUp = self.shiftedDownRaw
    existDown = self.shiftedUpRaw
    existRight = self.shiftedLeftRaw
    existLeft = self.shiftedRightRaw
    existDownRight = existDown.shiftedLeftRaw

  when inclVertical:
    let
      existDown2 = existDown.shiftedUpRaw
      existDownLeft = existDown.shiftedRightRaw
      hasDown = self * existDown
      hasDownOnly =
        hasDown -
        sum(existUp, existRight, existLeft, existDown2, existDownRight, existDownLeft)
      connection2Vertical = hasDownOnly + hasDownOnly.shiftedDownRaw

  when inclHorizontal:
    let
      existRight2 = existRight.shiftedLeftRaw
      existRightUp = existRight.shiftedDownRaw
      hasRight = self * existRight
      hasExactRight =
        hasRight -
        sum(existLeft, existUp, existDown, existRight2, existRightUp, existDownRight)
      connection2H = hasExactRight + hasExactRight.shiftedRightRaw

  when inclVertical and inclHorizontal:
    connection2Vertical + connection2H
  elif inclVertical:
    connection2Vertical
  elif inclHorizontal:
    connection2H
  else:
    BinaryField.init # dummy

func connection2*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field where exactly two cells are connected.
  self.connection2(inclVertical = true, inclHorizontal = true)

func connection2Vertical*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field where exactly two cells are connected vertically.
  self.connection2(inclVertical = true, inclHorizontal = false)

func connection2Horizontal*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field where exactly two cells are connected horizontally.
  self.connection2(inclVertical = false, inclHorizontal = true)

# ------------------------------------------------
# Connection - 3
# ------------------------------------------------

func connection3Impl(
    self: BinaryField, onlyLShape: static bool
): BinaryField {.inline, noinit.} =
  ## Returns the binary field where exactly three cells are connected.
  let
    hasUp = self * self.shiftedDownRaw
    hasDown = self * self.shiftedUpRaw
    hasRight = self * self.shiftedLeftRaw
    hasLeft = self * self.shiftedRightRaw

    hasUpDown = hasUp * hasDown
    hasRightLeft = hasRight * hasLeft
    hasUpOrDown = hasUp + hasDown
    hasRightOrLeft = hasRight + hasLeft

    has3 = hasUpDown * hasRightOrLeft + hasRightLeft * hasUpOrDown
    has2 = hasUpDown + hasRightLeft + hasUpOrDown * hasRightOrLeft

    canPop = (
      has3 +
      has2 *
      sum(
        has2.shiftedUpRaw, has2.shiftedDownRaw, has2.shiftedRightRaw,
        has2.shiftedLeftRaw,
      )
    ).dilated
    exclude =
      when onlyLShape:
        hasUpDown.dilatedVertical + hasRightLeft.dilatedHorizontal + canPop
      else:
        canPop

  has2.dilated * self - exclude

func connection3*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field where exactly three cells are connected.
  self.connection3Impl(onlyLShape = false)

func connection3LShape*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field where exactly three cells are connected by L-shape.
  self.connection3Impl(onlyLShape = true)

func connection3Vertical*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field where exactly three cells are connected vertically.
  let
    existUp = self.shiftedDownRaw
    existDown = self.shiftedUpRaw
    existRight = self.shiftedLeftRaw
    existLeft = self.shiftedRightRaw

    existUp2 = existUp.shiftedDownRaw
    existUpRight = existUp.shiftedLeftRaw
    existUpLeft = existUp.shiftedRightRaw
    existDown2 = existDown.shiftedUpRaw
    existDownRight = existDown.shiftedLeftRaw
    existDownLeft = existDown.shiftedRightRaw

    hasUpDownOnly =
      existUp * existDown * self -
      sum(
        existRight, existLeft, existUp2, existUpRight, existUpLeft, existDown2,
        existDownRight, existDownLeft,
      )

  hasUpDownOnly.dilatedVertical

func connection3Horizontal*(self: BinaryField): BinaryField {.inline, noinit.} =
  ## Returns the binary field where exactly three cells are connected horizontally.
  let
    existUp = self.shiftedDownRaw
    existDown = self.shiftedUpRaw
    existRight = self.shiftedLeftRaw
    existLeft = self.shiftedRightRaw

    existRight2 = existRight.shiftedLeftRaw
    existRightUp = existRight.shiftedDownRaw
    existRightDown = existRight.shiftedUpRaw
    existLeftLeft = existLeft.shiftedRightRaw
    existLeftUp = existLeft.shiftedDownRaw
    existLeftDown = existLeft.shiftedUpRaw

    hasRightLeftOnly =
      existRight * existLeft * self -
      sum(
        existUp, existDown, existRight2, existRightUp, existRightDown, existLeftLeft,
        existLeftUp, existLeftDown,
      )

  hasRightLeftOnly.dilatedHorizontal

# ------------------------------------------------
# BinaryField <-> array
# ------------------------------------------------

func toArray*(self: BinaryField): array[Row, array[Col, bool]] {.inline, noinit.} =
  ## Returns the array converted from the binary field.
  var boolArray {.noinit.}: array[Row, array[Col, bool]]
  staticFor(row, Row):
    staticFor(col, Col):
      {.push warning[Uninit]: off.}
      boolArray[row][col].assign self[row, col]
      {.pop.}

  boolArray

func toBinaryField*(
    boolArray: array[Row, array[Col, bool]]
): BinaryField {.inline, noinit.} =
  ## Returns the binary field converted from the array.
  var binaryField = BinaryField.init
  staticFor(row, Row):
    staticFor(col, Col):
      binaryField[row, col] = boolArray[row][col]

  binaryField

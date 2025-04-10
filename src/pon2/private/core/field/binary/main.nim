## This module implements binary fields.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[setutils]
import ../../../[assign3, simd, staticfor2]
import ../../../../core/[common, placement, rule]

when Sse42Available:
  import ./[xmm]
  export xmm

  type
    BinField* = XmmBinField
    DropMask* = XmmDropMask

elif defined(cpu32):
  import ./[bit32]
  export bit32

  type
    BinField* = Bit32BinField
    DropMask* = Bit32DropMask

else:
  import ./[bit64]
  export bit64

  type
    BinField* = Bit64BinField
    DropMask* = Bit64DropMask

# ------------------------------------------------
# Property
# ------------------------------------------------

func isDead*(self: BinField, rule: static Rule): bool {.inline.} =
  ## Returns `true` if the binary field is in a defeated state.
  when rule == Tsu:
    self[Row1, Col2]
  else:
    self * BinField.initLowerAir != BinField.initZero

# ------------------------------------------------
# Placement
# ------------------------------------------------

const
  AllCols = {Col.low .. Col.high}
  OuterCols: array[Col, set[Col]] =
    [{Col0}, {Col0, Col1}, {}, {Col3, Col4, Col5}, {Col4, Col5}, {Col5}]
  InvalidPlcmts: array[Col, set[Placement]] = [
    {Up0, Right0, Down0, Left1},
    {Up1, Right1, Down1, Left1, Right0, Left2},
    {Up2, Right2, Down2, Left2, Right1, Left3},
    {Up3, Right3, Down3, Left3, Right2, Left4},
    {Up4, Right4, Down4, Left4, Right3, Left5},
    {Up5, Down5, Left5, Right4},
  ]

func invalidPlacements*(self: BinField): set[Placement] {.inline.} =
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
    canMawashi = canMawashi and self[Row2, col]
  if canMawashi:
    availableCols = AllCols

  # If puyo exists at 13th row, that column and outer ones are unavailable.
  staticFor(col, Col):
    if self[Row0, col]:
      availableCols.excl OuterCols[col]

  for col in availableCols.complement:
    invalidPlcmts.incl InvalidPlcmts[col]

  invalidPlcmts

func validPlacements*(self: BinField): set[Placement] {.inline.} =
  ## Returns the valid placements.
  self.invalidPlacements.complement

func validDblPlacements*(self: BinField): set[Placement] {.inline.} =
  ## Returns the valid placements for double pairs.
  DblPlacements - self.invalidPlacements

# ------------------------------------------------
# Expand
# ------------------------------------------------

func expanded*(self: BinField): BinField {.inline.} =
  ## Dilates the binary field.
  sum(
    self, self.shiftedUpRaw, self.shiftedDownRaw, self.shiftedRightRaw,
    self.shiftedLeftRaw,
  )

func expandedVertical(self: BinField): BinField {.inline.} =
  ## Dilates the binary field vertically.
  sum(self, self.shiftedUpRaw, self.shiftedDownRaw)

func expandedHorizontal(self: BinField): BinField {.inline.} =
  ## Dilates the binary field horizontally.
  sum(self, self.shiftedRightRaw, self.shiftedLeftRaw)

# ------------------------------------------------
# Pop
# ------------------------------------------------

template calcConnAnd(self: BinField, calcPopped: static bool, body: untyped): untyped =
  ## Calculates the connection data and rus the body.
  ## This function ignores ghost puyos.
  ## Injects `connVisible`, `connHasUpDown`, `connHasRightLeft`, `connHas3`, and
  ## `connHas2`.
  ## If `calcPopped` is true, `connPopped` is also injected. 
  let
    connVisible {.inject.} = self.keptVisible

    hasU = connVisible * connVisible.shiftedDownRaw
    hasD = connVisible * self.shiftedUpRaw
    hasR = connVisible * self.shiftedLeftRaw
    hasL = connVisible * self.shiftedRightRaw

    connHasUpDown {.inject.} = hasU * hasD
    connHasRightLeft {.inject.} = hasR * hasL
    hasUorD = hasU + hasD
    hasRorL = hasR + hasL

    connHas3 {.inject.} = connHasUpDown * hasRorL + connHasRightLeft * hasUorD
    connHas2 {.inject.} = sum(connHasUpDown, connHasRightLeft, hasUorD * hasRorL)

  when calcPopped:
    let
      hasHas2U = connHas2 * connHas2.shiftedDownRaw
      hasHas2D = connHas2 * connHas2.shiftedUpRaw
      hasHas2R = connHas2 * connHas2.shiftedLeftRaw
      hasHas2L = connHas2 * connHas2.shiftedRightRaw

      connPopped {.inject.} =
        connVisible * sum(connHas3, hasHas2U, hasHas2D, hasHas2R, hasHas2L).expanded

  body

func popped*(self: BinField): BinField {.inline.} =
  ## Returns the binary field where four or more cells are connected.
  ## This function ignores ghost puyos.
  self.calcConnAnd(calcPopped = true):
    connPopped

func willPop*(self: BinField): bool {.inline.} =
  ## Returns `true` if four or more cells are connected.
  ## This function ignores ghost puyos.
  self.calcConnAnd(calcPopped = false):
    let
      hasHas2U = connHas2 * connHas2.shiftedDownRaw
      hasHas2R = connHas2 * connHas2.shiftedLeftRaw

    sum(connHas3, hasHas2U, hasHas2R) != BinField.initZero

# ------------------------------------------------
# Connect - 2
# ------------------------------------------------

func conn2(self: BinField, inclV, inclH: static bool): BinField {.inline.} =
  ## Returns the binary field where exactly two cells are connected.
  ## This function ignores ghost puyos.
  let
    existU = self.shiftedDownRaw
    existD = self.shiftedUpRaw
    existR = self.shiftedLeftRaw
    existL = self.shiftedRightRaw
    existDR = existD.shiftedLeftRaw
    visible = self.keptVisible

  when inclV:
    let
      existDD = existD.shiftedUpRaw
      existDL = existD.shiftedRightRaw
      hasD = visible * existD
      hasExactD = hasD - sum(existU, existR, existL, existDD, existDR, existDL)
      conn2V = hasExactD + hasExactD.shiftedDownRaw

  when inclH:
    let
      existRR = existR.shiftedLeftRaw
      existRU = existR.shiftedDownRaw
      hasR = visible * existR
      hasExactR = hasR - sum(existL, existU, existD, existRR, existRU, existDR)
      conn2H = hasExactR + hasExactR.shiftedRightRaw

  when inclV and inclH:
    conn2V + conn2H
  elif inclV:
    conn2V
  elif inclH:
    conn2H
  else:
    BinField.initZero # dummy

func conn2*(self: BinField): BinField {.inline.} =
  ## Returns the binary field where exactly two cells are connected.
  ## This function ignores ghost puyos.
  self.conn2(inclV = true, inclH = true)

func conn2Vertical*(self: BinField): BinField {.inline.} =
  ## Returns the binary field where exactly two cells are connected vertically.
  ## This function ignores ghost puyos.
  self.conn2(inclV = true, inclH = false)

func connect2Horizontal*(self: BinField): BinField {.inline.} =
  ## Returns the binary field where exactly two cells are connected horizontally.
  ## This function ignores ghost puyos.
  self.conn2(inclV = false, inclH = true)

# ------------------------------------------------
# Connect - 3
# ------------------------------------------------

func connect3*(self: BinField): BinField {.inline.} =
  ## Returns the binary field where exactly three cells are connected.
  ## This function ignores ghost puyos.
  self.calcConnAnd(calcPopped = true):
    connHas3.expanded * connVisible - connPopped

func connect3Vertical*(self: BinField): BinField {.inline.} =
  ## Returns the binary field where exactly three cells are connected vertically.
  ## This function ignores ghost puyos.
  let
    visible = self.keptVisible

    existU = visible.shiftedDownRaw
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

  hasExactUD.expandedVertical

func connect3Horizontal*(self: BinField): BinField {.inline.} =
  ## Returns the binary field where exactly three cells are connected horizontally.
  ## This function ignores ghost puyos.
  let
    visible = self.keptVisible

    existU = visible.shiftedDownRaw
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

  hasExactRL.expandedHorizontal

func connect3LShape*(self: BinField): BinField {.inline.} =
  ## Returns the binary field where exactly three cells are connected by L-shape.
  ## This function ignores ghost puyos.
  self.calcConnAnd(calcPopped = true):
    connHas3.expanded * connVisible -
      sum(
        connPopped, connHasUpDown.expandedVertical, connHasRightLeft.expandedHorizontal
      )

# ------------------------------------------------
# BinaryField <-> array
# ------------------------------------------------

func toArr*(self: BinField): array[Row, array[Col, bool]] {.inline.} =
  ## Returns the array converted from the binary field.
  var arr: array[Row, array[Col, bool]]
  staticFor(row, Row):
    staticFor(col, Col):
      {.push warning[Uninit]: off.}
      arr[row][col].assign self[row, col]
      {.pop.}

  arr

func toBinField*(arr: array[Row, array[Col, bool]]): BinField {.inline.} =
  ## Returns the binary field converted from the array.
  var binField = BinField.initZero
  staticFor(row, Row):
    staticFor(col, Col):
      binField[row, col] = arr[row][col]

  binField

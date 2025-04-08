## This module implements binary fields.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[setutils]
import ../../../[assign3, intrinsic, staticfor2]
import ../../../../core/[common, placement, rule]

when UseSse42:
  import ./[xmm]
  export xmm

  type BinField* = XmmBinField
elif defined(cpu32):
  import ./[bit32]
  export bit32

  type BinField* = Bit32BinField
else:
  import ./[bit64]
  export bit64

  type BinField* = Bit64BinField

type Conn = object ## Connection data.
  visible: BinField
  hasUD: BinField
  hasRL: BinField
  has3: BinField
  has2: BinField

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
# Shift
# ------------------------------------------------

func shiftedUp*(self: BinField): BinField {.inline.} =
  ## Returns the binary field shifted upward and extracted only the valid area.
  self.shiftedUpRaw.keptValid

func shiftedDown*(self: BinField): BinField {.inline.} =
  ## Returns the binary field shifted downward and extracted only the valid area.
  self.shiftedDownRaw.keptValid

func shiftedRight*(self: BinField): BinField {.inline.} =
  ## Returns the binary field shifted rightward and extracted only the valid area.
  self.shiftedRightRaw.keptValid

func shiftedLeft*(self: BinField): BinField {.inline.} =
  ## Returns the binary field shifted leftward and extracted only the valid area.
  self.shiftedLeftRaw.keptValid

func shiftUp*(self: var BinField) {.inline.} =
  ## Shifts the binary field upward and extracts only the valid area.
  self.shiftUpRaw
  self.keepValid

func shiftDown*(self: var BinField) {.inline.} =
  ## Shifts the binary field downward and extracts only the valid area.
  self.shiftDownRaw
  self.keepValid

func shiftRight*(self: var BinField) {.inline.} =
  ## Shifts the binary field rightward and extracts only the valid area.
  self.shiftRightRaw
  self.keepValid

func shiftLeft*(self: var BinField) {.inline.} =
  ## Shifts the binary field leftward and extracts only the valid area.
  self.shiftLeftRaw
  self.keepValid

# ------------------------------------------------
# Expand
# ------------------------------------------------

func expanded*(self: BinField): BinField {.inline.} =
  ## Dilates the binary field.
  sum(
    self, self.shiftedUpRaw, self.shiftedDownRaw, self.shiftedRightRaw,
    self.shiftedLeftRaw,
  )

func expandedV(self: BinField): BinField {.inline.} =
  ## Dilates the binary field vertically.
  sum(self, self.shiftedUpRaw, self.shiftedDownRaw)

func expandedH(self: BinField): BinField {.inline.} =
  ## Dilates the binary field horizontally.
  sum(self, self.shiftedRightRaw, self.shiftedLeftRaw)

# ------------------------------------------------
# Pop
# ------------------------------------------------

func calcConn(self: BinField): Conn {.inline.} =
  ## Returns the connection data.
  ## This function ignores ghost puyos.
  let
    visible = self.keptVisible

    hasU = visible * visible.shiftedDownRaw
    hasD = visible * self.shiftedUpRaw
    hasR = visible * self.shiftedLeftRaw
    hasL = visible * self.shiftedRightRaw

    hasUD = hasU * hasD
    hasRL = hasR * hasL
    hasUorD = hasU + hasD
    hasRorL = hasR + hasL

    has3 = hasUD * hasRorL + hasRL * hasUorD
    has2 = sum(hasUD, hasRL, hasUorD * hasRorL)

  Conn(visible: visible, hasUD: hasUD, hasRL: hasRL, has3: has3, has2: has2)

func popped(conn: Conn): BinField {.inline.} =
  ## Returns the binary field where four or more cells are connected.
  ## This function ignores ghost puyos.
  let
    hasHas2U = conn.has2 * conn.has2.shiftedDownRaw
    hasHas2D = conn.has2 * conn.has2.shiftedUpRaw
    hasHas2R = conn.has2 * conn.has2.shiftedLeftRaw
    hasHas2L = conn.has2 * conn.has2.shiftedRightRaw

  conn.visible * sum(conn.has3, hasHas2U, hasHas2D, hasHas2R, hasHas2L).expanded

func popped*(self: BinField): BinField {.inline.} =
  ## Returns the binary field where four or more cells are connected.
  ## This function ignores ghost puyos.
  self.calcConn.popped

func willPop*(self: BinField): bool {.inline.} =
  ## Returns `true` if four or more cells are connected.
  ## This function ignores ghost puyos.
  let
    conn = self.calcConn
    hasHas2U = conn.has2 * conn.has2.shiftedDownRaw
    hasHas2R = conn.has2 * conn.has2.shiftedLeftRaw

  sum(conn.has3, hasHas2U, hasHas2R) != BinField.initZero

# ------------------------------------------------
# Connect
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

func conn2V*(self: BinField): BinField {.inline.} =
  ## Returns the binary field where exactly two cells are connected vertically.
  ## This function ignores ghost puyos.
  self.conn2(inclV = true, inclH = false)

func connect2H*(self: BinField): BinField {.inline.} =
  ## Returns the binary field where exactly two cells are connected horizontally.
  ## This function ignores ghost puyos.
  self.conn2(inclV = false, inclH = true)

func connect3*(self: BinField): BinField {.inline.} =
  ## Returns the binary field where exactly three cells are connected.
  ## This function ignores ghost puyos.
  let conn = self.calcConn
  conn.has3.expanded * conn.visible - conn.popped

func connect3V*(self: BinField): BinField {.inline.} =
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

  hasExactUD.expandedV

func connect3H*(self: BinField): BinField {.inline.} =
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

  hasExactRL.expandedH

func connect3L*(self: BinField): BinField {.inline.} =
  ## Returns the binary field where exactly three cells are connected by L-shape.
  ## This function ignores ghost puyos.
  let conn = self.calcConn
  conn.has3.expanded * conn.visible -
    sum(conn.popped, conn.hasUD.expandedV, conn.hasRL.expandedH)

# ------------------------------------------------
# BinaryField <-> array
# ------------------------------------------------

func toArr*(self: BinField): array[Row, array[Col, bool]] {.inline.} =
  ## Returns the array converted from the binary field.
  var arr {.noinit.}: array[Row, array[Col, bool]]
  staticFor(row, Row):
    staticFor(col, Col):
      arr[row][col].assign self[row, col]

  arr

func toBinField*(arr: array[Row, array[Col, bool]]): BinField {.inline.} =
  ## Returns the binary field converted from the array.
  var binField = BinField.initZero
  staticFor(row, Row):
    staticFor(col, Col):
      binField[row, col] = arr[row][col]

  binField

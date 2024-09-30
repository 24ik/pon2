## This module implements binary fields.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[bitops, setutils]
import ../../[intrinsic]
import ../../../core/[fieldtype, position, rule]

when UseAvx2:
  import ./avx2/binary
else:
  when defined(cpu32):
    import ./primitive/bit32/binary
  else:
    import ./primitive/bit64/binary

export binary.popcnt

type Connection = object ## Intermediate results for calculating connections.
  visible: BinaryField
  hasUpDown: BinaryField
  hasRightLeft: BinaryField
  connect4T: BinaryField
  connect3IL: BinaryField

using
  self: BinaryField
  mSelf: var BinaryField

# ------------------------------------------------
# Property
# ------------------------------------------------

func isDead*(self; rule: Rule): bool {.inline.} =
  ## Returns `true` if the field is in a defeated state.
  case rule
  of Tsu:
    bool self.exist(1, 2)
  of Water:
    not self.row(WaterRow.low.pred).isZero

# ------------------------------------------------
# Position
# ------------------------------------------------

const
  AllColumns = {Column.low .. Column.high}
  OuterColumns: array[2, array[Column, set[Column]]] =
    [[{}, {}, {}, {}, {}, {}], [{0}, {0, 1}, {}, {3, 4, 5}, {4, 5}, {5}]]
  LiftPositions: array[2, array[Column, set[Position]]] =
    [[{}, {}, {}, {}, {}, {}], [{Down0}, {Down1}, {Down2}, {Down3}, {Down4}, {Down5}]]
  InvalidPositions: array[Column, set[Position]] = [
    {Up0, Right0, Down0, Left1},
    {Up1, Right1, Down1, Left1, Right0, Left2},
    {Up2, Right2, Down2, Left2, Right1, Left3},
    {Up3, Right3, Down3, Left3, Right2, Left4},
    {Up4, Right4, Down4, Left4, Right3, Left5},
    {Up5, Down5, Left5, Right4},
  ]

func invalidPositions*(self): set[Position] {.inline.} =
  ## Returns the invalid positions.
  ## `Position.None` is not included.
  result = {}
  var usableColumns = AllColumns

  # If any puyo is in the 12th row, that column and its outer ones cannot be
  # used, and the axis-puyo cannot be lifted at the column.
  for col in Column.low .. Column.high:
    let row12 = self.exist(1, col)
    usableColumns.excl OuterColumns[row12][col]
    result.incl LiftPositions[row12][col]

  # If there is a usable column with height 11, or the heights of the 2nd and
  # 4th columns are both 12, all columns are usable.
  var allColumnsUsable = bitand(self.exist(1, 1), self.exist(1, 3))
  for col in usableColumns:
    allColumnsUsable.setMask self.exist(2, col)
  usableColumns = [usableColumns, AllColumns][allColumnsUsable]

  # If any puyo is in the 13th row, that column and its outer ones cannot be
  # used.
  for col in Column.low .. Column.high:
    usableColumns.excl OuterColumns[self.exist(0, col)][col]

  for col in usableColumns.complement:
    result.incl InvalidPositions[col]

func validPositions*(self): set[Position] {.inline.} =
  ## Returns the valid positions.
  ## `Position.None` is not included.
  AllPositions - self.invalidPositions

func validDoublePositions*(self): set[Position] {.inline.} =
  ## Returns the valid positions for a double pair.
  ## `Position.None` is not included.
  AllDoublePositions - self.invalidPositions

# ------------------------------------------------
# Shift
# ------------------------------------------------

func shiftUpWithoutTrim*(mSelf; amount: static int32 = 1) {.inline.} =
  ## Shifts the binary field upward.
  mSelf = mSelf.shiftedUpWithoutTrim amount

func shiftDownWithoutTrim*(mSelf; amount: static int32 = 1) {.inline.} =
  ## Shifts the binary field downward.
  mSelf = mSelf.shiftedDownWithoutTrim amount

func shiftRightWithoutTrim*(mSelf) {.inline.} =
  ## Shifts the binary field rightward.
  mSelf = mSelf.shiftedRightWithoutTrim

func shiftLeftWithoutTrim*(mSelf) {.inline.} =
  ## Shifts the binary field leftward.
  mSelf = mSelf.shiftedLeftWithoutTrim

func shiftedUp*(self): BinaryField {.inline.} =
  ## Returns the binary field shifted upward and then trimmed.
  self.shiftedUpWithoutTrim.trimmed

func shiftedDown*(self): BinaryField {.inline.} =
  ## Returns the binary field shifted downward and then trimmed.
  self.shiftedDownWithoutTrim.trimmed

func shiftedRight*(self): BinaryField {.inline.} =
  ## Returns the binary field shifted rightward and then trimmed.
  self.shiftedRightWithoutTrim.trimmed

func shiftedLeft*(self): BinaryField {.inline.} =
  ## Returns the binary field shifted leftward and then trimmed.
  self.shiftedLeftWithoutTrim.trimmed

# ------------------------------------------------
# Flip
# ------------------------------------------------

func flipV*(mSelf) {.inline.} =
  mSelf = mSelf.flippedV
  # Flips the binary field vertically.

func flipH*(mSelf) {.inline.} =
  mSelf = mSelf.flippedH
  # Flips the binary field horizontally.

# ------------------------------------------------
# Expand
# ------------------------------------------------

func expanded*(self): BinaryField {.inline.} =
  ## Dilates the binary field.
  ## This function does not trim.
  sum(
    self, self.shiftedUpWithoutTrim, self.shiftedDownWithoutTrim,
    self.shiftedRightWithoutTrim, self.shiftedLeftWithoutTrim,
  )

func expandedV(self): BinaryField {.inline.} =
  ## Dilates the binary field vertically.
  ## This function does not trim.
  sum(self, self.shiftedUpWithoutTrim, self.shiftedDownWithoutTrim)

func expandedH(self): BinaryField {.inline.} =
  ## Dilates the binary field horizontally.
  ## This function does not trim.
  sum(self, self.shiftedRightWithoutTrim, self.shiftedLeftWithoutTrim)

# ------------------------------------------------
# Disappear
# ------------------------------------------------

func connections(self): Connection {.inline.} =
  ## Returns intermediate results for calculating connections.
  let
    visibleCells = self.visible

    hasUp = visibleCells * visibleCells.shiftedDownWithoutTrim
    hasDown = visibleCells * visibleCells.shiftedUpWithoutTrim
    hasRight = visibleCells * visibleCells.shiftedLeftWithoutTrim
    hasLeft = visibleCells * visibleCells.shiftedRightWithoutTrim

    hasUpDown = hasUp * hasDown
    hasRightLeft = hasRight * hasLeft
    hasUpOrDown = hasUp + hasDown
    hasRightOrLeft = hasRight + hasLeft

    connect4T = hasUpDown * hasRightOrLeft + hasRightLeft * hasUpOrDown
    connect3IL = sum(hasUpDown, hasRightLeft, hasUpOrDown * hasRightOrLeft)

  result.visible = visibleCells
  result.hasUpDown = hasUpDown
  result.hasRightLeft = hasRightLeft
  result.connect4T = connect4T
  result.connect3IL = connect3IL

func disappeared(connection: Connection): BinaryField {.inline.} =
  ## Returns the binary field where four or more cells are connected.
  let
    connect4Up = connection.connect3IL * connection.connect3IL.shiftedUpWithoutTrim
    connect4Down = connection.connect3IL * connection.connect3IL.shiftedDownWithoutTrim
    connect4Right =
      connection.connect3IL * connection.connect3IL.shiftedRightWithoutTrim
    connect4Left = connection.connect3IL * connection.connect3IL.shiftedLeftWithoutTrim

  result =
    connection.visible * (
      sum(connection.connect4T, connect4Up, connect4Down, connect4Right, connect4Left)
    ).expanded

func disappeared*(self): BinaryField {.inline.} =
  ## Returns the binary field where four or more cells are connected.
  self.connections.disappeared

func willDisappear*(self): bool {.inline.} =
  ## Returns `true` if four or more cells are connected.
  let
    connection = self.connections
    connect4Up = connection.connect3IL * connection.connect3IL.shiftedUpWithoutTrim
    connect4Right =
      connection.connect3IL * connection.connect3IL.shiftedRightWithoutTrim

  result = not sum(connection.connect4T, connect4Up, connect4Right).isZero

# ------------------------------------------------
# Connect
# ------------------------------------------------

func connect2*(self): BinaryField {.inline.} =
  ## Returns the binary field with only the locations where exactly two
  ## cells are connected.
  ## This function ignores ghost puyos.
  let
    visibleField = self.visible

    up = visibleField.shiftedUpWithoutTrim
    down = visibleField.shiftedDownWithoutTrim
    right = visibleField.shiftedRightWithoutTrim
    left = visibleField.shiftedLeftWithoutTrim

    upRight = up.shiftedRightWithoutTrim

    seedV =
      visibleField * up -
      sum(
        up.shiftedUpWithoutTrim, down, right, left, upRight, up.shiftedLeftWithoutTrim
      )
    seedH =
      visibleField * right -
      sum(
        right.shiftedRightWithoutTrim, up, down, left, upRight,
        right.shiftedDownWithoutTrim,
      )

  result = sum(seedV.shiftedDownWithoutTrim, seedV, seedH.shiftedLeftWithoutTrim, seedH)

func connect2V*(self): BinaryField {.inline.} =
  ## Returns the binary field with only the locations where exactly two
  ## cells are connected vertically.
  ## This function ignores ghost puyos.
  let
    visibleField = self.visible

    up = visibleField.shiftedUpWithoutTrim
    down = visibleField.shiftedDownWithoutTrim
    right = visibleField.shiftedRightWithoutTrim
    left = visibleField.shiftedLeftWithoutTrim

    seed =
      visibleField * up -
      sum(
        up.shiftedUpWithoutTrim, down, right, left, up.shiftedRightWithoutTrim,
        up.shiftedLeftWithoutTrim,
      )

  result = seed + seed.shiftedDownWithoutTrim

func connect2H*(self): BinaryField {.inline.} =
  ## Returns the binary field with only the locations where exactly two
  ## cells are connected horizontally.
  ## This function ignores ghost puyos.
  let
    visibleField = self.visible

    up = visibleField.shiftedUpWithoutTrim
    down = visibleField.shiftedDownWithoutTrim
    right = visibleField.shiftedRightWithoutTrim
    left = visibleField.shiftedLeftWithoutTrim

    seed =
      visibleField * right -
      sum(
        right.shiftedRightWithoutTrim, up, down, left, right.shiftedUpWithoutTrim,
        right.shiftedDownWithoutTrim,
      )

  result = seed + seed.shiftedLeftWithoutTrim

func connect3*(self): BinaryField {.inline.} =
  ## Returns the binary field with only the locations where exactly three
  ## cells are connected.
  ## This function ignores ghost puyos.
  let connection = self.connections
  result = connection.connect3IL.expanded * connection.visible - connection.disappeared

func connect3V*(self): BinaryField {.inline.} =
  ## Returns the binary field with only the locations where exactly three
  ## cells are connected vertically.
  ## This function ignores ghost puyos.
  let
    visibleField = self.visible

    up = visibleField.shiftedUpWithoutTrim
    down = visibleField.shiftedDownWithoutTrim
    right = visibleField.shiftedRightWithoutTrim
    left = visibleField.shiftedLeftWithoutTrim

    upDown = prod(visibleField, up, down)
    exclude =
      visibleField *
      sum(
        right, left, up.shiftedRightWithoutTrim, up.shiftedLeftWithoutTrim,
        down.shiftedRightWithoutTrim, down.shiftedLeftWithoutTrim,
        up.shiftedUpWithoutTrim, down.shiftedDownWithoutTrim,
      )

  result = (upDown - exclude).expandedV

func connect3H*(self): BinaryField {.inline.} =
  ## Returns the binary field with only the locations where exactly three
  ## cells are connected horizontally.
  ## This function ignores ghost puyos.
  let
    visibleField = self.visible

    up = visibleField.shiftedUpWithoutTrim
    down = visibleField.shiftedDownWithoutTrim
    right = visibleField.shiftedRightWithoutTrim
    left = visibleField.shiftedLeftWithoutTrim

    rightLeft = prod(visibleField, right, left)
    exclude =
      visibleField *
      sum(
        up, down, up.shiftedRightWithoutTrim, up.shiftedLeftWithoutTrim,
        down.shiftedRightWithoutTrim, down.shiftedLeftWithoutTrim,
        right.shiftedRightWithoutTrim, left.shiftedLeftWithoutTrim,
      )

  result = (rightLeft - exclude).expandedH

func connect3L*(self: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field with only the locations where exactly three
  ## cells are connected by L-shape.
  ## This function ignores ghost puyos.
  let connection = self.connections
  result =
    connection.connect3IL.expanded * connection.visible -
    sum(
      connection.disappeared, connection.hasUpDown.expandedV,
      connection.hasRightLeft.expandedH,
    )

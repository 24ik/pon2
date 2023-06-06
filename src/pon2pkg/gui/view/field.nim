## This module implements the field control.
##

import sugar

import nazopuyo_core
import nigui
import puyo_core

import ../config
import ../resource
import ../state

type FieldControl* = ref object of LayoutContainer
  ## Field control.
  nazo: ref Nazo

  mode: ref Mode
  focus: ref Focus
  inserted: ref bool

  cfg: ref Config
  resource: ref Resource

  cursor*: tuple[row: Row, col: Col]

# ------------------------------------------------
# Property
# ------------------------------------------------

proc fieldControl(event: DrawEvent): FieldControl {.inline.} =
  ## Returns the field control from the :code:`event`.
  let control = event.control.parentWindow.control.childControls[1].childControls[0].childControls[1]
  assert control of FieldControl
  return cast[FieldControl](control)

# ------------------------------------------------
# Constructor
# ------------------------------------------------

proc cellDrawHandler(event: DrawEvent, row: Row, col: Col) {.inline.} =
  ## Draws cells in the field.
  let
    control = event.fieldControl
    theme = control.cfg[].theme
    canvas = event.control.canvas

  canvas.areaColor =
    if control.mode[] == Mode.EDIT and control.focus[] == Focus.FIELD and control.cursor == (row, col): theme.bgSelect
    elif row == Row.low: theme.bgGhost
    else: theme.bgControl

  if control.inserted[]:
    let halfHeight = control.resource[].cellImageHeight div 2

    # lower half
    canvas.drawRectArea 0, halfHeight, control.resource[].cellImageWidth, halfHeight

    # upper half
    canvas.areaColor = if row == Row.low: theme.bgGhost else: theme.bgControl
    canvas.drawRectArea 0, 0, control.resource[].cellImageWidth, halfHeight
  else:
    canvas.fill

  canvas.drawImage control.resource[].cellImages[control.nazo[].env.field[row, col]]

proc newCellControl(row: Row, col: Col): Control {.inline.} =
  ## Returns a new cell control.
  result = newControl()
  result.onDraw = (event: DrawEvent) => event.cellDrawHandler(row, col)

proc newFieldControl*(
  nazo: ref Nazo,

  mode: ref Mode,
  focus: ref Focus,
  inserted: ref bool,

  cfg: ref Config,
  resource: ref Resource,

  cursor = (row: Row.high, col: Col.low),
): FieldControl {.inline.} =
  ## Returns a new field control.
  result = new FieldControl
  result.init
  result.layout = Layout_Vertical

  result.nazo = nazo
  result.mode = mode
  result.focus = focus
  result.inserted = inserted
  result.cfg = cfg
  result.resource = resource
  result.cursor = cursor

  for row in Row.low .. Row.high:
    let line = newLayoutContainer Layout_Horizontal
    line.spacing = 0
    line.padding = 0

    for col in Col.low .. Col.high:
      let cell = newCellControl(row, col)
      cell.width = resource[].cellImageWidth
      cell.height = resource[].cellImageHeight
      line.add cell

    result.add line

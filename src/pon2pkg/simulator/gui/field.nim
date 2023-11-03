## This module implements the field control.
##

{.experimental: "strictDefs".}

import std/[sugar]
import nigui
import ./[assets, misc]
import ../[simulator, render]
import ../../core/[field, misc]

type FieldControl* = ref object of LayoutContainer
  ## Field control.
  simulator: ref Simulator
  assets: ref Assets


proc cellDrawHandler(control: FieldControl, event: DrawEvent, row: Row,
                     col: Column) {.inline.} =
  ## Draws the cell.
  let canvas = event.control.canvas

  canvas.areaColor =
    control.simulator[].fieldCellBackgroundColor(row, col).toColor
  canvas.fill

  let cell = control.simulator[].withField:
    field[row, col]
  canvas.drawImage control.assets[].cellImages[cell]

func initeCellDrawHandler(control: FieldControl, row: Row, col: Column):
    (event: DrawEvent) -> void =
  ## Returns the handler.
  # NOTE: inline handler does not work due to specifications
  (event: DrawEvent) => control.cellDrawHandler(event, row, col)

proc initFieldControl*(simulator: ref Simulator, assets: ref Assets):
    FieldControl {.inline.} =
  ## Returns a field control.
  result = new FieldControl
  result.init
  result.layout = Layout_Vertical

  result.simulator = simulator
  result.assets = assets

  for row in Row.low..Row.high:
    let line = newLayoutContainer Layout_Horizontal
    result.add line

    line.spacing = 0
    line.padding = 0

    for col in Column.low .. Column.high:
      let cell = newControl()
      line.add cell

      cell.height = assets[].cellImageSize.height
      cell.width = assets[].cellImageSize.width
      cell.onDraw = result.initeCellDrawHandler(row, col)

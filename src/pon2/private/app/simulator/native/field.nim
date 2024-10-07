## This module implements the field control.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import nigui
import ./[assets]
import ../[common]
import ../../../../app/[color, nazopuyo, simulator]
import ../../../../core/[cell, field, fieldtype]

type FieldControl* = ref object of LayoutContainer not nil ## Field control.
  simulator: ref Simulator
  assets: Assets

proc cellDrawHandler(
    control: FieldControl, event: DrawEvent, row: Row, col: Column
) {.inline.} =
  ## Draws the cell.
  let canvas = event.control.canvas

  canvas.areaColor = control.simulator[].fieldCellBackgroundColor(row, col).toNiguiColor
  canvas.fill

  let cell: Cell
  control.simulator[].nazoPuyoWrap.get:
    cell = wrappedNazoPuyo.puyoPuyo.field[row, col]
  canvas.drawImage control.assets[].cellImages[cell]

func newCellDrawHandler(
    control: FieldControl, row: Row, col: Column
): (event: DrawEvent) -> void =
  ## Returns the handler.
  # NOTE: cannot inline due to lazy evaluation
  (event: DrawEvent) => control.cellDrawHandler(event, row, col)

proc newFieldControl*(
    simulator: ref Simulator, assets: Assets
): FieldControl {.inline.} =
  ## Returns a field control.
  {.push warning[ProveInit]: off.}
  result.new
  {.pop.}
  result.init
  result.layout = Layout_Vertical

  result.simulator = simulator
  result.assets = assets

  for row in Row.low .. Row.high:
    let line = newLayoutContainer Layout_Horizontal
    result.add line

    line.spacing = 0
    line.padding = 0

    for col in Column.low .. Column.high:
      let cell = newControl()
      line.add cell

      cell.height = assets.cellImageSize.height
      cell.width = assets.cellImageSize.width
      cell.onDraw = result.newCellDrawHandler(row, col)

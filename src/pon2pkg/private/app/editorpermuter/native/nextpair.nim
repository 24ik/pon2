## This module implements the next pair control.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import nigui
import ./[assets]
import ../[render]
import ../../../../apppkg/[misc, simulator]
import ../../../../corepkg/[cell, fieldtype, misc]

type NextPairControl* = ref object of LayoutContainer
  ## Next pair control.
  simulator: ref Simulator
  assets: ref Assets

proc cellDrawHandler(control: NextPairControl, event: DrawEvent,
                     idx: range[-1..1], col: Column) {.inline.} =
  ## Draws cell.
  let canvas = event.control.canvas

  canvas.areaColor = DefaultColor.toNiguiColor
  canvas.fill

  canvas.drawImage control.assets[].cellImages[
    if control.simulator[].mode == Edit: None
    else: control.simulator[].nextPairCell(idx, col)]

func initCellDrawHandler(control: NextPairControl, idx: range[-1..1],
                         col: Column): (event: DrawEvent) -> void =
  ## Returns the handler.
  # NOTE: cannot inline due to lazy evaluation
  (event: DrawEvent) => control.cellDrawHandler(event, idx, col)

proc initNextPairControl*(simulator: ref Simulator, assets: ref Assets):
    NextPairControl {.inline.} =
  ## Returns a next pair control.
  result = new NextPairControl
  result.init
  result.layout = Layout_Vertical

  result.simulator = simulator
  result.assets = assets

  for idx in -1..1:
    let line = newLayoutContainer Layout_Horizontal
    result.add line

    line.spacing = 0
    line.padding = 0

    for col in Column.low..Column.high:
      let cell = newControl()
      line.add cell

      cell.height = assets[].cellImageSize.height
      cell.width = assets[].cellImageSize.width
      cell.onDraw = result.initCellDrawHandler(idx, col)

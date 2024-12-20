## This module implements the operating control.
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
import ../../../../app/[color, simulator]
import ../../../../core/[cell, fieldtype]

type OperatingPairControl* = ref object of LayoutContainer ## Operating control.
  simulator: Simulator
  assets: Assets

proc cellDrawHandler(
    control: OperatingPairControl, event: DrawEvent, idx: range[-1 .. 1], col: Column
) {.inline.} =
  ## Draws cell.
  let canvas = event.control.canvas

  canvas.areaColor = DefaultColor.toNiguiColor
  canvas.fill

  canvas.drawImage control.assets.cellImages[
    if control.simulator.mode == Edit:
      None
    else:
      control.simulator.operatingPairCell(idx, col)
  ]

func newCellDrawHandler(
    control: OperatingPairControl, idx: range[-1 .. 1], col: Column
): (event: DrawEvent) -> void =
  ## Returns the handler.
  # NOTE: cannot inline due to lazy evaluation
  (event: DrawEvent) => control.cellDrawHandler(event, idx, col)

proc newOperatingControl*(
    simulator: Simulator, assets: Assets
): OperatingPairControl {.inline.} =
  ## Returns an operating control.
  {.push warning[ProveInit]: off.}
  result.new
  {.pop.}
  result.init
  result.layout = Layout_Vertical

  result.simulator = simulator
  result.assets = assets

  for idx in -1 .. 1:
    let line = newLayoutContainer Layout_Horizontal
    result.add line

    line.spacing = 0
    line.padding = 0

    for col in Column.low .. Column.high:
      let cell = newControl()
      line.add cell

      cell.height = assets.cellImageSize.height
      cell.width = assets.cellImageSize.width
      cell.onDraw = result.newCellDrawHandler(idx, col)

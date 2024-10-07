## This module implements the immediate pairs control.
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
import ../../../../core/[cell]

type ImmediatePairsControl* = ref object of LayoutContainer ## Immediate pairs control.
  simulator: ref Simulator
  assets: Assets

proc cellDrawHandler(
    control: ImmediatePairsControl, event: DrawEvent, idx: Natural
) {.inline.} =
  ## Draws the cell.
  let canvas = event.control.canvas

  canvas.areaColor = DefaultColor.toNiguiColor
  canvas.fill

  let cell =
    if control.simulator[].mode == Edit:
      None
    else:
      case idx
      of 0 .. 2:
        Cell.None
      of 3:
        control.simulator[].immediateNextPairCell false
      of 4:
        control.simulator[].immediateNextPairCell true
      of 5:
        Cell.None
      of 6:
        control.simulator[].immediateDoubleNextPairCell false
      of 7:
        control.simulator[].immediateDoubleNextPairCell true
      else:
        Cell.None
  canvas.drawImage control.assets[].cellImages[cell]

func newCellDrawHandler(
    control: ImmediatePairsControl, idx: Natural
): (event: DrawEvent) -> void =
  ## Returns the draw handler.
  # NOTE: cannot inline due to lazy evaluation
  (event: DrawEvent) => control.cellDrawHandler(event, idx)

proc newImmediatePairsControl*(
    simulator: ref Simulator, assets: Assets
): ImmediatePairsControl {.inline.} =
  ## Returns an immediate pairs control.
  {.push warning[ProveInit]: off.}
  result.new
  {.pop.}
  result.init
  result.layout = Layout_Vertical

  result.simulator = simulator
  result.assets = assets

  result.spacing = 0
  result.padding = 0

  for idx in 0 .. 7:
    let cell = newControl()
    result.add cell

    cell.height = assets.cellImageSize.height
    cell.width = assets.cellImageSize.width
    cell.onDraw = result.newCellDrawHandler idx
